# Women's Land Communities in *Lesbian Connection*, 1976–1986

HIST 8510 · Project 1 · Emma Stewart

A relational SQLite database of women's land communities (land trusts,
intentional communities, private land, retreats, and land funds) as they
were listed in the land directories and classified ads of *Lesbian
Connection* (LC). Each listing was transcribed from the scanned page and
checked cell by cell.

The database is built around **observations**. One row records one mention
of one community in one issue, so a community that appears in several issues
has one row per appearance, and changes in its size, residents, welcome
policy, type and purpose can be traced over time.

## What's in it

| | |
|---|---|
| Issues | 5 (LC Sept 1976, Dec 1982–Jan 1983, Mar/Apr 1983, June/July 1983, Mar/Apr 1986) |
| Communities | 76 |
| Observations | 107 (25 communities appear in more than one issue) |
| Accepted-group links | 305 |
| Focus links | 153 |

| Issue | Vol. | No. | Observations |
|---|---|---|---|
| September 1976 | 2 | 5 | 12 |
| December 1982–January 1983 | 6 | 1 | 31 |
| March/April 1983 | 6 | 2 | 15 |
| June/July 1983 | 6 | 3 | 17 |
| March/April 1986 | 8 | 5 | 32 |

## Tables

| Table | One row is |
|---|---|
| `sources` | one issue of LC |
| `communities` | one land community, however many times it was listed |
| `community_observations` | one listing (or mention) of one community in one issue |
| `community_types` | one category of land arrangement (lookup) |
| `accepted_groups` | one category of person a listing welcomes (lookup) |
| `observation_accepted_groups` | one group welcomed by one listing (junction) |
| `focuses` | one thing a community was built around: a population, a politics, or a purpose (lookup) |
| `observation_focuses` | one focus of one listing (junction) |

The full diagram, field definitions, controlled vocabularies and encoding
rules are in [`docs/data_model.md`](docs/data_model.md).

## Rebuilding the database

Requires Python 3 (standard library only).

```bash
python3 build_db.py
```

This deletes and rebuilds `lc_land_database.db` from `schema.sql` and the
CSVs in `source_data/`. Foreign keys are enforced during the build. The script
prints row counts, traces the community with the most listings across the
years, and checks for orphaned observations and year mismatches.

## Repository map

```
README.md                 this file
schema.sql                table definitions, with comments explaining each design choice
build_db.py               builds the database from the CSVs
lc_land_database.db       the built SQLite database
source_data/              one CSV per table (the hand-checked data)
docs/data_model.md        diagram, what one row is, vocabularies, encoding rules
docs/revision_log.md      how the schema and categories changed, errors found in the
                          earlier version of this data, and excluded listings
```

## Notes on the data

- `raw_text` reproduces each listing word for word as printed, including the
  original spellings, and the names and addresses LC published. Separate
  phone and email columns are deliberately not kept.
- Every judgment call (type, inferred land location, resident counts,
  inferred accepted groups, focus codes) is explained in that row's `notes`.
- Location is split between where the mail went (`contact_*`) and where the
  land was (`land_*`). The two are often different.
- Groups without land, rental cottages and guest houses without land, and
  events are excluded. The excluded listings are named in
  [`docs/revision_log.md`](docs/revision_log.md).

## Source

*Lesbian Connection* (East Lansing, MI: Ambitious Amazons), accessed through
Reveal Digital / JSTOR's open collection.
