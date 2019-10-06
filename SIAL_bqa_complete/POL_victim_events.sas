/*********************************************************************************************************
TITLE: POL_victim_events

DESCRIPTION: Reformat and recode Police victims data into SIAL format

INPUT: 
[&idi_refresh.].[pol_clean].[pre_count_victimisations]

OUTPUT: 
[&schema.].SIAL_POL_victim_events

DEPENDENCIES: 
NA

NOTES: 
See SIAL data dictionary for business rules applied

AUTHOR: K Maxwell

CREATED: 03 March 2017

PNH Aug 2019 Added a select statement to ensure the user has access to the underlying IDI tables. This will show up in the log

*********************************************************************************************************/


proc sql;
&idi_usercode_connect; 
execute(
create view [&schema.].SIAL_POL_victim_events
as select  snz_uid, /* This is the incident occurance ID */
			'POL' as department,
			'VIC' as datamart,
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
		from [&idi_refresh.].[pol_clean].pre_count_victimisations;

	) by odbc;
	execute(select top 10 * from [&schema.].SIAL_POL_victim_events) by odbc;
	disconnect from odbc;
Quit;