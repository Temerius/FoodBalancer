CREATE MATERIALIZED VIEW expiring_ingredients AS
SELECT 
    mui.mui_usr_id,
    i.ing_name,
    i.ing_exp_date,
    mui.mui_quantity,
    mui.mui_quantity_type
FROM m2m_usr_ing mui
JOIN ingredient i ON i.ing_id = mui.mui_ing_id
WHERE i.ing_exp_date BETWEEN CURRENT_DATE AND CURRENT_DATE + INTERVAL '4 days'
ORDER BY i.ing_exp_date;