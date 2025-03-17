/* ---------------------------------------------------- */
/*  Generated by Enterprise Architect Version 16.0 		*/
/*  Created On : 16-����-2025 17:44:45 				*/
/*  DBMS       : PostgreSQL 						*/
/* ---------------------------------------------------- */

/* Drop Sequences for Autonumber Columns */

DROP SEQUENCE IF EXISTS favorite_recipe_fvr_id_seq
;

/* Drop Tables */

DROP TABLE IF EXISTS favorite_recipe CASCADE
;

/* Create Tables */

CREATE TABLE favorite_recipe
(
	fvr_id integer NOT NULL   DEFAULT NEXTVAL(('"favorite_recipe_fvr_id_seq"'::text)::regclass),
	fvr_rcp_id integer NULL,
	fvr_usr_id bigint NULL
)
;

/* Create Primary Keys, Indexes, Uniques, Checks */

ALTER TABLE favorite_recipe ADD CONSTRAINT "PK_favorite_recipe"
	PRIMARY KEY (fvr_id)
;

CREATE INDEX "IXFK_favorite_recipe_recipe" ON favorite_recipe (fvr_rcp_id ASC)
;

CREATE INDEX "IXFK_favorite_recipe_user" ON favorite_recipe (fvr_usr_id ASC)
;

/* Create Foreign Key Constraints */

ALTER TABLE favorite_recipe ADD CONSTRAINT "FK_favorite_recipe_recipe"
	FOREIGN KEY (fvr_rcp_id) REFERENCES recipe (rcp_id) ON DELETE No Action ON UPDATE No Action
;

ALTER TABLE favorite_recipe ADD CONSTRAINT "FK_favorite_recipe_user"
	FOREIGN KEY (fvr_usr_id) REFERENCES "user" (usr_id) ON DELETE Cascade ON UPDATE Cascade
;

/* Create Table Comments, Sequences for Autonumber Columns */

CREATE SEQUENCE favorite_recipe_fvr_id_seq INCREMENT 1 START 1
;