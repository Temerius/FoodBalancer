/* ---------------------------------------------------- */
/*  Generated by Enterprise Architect Version 16.0 		*/
/*  Created On : 16-����-2025 17:44:45 				*/
/*  DBMS       : PostgreSQL 						*/
/* ---------------------------------------------------- */

/* Drop Sequences for Autonumber Columns */

DROP SEQUENCE IF EXISTS daily_meal_plan_dmp_id_seq
;

/* Drop Tables */

DROP TABLE IF EXISTS daily_meal_plan CASCADE
;

/* Create Tables */

CREATE TABLE daily_meal_plan
(
	dmp_id integer NOT NULL   DEFAULT NEXTVAL(('"daily_meal_plan_dmp_id_seq"'::text)::regclass),
	dmp_date date NULL,
	dmp_cal_day integer NULL,
	dmp_wmp_id integer NULL
)
;

/* Create Primary Keys, Indexes, Uniques, Checks */

ALTER TABLE daily_meal_plan ADD CONSTRAINT "PK_day_meal_plan"
	PRIMARY KEY (dmp_id)
;

CREATE INDEX "IXFK_daily_meal_plan_weakly_meal_plan" ON daily_meal_plan (dmp_wmp_id ASC)
;

/* Create Foreign Key Constraints */

ALTER TABLE daily_meal_plan ADD CONSTRAINT "FK_daily_meal_plan_weakly_meal_plan"
	FOREIGN KEY (dmp_wmp_id) REFERENCES weakly_meal_plan (wmp_id) ON DELETE No Action ON UPDATE No Action
;

/* Create Table Comments, Sequences for Autonumber Columns */

CREATE SEQUENCE daily_meal_plan_dmp_id_seq INCREMENT 1 START 1
;