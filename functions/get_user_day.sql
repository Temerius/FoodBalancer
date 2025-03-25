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