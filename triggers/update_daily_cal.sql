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