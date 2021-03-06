CREATE EXTERNAL TABLE et_call_center (
    cc_call_center_sk int,
    cc_call_center_id varchar(16),
    cc_rec_start_date timestamp,
    cc_rec_end_date timestamp,
    cc_closed_date_sk int,
    cc_open_date_sk int,
    cc_name varchar(50),
    cc_class varchar(50),
    cc_employees int,
    cc_sq_ft int,
    cc_hours varchar(20),
    cc_manager varchar(40),
    cc_mkt_id int,
    cc_mkt_class varchar(50),
    cc_mkt_desc varchar(100),
    cc_market_manager varchar(40),
    cc_division char(1),
    cc_division_name varchar(50),
    cc_company char(1),
    cc_company_name varchar(50),
    cc_street_number varchar(10),
    cc_street_name varchar(60),
    cc_street_type varchar(15),
    cc_suite_number varchar(10),
    cc_city varchar(60),
    cc_county varchar(30),
    cc_state varchar(2),
    cc_zip varchar(10),
    cc_country varchar(20),
    cc_gmt_offset decimal(5,2),
    cc_tax_percentage decimal(5,2)
)
row format delimited fields terminated by '|'
location '/user/impadmin/tpcds_parquet/call_center'
tblproperties ('serialization.null.format'='')
;
