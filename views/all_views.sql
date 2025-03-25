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

CREATE OR REPLACE VIEW user_inventory AS
SELECT 
  u.usr_id,
  i.ing_name,
  mui.mui_quantity,
  mui.mui_quantity_type
FROM "user" u
JOIN m2m_usr_ing mui ON mui.mui_usr_id = u.usr_id
JOIN ingredient i ON i.ing_id = mui.mui_ing_id;

CREATE OR REPLACE VIEW user_shopping_list AS
SELECT 
  spl_usr_id AS user_id,
  json_agg(json_build_object(
    'ingredient_type', it.igt_name,
    'quantity', mis.mis_quantity,
    'quantity_type', mis.mis_quantity_type
  )) AS items
FROM shopping_list spl
JOIN m2m_ing_spl mis ON mis.mis_spl_id = spl.spl_id
JOIN ingredient_type it ON it.igt_id = mis.mis_igt_id
GROUP BY spl_usr_id;

CREATE or replace VIEW weekly_meal_overview AS
SELECT 
    wmp.wmp_id,
    wmp.wmp_start,
    wmp.wmp_end,
    u.usr_name,
    SUM(dmp.dmp_cal_day) AS total_calories,
    json_agg(json_build_object(
        'date', dmp.dmp_date,
        'recipes', (SELECT json_agg(r.rcp_title) 
                   FROM m2m_rcp_dmp mrd 
                   JOIN recipe r ON r.rcp_id = mrd.mrd_rcp_id
                   WHERE mrd.mrd_dmp_id = dmp.dmp_id),
        'calories', dmp.dmp_cal_day
               
    )) AS daily_plans
FROM weakly_meal_plan wmp
JOIN "user" u ON u.usr_id = wmp.wmp_usr_id
JOIN daily_meal_plan dmp ON dmp.dmp_wmp_id = wmp.wmp_id
GROUP BY wmp.wmp_id, u.usr_name;

drop materialized view if exists popular_recipes;
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

drop materialized view if exists expiring_ingredients;
CREATE MATERIALIZED VIEW expiring_ingredients AS
SELECT 
    mui.mui_usr_id,
    i.ing_name,
    i.ing_exp_date,
    mui.mui_quantity,
    mui.mui_quantity_type
FROM m2m_usr_ing mui
JOIN ingredient i ON i.ing_id = mui.mui_ing_id
WHERE i.ing_exp_date BETWEEN CURRENT_DATE AND CURRENT_DATE + INTERVAL '15 days'
ORDER BY i.ing_exp_date;

drop MATERIALIZED view if exists daily_consumption_stats;
CREATE MATERIALIZED VIEW daily_consumption_stats AS
SELECT
    adm.adm_date,
    u.usr_id,
    u.usr_name,
    COALESCE(SUM(ing_calories), 0) AS total_calories,
    COALESCE(SUM(ing_protein), 0) AS total_protein,
    COALESCE(SUM(ing_fat), 0) AS total_fat,
    COALESCE(SUM(ing_hydrates), 0) AS total_carbs,
    COUNT(DISTINCT mia.mia_ing_id) AS unique_ingredients,
    COUNT(DISTINCT mra.mra_rcp_id) AS unique_recipes,
    json_agg(DISTINCT jsonb_build_object(
        'ingredient', i.ing_name,
        'quantity', mia.mia_quantity,
        'type', mia.mia_quantity_type
    )) FILTER (WHERE i.ing_id IS NOT NULL) AS ingredients_details,
    json_agg(DISTINCT jsonb_build_object(
        'recipe', r.rcp_title,
        'calories', r.rcp_cal
    )) FILTER (WHERE r.rcp_id IS NOT NULL) AS recipes_details
FROM actual_day_meal adm
JOIN "user" u ON adm.adm_usr_id = u.usr_id
LEFT JOIN m2m_ing_adm mia ON adm.adm_id = mia.mia_adm_id
LEFT JOIN ingredient i ON mia.mia_ing_id = i.ing_id
LEFT JOIN m2m_rcp_adm mra ON adm.adm_id = mra.mra_adm_id
LEFT JOIN recipe r ON mra.mra_rcp_id = r.rcp_id
GROUP BY adm.adm_date, u.usr_id, u.usr_name;

drop MATERIALIZED view if exists equipment_recipe_usage;
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

drop MATERIALIZED view if exists user_available_recipes;
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