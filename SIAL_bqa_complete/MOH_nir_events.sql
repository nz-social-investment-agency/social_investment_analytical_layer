/*********************************************************************************************************
TITLE: MOH_nir_events

DESCRIPTION: Create MOH NIR events table in SIAL format

INPUT: 
IDI_Sandpit.[clean_read_MOH_NIR].[moh_nir_events_dec2015]
IDI_Clean.moh_clean.pop_cohort_demographics

OUTPUT: {schemaname}.SIAL_MOH_nir_events

DEPENDENCIES: 
NA

NOTES: 
See SIAL data dictionary for business rules applied

AUTHOR: V Benny

DATE: 22 July 2016

HISTORY: 
v2	WJ	Added vaccine dose and event sub status description
v1	VB	Created
*********************************************************************************************************/

create view {schemaname}.SIAL_MOH_nir_events as
 (select
	pop.snz_uid as snz_uid,
	'MOH' as department,
	'NIR' as datamart,
	'NIR' as subject_area,
	cast(vacination_date as datetime) as [start_date],
	cast(vacination_date as datetime) as [end_date],
	--x.snz_moh_uid, 
	vaccine as event_type,
	[event_status_description] as event_type_2,
	[vaccine_dose] as event_type_3,
	[event_sub_status_description] as event_type_4
 from (select distinct 
 snz_moh_uid,
 vaccine,
 event_status_description,
 vaccine_dose,
 event_sub_status_description,
 vacination_date
  from IDI_Sandpit.[clean_read_MOH_NIR].[moh_nir_events_dec2015])x
 left join IDI_Clean.moh_clean.pop_cohort_demographics pop on (x.snz_moh_uid = pop.snz_moh_uid));

