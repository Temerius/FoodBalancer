/* ---------------------------------------------------- */
/*  Generated by Enterprise Architect Version 16.0 		*/
/*  Created On : 21-����-2025 01:26:29 				*/
/*  DBMS       : PostgreSQL 						*/
/* ---------------------------------------------------- */

/* Drop Tables */

DROP TABLE IF EXISTS m2m_usr_alg CASCADE
;

/* Create Tables */

CREATE TABLE m2m_usr_alg
(
	mua_alg_id integer NULL,
	mua_usr_id bigint NULL
)
;

/* Create Primary Keys, Indexes, Uniques, Checks */

CREATE INDEX "IXFK_m2m_usr_alg_allergen" ON m2m_usr_alg (mua_alg_id ASC)
;

CREATE INDEX "IXFK_m2m_usr_alg_user" ON m2m_usr_alg (mua_usr_id ASC)
;

/* Create Foreign Key Constraints */

ALTER TABLE m2m_usr_alg ADD CONSTRAINT "FK_m2m_usr_alg_allergen"
	FOREIGN KEY (mua_alg_id) REFERENCES allergen (alg_id) ON DELETE Cascade ON UPDATE Cascade
;

ALTER TABLE m2m_usr_alg ADD CONSTRAINT "FK_m2m_usr_alg_user"
	FOREIGN KEY (mua_usr_id) REFERENCES "user" (usr_id) ON DELETE Cascade ON UPDATE Cascade
;