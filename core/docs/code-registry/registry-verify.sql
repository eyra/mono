-- code-registry: verify the registry columns against the per-type columns (read-only).
-- Run after each release-1/2 migration step on the rehearsal copy and on staging;
-- the Next team runs it on production after the release-1 deploy.
-- Expected: the four lines of the first query are 0. In the second query, the per-type
-- counts equal registry-prod-shape.sql checks 2 and 8, and type 'none' equals the "0"
-- rows of checks 3 and 9 (prod, 17 Nov: 6 tool_refs, 0 project_items).
--
\set ON_ERROR_STOP on
BEGIN TRANSACTION READ ONLY;
SET LOCAL statement_timeout = '60s';

SELECT 'tool_refs without type, or without id outside none' AS check, count(*) AS n
  FROM tool_refs WHERE tool_type IS NULL OR (tool_id IS NULL AND tool_type <> 'none')
UNION ALL
SELECT 'tool_refs mismatch', count(*) FROM tool_refs WHERE
  tool_type IS DISTINCT FROM coalesce(CASE
    WHEN alliance_tool_id IS NOT NULL THEN 'alliance' WHEN document_tool_id IS NOT NULL THEN 'document'
    WHEN feldspar_tool_id IS NOT NULL THEN 'feldspar' WHEN graphite_tool_id IS NOT NULL THEN 'graphite'
    WHEN instruction_tool_id IS NOT NULL THEN 'instruction' WHEN lab_tool_id IS NOT NULL THEN 'lab'
    WHEN manual_tool_id IS NOT NULL THEN 'manual' WHEN zircon_screening_tool_id IS NOT NULL THEN 'zircon_screening' END, 'none')
  OR tool_id IS DISTINCT FROM coalesce(alliance_tool_id, document_tool_id, feldspar_tool_id,
    graphite_tool_id, instruction_tool_id, lab_tool_id, manual_tool_id, zircon_screening_tool_id)
UNION ALL
SELECT 'project_items without type, or without id outside none', count(*)
  FROM project_items WHERE item_type IS NULL OR (item_id IS NULL AND item_type <> 'none')
UNION ALL
SELECT 'project_items mismatch', count(*) FROM project_items WHERE
  item_type IS DISTINCT FROM coalesce(CASE
    WHEN assignment_id IS NOT NULL THEN 'assignment' WHEN advert_id IS NOT NULL THEN 'advert'
    WHEN leaderboard_id IS NOT NULL THEN 'leaderboard' WHEN storage_endpoint_id IS NOT NULL THEN 'storage_endpoint' END, 'none')
  OR item_id IS DISTINCT FROM coalesce(assignment_id, advert_id, leaderboard_id, storage_endpoint_id);

SELECT 'tool_type' AS check, coalesce(tool_type, '<null>') AS key, count(*) AS n FROM tool_refs GROUP BY tool_type
UNION ALL
SELECT 'item_type', coalesce(item_type, '<null>'), count(*) FROM project_items GROUP BY item_type
ORDER BY 1, 2;

ROLLBACK;
