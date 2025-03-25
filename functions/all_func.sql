CREATE OR REPLACE FUNCTION get_user_day(_user_id BIGINT, _date DATE)
RETURNS TABLE (
    adm_date DATE,
    total_calories BIGINT,
    total_protein BIGINT,
    total_fat BIGINT,
    total_carbs BIGINT,
    ingredients JSON,
    recipes JSON
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        dcs.adm_date,           
        dcs.total_calories,
        dcs.total_protein,
        dcs.total_fat,
        dcs.total_carbs,
        dcs.ingredients_details,
        dcs.recipes_details
    FROM daily_consumption_stats dcs
    WHERE dcs.usr_id = _user_id 
      AND dcs.adm_date = _date;
END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION get_expiring_ingredients(_user_id BIGINT)
RETURNS TABLE (
    ingredient_name VARCHAR(100),
    exp_date DATE,
    quantity INT,
    quantity_type quantity_enum
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        ing_name,
        ing_exp_date,
        mui_quantity,
        mui_quantity_type
    FROM expiring_ingredients
    WHERE mui_usr_id = _user_id;
END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION get_shopping_list(_user_id BIGINT)
RETURNS JSONB AS $$
DECLARE
    result JSONB;
BEGIN
    SELECT items INTO result
    FROM user_shopping_list
    WHERE user_id = _user_id;
    
    RETURN result;
END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION get_daily_meal_plan(_user_id BIGINT, _date DATE)
RETURNS TABLE (
    recipes JSON,
    total_calories INT
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        COALESCE(
            json_agg(json_build_object(
                'recipe_title', r.rcp_title,
                'recipe_id', r.rcp_id
            )),
            '[]'::json
        ) AS recipes,
        dmp.dmp_cal_day
    FROM daily_meal_plan dmp
    LEFT JOIN m2m_rcp_dmp mrd ON dmp.dmp_id = mrd.mrd_dmp_id
    LEFT JOIN recipe r ON mrd.mrd_rcp_id = r.rcp_id
    WHERE dmp.dmp_wmp_id IN (
        SELECT wmp_id 
        FROM weakly_meal_plan 
        WHERE wmp_usr_id = _user_id
    )
    AND dmp.dmp_date = _date
    GROUP BY dmp.dmp_id, dmp.dmp_cal_day;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION get_available_recipes(_user_id BIGINT)
RETURNS SETOF recipe_details AS $$
BEGIN
    RETURN QUERY
    SELECT rd.*
    FROM user_available_recipes uar
    JOIN recipe_details rd ON uar.rcp_id = rd.rcp_id
    WHERE usr_id = _user_id;
END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION get_missing_ingredients(_user_id BIGINT, _recipe_id INT)
RETURNS TABLE (missing_ingredients JSON) AS $$
BEGIN
    RETURN QUERY
    WITH recipe_ingredients AS (
        SELECT json_array_elements_text(rd.ingredients)::VARCHAR AS igt_name
        FROM recipe_details rd
        WHERE rd.rcp_id = _recipe_id
    )
    SELECT COALESCE(
        json_agg(ri.igt_name) FILTER (WHERE ri.igt_name NOT IN (
            SELECT ui.ing_name 
            FROM user_inventory ui 
            WHERE ui.usr_id = _user_id
        )),
        '[]'::json
    )
    FROM recipe_ingredients ri;
END;
$$ LANGUAGE plpgsql;