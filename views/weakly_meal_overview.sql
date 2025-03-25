CREATE OR REPLACE VIEW weekly_meal_overview AS
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
                   WHERE mrd.mrd_dmp_id = dmp.dmp_id)
    )) AS daily_plans
FROM weakly_meal_plan wmp
JOIN "user" u ON u.usr_id = wmp.wmp_usr_id
JOIN daily_meal_plan dmp ON dmp.dmp_wmp_id = wmp.wmp_id
GROUP BY wmp.wmp_id, u.usr_name;