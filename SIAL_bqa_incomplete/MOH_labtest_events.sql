/*********************************************************************************************************
TITLE: MOH_labtest_events

DESCRIPTION: Reformat and recode lab test data into SIAL format

INPUT: IDI_Clean.[moh_clean].[lab_claims]

OUTPUT: {schemaname}.SIAL_MOH_labtest_events

DEPENDENCIES: 
NA

NOTES: 
See SIAL data dictionary for business rules applied

AUTHOR: V Benny

DATE: 22 July 2016

HISTORY: 

*********************************************************************************************************/

create view {schemaname}.SIAL_MOH_labtest_events as (
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
	from IDI_Clean.[moh_clean].[lab_claims]
	group by 
		snz_uid, 
		[moh_lab_visit_date],
		moh_lab_test_code,
		moh_lab_tests_nbr);
