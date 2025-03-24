INSERT INTO favorite_recipe (fvr_rcp_id, fvr_usr_id)
SELECT 
    (random() * 49 + 1)::integer,
    usr_id
FROM generate_series(1,50) AS usr_id;

INSERT INTO favorite_recipe (fvr_rcp_id, fvr_usr_id)
SELECT
    (random() * 49 + 1)::integer,
    (random() * 49 + 1)::integer
FROM generate_series(1,100);