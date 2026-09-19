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


-- Query 4 - Counts the accepted groups across all observations, provides a count for each group and a percentage of how often they are explicitly welcome at a community. 
SELECT g.group_name,
       COUNT(l.observation_id) AS observations,
       ROUND(100.0 * COUNT(l.observation_id)
             / (SELECT COUNT(*) FROM community_observations WHERE notes NOT LIKE 'Not a listing%'), 1) AS pct_of_listings
FROM accepted_groups g
LEFT JOIN observation_accepted_groups l ON l.group_id = g.group_id
GROUP BY g.group_id
ORDER BY g.group_id;


-- Query 5 - Shows/counts the number of times a group is accepted in a specific issue. 
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

-- Query 6 - Provides a count of how many times a community shows up in the observation table, then shows the change between listings of the number of residents.
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


-- Query 7 - Shows resident count for each issue and provides the overall change. 
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


-- Query 8 - Shows total resident counts among all communities in each issue, provides an average, min, and max. 
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



-- Query 9
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


-- Query 10
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
