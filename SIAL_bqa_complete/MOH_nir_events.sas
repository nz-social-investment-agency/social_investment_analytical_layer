/*********************************************************************************************************
TITLE: MOH_nir_events

DESCRIPTION: Create MOH NIR events table in SIAL format

INPUT: 
IDI_Sandpit.[clean_read_MOH_NIR].[moh_nir_events_dec2015]
&idi_refresh..moh_clean.pop_cohort_demographics

OUTPUT: [&schema.].SIAL_MOH_nir_events

DEPENDENCIES: 
NA

NOTES: 
See SIAL data dictionary for business rules applied

AUTHOR: V Benny

DATE: 22 July 2016

HISTORY: 
v2	WJ	Added vaccine dose and event sub status description
v1	VB	Created
PNH Aug 2019 Added a select statement to ensure the user has access to the underlying IDI tables. This will show up in the log
*********************************************************************************************************/
proc sql;
	&idi_usercode_connect;
	execute(
		create view [&schema.].SIAL_MOH_nir_events as
		(	select
				snz_uid,
				'MOH' as department,
				'NIR' as datamart,
				'NIR' as subject_area,
				cast([moh_nir_evt_vaccine_date] as datetime) as [start_date],
				cast([moh_nir_evt_vaccine_date] as datetime) as [end_date],
				/*	--x.snz_moh_uid, */
				/*vaccine as event_type,
				[event_status_description] as event_type_2,
				[vaccine_dose] as event_type_3,
				[event_sub_status_description] as event_type_4*/
				moh_nir_evt_vaccine_text as event_type,
				[moh_nir_evt_status_desc_text] as event_type_2,
				[moh_nir_evt_vaccine_dose_nbr] as event_type_3,
				[moh_nir_evt_sub_status_desc_text] as event_type_4
			from (select distinct 
				snz_uid, snz_moh_uid,
				moh_nir_evt_vaccine_text,
				[moh_nir_evt_vaccine_dose_nbr],
				[moh_nir_evt_status_desc_text],
				[moh_nir_evt_sub_status_desc_text],
				[moh_nir_evt_vaccine_date]
				/*vaccine,
				event_status_description,
				vaccine_dose,
				event_sub_status_description,
				vacination_date*/
				/* from IDI_Sandpit.[clean_read_MOH_NIR].[moh_nir_events_dec2015])x*/
				/* Table appears to have moved to &idi_refresh. tables*/
				/* PNH - MARCH 2019 - SAS Grid migration*/
			from [&idi_refresh.].[moh_clean].[nir_event])x
				);
	) by odbc;
	execute(select top 10 * from [&schema.].SIAL_MOH_nir_events) by odbc;
	disconnect from odbc;
Quit;