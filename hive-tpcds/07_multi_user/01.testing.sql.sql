CREATE EXTERNAL TABLE testing.sql_queries
(id int, description string, tuples bigint, duration string)
row format delimited fields terminated by '|'
location '/user/${hivevar:user}/testing/sql';
