/*********************************************************************************************************
TITLE: POL_offender_events

DESCRIPTION: Reformat and recode Police offenders data into SIAL format

INPUT: 
[IDI_Clean].[pol_clean].[pre_count_offenders]

OUTPUT: 
{schemaname}.SIAL_POL_offender_events

DEPENDENCIES: 
NA

NOTES: 
See SIAL data dictionary for business rules applied

AUTHOR: K Maxwell

DATE: 03 March 2017


*********************************************************************************************************/



create view {schemaname}.SIAL_POL_offender_events
as select  snz_uid, /* This is the incident occurance ID */
			'POL' as department,
			'OFF' as datamart,
			'OFF' as subject_area,			
			cast(pol_pro_proceeding_date as datetime) as [start_date],
			cast(pol_pro_proceeding_date as datetime) as end_date,
			case when pol_pro_offence_inv_ind = 1 then 'Investigated' else 'Not investigated' end as event_type,
			pol_pro_anzsoc_offence_code as event_type_2, /*Type of offence */
			case when pol_pro_rov_code = '2000' then 'Stranger' 
				when pol_pro_rov_code in ('4000', '8000', '9999') then 'Other/NA'
				else 'Known' end as event_type_3, /* Relationship of offender to victim */
			snz_pol_occurrence_uid as event_type_4,
			snz_pol_offence_uid as event_type_5 /* This is the offence occurance ID, can have multiple offences per occurrence */
		from [IDI_Clean].[pol_clean].[pre_count_offenders]
		where (snz_pol_occurrence_uid != 1    /* When snz_pol_occurrence_uid = 1 and pol_pro_offence_inv_ind = 0 recoreds are incomplete, so excluding */
			and pol_pro_offence_inv_ind != 0); /* Note there are none of these records, just future proofing */

