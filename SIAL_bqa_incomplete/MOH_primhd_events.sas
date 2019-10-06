/*********************************************************************************************************
TITLE: MOH_primhd_events

DESCRIPTION: Create PRIMHD events table in SIAL format

INPUT: 
&idi_refresh..[moh_clean].[PRIMHD]
[IDI_Sandpit].[&schema.].moh_primhd_pu_pricing

OUTPUT: [&schema.].SIAL_MOH_primhd_events

DEPENDENCIES: 
The table moh_primhd_pu_pricing must exist

NOTES: 
See SIAL data dictionary for business rules applied

AUTHOR: V Benny

DATE: 22 July 2016

HISTORY: 
v1	16 Jun 2017	WJ	Adding for primhd team type code
PNH - June 2019 - Views now have to be created in the IDI_UserCode Schema in the IDI
August 2019 - Added a select statement to log if user does not have access to under lying IDI tables
Added organisation code for easy entity summary for output checking
*********************************************************************************************************/
proc sql;
&IDI_usercode_connect; 
execute(
create view [&schema.].SIAL_MOH_primhd_events as (
	select 
		snz_uid, 
		'MOH' as department,
		'PRM' as datamart,
		'PRM' as subject_area,
		cast(moh_mhd_activity_start_date as datetime) as [start_date],
		cast(moh_mhd_activity_end_date as datetime) as [end_date],
		case when moh_mhd_activity_unit_type_text = 'SEC' then 0.00 
		else price.activity_price*moh_mhd_activity_unit_count_nbr end as cost,
		moh_mhd_activity_setting_code as event_type,
		moh_mhd_activity_type_code as event_type_2,
		moh_mhd_activity_unit_type_text as event_type_3,
		moh_mhd_team_type_code as event_type_4,
		moh_mhd_organisation_id_code as entity_id
	from &idi_refresh..moh_clean.PRIMHD primhd
	left join [IDI_Sandpit].[&schema.].moh_primhd_pu_pricing price
		on (primhd.moh_mhd_activity_setting_code = price.activity_setting_code 
			and primhd.moh_mhd_activity_type_code = price.activity_type_code 
			and primhd.moh_mhd_activity_unit_type_text=price.activity_unit_type
			and primhd.moh_mhd_activity_start_date between price.start_date and price.end_date)
);
) by odbc;
	execute(select top 10 * from [&schema.].SIAL_MOH_primhd_events) by odbc;
	disconnect from odbc;
Quit;