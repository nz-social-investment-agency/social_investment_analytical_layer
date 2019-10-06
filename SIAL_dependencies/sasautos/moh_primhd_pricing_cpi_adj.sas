/*******************************************************************************************************
TITLE: moh_primhd_pricing_cpi_adj

DESCRIPTION: 
Perform the price index inflation adjustment to 2013/2014 base prices to build the other periods

INPUT: 

OUTPUT:

DEPENDENCIES: 


NOTES: 
Price adjustment is applied on a yearly basis 
(considering averages of quarterly inflation rates)


AUTHOR: 
Ben Vandenbroucke

DATE: 08 Jan 2018

KNOWN ISSUES: 

HISTORY: 
08 Jan 2018 BV v1
*******************************************************************************************************/


/*Annual CPI adjustment table from 2006/2007 to 2015/2016 (max of inflation table) */
proc sql;
	connect to odbc (dsn=idi_clean_archive_srvprd);
	create table work._temp_cpi as 
	select * from connection to odbc(
		select
		case when month(cast(start_date as datetime)) <= 6 then year(cast(start_date as datetime)) -1 
			else year(cast(start_date as datetime)) end as fin_year,
			quarter,
			value,
			cast(start_date as datetime) as start_date,
			cast(end_date as datetime) as end_date
		from [IDI_Sandpit].[&si_proj_schema.].inflation_index
		where inflation_type = 'CPI' and quarter >= '2006Q3'
	);

	disconnect from odbc;
quit;

proc sql;
	create table work.cpi_table as
	select catx("/",fin_year,substr(put(fin_year+1,4.),3,2)) as fin_year,
		min(datepart(start_date)) as start_date format date9.,
		max(datepart(end_date)) as end_date format date9.,
		sum(value)/ (select sum(value) from work._temp_cpi where fin_year = 2013 ) as cpi_index
	from work._temp_cpi group by fin_year;
quit;



/*Test: apply to the current pricing */

/*proc sql;*/
/*	select distinct activity_unit_type,*/
/*		activity_setting_code,*/
/*		activity_setting_desc,*/
/*		activity_type_code,*/
/*		activity_type_desc*/
/*	from sand.moh_primhd_pu_pricing*/
/*	order by activity_setting_code, activity_type_code, activity_unit_type;*/
/*quit;*/

proc sql;
	create table _temp_moh_primhd_pu_pricing_2 as
	select distinct 
		a.activity_setting_code,
		a.activity_setting_desc,
		a.activity_type_code,
		a.activity_type_desc,
		a.activity_unit_type,
		b.fin_year,
		a.type_weight,
		a.setting_weight,
		0 as activity_price,
		b.start_date,
		b.end_date
	from sand.moh_primhd_pu_pricing a, work.cpi_table b 
	order by activity_setting_code, activity_type_code, activity_unit_type, fin_year;
quit;


/*Apply the CPI table to the updated pricing table*/

/*proc sql;*/
/*	select distinct activity_unit_type,*/
/*		activity_setting_code,*/
/*		activity_type_code*/
/*	from PRIMHD_master_dimension_cost*/
/*	order by activity_setting_code, activity_type_code, activity_unit_type;*/
/*quit;*/

proc sql;
	create table _temp_moh_primhd_pricing_adj as
	select distinct a.activity_setting_code,
		a.activity_type_code,
		a.activity_unit_type,
		b.fin_year,
		a.activity_type_code2 as type_weight,
		a.activity_setting_code2 as setting_weight,
		b.start_date,
		b.end_date,
		a.base_price_20132014,
		a.final_unit_price,
		case when a.activity_unit_type = 'CON' then a.activity_type_code2*a.activity_setting_code2*b.cpi_index*183.2156011
			 when a.activity_unit_type = 'BED' then a.activity_type_code2*a.activity_setting_code2*b.cpi_index*280.6586004	end as activity_price_adj
	from WORK.PRIMHD_master_dimension_cost a, work.cpi_table b
	order by activity_setting_code, activity_type_code, activity_unit_type, fin_year;
quit;


/*Merge the existing table with the updated costs (0 if no update)*/

proc sql;
	create table moh_primhd_pu_pricing_v2 as
	select distinct
		a.activity_setting_code,
		a.activity_setting_desc,
		a.activity_type_code,
		a.activity_type_desc,
		a.activity_unit_type,
		a.fin_year,
		coalesce(b.type_weight,a.type_weight) as type_weight,
		coalesce(b.setting_weight,a.setting_weight) as setting_weight,
		coalesce(b.activity_price_adj,a.activity_price) as activity_price,
		a.start_date,
		a.end_date
	from _temp_moh_primhd_pu_pricing_2 a
	left join _temp_moh_primhd_pricing_adj b
	on a.activity_setting_code=b.activity_setting_code and a.activity_type_code=b.activity_type_code 
		and a.activity_unit_type=b.activity_unit_type and a.fin_year=b.fin_year
	order by activity_setting_code, activity_type_code, activity_unit_type, fin_year;
quit;

/*Push to the sandpit*/
data sand.moh_primhd_pu_pricing_v2;
 set moh_primhd_pu_pricing_v2;
run;

