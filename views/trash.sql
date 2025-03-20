-- 2. Структурированный список покупок
CREATE OR REPLACE VIEW structured_shopping_list AS
SELECT
    sl.spl_id,
    it.igt_name AS category,
    STRING_AGG(i.ing_name || ' (' || mis.mis_quantity || 'g)', ', ') AS items,
    SUM(mis.mis_quantity) AS total_quantity
FROM 
    shopping_list sl
JOIN m2m_ing_spl mis ON sl.spl_id = mis.mis_spl_id
JOIN ingredient i ON mis.mis_ing_id = i.ing_id
JOIN ingredient_type it ON i.ing_igt_id = it.igt_id
GROUP BY 
    sl.spl_id, it.igt_name
ORDER BY 
    it.igt_name, sl.spl_id;

-- 3. Календарь питания
CREATE OR REPLACE VIEW meal_plan_calendar AS
SELECT
    w.wmp_id,
    w.wmp_start,
    w.wmp_end,
    d.dmp_date,
    TO_CHAR(d.dmp_date, 'Day') AS day_of_week,
    STRING_AGG(r.rcp_title, ', ') AS planned_recipes,
    SUM(r.rcp_cal) AS total_calories
FROM 
    weekly_meal_plan w
JOIN daily_meal_plan d ON w.wmp_id = d.dmp_wmp_id
LEFT JOIN m2m_rcp_dmp mrd ON d.dmp_id = mrd.mrd_dmp_id
LEFT JOIN recipe r ON mrd.mrd_rcp_id = r.rcp_id
GROUP BY 
    w.wmp_id, w.wmp_start, w.wmp_end, d.dmp_date
ORDER BY 
    w.wmp_start, d.dmp_date;

-- 4. Истекающие ингредиенты
CREATE OR REPLACE VIEW expiring_ingredients AS
SELECT 
    ing_id,
    ing_name,
    ing_exp_date,
    DATE_PART('day', ing_exp_date - CURRENT_DATE) AS days_until_expiry,
    CASE 
        WHEN ing_exp_date < CURRENT_DATE THEN 'Expired'
        WHEN ing_exp_date <= CURRENT_DATE + INTERVAL '3 days' THEN 'Critical'
        WHEN ing_exp_date <= CURRENT_DATE + INTERVAL '7 days' THEN 'Warning'
        ELSE 'Fresh'
    END AS expiry_status
FROM 
    ingredient
WHERE 
    ing_exp_date < CURRENT_DATE + INTERVAL '7 days';




CREATE INDEX idx_ingredient_exp_date ON ingredient(ing_exp_date);
CREATE INDEX idx_recipe_calories ON recipe(rcp_cal);
CREATE INDEX idx_meal_plan_dates ON weekly_meal_plan(wmp_start, wmp_end);



CREATE MATERIALIZED VIEW weekly_nutrition_summary AS
SELECT
    w.wmp_id,
    SUM(r.rcp_cal) AS total_calories,
    AVG(r.rcp_cal) AS avg_daily_calories,
    COUNT(DISTINCT r.rcp_id) AS unique_recipes
FROM 
    weekly_meal_plan w
JOIN daily_meal_plan d ON w.wmp_id = d.dmp_wmp_id
JOIN m2m_rcp_dmp mrd ON d.dmp_id = mrd.mrd_dmp_id
JOIN recipe r ON mrd.mrd_rcp_id = r.rcp_id
GROUP BY w.wmp_id
WITH DATA;

REFRESH MATERIALIZED VIEW weekly_nutrition_summary;



-- Получить детали рецепта
SELECT * FROM recipe_details WHERE rcp_id = 15;

-- Показать список покупок с категориями
SELECT category, items 
FROM structured_shopping_list 
WHERE spl_id = 1;

-- Просмотреть план питания на неделю
SELECT * FROM meal_plan_calendar 
WHERE wmp_start >= '2024-01-01';

-- Проверить истекающие продукты
SELECT * FROM expiring_ingredients 
WHERE expiry_status IN ('Critical', 'Warning');