/*********************************************************************************************************
TITLE: MOH_cancer_events

DESCRIPTION: Create MOH cancer registration events table into SIAL format

INPUT: idi_clean.moh_clean.cancer_registrations

OUTPUT: {schemaname}.SIAL_MOH_cancer_events

DEPENDENCIES: 
NA

NOTES: 
See SIAL data dictionary for business rules applied

AUTHOR: E Walsh

DATE: 22 July 2016

HISTORY: 

*********************************************************************************************************/


/* cancer registrations */
create view {schemaname}.SIAL_MOH_cancer_events as
select snz_uid, 
			'MOH' as department,
			'CAN' as datamart,
			'REG' as subject_area,				
			cast(moh_can_diagnosis_date as datetime) as [start_date], /*diagnoses are point in time events*/
			cast(moh_can_diagnosis_date as datetime) as [end_date],
		moh_can_site_code as event_type,
		moh_can_extent_of_disease_code as event_type_2

from IDI_Clean.moh_clean.cancer_registrations;

