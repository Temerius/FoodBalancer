CREATE OR REPLACE VIEW recipe_details AS
SELECT 
    r.rcp_id,
    r.rcp_title,
    r.rcp_description,
    r.rcp_instruction,
    r.rcp_cal AS calories_per_serving,
    r.rcp_portion_count,
    STRING_AGG(DISTINCT it.igt_name, ', ') AS ingredients,
    STRING_AGG(DISTINCT e.eqp_type, ', ') AS required_equipment
FROM 
    recipe r
LEFT JOIN m2m_rcp_igt mri ON r.rcp_id = mri.mri_rcp_id
LEFT JOIN ingredient_type it ON mri.mri_igt_id = it.igt_id
LEFT JOIN m2m_rcp_eqp mre ON r.rcp_id = mre.mre_rcp_id
LEFT JOIN equipment e ON mre.mre_eqp_id = e.eqp_id
GROUP BY 
    r.rcp_id, r.rcp_title, r.rcp_description, 
    r.rcp_instruction, r.rcp_cal, r.rcp_portion_count;