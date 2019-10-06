/*********************************************************************************************************
TITLE: MOE_intervention_events

DESCRIPTION: Reformat and recode MOE interventions data into SIAL format

INPUT: 
[&idi_refresh.].[cyf_clean].[cyf_abuse_event]

OUTPUT: 
[&schema.].SIAL_MOE_intervention_events

DEPENDENCIES: 
NA

NOTES: 
See SIAL data dictionary for business rules applied

AUTHOR: K Maxwell

CREATED: 22 Jul 2016

HISTORY: 
PNH Aug 2019 Added a select statement to ensure the user has access to the underlying IDI tables. This will show up in the log
Added institution number for summary of entities for output checking.
*********************************************************************************************************/
proc sql;
&idi_usercode_connect; 
execute(
create view [&schema.].SIAL_MOE_intervention_events 
as select snz_uid,
			'MOE' as department,
			'STU' as datamart,
			'INT' as subject_area,	
			cast(moe_inv_start_date as datetime) as [start_date],
			cast(moe_inv_end_date as datetime) as [end_date],
			moe_inv_intrvtn_code as event_type,
			moe_inv_inst_num_code as entity_id

from &idi_refresh..[moe_clean].student_interventions ;

	) by odbc;
	execute(select top 10 * from [&schema.].SIAL_MOE_intervention_events) by odbc;
	disconnect from odbc;
Quit;