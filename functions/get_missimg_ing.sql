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