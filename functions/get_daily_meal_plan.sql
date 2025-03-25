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