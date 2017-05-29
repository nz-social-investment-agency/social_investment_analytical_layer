/*********************************************************************************************************
 TITLE: MIX_selfharm_events

 DESCRIPTION: Create an event table of records of suicide or self harm using ACC events table
 CYF events table and a MOH PFD and NNPAC 

 INPUT: 
 {schemaname}.SIAL_ACC_injury_events
 {schemaname}.SIAL_CYF_abuse_events
 [IDI_Clean].[moh_clean].[pub_fund_hosp_discharges_diag]
 [IDI_Clean].[moh_clean].[pub_fund_hosp_discharges_event]

 OUTPUT: 
 {schemaname}.SIAL_MIX_selfharm_events

 DEPENDENCIES: 
 SIAL_CYF_abuse_events, SIAL_MOH_pfhd_events and SIAL_ACC_injury_events must exist

 NOTES: 
 See SIAL data dictionary for business rules applied

 AUTHOR: 
 E Walsh

 CREATED: 
 04 Oct 2016

 HISTORY: 
 
*********************************************************************************************************/



create view {schemaname}.SIAL_MIX_selfharm_events as (
select  snz_uid, 
			'MIX' as department,
			'HRM' as datamart,
			'SLF' as subject_area,	
			/* just in case the extra sources of info dont have datetime format*/			
			cast(sdt as datetime) as [start_date],
			cast(edt as datetime) as [end_date],
			source_agency as event_type/*,*/
from (
select snz_uid, start_date as sdt, end_date as edt, department as source_agency, null as cost
from {schemaname}.SIAL_ACC_injury_events
/* warning in the ACC_injury_events SIAL table if event_type_2 is no longer acc_cla_wilful_self_inflicted_status_text or the
3 character code changes then this will be incorrect. A note is included in the ACC_injury_events SIAL script to note this dependency */
/* CON is short for confirmed wilful self inflicted status*/
where event_type_2 = 'CON'
union all
select snz_uid, start_date as sdt, end_date as edt, department as source_agency, null as cst
from {schemaname}.SIAL_CYF_abuse_events
/* warning if these 3 digit short hands change then this will be incorrect */
/* SHS is short for suicide or self harm */
where event_type = 'SHS'
union all
select snz_uid, start_date as sdt, end_date as edt, department as source_agency, null as cst 
/* no filtering required for this table as the identification of suicide and self harm is done
in the table above */
--from {schemaname}.[moh_sucide_selfharm_v2]
		from (select distinct snz_uid, 
				department,
				datamart,
				subject_area,	
				cast([start_date] as datetime) as [start_date], 
				cast([end_date] as datetime) as [end_date]
		from (
			select 
				p.snz_uid
				,'MOH' as department
				,'HRM' as datamart
				,'SLF' as subject_area
				,p.moh_evt_event_id_nbr
				,case when d.moh_dia_op_date is null /* If there is an operation date use that otherwise use the event start date */
				then p.moh_evt_evst_date
				else d.moh_dia_op_date
				end as [start_date]
				,p.moh_evt_even_date  as end_date
		   
			from [IDI_Clean].[moh_clean].[pub_fund_hosp_discharges_diag] d left join [IDI_Clean].[moh_clean].[pub_fund_hosp_discharges_event] p 
				on d.moh_dia_event_id_nbr=p.moh_evt_event_id_nbr
			/* look for external cause */
				where d.moh_dia_diagnosis_type_code = 'E' and 
		/* note we have constructed the codes in this way as ICD10 codes refer to X60-X84 as intentional self harm */
				substring(d.moh_dia_clinical_code,1,3) in ('X60','X61','X62','X63',
				'X64','X65','X66','X67','X68','X69','X70','X71','X72','X73','X74',
				'X75','X76','X77','X78','X79','X80','X81','X82','X83','X84') and  p.snz_acc_claim_uid is null )x
		/*   For 2015 19,500 for 2015 */
		group by snz_uid, department, datamart, subject_area, [start_date], [end_date]) moh_sucide_selfharm_v2
)x
);




