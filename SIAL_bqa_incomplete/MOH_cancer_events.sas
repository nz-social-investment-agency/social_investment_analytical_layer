
/*********************************************************************************************************
TITLE: MOH_cancer_events

DESCRIPTION: Create MOH cancer registration events table into SIAL format

INPUT: &idi_refresh..moh_clean.cancer_registrations

OUTPUT: [&schema.].SIAL_MOH_cancer_events

DEPENDENCIES: 
NA

NOTES: 
See SIAL data dictionary for business rules applied

AUTHOR: E Walsh

DATE: 22 July 2016

HISTORY: 
June 2019 - Views now have to be created in the IDI_UserCode Schema in the IDI
August 2019 - Added a select statement to log if user does not have access to under lying IDI tables
*********************************************************************************************************/

proc sql;
&IDI_usercode_connect; 
execute(
/* cancer registrations */
create view [&schema.].SIAL_MOH_cancer_events as
select snz_uid, 
			'MOH' as department,
			'CAN' as datamart,
			'REG' as subject_area,				
			cast(moh_can_diagnosis_date as datetime) as [start_date], /*diagnoses are point in time events*/
			cast(moh_can_diagnosis_date as datetime) as [end_date],
		moh_can_site_code as event_type,
		moh_can_extent_of_disease_code as event_type_2

from &idi_refresh..moh_clean.cancer_registrations;

	) by odbc;
		execute(select top 10 * from [&schema.].SIAL_MOH_cancer_events) by odbc;
	disconnect from odbc;
Quit;