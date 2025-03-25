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