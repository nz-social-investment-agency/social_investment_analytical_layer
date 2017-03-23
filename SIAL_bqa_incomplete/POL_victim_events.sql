/*********************************************************************************************************
TITLE: POL_victim_events

DESCRIPTION: Reformat and recode Police victims data into SIAL format

INPUT: 
[IDI_Clean].[pol_clean].[pre_count_victimisations]

OUTPUT: 
{schemaname}.SIAL_POL_victim_events

DEPENDENCIES: 
NA

NOTES: 
See SIAL data dictionary for business rules applied

AUTHOR: K Maxwell

CREATED: 03 March 2017


*********************************************************************************************************/



create view {schemaname}.SIAL_POL_victim_events
as select  snz_uid, /* This is the incident occurance ID */
			'POL' as department,
			'POL' as datamart,
			'VIC' as subject_area,			
			cast(pol_prv_reported_date as datetime) as [start_date],
			cast(pol_prv_reported_date as datetime) as end_date,
			case when pol_prv_offence_inv_ind = 1 then 'Investigated' else 'Not investigated' end as event_type,
			pol_prv_anzsoc_offence_code as event_type_2, /*Type of offence */
			case when pol_prv_rov_code = '2000' then 'Stranger' 
				when pol_prv_rov_code in ('4000', '8000', '9999') then 'Other/NA'
				else 'Known' end as event_type_3, /* Relationship of offender to offender */
			snz_pol_occurrence_uid as event_type_4,
			snz_pol_offence_uid as event_type_5 /* This is the offence occurence ID, can have multiple offences per occurrence */
		from [IDI_Clean].[pol_clean].pre_count_victimisations;

