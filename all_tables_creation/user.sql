CREATE TYPE gender_enum AS ENUM ('Male', 'Female');

DROP TABLE IF EXISTS "user" CASCADE;

CREATE TABLE "user"
(
    usr_id bigint NOT NULL DEFAULT NEXTVAL(('"user_usr_id_seq"'::text)::regclass),
    usr_name varchar(100) NULL,
    usr_pas_hash char(32) NULL,
    usr_mail varchar(100) NULL,
    usr_height smallint NULL,
    usr_weight smallint NULL,
    usr_age smallint NULL,
    usr_gender gender_enum NULL, 
    usr_cal_day integer NULL
);

ALTER TABLE "user" ADD CONSTRAINT "PK_user"
    PRIMARY KEY (usr_id);

CREATE SEQUENCE user_usr_id_seq INCREMENT 1 START 1;