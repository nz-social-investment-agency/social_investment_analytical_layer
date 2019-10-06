/*********************************************************************************************************
TITLE: MOH_nnpac_events

DESCRIPTION: Create MOH NNPAC events table in SIAL format

INPUT: 
&idi_refresh..[moh_clean].[nnpac]
IDI_Sandpit.[&schema.].[moh_pu_pricing]

OUTPUT: [&schema.].[SIAL_MOH_nnpac_events]

DEPENDENCIES: 
 moh_pu_pricing must exist


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
create view [&schema.].SIAL_MOH_nnpac_events as 
	(select snz_uid, 
			department,
			datamart,
			subject_area,	
			cast([start_date] as datetime) as [start_date], 
			cast([end_date] as datetime) as end_date, 
			sum(nnpac_claim_cost) as cost,
			event_type,
			event_type_2,
			event_type_3
	 from (
			select 
				snz_uid, 
				nn.snz_moh_uid, 
				'MOH' as department,
				'NNP' as datamart,
				'NNP' as subject_area,
				moh_nnp_service_datetime as [start_date], /*+ cast( coalesce(moh_nnp_time_of_service, cast('00:00:00.0000000' as time)) as datetime) as [start_date], */
				case when cast(nn.moh_nnp_event_end_datetime as date) = cast('9999-12-31' as date) /* If there is a valid end date, use this, else use service date */
					then moh_nnp_service_datetime
					else moh_nnp_event_end_datetime
				end as [end_date], 
				nn.moh_nnp_volume_amt, 
				case when nn.moh_nnp_event_type_code ='ED' and nn.moh_nnp_purchase_unit_code like 'ED%A'  /* If ED results in hospital admission (ED%A), this is not counted as an NNPAC event*/
					then 0.00
					else (pu.pu_price * nn.moh_nnp_volume_amt) 
				end as nnpac_claim_cost,					
				nn.moh_nnp_purchase_unit_code as event_type,
				nn.moh_nnp_attendence_code as event_type_2,
				nn.moh_nnp_hlth_spc_code as event_type_3
			from &idi_refresh..[moh_clean].[nnpac] nn
			left join IDI_Sandpit.[&schema.].[moh_pu_pricing] as pu on (nn.moh_nnp_purchase_unit_code = pu.pu_code and nn.moh_nnp_service_datetime between pu.[start_date] and pu.end_date)
			)x group by snz_uid, department, datamart, subject_area, [start_date], [end_date], event_type, event_type_2, event_type_3);

	) by odbc;
		execute(select top 10 * from [&schema.].SIAL_MOH_nnpac_events) by odbc;
	disconnect from odbc;
Quit;