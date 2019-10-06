/*********************************************************************************************************
TITLE: CYF_client_events

DESCRIPTION: Create CYF client events table in SIAL format

INPUT: 
IDI_Sandpit.[clean_read_CYF].[cyf_cec_client_event_cost]
&idi_refresh..[cyf_clean].[cyf_identity_cluster]

OUTPUT: [&schema.].SIAL_CYF_client_events

DEPENDENCIES: 
NA

NOTES: 
See SIAL data dictionary for business rules applied

AUTHOR: V Benny

CREATED: 22 July 2016

BUSINESS QA COMPLETE: September 2016

HISTORY: 

26 May 2017 V Benny	Changed the subject area to use cyf_cec_business_area_type_code
20 DEC 2016	K Maxwell - using only data from IDI clean. Previous version used sandpit data (as all data was not 
available in IDI clean) and all sandpit records did not have unique ID's. Table now 
much more simple and clean.
PNH Aug 2019 Added a select statement to ensure the user has access to the underlying IDI tables. This will show up in the log
*********************************************************************************************************/
proc sql;
	&idi_usercode_connect;
	execute(
		create view [&schema.].SIAL_CYF_client_events as
			(select id.snz_uid as snz_uid,cec.snz_uid as cec_snz_uid,
				'MSD' as department,
				'CYF' as datamart,
				cyf_cec_business_area_type_code as subject_area, 
				cast(cec.cyf_cec_event_start_date as datetime) as [start_date], 
				cast(cec.cyf_cec_event_end_date as datetime) as [end_date], 
				sum(cec.cyf_cec_direct_gross_amt) as cost, 
				sum(cec.cyf_cec_indirect_gross_amt) as cost_2,
				cec.cyf_cec_event_type_text as event_type, 
				cec.cyf_cec_event_type_specific_text as event_type_2,
				cec.cyf_cec_clients_per_event_nbr as event_type_3 			
			from &idi_refresh..[cyf_clean].[cyf_cec_client_event_cost] cec 
				left join (select snz_systm_prsn_uid, snz_uid
					from &idi_refresh..[cyf_clean].[cyf_identity_cluster] 
						where cyf_idc_role_type_text ='Client') id
							on (cec.snz_systm_prsn_uid = id.snz_systm_prsn_uid)	
						group by id.snz_uid, cec.snz_uid, cec.cyf_cec_business_area_type_code, cec.cyf_cec_event_type_text, cec.cyf_cec_event_type_specific_text,
							cec.cyf_cec_event_start_date, cec.cyf_cec_event_end_date, cec.cyf_cec_clients_per_event_nbr);
	) by odbc;
	execute(select top 10 * from [&schema.].SIAL_CYF_client_events) by odbc;
	disconnect from odbc;
Quit;