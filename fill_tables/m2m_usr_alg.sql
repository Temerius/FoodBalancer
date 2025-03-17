INSERT INTO m2m_usr_alg (mua_usr_id, mua_alg_id)
SELECT
    usr_id,
    (random() * 19 + 1)::integer
FROM 
    (SELECT generate_series(1,50) AS usr_id) users
CROSS JOIN LATERAL
    (SELECT * FROM generate_series(1, (random() * 2 + 1)::integer)) AS allergies
WHERE random() < 0.3
ON CONFLICT (mua_usr_id, mua_alg_id) DO NOTHING;