CREATE MATERIALIZED VIEW daily_consumption_stats AS
SELECT
    adm.adm_date,
    u.usr_id,
    u.usr_name,
    COALESCE(SUM(ing_cal), 0) AS total_calories,
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