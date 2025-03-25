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