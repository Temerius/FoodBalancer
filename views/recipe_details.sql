CREATE OR REPLACE VIEW recipe_details AS
SELECT 
  r.rcp_id,
  r.rcp_title,
  r.rcp_description,
  r.rcp_cal,
  r.rcp_portion_count,
  json_agg(DISTINCT stp.*) AS steps,
  json_agg(DISTINCT it.igt_name) AS ingredients
FROM recipe r
INNER JOIN step stp ON stp.stp_rcp_id = r.rcp_id
INNER JOIN m2m_stp_igt msi ON msi.msi_stp_id = stp.stp_id
INNER JOIN ingredient_type it ON it.igt_id = msi.msi_igt_id
GROUP BY r.rcp_id, r.rcp_title, r.rcp_description, r.rcp_cal, r.rcp_portion_count;