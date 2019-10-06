/*********************************************************************************************************
TITLE: MOH_labtest_events

DESCRIPTION: Reformat and recode lab test data into SIAL format

INPUT: &idi_refresh..[moh_clean].[lab_claims]

OUTPUT: [&schema.].SIAL_MOH_labtest_events

DEPENDENCIES: 
NA

NOTES: 
See SIAL data dictionary for business rules applied

AUTHOR: V Benny

DATE: 22 July 2016

HISTORY: 
PNH - June 2019 - Views now have to be created in the IDI_UserCode Schema in the IDI
August 2019 - Added a select statement to log if user does not have access to under lying IDI tables
*********************************************************************************************************/
proc sql;
&IDI_usercode_connect; 
execute(
create view [&schema.].SIAL_MOH_labtest_events as (
	select 
		snz_uid, 
		'MOH' as department,
		'LAB' as datamart,
		'LAB' as subject_area,
		cast([moh_lab_visit_date] as datetime) as [start_date],
		cast([moh_lab_visit_date]as datetime) as [end_date],
		sum([moh_lab_amount_paid_amt]) as cost,
		moh_lab_test_code as event_type,
		moh_lab_tests_nbr as event_type_2
	from &idi_refresh..[moh_clean].[lab_claims]
	group by 
		snz_uid, 
		[moh_lab_visit_date],
		moh_lab_test_code,
		moh_lab_tests_nbr);
	) by odbc;
		execute(select top 10 * from [&schema.].SIAL_MOH_labtest_events) by odbc;
	disconnect from odbc;
Quit;