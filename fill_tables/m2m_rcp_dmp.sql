INSERT INTO m2m_rcp_dmp (mrd_rcp_id, mrd_dmp_id)
SELECT 
    (random() * 49 + 1)::integer,  
    dmp_id
FROM daily_meal_plan
CROSS JOIN LATERAL (
    SELECT * FROM generate_series(1, (random() * 2 + 1)::integer) 
) AS recipes