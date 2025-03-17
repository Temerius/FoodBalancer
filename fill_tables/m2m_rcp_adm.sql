INSERT INTO m2m_rcp_adm (mra_rcp_id, mra_adm_id)
SELECT
    (random() * 49 + 1)::integer, 
    adm_id
FROM actual_day_meal
CROSS JOIN LATERAL (
    SELECT * FROM generate_series(1, (random() * 1 + 1)::integer) 
) AS meals