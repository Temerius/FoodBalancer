/* ---------------------------------------------------- */
/*  Generated by Enterprise Architect Version 16.0 		*/
/*  Created On : 21-����-2025 01:26:27 				*/
/*  DBMS       : PostgreSQL 						*/
/* ---------------------------------------------------- */

/* Drop Sequences for Autonumber Columns */

DROP SEQUENCE IF EXISTS equipment_eqp_id_seq
;

/* Drop Tables */

DROP TABLE IF EXISTS equipment CASCADE
;

/* Create Tables */

CREATE TABLE equipment
(
	eqp_id integer NOT NULL   DEFAULT NEXTVAL(('"equipment_eqp_id_seq"'::text)::regclass),
	eqp_type varchar(50) NULL,
	eqp_power integer NULL,
	eqp_capacity integer NULL,
	eqp_img_url varchar(256) NULL
)
;

/* Create Primary Keys, Indexes, Uniques, Checks */

ALTER TABLE equipment ADD CONSTRAINT "PK_equipment"
	PRIMARY KEY (eqp_id)
;

/* Create Table Comments, Sequences for Autonumber Columns */

CREATE SEQUENCE equipment_eqp_id_seq INCREMENT 1 START 1
;