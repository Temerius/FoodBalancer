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