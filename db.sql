BEGIN TRANSACTION;
create table trips (id integer primary key, name text);
create table legs(id integer primary key, trip_id integer, start_dt datetime, start_odometer, end_dt datetime, end_odometer);
COMMIT;
