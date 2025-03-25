CREATE MATERIALIZED VIEW equipment_recipe_usage AS
SELECT 
    eqp.eqp_id,
    eqp.eqp_type,
    eqp.eqp_img_url AS equipment_image,
    COUNT(DISTINCT mre.mre_rcp_id) AS used_in_recipes_count,
    ARRAY_AGG(DISTINCT rcp.rcp_title) AS sample_recipes
FROM equipment eqp
LEFT JOIN m2m_rcp_eqp mre ON eqp.eqp_id = mre.mre_eqp_id
LEFT JOIN recipe rcp ON mre.mre_rcp_id = rcp.rcp_id
GROUP BY eqp.eqp_id, eqp.eqp_type, eqp.eqp_img_url;