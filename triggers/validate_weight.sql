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