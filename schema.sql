-- =====================================================================
-- schema.sql
-- HIST 8510  ·  Project 1
--
-- YOUR NAME: Emma Stewart
-- YOUR SOURCES: land directories from the periodical Lesbian Connection
-- (1976-1988). This is a smaller, hand-checked rebuild of the Week 2
-- database: every row was checked cell by cell against the scanned page.
-- The tables are structured to fit most of the information these listings
-- provide.
-- =====================================================================



DROP TABLE IF EXISTS observation_focuses;
DROP TABLE IF EXISTS focuses;
DROP TABLE IF EXISTS observation_accepted_groups;
DROP TABLE IF EXISTS accepted_groups;
DROP TABLE IF EXISTS community_observations;
DROP TABLE IF EXISTS communities;
DROP TABLE IF EXISTS sources;
DROP TABLE IF EXISTS community_types;


-- ---------------------------------------------------------------------
-- Tables 1 to 5 — lookup or "one" side: community types, accepted groups, focuses, sources, and communities
-- ---------------------------------------------------------------------
-- all of these are lookup or one sided tables. The community types table will denote whether a community, at the time of observation, was listed as a land trust, intentional community, cooperative, privately owned, retreat, or as an idea (usually a call for a land fund or something)
-- the accepted groups will have a list of controlled vocab for the types of people welcome at the land community
-- the sources table lists all of my sources
-- the communities table is a comprehensive list of individual communities with additional information about them; community observations is just a snapshot while this is more concrete
--
CREATE TABLE community_types (
     type_id     INTEGER PRIMARY KEY,
     type_name   TEXT NOT NULL UNIQUE,
     description TEXT
);
CREATE TABLE accepted_groups (
     group_id     INTEGER PRIMARY KEY,
     group_name   TEXT NOT NULL UNIQUE
);
-- the focuses table is controlled vocab for what a community was built around
-- beyond who is welcome: populations it centers (disabled women, older women),
-- politics (separatism), and purposes (farming, spirituality, workshops).
-- I added it after The Beachtree (LC Dec 1982), a community of disabled
-- lesbians: accepted_groups sorts people by sexuality, gender and age only, so
-- without this table that community's reason for existing lived only in text.
-- A focus is coded only when the listing presents it as a purpose, identity, or
-- rule of the place, not a passing mention or a questionnaire checkbox.
CREATE TABLE focuses (
     focus_id     INTEGER PRIMARY KEY,
     focus_name   TEXT NOT NULL UNIQUE,
     description  TEXT
);
-- One row is one issue of a periodical. There is no section column: the page
-- each listing appears on is recorded on its observation instead, which
-- points back to the scan more precisely than a section name would.
CREATE TABLE sources (
     source_id   INTEGER PRIMARY KEY,
     publication TEXT NOT NULL,
     year        INTEGER,
     month       TEXT,
     volume      INTEGER,
     issue       INTEGER,
     file_name   TEXT

);
-- There are no first/last observed year or location columns here on purpose.
-- Every observation already carries year_recorded and the land's location,
-- so storing them again on the community would just be a second copy that
-- could fall out of sync with the observations. When I need a community's
-- first and last years, I calculate them with MIN/MAX(year_recorded), and
-- its location comes from the land_* columns of its observations.
CREATE TABLE communities (
     community_id   INTEGER PRIMARY KEY,
     name   TEXT NOT NULL,
     alternate_names    TEXT,
     notes  TEXT
 );


-- ---------------------------------------------------------------------
-- Table 6 — the central table, the thing I have the most rows of
-- ---------------------------------------------------------------------
-- The community observations is the central table. One row is one MENTION of a community in one source. Type ID is nullable because not all locations have an explicit type.
CREATE TABLE community_observations (
    observation_id  INTEGER PRIMARY KEY,

    community_id INTEGER NOT NULL,
    source_id INTEGER NOT NULL,
    type_id INTEGER,

    page INTEGER, -- the printed page number the listing appears on

    year_recorded INTEGER,
    month_recorded TEXT,

    -- The contact_* columns are the mailing address given in the listing.
    -- I do not record phone numbers or emails as separate columns: they are
    -- personal details that add nothing to the historical argument. (They
    -- survive only inside raw_text, which is the listing word for word.)
    contact_name TEXT,
    contact_street_address TEXT,
    contact_city TEXT,
    contact_state TEXT,
    contact_zip TEXT,

    -- The land_* columns are where the land itself is, which is often not
    -- where the mail goes (e.g. a Boston PO box for land in Maine). They are
    -- left blank when the listing does not say. land_location_as_stated keeps
    -- the listing's own wording for vague places like "southern Oregon" or
    -- "25 miles southeast of Tucson".
    land_street_address TEXT,
    land_city TEXT,
    land_state TEXT,
    land_zip TEXT,
    land_location_as_stated TEXT,

    acreage REAL, -- REAL instead of INTEGER because sometimes it is a fraction
    num_residents INTEGER,

    description TEXT,
    raw_text TEXT,

    -- My judgment calls about this one listing, kept apart from the listing's
    -- own words in description/raw_text: e.g. a resident range where I stored
    -- the minimum, acreage that describes surrounding land rather than land
    -- the community holds, a type I inferred, or an unreadable word.
    notes TEXT,

    FOREIGN KEY (community_id) REFERENCES communities (community_id),
    FOREIGN KEY (source_id) REFERENCES sources (source_id),
    FOREIGN KEY (type_id) REFERENCES community_types (type_id)
);


-- ---------------------------------------------------------------------
-- Tables 7 and 8 — the junction tables
-- ---------------------------------------------------------------------
-- my first junction table connects accepted groups with community observations; one observation could note that a community accepts many different "categories" of people, such as lesbian and non-lesbian women
CREATE TABLE observation_accepted_groups (
    observation_id    INTEGER NOT NULL,
    group_id    INTEGER NOT NULL,
    PRIMARY KEY (observation_id, group_id),
    FOREIGN KEY (observation_id) REFERENCES community_observations (observation_id),
    FOREIGN KEY (group_id) REFERENCES accepted_groups (group_id)
 );

-- my second junction table connects focuses with community observations; one listing can center several things at once (e.g. older, working-class, and sober lesbians). It hangs off observations rather than communities so a community's focus can change over time.
CREATE TABLE observation_focuses (
    observation_id    INTEGER NOT NULL,
    focus_id    INTEGER NOT NULL,
    PRIMARY KEY (observation_id, focus_id),
    FOREIGN KEY (observation_id) REFERENCES community_observations (observation_id),
    FOREIGN KEY (focus_id) REFERENCES focuses (focus_id)
 );


-- =====================================================================
-- PRAGMA foreign_keys = ON has to be set on every connection.
-- The FOREIGN KEY lines above do nothing without it. build_db.py sets it.
-- =====================================================================
