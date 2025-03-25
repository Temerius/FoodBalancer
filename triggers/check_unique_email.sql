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