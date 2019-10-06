/*********************************************************************************************************
TITLE: MIX_mortality_events

DESCRIPTION: Standardised SIAL events table for the MOH and DIA based mortality dataset

INPUT: 
[&idi_refresh.].[moh_clean].[mortality_registrations]
[&idi_refresh.].[dia_clean].[deaths]

OUTPUT: 
[&schema.].SIAL_MIX_mortality_events

DEPENDENCIES: 
NA

NOTES: 
See SIAL data dictionary for business rules applied

AUTHOR: 
E Walsh

CREATED: 
04 Oct 2016

HISTORY: 
18 May 2017 EW rewrote to handle new MOH tables
PNH - June 2019 - Views now have to be created in the IDI_UserCode Schema in the IDI
August 2019 - Added a select statement to log if user does not have access to under lying IDI tables
*********************************************************************************************************/
proc sql;
&IDI_usercode_connect; 
execute(
	create view [&schema.].SIAL_MIX_mortality_events as (
	select snz_uid,
	department,
	datamart,
	subject_area,
	[start_date],
	[end_date],
	event_type, event_type_2, event_type_3
	from (
	select snz_uid,
	'MIX' as department,
	'MOR' as datamart,
	'MOR' as subject_area,
	cast(cast(moh_mor_death_year_nbr as varchar(4))+ '-' +
	cast(moh_mor_death_month_nbr as varchar(2))+'-01' as datetime) as [start_date],
	cast(cast(moh_mor_death_year_nbr as varchar(4))+ '-' +
	cast(moh_mor_death_month_nbr as varchar(2))+'-01' as datetime) as [end_date],
	moh_mor_icd_d_code as event_type,
	moh_mor_death_year_nbr-moh_mor_birth_year_nbr as event_type_2,
	'MOH' as event_type_3
	from [&idi_refresh.].[moh_clean].[mortality_registrations]
	union all
	select [snz_uid],
	'MIX' as department,
	'MOR' as datamart,
	'MOR' as subject_area,
	cast(cast(dia_dth_death_year_nbr as varchar(4))+ '-' +
		cast(dia_dth_death_month_nbr as varchar(2))+'-01' as datetime) as [start_date],
	cast(cast(dia_dth_death_year_nbr as varchar(4))+ '-' +
		cast(dia_dth_death_month_nbr as varchar(2))+'-01' as datetime) as [end_date],
	null as event_type, 
	/* PNH we can get age at death (event_type2) from DIA table) */
	dia_dth_death_year_nbr-dia_dth_birth_year_nbr as event_type_2,
	'DIA' as event_type_3
	from [&idi_refresh.].[dia_clean].[deaths]
	where [dia_dth_death_year_nbr] > ( select max(moh_mor_death_year_nbr) from [&idi_refresh.].[moh_clean].[mortality_registrations])
	)x
	) ;
	) by odbc;
		execute(select top 10 * from [&schema.].SIAL_MIX_mortality_events) by odbc;
	disconnect from odbc;
Quit;