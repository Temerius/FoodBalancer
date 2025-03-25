CREATE MATERIALIZED VIEW popular_recipes AS
SELECT 
  r.rcp_id,
  r.rcp_title,
  COUNT(fvr.fvr_id) AS favorites_count
FROM recipe r
LEFT JOIN favorite_recipe fvr ON fvr.fvr_rcp_id = r.rcp_id
GROUP BY r.rcp_id
ORDER BY favorites_count DESC
LIMIT 10;