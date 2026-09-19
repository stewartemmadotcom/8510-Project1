-- =====================================================================
-- CHANGE OVER TIME
-- =====================================================================


-- Query 1: What communities changed type across different observations? What type did they change from and to? 
WITH typed AS (
    SELECT o.community_id, o.observation_id, s.source_id, s.year, s.month,
           t.type_name
    FROM community_observations o
    JOIN sources s         ON s.source_id = o.source_id
    JOIN community_types t ON t.type_id = o.type_id
),
in_order AS (
    SELECT *,
           LAG(type_name) OVER w AS prev_type,
           LAG(source_id) OVER w AS prev_source,
           LAG(year)      OVER w AS prev_year,
           LAG(month)     OVER w AS prev_month
    FROM typed
    WINDOW w AS (PARTITION BY community_id ORDER BY source_id, observation_id)
)
SELECT c.name,
       prev_year || ' ' || prev_month AS from_issue,
       prev_type                      AS from_type,
       year || ' ' || month           AS to_issue,
       type_name                      AS to_type
FROM in_order
JOIN communities c ON c.community_id = in_order.community_id
WHERE prev_type IS NOT NULL
  AND prev_source <> source_id
  AND prev_type <> type_name
ORDER BY c.name, source_id;


-- Query 2 - Pairs different observations from the same community, then shows if type changed and how many times it shows up in observations
WITH typed AS (
    SELECT o.community_id, o.observation_id, s.source_id, t.type_name
    FROM community_observations o
    JOIN sources s         ON s.source_id = o.source_id
    JOIN community_types t ON t.type_id = o.type_id
),
in_order AS (
    SELECT *,
           LAG(type_name) OVER w AS prev_type,
           LAG(source_id) OVER w AS prev_source
    FROM typed
    WINDOW w AS (PARTITION BY community_id ORDER BY source_id, observation_id)
)
SELECT prev_type AS from_type,
       type_name AS to_type,
       CASE WHEN prev_type = type_name THEN 'same' ELSE 'changed' END AS result,
       COUNT(*)  AS times
FROM in_order
WHERE prev_type IS NOT NULL
  AND prev_source <> source_id
GROUP BY prev_type, type_name
ORDER BY result, times DESC, from_type;


-- Query 3 - Shows every community that shows up multiple times and documents the type they were listed under for each observation. 
SELECT c.name,
       COUNT(*) AS observations,
       GROUP_CONCAT(
           s.year || ': ' ||
           COALESCE(t.type_name,
               CASE
                   WHEN o.notes LIKE 'Not a listing: LAND SOLD%'      THEN '(land sold)'
                   WHEN o.notes LIKE 'Not a listing: LAND DISSOLVED%' THEN '(land dissolved)'
                   WHEN o.notes LIKE 'Not a listing: reported folded%' THEN '(reported folded)'
                   WHEN o.notes LIKE 'Not a listing: a letter%'       THEN '(letter, not a listing)'
                   ELSE '(bare listing, untyped)'
               END),
           '  ->  ' ORDER BY s.source_id, o.observation_id
       ) AS type_history
FROM community_observations o
JOIN communities c           ON c.community_id = o.community_id
JOIN sources s               ON s.source_id = o.source_id
LEFT JOIN community_types t  ON t.type_id = o.type_id
GROUP BY o.community_id
HAVING COUNT(DISTINCT o.source_id) > 1
ORDER BY c.name;


-- Query 4 - Shows/counts the number of times a group is accepted in a specific issue. 
WITH listings AS (
    SELECT s.source_id, s.year || ' ' || s.month AS issue, COUNT(*) AS n
    FROM community_observations o
    JOIN sources s ON s.source_id = o.source_id
    WHERE o.notes NOT LIKE 'Not a listing%'
    GROUP BY s.source_id
)
SELECT li.issue,
       g.group_name,
       COUNT(l.observation_id) AS observations,
       li.n AS listings_in_issue,
       ROUND(100.0 * COUNT(l.observation_id) / li.n, 1) AS pct_of_issue
FROM listings li
CROSS JOIN accepted_groups g
LEFT JOIN community_observations o ON o.source_id = li.source_id AND o.notes NOT LIKE 'Not a listing%'
LEFT JOIN observation_accepted_groups l ON l.observation_id = o.observation_id AND l.group_id = g.group_id
GROUP BY li.source_id, g.group_id
ORDER BY li.source_id, g.group_id;


-- Query 5 - Provides a count of how many times a community shows up in the observation table, then shows the change between listings of the number of residents.
SELECT c.name,
       COUNT(*) AS observations,
       GROUP_CONCAT(s.year || ': ' || COALESCE(o.num_residents, '?'),
                    '  ->  ' ORDER BY s.source_id, o.observation_id) AS residents_history
FROM community_observations o
JOIN communities c ON c.community_id = o.community_id
JOIN sources s     ON s.source_id = o.source_id
GROUP BY o.community_id
HAVING COUNT(DISTINCT o.source_id) > 1
ORDER BY c.name;


-- Query 6 - Shows resident count for each issue and provides the overall change. 
WITH known AS (
    SELECT o.community_id, o.observation_id, s.source_id, s.year, s.month, o.num_residents
    FROM community_observations o
    JOIN sources s ON s.source_id = o.source_id
    WHERE o.num_residents IS NOT NULL
),
in_order AS (
    SELECT *,
           LAG(num_residents) OVER w AS prev_residents,
           LAG(source_id)     OVER w AS prev_source,
           LAG(year)          OVER w AS prev_year,
           LAG(month)         OVER w AS prev_month
    FROM known
    WINDOW w AS (PARTITION BY community_id ORDER BY source_id, observation_id)
)
SELECT c.name,
       prev_year || ' ' || prev_month  AS from_issue,
       prev_residents                  AS from_residents,
       year || ' ' || month            AS to_issue,
       num_residents                   AS to_residents,
       num_residents - prev_residents  AS change
FROM in_order
JOIN communities c ON c.community_id = in_order.community_id
WHERE prev_residents IS NOT NULL
  AND prev_source <> source_id
ORDER BY change, c.name;


-- Query 7 - Shows total resident counts among all communities in each issue, provides an average, min, and max. 
SELECT s.year || ' ' || s.month AS issue,
       COUNT(*)                 AS listings,
       COUNT(o.num_residents)   AS listings_with_residents,
       SUM(o.num_residents)     AS total_residents,
       ROUND(AVG(o.num_residents), 1) AS avg_residents,
       MIN(o.num_residents)     AS min_residents,
       MAX(o.num_residents)     AS max_residents,
       SUM(o.num_residents = 0) AS listings_with_zero
FROM community_observations o
JOIN sources s ON s.source_id = o.source_id
WHERE o.notes NOT LIKE 'Not a listing%'
  AND o.notes NOT LIKE 'NOT WOMEN''S LAND%'
GROUP BY s.source_id
ORDER BY s.source_id;


-- Query 8 - Shows the number and percentage of focuses in each issue
WITH listings AS (
    SELECT s.source_id, s.year || ' ' || s.month AS issue, COUNT(*) AS n
    FROM community_observations o
    JOIN sources s ON s.source_id = o.source_id
    WHERE o.notes NOT LIKE 'Not a listing%'
    GROUP BY s.source_id
)
SELECT li.issue,
       f.focus_name,
       COUNT(x.observation_id) AS observations,
       li.n AS listings_in_issue,
       ROUND(100.0 * COUNT(x.observation_id) / li.n, 1) AS pct_of_issue
FROM listings li
CROSS JOIN focuses f
LEFT JOIN community_observations o ON o.source_id = li.source_id AND o.notes NOT LIKE 'Not a listing%'
LEFT JOIN observation_focuses x    ON x.observation_id = o.observation_id AND x.focus_id = f.focus_id
GROUP BY li.source_id, f.focus_id
ORDER BY li.source_id, observations DESC, f.focus_name;


-- Query 9 - Tracks each individual community, the number of observations it is listed in, and how the acreage was represented in each.
SELECT c.name,
       COUNT(*) AS observations,
       GROUP_CONCAT(s.year || ': ' || COALESCE(o.acreage, '?'),
                    '  ->  ' ORDER BY s.source_id, o.observation_id) AS acreage_history
FROM community_observations o
JOIN communities c ON c.community_id = o.community_id
JOIN sources s     ON s.source_id = o.source_id
GROUP BY o.community_id
HAVING COUNT(DISTINCT o.source_id) > 1
ORDER BY c.name;


-- Query 10 - Tracks the change in acreage between issue for individual communities. 
WITH known AS (
    SELECT o.community_id, o.observation_id, s.source_id, s.year, s.month, o.acreage
    FROM community_observations o
    JOIN sources s ON s.source_id = o.source_id
    WHERE o.acreage IS NOT NULL
),
in_order AS (
    SELECT *,
           LAG(acreage)   OVER w AS prev_acreage,
           LAG(source_id) OVER w AS prev_source,
           LAG(year)      OVER w AS prev_year,
           LAG(month)     OVER w AS prev_month
    FROM known
    WINDOW w AS (PARTITION BY community_id ORDER BY source_id, observation_id)
)
SELECT c.name,
       prev_year || ' ' || prev_month AS from_issue,
       prev_acreage                   AS from_acreage,
       year || ' ' || month           AS to_issue,
       acreage                        AS to_acreage,
       acreage - prev_acreage         AS change
FROM in_order
JOIN communities c ON c.community_id = in_order.community_id
WHERE prev_acreage IS NOT NULL
  AND prev_source <> source_id
ORDER BY change, c.name;


-- Query 11 - Charts the total acreage in each issue across all community observations from that source, as well as the average, min, and max for each. 
SELECT s.year || ' ' || s.month AS issue,
       COUNT(*)                 AS listings,
       COUNT(o.acreage)         AS listings_with_acreage,
       SUM(o.acreage)           AS total_acreage,
       ROUND(AVG(o.acreage), 1) AS avg_acreage,
       MIN(o.acreage)           AS min_acreage,
       MAX(o.acreage)           AS max_acreage
FROM community_observations o
JOIN sources s ON s.source_id = o.source_id
WHERE o.notes NOT LIKE 'Not a listing%'
  AND o.notes NOT LIKE 'NOT WOMEN''S LAND%'
GROUP BY s.source_id
ORDER BY s.source_id;


-- Query 12 - How many listings, communities, and total acreage showed up in each state per year recorded? 
SELECT CASE WHEN s.year = 1976 THEN '1976'
            WHEN s.year IN (1982, 1983) THEN '1982-83'
            ELSE '1986' END              AS period,
       COALESCE(o.land_state, '(not stated)') AS land_state,
       COUNT(*)                          AS listings,
       COUNT(DISTINCT o.community_id)    AS communities,
       SUM(o.acreage)                    AS total_acreage
FROM community_observations o
JOIN sources s ON s.source_id = o.source_id
WHERE o.notes NOT LIKE 'Not a listing%'
  AND o.notes NOT LIKE 'NOT WOMEN''S LAND%'
GROUP BY period, land_state
ORDER BY period, listings DESC, land_state;


-- Query 13 - Number of listings that accept each group by issue. 
WITH welcomed AS (
    SELECT o.observation_id, o.source_id,
           MAX(l.group_id = 1) AS lesbian,
           MAX(l.group_id = 2) AS nonlesbian,
           MAX(l.group_id = 3) AS girls,
           MAX(l.group_id = 4) AS boys,
           MAX(l.group_id IN (5, 6)) AS men,
           COUNT(l.group_id) AS n_groups
    FROM community_observations o
    LEFT JOIN observation_accepted_groups l ON l.observation_id = o.observation_id
    WHERE o.notes NOT LIKE 'Not a listing%'
  AND o.notes NOT LIKE 'NOT WOMEN''S LAND%'
    GROUP BY o.observation_id
)
SELECT s.year || ' ' || s.month                      AS issue,
       COUNT(*)                                      AS listings,
       SUM(COALESCE(girls, 0))                       AS girls_welcome,
       SUM(COALESCE(boys, 0))                        AS boys_welcome,
       SUM(COALESCE(girls, 0) AND NOT COALESCE(boys, 0)) AS girls_not_boys,
       SUM(NOT COALESCE(girls, 0) AND NOT COALESCE(boys, 0)) AS no_children,
       SUM(n_groups = 1 AND lesbian = 1)             AS lesbians_only,
       ROUND(100.0 * SUM(n_groups = 1 AND lesbian = 1) / COUNT(*), 1) AS pct_lesbians_only,
       SUM(COALESCE(nonlesbian, 0))                  AS nonlesbian_women_welcome,
       SUM(COALESCE(men, 0))                         AS men_welcome
FROM welcomed w
JOIN sources s ON s.source_id = w.source_id
GROUP BY s.source_id
ORDER BY s.source_id;


-- Query 14 - Grouped by issue (change over time), shows the total focuses, average number of focuses per listing, listings with no focus, etc.
WITH counted AS (
    SELECT o.observation_id, o.source_id, COUNT(x.focus_id) AS n_focuses
    FROM community_observations o
    LEFT JOIN observation_focuses x ON x.observation_id = o.observation_id
    WHERE o.notes NOT LIKE 'Not a listing%'
      AND o.notes NOT LIKE 'NOT WOMEN''S LAND%'
    GROUP BY o.observation_id
)
SELECT s.year || ' ' || s.month          AS issue,
       COUNT(*)                          AS listings,
       SUM(n_focuses)                    AS total_focuses,
       ROUND(AVG(n_focuses), 2)          AS avg_focuses_per_listing,
       SUM(n_focuses = 0)                AS listings_with_no_focus,
       SUM(n_focuses >= 3)               AS listings_with_3_or_more,
       MAX(n_focuses)                    AS max_focuses
FROM counted c
JOIN sources s ON s.source_id = c.source_id
GROUP BY s.source_id
ORDER BY s.source_id;


-- Query 15 - This query tracks the level of detail found across issues. 
WITH per_listing AS (
    SELECT o.observation_id, o.source_id, o.type_id, o.acreage, o.num_residents,
           o.land_state, o.land_location_as_stated,
           LENGTH(TRIM(o.raw_text)) - LENGTH(REPLACE(TRIM(o.raw_text), ' ', '')) + 1 AS words,
           (SELECT COUNT(*) FROM observation_accepted_groups l
             WHERE l.observation_id = o.observation_id) AS n_groups,
           (SELECT COUNT(*) FROM observation_focuses x
             WHERE x.observation_id = o.observation_id) AS n_focuses
    FROM community_observations o
    WHERE o.notes NOT LIKE 'Not a listing%'
      AND o.notes NOT LIKE 'NOT WOMEN''S LAND%'
)
SELECT s.year || ' ' || s.month                                          AS issue,
       COUNT(*)                                                          AS listings,
       ROUND(AVG(words), 0)                                              AS avg_words,
       ROUND(100.0 * COUNT(acreage) / COUNT(*), 1)                       AS pct_with_acreage,
       ROUND(100.0 * COUNT(num_residents) / COUNT(*), 1)                 AS pct_with_residents,
       ROUND(100.0 * COUNT(land_state) / COUNT(*), 1)                    AS pct_with_land_state,
       ROUND(100.0 * SUM(land_location_as_stated IS NOT NULL
                         AND land_location_as_stated <> '') / COUNT(*), 1) AS pct_with_land_description,
       ROUND(AVG(n_groups), 2)                                           AS avg_groups,
       ROUND(AVG(n_focuses), 2)                                          AS avg_focuses,
       ROUND(100.0 * COUNT(type_id) / COUNT(*), 1)                       AS pct_typed
FROM per_listing p
JOIN sources s ON s.source_id = p.source_id
GROUP BY s.source_id
ORDER BY s.source_id;


-- =====================================================================
-- OVERALL ANALYSIS
-- =====================================================================


-- Query 16 - Counts the accepted groups across all observations, provides a count for each group and a percentage of how often they are explicitly welcome at a community. 
SELECT g.group_name,
       COUNT(l.observation_id) AS observations,
       ROUND(100.0 * COUNT(l.observation_id)
             / (SELECT COUNT(*) FROM community_observations WHERE notes NOT LIKE 'Not a listing%'), 1) AS pct_of_listings
FROM accepted_groups g
LEFT JOIN observation_accepted_groups l ON l.group_id = g.group_id
GROUP BY g.group_id
ORDER BY g.group_id;


-- Query 17 - Provides the total number of observations and individual communities that list each focus, in additional to a percentage of listings that the focus shows up in.
SELECT f.focus_name,
       COUNT(x.observation_id) AS observations,
       COUNT(DISTINCT o.community_id) AS communities,
       ROUND(100.0 * COUNT(x.observation_id)
             / (SELECT COUNT(*) FROM community_observations WHERE notes NOT LIKE 'Not a listing%'), 1) AS pct_of_listings
FROM focuses f
LEFT JOIN observation_focuses x    ON x.focus_id = f.focus_id
LEFT JOIN community_observations o ON o.observation_id = x.observation_id
GROUP BY f.focus_id
ORDER BY observations DESC, f.focus_name;


-- Query 18 - Total listings, communities, and acreage per state. Also tracks average acreage across communities in each state. 
SELECT COALESCE(o.land_state, '(not stated)') AS land_state,
       COUNT(*)                          AS listings,
       COUNT(DISTINCT o.community_id)    AS communities,
       SUM(o.acreage)                    AS total_acreage,
       ROUND(AVG(o.acreage), 1)          AS avg_acreage
FROM community_observations o
WHERE o.notes NOT LIKE 'Not a listing%'
  AND o.notes NOT LIKE 'NOT WOMEN''S LAND%'
GROUP BY land_state
ORDER BY listings DESC, land_state;


-- Query 19 - Shows the count of communities where the land and mail address were different or the same. 
SELECT CASE
           WHEN o.land_state IS NULL                THEN 'land location not stated'
           WHEN o.land_state = o.contact_state
            AND (o.land_city IS NULL OR o.land_city = o.contact_city)
                                                    THEN 'land and mail in same place'
           WHEN o.land_state = o.contact_state      THEN 'same state, different town'
           ELSE 'land and mail in different states'
       END      AS land_vs_mail,
       COUNT(*) AS listings,
       ROUND(100.0 * COUNT(*) / (SELECT COUNT(*) FROM community_observations
                                 WHERE notes NOT LIKE 'Not a listing%'), 1) AS pct_of_listings
FROM community_observations o
WHERE o.notes NOT LIKE 'Not a listing%'
GROUP BY land_vs_mail
ORDER BY listings DESC;


-- Query 20 - Shows communities that had separate mailing and land addresses, and where each was. 
SELECT c.name,
       s.year || ' ' || s.month                            AS issue,
       COALESCE(o.contact_city || ', ', '') || o.contact_state AS mail_to,
       COALESCE(o.land_city || ', ', '') || o.land_state       AS land_in,
       o.land_location_as_stated
FROM community_observations o
JOIN communities c ON c.community_id = o.community_id
JOIN sources s     ON s.source_id = o.source_id
WHERE o.notes NOT LIKE 'Not a listing%'
  AND o.land_state IS NOT NULL
  AND (o.land_state <> o.contact_state
       OR (o.land_city IS NOT NULL AND o.land_city <> o.contact_city))
ORDER BY s.source_id, c.name;


-- Query 21 - Shows avg, min, max acreage and residents by type of community. 
SELECT t.type_name,
       COUNT(*)                          AS listings,
       COUNT(DISTINCT o.community_id)    AS communities,
       COUNT(o.acreage)                  AS listings_with_acreage,
       ROUND(AVG(o.acreage), 1)          AS avg_acreage,
       MIN(o.acreage)                    AS min_acreage,
       MAX(o.acreage)                    AS max_acreage,
       COUNT(o.num_residents)            AS listings_with_residents,
       ROUND(AVG(o.num_residents), 1)    AS avg_residents,
       MIN(o.num_residents)              AS min_residents,
       MAX(o.num_residents)              AS max_residents
FROM community_observations o
JOIN community_types t ON t.type_id = o.type_id
WHERE o.notes NOT LIKE 'NOT WOMEN''S LAND%'
GROUP BY t.type_id
ORDER BY t.type_id;


-- Query 22 - Shows the accepted groups by type of community. 
WITH per_type AS (
    SELECT o.type_id, COUNT(*) AS n
    FROM community_observations o
    WHERE o.type_id IS NOT NULL
      AND o.notes NOT LIKE 'NOT WOMEN''S LAND%'
    GROUP BY o.type_id
)
SELECT t.type_name,
       g.group_name,
       COUNT(l.observation_id)                         AS listings,
       pt.n                                            AS listings_of_type,
       ROUND(100.0 * COUNT(l.observation_id) / pt.n, 1) AS pct_of_type
FROM per_type pt
JOIN community_types t ON t.type_id = pt.type_id
CROSS JOIN accepted_groups g
LEFT JOIN community_observations o
       ON o.type_id = pt.type_id
      AND o.notes NOT LIKE 'NOT WOMEN''S LAND%'
LEFT JOIN observation_accepted_groups l
       ON l.observation_id = o.observation_id
      AND l.group_id = g.group_id
GROUP BY pt.type_id, g.group_id
ORDER BY pt.type_id, g.group_id;


-- Query 23 - Shows the focuses by type of community. 
WITH per_type AS (
    SELECT o.type_id, COUNT(*) AS n
    FROM community_observations o
    WHERE o.type_id IS NOT NULL
      AND o.notes NOT LIKE 'NOT WOMEN''S LAND%'
    GROUP BY o.type_id
)
SELECT t.type_name,
       f.focus_name,
       COUNT(x.observation_id)                         AS listings,
       pt.n                                            AS listings_of_type,
       ROUND(100.0 * COUNT(x.observation_id) / pt.n, 1) AS pct_of_type
FROM per_type pt
JOIN community_types t ON t.type_id = pt.type_id
CROSS JOIN focuses f
LEFT JOIN community_observations o
       ON o.type_id = pt.type_id
      AND o.notes NOT LIKE 'NOT WOMEN''S LAND%'
LEFT JOIN observation_focuses x
       ON x.observation_id = o.observation_id
      AND x.focus_id = f.focus_id
GROUP BY pt.type_id, f.focus_id
HAVING COUNT(x.observation_id) > 0
ORDER BY pt.type_id, listings DESC, f.focus_name;


-- Query 24 - Shows listings that accept lesbian women only 
SELECT c.name,
       s.year || ' ' || s.month AS issue,
       t.type_name
FROM community_observations o
JOIN communities c           ON c.community_id = o.community_id
JOIN sources s               ON s.source_id = o.source_id
LEFT JOIN community_types t  ON t.type_id = o.type_id
WHERE o.observation_id IN (SELECT observation_id FROM observation_accepted_groups GROUP BY observation_id HAVING COUNT(*) = 1 AND MAX(group_id) = 1)
  AND o.notes NOT LIKE 'Not a listing%'
  AND o.notes NOT LIKE 'NOT WOMEN''S LAND%'
ORDER BY s.source_id, c.name;


-- Query 25 - This query compares the community observations that listed lesbian separatism explicitly as a focus with those that did not. It shows the avg number of groups each accepted, percent that accepted non lesbian women, percent that accepted boy children, and the percent that accepted men. 
WITH welcomed AS (
    SELECT o.observation_id,
           EXISTS (SELECT 1 FROM observation_focuses x
                   WHERE x.observation_id = o.observation_id AND x.focus_id = 5) AS separatist,
           COUNT(l.group_id)            AS n_groups,
           MAX(l.group_id = 2)          AS nonlesbian,
           MAX(l.group_id = 4)          AS boys,
           MAX(l.group_id IN (5, 6))    AS men
    FROM community_observations o
    LEFT JOIN observation_accepted_groups l ON l.observation_id = o.observation_id
    WHERE o.notes NOT LIKE 'Not a listing%'
  AND o.notes NOT LIKE 'NOT WOMEN''S LAND%'
    GROUP BY o.observation_id
)
SELECT CASE WHEN separatist THEN 'separatist focus' ELSE 'no separatist focus' END AS listings_with,
       COUNT(*)                                            AS listings,
       ROUND(AVG(n_groups), 2)                             AS avg_groups_welcomed,
       ROUND(100.0 * SUM(COALESCE(nonlesbian, 0)) / COUNT(*), 1) AS pct_nonlesbian_women,
       ROUND(100.0 * SUM(COALESCE(boys, 0)) / COUNT(*), 1)       AS pct_boy_children,
       ROUND(100.0 * SUM(COALESCE(men, 0)) / COUNT(*), 1)        AS pct_men
FROM welcomed
GROUP BY separatist
ORDER BY separatist DESC;


-- Query 26 - Shows common focus pairings. 
SELECT f1.focus_name AS focus,
       f2.focus_name AS appears_with,
       COUNT(*)      AS listings
FROM observation_focuses a
JOIN observation_focuses b     ON b.observation_id = a.observation_id
                              AND b.focus_id > a.focus_id
JOIN focuses f1                ON f1.focus_id = a.focus_id
JOIN focuses f2                ON f2.focus_id = b.focus_id
JOIN community_observations o  ON o.observation_id = a.observation_id
WHERE o.notes NOT LIKE 'NOT WOMEN''S LAND%'
GROUP BY a.focus_id, b.focus_id
ORDER BY listings DESC, focus, appears_with;