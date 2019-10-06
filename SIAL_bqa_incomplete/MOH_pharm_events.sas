/*********************************************************************************************************
TITLE: MOH_pharm_events

DESCRIPTION: Create MOH pharmaceutical event table in SIAL format

INPUT: IDI_Clean.moh_clean.pharmaceutical

OUTPUT: [&schema.].SIAL_MOH_pharm_events

DEPENDENCIES: 
NA

NOTES: 
See SIAL data dictionary for business rules applied

AUTHOR: V Benny

DATE: 22 July 2016

HISTORY: 
PNH - June 2019 - Views now have to be created in the IDI_UserCode Schema in the IDI
August 2019 - Added a select statement to log if user does not have access to under lying IDI tables
Added provider id to summarise entities for output checking
*********************************************************************************************************/
proc sql;
&IDI_usercode_connect; 
execute(
create view [&schema.].SIAL_MOH_pharm_events as
		(select snz_uid, 
				'MOH' as department,
				'PHA' as datamart,
				'PHA' as subject_area,				
				cast(moh_pha_dispensed_date as datetime) as [start_date],
				cast(moh_pha_dispensed_date as datetime) as [end_date],
				sum(moh_pha_remimburs_cost_exc_gst_amt) as cost,
				cast('DISPENSE' as varchar(10)) as event_type,
				snz_moh_provider_uid as entity_id
		from (
			select distinct * from &idi_refresh..moh_clean.pharmaceutical) pharm /*Remove exact row duplicates from table*/
		group by snz_uid, 
				 snz_moh_uid, 
 				 moh_pha_dispensed_date,
				snz_moh_provider_uid);
	) by odbc;
		execute(select top 10 * from [&schema.].SIAL_MOH_pharm_events) by odbc;
	disconnect from odbc;
Quit;