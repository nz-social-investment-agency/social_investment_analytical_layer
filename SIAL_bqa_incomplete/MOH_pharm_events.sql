/*********************************************************************************************************
TITLE: MOH_pharm_events

DESCRIPTION: Create MOH pharmaceutical event table in SIAL format

INPUT: IDI_Clean.moh_clean.pharmaceutical

OUTPUT: {schemaname}.SIAL_MOH_pharm_events

DEPENDENCIES: 
NA

NOTES: 
See SIAL data dictionary for business rules applied

AUTHOR: V Benny

DATE: 22 July 2016

HISTORY: 

*********************************************************************************************************/

create view {schemaname}.SIAL_MOH_pharm_events as
		(select snz_uid, 
				'MOH' as department,
				'PHA' as datamart,
				'PHA' as subject_area,				
				cast(moh_pha_dispensed_date as datetime) as [start_date],
				cast(moh_pha_dispensed_date as datetime) as [end_date],
				sum(moh_pha_remimburs_cost_exc_gst_amt) as cost,
				cast('DISPENSE' as varchar(10)) as event_type
		from (
			select distinct * from IDI_Clean.moh_clean.pharmaceutical) pharm /*Remove exact row duplicates from table*/
		group by snz_uid, 
				 snz_moh_uid, 
 				 moh_pha_dispensed_date);
