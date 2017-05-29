/*********************************************************************************************************
TITLE: MOE_intervention_events

DESCRIPTION: Reformat and recode MOE interventions data into SIAL format

INPUT: 
[IDI_Clean].[cyf_clean].[cyf_abuse_event]

OUTPUT: 
{schemaname}.SIAL_MOE_intervention_events

DEPENDENCIES: 
NA

NOTES: 
See SIAL data dictionary for business rules applied

AUTHOR: K Maxwell

CREATED: 22 Jul 2016

HISTORY: 
*********************************************************************************************************/


create view {schemaname}.SIAL_MOE_intervention_events 
as select snz_uid,
			'MOE' as department,
			'STU' as datamart,
			'INT' as subject_area,	
			cast(moe_inv_start_date as datetime) as [start_date],
			cast(moe_inv_end_date as datetime) as [end_date],
			moe_inv_intrvtn_code as event_type
from IDI_clean.[moe_clean].student_interventions ;

