/*********************************************************************************************************
TITLE: HNZ_REG_events

DESCRIPTION: Create the event table of new applications and transfers for social housing by
	application and snz_uid

INPUT: [IDI_Clean].[hnz_clean].[new_applications_household]
	[IDI_Clean].[hnz_clean].[new_applications]
	[IDI_Clean].[hnz_clean].[transfer_applications_household]
	[IDI_Clean].[hnz_clean].[transfer_applications]
	[IDI_Clean].[hnz_clean].[register_exit]

OUTPUT: {schemaname}.SIAL_HNZ_register_events

DEPENDENCIES: 

NOTES: 
Reference period start: 1 July 2000 
Reference period end: 31 Aug 2015

Each row is per application for each snz_uid

AUTHOR: Wen Jhe Lee

DATE: 28 April 2017

HISTORY: 
18 May 2017	CM	Minor formatting changes
18 May 2017	VB	Formatting changes, view name change
28 Apr 2017	WL	v1	

*********************************************************************************************************/

create view {schemaname}.SIAL_HNZ_register_events as (
	select 
		snz_uid,
		snz_application_uid,
		snz_legacy_application_uid,
		'HNZ' as department,
		'REG' as datamart,
		'REG' as subject_area,
		start_date,
		case when end_date1 IS NULL 
			then cast('9999-12-31' as datetime) /* max end date as still in register as of Aug 2015 */
			else end_date1 
		end as end_date, /* end date is as at the register */
		type as event_type, /* whether New Application Or Transfer */
		case when end_status IS NULL then 'IN REGISTR'
			else end_status
		end as event_type_2, /*exit status*/
		total_score as event_type_3, /*score during assessment*/
		main_reason as event_type_4 /* reason for transfer or housing application*/
	from (
		select								
			cast(newapp.hnz_na_date_of_application_date as datetime) as start_date ,
			cast(reg.hnz_re_exit_date as datetime) as end_date1 ,	
			newapp_hh.snz_application_uid, 	
			newapp_hh.snz_legacy_application_uid,	
			newapp_hh.snz_uid,	 
			'NEW APP' as type,	
			reg.hnz_re_exit_status_text as end_status,	
			newapp.hnz_na_analysis_total_score_text as total_score,	
			newapp.hnz_na_main_reason_app_text as main_reason	
		from		
			(
			select distinct 
			snz_application_uid,
			snz_legacy_application_uid,
			snz_uid
			from 
				[IDI_Clean].[hnz_clean].[new_applications_household] ) newapp_hh	
		inner join		
			(
				select
					snz_application_uid,
					snz_legacy_application_uid,
					hnz_na_analysis_total_score_text, 
					hnz_na_main_reason_app_text,
					hnz_na_date_of_application_date
				from 
					[IDI_Clean].[hnz_clean].[new_applications] ) newapp	
		on		
			coalesce(newapp.snz_application_uid, -1)  = coalesce(newapp_hh.snz_application_uid, -1)
			and coalesce(newapp.snz_legacy_application_uid, -1)  = coalesce(newapp_hh.snz_legacy_application_uid, -1)
		inner join		
			[IDI_Clean].[hnz_clean].[register_exit] reg	
		on		
			coalesce(newapp_hh.snz_application_uid, -1)  = coalesce(reg.snz_application_uid, -1)
			and coalesce(newapp_hh.snz_legacy_application_uid, -1)  = coalesce(reg.snz_legacy_application_uid, -1)
		union all
		select								
			cast (tfapp.hnz_ta_application_date as datetime) as start_date ,
			cast(reg.hnz_re_exit_date as datetime) as end_date1 ,	
			tfapp_hh.snz_application_uid, 	
			tfapp_hh.snz_legacy_application_uid,	
			tfapp_hh.snz_uid,	
			'TRANSFER' as type,	
			reg.hnz_re_exit_status_text as end_status,	
			tfapp.hnz_ta_analysis_total_score_text as total_score,	
			tfapp.hnz_ta_main_reason_app_text as main_reason	
		from		
			(select distinct 
				snz_application_uid,
				snz_legacy_application_uid,
				snz_uid
			 from [IDI_Clean].[hnz_clean].[transfer_applications_household]) tfapp_hh	
		inner join		
			(select 
				snz_application_uid,
				snz_legacy_application_uid,
				hnz_ta_analysis_total_score_text,
				hnz_ta_main_reason_app_text,
				hnz_ta_application_date
			 from [IDI_Clean].[hnz_clean].[transfer_applications]) tfapp	
		on		
			coalesce(tfapp.snz_application_uid, -1)  = coalesce(tfapp_hh.snz_application_uid, -1)
			and coalesce(tfapp.snz_legacy_application_uid, -1)  = coalesce(tfapp_hh.snz_legacy_application_uid, -1)
		inner join		
			[IDI_Clean].[hnz_clean].[register_exit] reg	
		on		
			coalesce(tfapp_hh.snz_application_uid, -1)  = coalesce(reg.snz_application_uid, -1)
			and coalesce(tfapp_hh.snz_legacy_application_uid, -1)  = coalesce(reg.snz_legacy_application_uid, -1)
		) full_tab	
);
