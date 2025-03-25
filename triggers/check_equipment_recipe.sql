CREATE OR REPLACE FUNCTION check_equipment_for_recipe()
RETURNS TRIGGER AS $$
DECLARE
    v_user_id BIGINT;
BEGIN
    SELECT wmp_usr_id INTO v_user_id 
    FROM weakly_meal_plan 
    JOIN daily_meal_plan ON wmp_id = dmp_wmp_id 
    WHERE dmp_id = NEW.mrd_dmp_id;

    IF NOT EXISTS (
        SELECT 1 
        FROM m2m_rcp_eqp re
        JOIN m2m_usr_eqp ue ON re.mre_eqp_id = ue.mue_eqp_id
        WHERE re.mre_rcp_id = NEW.mrd_rcp_id 
          AND ue.mue_usr_id = v_user_id
    ) THEN
        RAISE WARNING 'User % does not have required equipment for recipe %', v_user_id, NEW.mrd_rcp_id;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE or replace TRIGGER trg_warn_equipment
BEFORE INSERT ON m2m_rcp_dmp
FOR EACH ROW EXECUTE FUNCTION check_equipment_for_recipe();