/*********************************************************************************************************
TITLE: MOH_chronic_events

DESCRIPTION: Create MOH chronic condition events table into SIAL format

INPUT: idi_clean.moh_clean.chronic_condition

OUTPUT: {schemaname}.SIAL_MOH_chronic_events

DEPENDENCIES: 
NA

NOTES: 
See SIAL data dictionary for business rules applied

AUTHOR: E Walsh

DATE: 22 July 2016

HISTORY: 
*********************************************************************************************************/

create view {schemaname}.SIAL_MOH_chronic_events as
select snz_uid, 
			'MOH' as department,
			'TKR' as datamart, /* the tracker */
			'CCC' as subject_area, /* the chronic condition code */				
			cast(moh_chr_fir_incidnt_date as datetime) as [start_date], /*diagnoses are point in time events*/
			cast(moh_chr_last_incidnt_date as datetime) as [end_date],
		moh_chr_condition_text as event_type,
		moh_chr_collection_text as event_type_2

from idi_clean.moh_clean.chronic_condition
