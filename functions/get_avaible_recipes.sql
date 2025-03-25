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