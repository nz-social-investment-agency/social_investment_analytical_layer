/*********************************************************************************************************
TITLE: MOH_pfhd_events

DESCRIPTION: Create MOH pfhd (pubically funded hospital discharges) event table in SIAL format

INPUT: 
IDI_Clean.[moh_clean].[pub_fund_hosp_discharges_event]
IDI_Sandpit.{schemaname}.[moh_pu_pricing]

OUTPUT: {schemaname}.SIAL_MOH_pfhd_events

DEPENDENCIES: 
moh_pu_pricing must exist


NOTES: 
See SIAL data dictionary for business rules applied

AUTHOR: V Benny

DATE: 22 July 2016

HISTORY: 

*********************************************************************************************************/

create view {schemaname}.SIAL_MOH_pfhd_events as (
	select 
		[snz_uid], 
		department,
		datamart,
		subject_area,
		cast([start_date] as datetime) as [start_date],
		cast([end_date] as datetime) as [end_date],
		sum(cost) as cost,
		event_type
	from (
			select 
				[snz_uid], [snz_moh_uid], [moh_evt_event_id_nbr], 
				'MOH' as department,
				'PFH' as datamart,
				'PFH' as subject_area,
				[moh_evt_event_type_code],
				[moh_evt_end_type_code],
				[moh_evt_evst_date] as [start_date],
				[moh_evt_even_date] as [end_date],
				moh_evt_cost_weight_amt, [moh_evt_cost_wgt_code], pu.pu_price, 
				case when moh_evt_pur_unit_text is null or moh_evt_cost_weight_amt is null or moh_evt_pur_unit_text='EXCLU'
					then 0.00
					else  moh_evt_cost_weight_amt*pu.pu_price
				end as cost,
				moh_evt_pur_unit_text as event_type
			from IDI_Clean.[moh_clean].[pub_fund_hosp_discharges_event] pfhd
			left join IDI_Sandpit.{schemaname}.[moh_pu_pricing] pu on 
				(replace(pfhd.moh_evt_pur_unit_text, '.', '0')=pu.pu_code and pfhd.moh_evt_evst_date between pu.[start_date] and pu.end_date)
			/* Filter out short stay events as per Data dictionary advice*/
			where [moh_evt_shrtsty_ed_flg_ind] is null) full_query
	group by [snz_uid], department,
		datamart,
		subject_area,
		[start_date],
		[end_date],
		event_type
		);
