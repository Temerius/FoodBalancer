CREATE MATERIALIZED VIEW user_available_recipes AS
WITH 
user_equipment AS (
    SELECT 
        mue.mue_usr_id AS user_id,
        array_agg(mue.mue_eqp_id) AS equipment_ids
    FROM m2m_usr_eqp mue
    GROUP BY mue.mue_usr_id
),
user_ingredients AS (
    SELECT 
        mui.mui_usr_id AS user_id,
        array_agg(i.ing_igt_id) AS ingredient_type_ids
    FROM m2m_usr_ing mui
    JOIN ingredient i ON mui.mui_ing_id = i.ing_id
    GROUP BY mui.mui_usr_id
),
recipe_requirements AS (
    SELECT
        r.rcp_id,
        array_agg(DISTINCT mre.mre_eqp_id) AS required_equipment,
        array_agg(DISTINCT msi.msi_igt_id) AS required_ing_types
    FROM recipe r
    LEFT JOIN m2m_rcp_eqp mre ON r.rcp_id = mre.mre_rcp_id
    LEFT JOIN step s ON r.rcp_id = s.stp_rcp_id
    LEFT JOIN m2m_stp_igt msi ON s.stp_id = msi.msi_stp_id
    GROUP BY r.rcp_id
)
SELECT
    u.usr_id,
    r.rcp_id,
    r.rcp_title,
    r.rcp_cal,
    r.rcp_portion_count
FROM "user" u
CROSS JOIN recipe r
JOIN recipe_requirements rr ON r.rcp_id = rr.rcp_id
LEFT JOIN user_equipment ue ON ue.user_id = u.usr_id
LEFT JOIN user_ingredients ui ON ui.user_id = u.usr_id
WHERE 
    (rr.required_equipment IS NULL OR 
     rr.required_equipment <@ ue.equipment_ids) AND
    (rr.required_ing_types IS NULL OR 
     rr.required_ing_types <@ ui.ingredient_type_ids);