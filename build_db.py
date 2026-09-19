"""
build_db.py  —  Run schema.sql and load the source CSVs into it
HIST 8510  ·  Project 1

This file is deliberately thin. It does four things:

    1. opens a connection and turns foreign key enforcement ON
    2. runs schema.sql
    3. loads the eight source CSVs, parents before children
    4. prints what it built so you can see it worked

All the interesting decisions live in schema.sql, not here. The schema is
the argument; this file is the plumbing that runs it.

Run it with:  python3 build_db.py

It deletes and rebuilds the database every time, which is what you want
while you are still changing your schema. Once you start correcting data
inside DBcode, take the delete out.
"""

import csv
import os
import sqlite3

DB_FILE = "lc_land_database.db"
SCHEMA_FILE = "schema.sql"

# (csv path, table name, column names) — loaded in this order so that
# foreign keys always point at rows that already exist. The CSVs carry
# their own integer ids, so a row here is a straight copy into the table.
SEED_FILES = [
    ("source_data/community_types.csv", "community_types",
     ["type_id", "type_name", "description"]),

    ("source_data/accepted_groups.csv", "accepted_groups",
     ["group_id", "group_name"]),

    ("source_data/focuses.csv", "focuses",
     ["focus_id", "focus_name", "description"]),

    ("source_data/sources.csv", "sources",
     ["source_id", "publication", "year", "month",
      "volume", "issue", "file_name"]),

    ("source_data/communities.csv", "communities",
     ["community_id", "name", "alternate_names", "notes"]),

    ("source_data/community_observations.csv", "community_observations",
     ["observation_id", "community_id", "source_id", "type_id", "page",
      "year_recorded", "month_recorded", "contact_name",
      "contact_street_address", "contact_city", "contact_state",
      "contact_zip", "land_street_address", "land_city", "land_state",
      "land_zip", "land_location_as_stated",
      "acreage", "num_residents", "description", "raw_text", "notes"]),

    ("source_data/observation_accepted_groups.csv", "observation_accepted_groups",
     ["observation_id", "group_id"]),

    ("source_data/observation_focuses.csv", "observation_focuses",
     ["observation_id", "focus_id"]),
]


def main():
    print("=== Building the women's land communities database ===")

    # While you are drafting, starting fresh every run is the right
    # behavior — you will be changing the schema constantly and half-built
    # tables from a previous attempt cause confusing errors.
    if os.path.exists(DB_FILE):
        os.remove(DB_FILE)
        print(f"\nRemoved the old {DB_FILE}")

    # Step 1 ---------------------------------------------------- connect
    conn = sqlite3.connect(DB_FILE)
    cursor = conn.cursor()

    # Do not delete this line. Without it every FOREIGN KEY in the schema
    # is decorative, and you can insert rows pointing at records that do
    # not exist without ever being told. It is a property of the session,
    # not the file, so it has to be set on every connection.
    cursor.execute("PRAGMA foreign_keys = ON")

    # Step 2 ----------------------------------------------- run the schema
    print(f"\nStep 1: Running {SCHEMA_FILE}...")
    with open(SCHEMA_FILE, encoding="utf-8") as f:
        cursor.executescript(f.read())
    cursor.execute("PRAGMA foreign_keys = ON")   # executescript can reset it

    # Step 3 ------------------------------------------------ load the CSVs
    print("\nStep 2: Loading source data...")
    for path, table, columns in SEED_FILES:
        if not os.path.exists(path):
            raise SystemExit(f"Cannot find {path}. Did you move source_data/?")
        with open(path, encoding="utf-8") as f:
            # Empty cells become NULL rather than the empty string, so that
            # `WHERE acreage IS NULL` finds the listings that gave no acreage.
            rows = [[r[c] if r[c] != "" else None for c in columns]
                    for r in csv.DictReader(f)]

        placeholders = ", ".join("?" for _ in columns)
        cursor.executemany(
            f"INSERT INTO {table} ({', '.join(columns)}) VALUES ({placeholders})",
            rows,
        )
        print(f"  {table:<28} {len(rows):>5} rows")

    conn.commit()

    # Step 4 ------------------------------------------------------- verify
    # A join, to prove the relationships hold and to show what the design
    # actually bought: one community, tracked across time and sources. It
    # traces whichever community has the most listings so far, since the
    # set of communities grows as issues are added.
    print("\nStep 3: Checking that the relationships hold...")

    most_listed = cursor.execute("""
        SELECT c.name FROM community_observations o
        JOIN communities c ON o.community_id = c.community_id
        GROUP BY o.community_id
        ORDER BY COUNT(*) DESC, MIN(o.year_recorded)
        LIMIT 1
    """).fetchone()
    traced_name = most_listed[0] if most_listed else None

    traced = cursor.execute("""
        SELECT  o.year_recorded,
                s.publication,
                o.num_residents,
                o.acreage,
                GROUP_CONCAT(g.group_name, ' + ') AS welcomed
        FROM community_observations o
        JOIN communities c              ON o.community_id = c.community_id
        JOIN sources s                  ON o.source_id = s.source_id
        LEFT JOIN observation_accepted_groups l
                                        ON o.observation_id = l.observation_id
        LEFT JOIN accepted_groups g     ON l.group_id = g.group_id
        WHERE c.name = ?
        GROUP BY o.observation_id
        ORDER BY o.year_recorded
    """, (traced_name,)).fetchall()

    print(f"\n  {traced_name}, across the years:")
    for year, pub, residents, acres, welcomed in traced:
        print(f"    {year}  {pub:<20} residents={residents}  acres={acres}")
        print(f"          welcomed: {welcomed}")

    orphans = cursor.execute("""
        SELECT COUNT(*) FROM community_observations o
        LEFT JOIN communities c ON o.community_id = c.community_id
        WHERE c.community_id IS NULL
    """).fetchone()[0]
    print(f"\n  Observations pointing at a community that does not exist: {orphans}")

    # year_recorded is copied from the source by hand, so check it agrees.
    mismatched = cursor.execute("""
        SELECT COUNT(*) FROM community_observations o
        JOIN sources s ON o.source_id = s.source_id
        WHERE o.year_recorded IS NOT s.year
    """).fetchone()[0]
    print(f"  Observations whose year differs from their source's year: {mismatched}")

    # Step 5 -------------------------------------------- show what got built
    tables = cursor.execute(
        "SELECT name FROM sqlite_master WHERE type='table' ORDER BY name"
    ).fetchall()

    print(f"\nBuilt {DB_FILE} with {len(tables)} tables:\n")
    for (name,) in tables:
        print(f"  {name}")
        for col in cursor.execute(f"PRAGMA table_info({name})").fetchall():
            pk = "  PRIMARY KEY" if col[5] else ""
            null = "  NOT NULL" if col[3] else ""
            print(f"      {col[1]:<24} {col[2] or '(no type)':<10}{pk}{null}")
        for fk in cursor.execute(f"PRAGMA foreign_key_list({name})").fetchall():
            print(f"      -> {fk[3]} references {fk[2]}({fk[4]})")
        print()

    conn.close()
    print("=== Done. Open it in DBcode to look at what you just made. ===")


if __name__ == "__main__":
    main()
