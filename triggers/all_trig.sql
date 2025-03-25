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


CREATE OR REPLACE FUNCTION check_unique_email()
RETURNS TRIGGER AS $$
BEGIN
    IF EXISTS (
        SELECT 1 
        FROM "user" 
        WHERE usr_mail = NEW.usr_mail 
        AND usr_id != NEW.usr_id
    ) THEN
        RAISE EXCEPTION 'Email already exists!';
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE or replace TRIGGER trg_check_unique_email
BEFORE INSERT OR UPDATE ON "user"
FOR EACH ROW EXECUTE FUNCTION check_unique_email();

CREATE OR REPLACE FUNCTION check_user_allergen()
RETURNS TRIGGER AS $$
BEGIN
    IF EXISTS (
        SELECT 1 
        FROM m2m_usr_alg ua
        JOIN m2m_ing_alg ia ON ua.mua_alg_id = ia.mia_alg_id
        WHERE ua.mua_usr_id = NEW.mui_usr_id 
          AND ia.mia_ing_id = NEW.mui_ing_id
    ) THEN
        RAISE WARNING 'User % has allergy to ingredient %', NEW.mui_usr_id, NEW.mui_ing_id;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE or replace TRIGGER trg_warn_allergic_ingredient
BEFORE INSERT OR UPDATE ON m2m_usr_ing
FOR EACH ROW EXECUTE FUNCTION check_user_allergen();


CREATE OR REPLACE FUNCTION update_daily_calories()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE daily_meal_plan dmp
    SET dmp_cal_day = (
        SELECT SUM(rcp_cal) 
        FROM m2m_rcp_dmp mrd
        JOIN recipe r ON mrd.mrd_rcp_id = r.rcp_id
        WHERE mrd.mrd_dmp_id = NEW.mrd_dmp_id
    )
    WHERE dmp.dmp_id = NEW.mrd_dmp_id;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE or replace TRIGGER trg_update_daily_calories
AFTER INSERT OR DELETE OR UPDATE ON m2m_rcp_dmp
FOR EACH ROW EXECUTE FUNCTION update_daily_calories();


CREATE OR REPLACE FUNCTION validate_user_age()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.usr_age IS NOT NULL AND (NEW.usr_age < 1 OR NEW.usr_age > 150) THEN
        RAISE EXCEPTION 'Invalid age (1-150 years allowed) for user %', NEW.usr_id;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER trg_check_age
BEFORE INSERT OR UPDATE ON "user"
FOR EACH ROW EXECUTE FUNCTION validate_user_age();


CREATE OR REPLACE FUNCTION validate_user_email()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.usr_mail IS NOT NULL AND NEW.usr_mail !~ '^[A-Za-z0-9._%-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,4}$' THEN
        RAISE EXCEPTION 'Invalid email format for user %', NEW.usr_id;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

create or replace TRIGGER trg_check_email
BEFORE INSERT OR UPDATE ON "user"
FOR EACH ROW EXECUTE FUNCTION validate_user_email();


CREATE OR REPLACE FUNCTION validate_user_height()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.usr_height IS NOT NULL AND (NEW.usr_height < 50 OR NEW.usr_height > 250) THEN
        RAISE EXCEPTION 'Invalid height (35-255 cm allowed) for user %', NEW.usr_id;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE or replace TRIGGER trg_check_height
BEFORE INSERT OR UPDATE ON "user"
FOR EACH ROW EXECUTE FUNCTION validate_user_height();

CREATE OR REPLACE FUNCTION validate_weakly_plan_dates()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.wmp_end <= NEW.wmp_start THEN
        RAISE EXCEPTION 'End date must be after start date';
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE or replace TRIGGER trg_validate_weakly_plan_dates
BEFORE INSERT OR UPDATE ON weakly_meal_plan
FOR EACH ROW EXECUTE FUNCTION validate_weakly_plan_dates();


CREATE OR REPLACE FUNCTION validate_user_weight()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.usr_weight IS NOT NULL AND (NEW.usr_weight < 30 OR NEW.usr_weight > 300) THEN
        RAISE EXCEPTION 'Invalid weight (3-600 kg allowed) for user %', NEW.usr_id;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER trg_check_weight
BEFORE INSERT OR UPDATE ON "user"
FOR EACH ROW EXECUTE FUNCTION validate_user_weight();