/*********************************************************************************************************
TITLE: MOH_gms_events

DESCRIPTION: Reformat and recode GMS data into SIAL format

INPUT: &idi_refresh..[moh_clean].[gms_claims]

OUTPUT: [&schema.].SIAL_MOH_gms_events

DEPENDENCIES: 
NA

NOTES: 
See SIAL data dictionary for business rules applied

AUTHOR: V Benny

DATE: 22 July 2016

HISTORY: 
June 2019 - Views now have to be created in the IDI_UserCode Schema in the IDI
August 2019 - Added a select statement to log if user does not have access to under lying IDI tables
*********************************************************************************************************/

proc sql;
&IDI_usercode_connect; 
execute(

create view [&schema.].SIAL_MOH_gms_events as 
	(select snz_uid,
			'MOH' as department,
			'GMS' as datamart,
			'GMS' as subject_area,	
			cast(moh_gms_visit_date as datetime) as [start_date],
			cast(moh_gms_visit_date as datetime) as [end_date],
			sum(moh_gms_amount_paid_amt) as cost,
			cast('GMS' as varchar(10)) as event_type
	from &idi_refresh..[moh_clean].[gms_claims]
	group by snz_uid, moh_gms_visit_date);

	) by odbc;
	execute(select top 10 * from [&schema.].SIAL_MOH_gms_events) by odbc;
	disconnect from odbc;
Quit;