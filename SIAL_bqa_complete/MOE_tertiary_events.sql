
/*********************************************************************************************************
TITLE: SIAL_MOE_tertiary_events

DESCRIPTION: create the event table for tertiary 
education spells and costs excluding Industry 
Training

INPUT: [IDI_CLEAN].[moe_clean].[enrolment]
	[IDI_Sandpit].[DL-MAA2016-15].[moe_ter_fundingrates]

OUTPUT: {schemaname}.SIAL_MOE_ter_edu_event

DEPENDENCIES: 
moe_ter_fundingrates table must exist

NOTES: 
See SIAL data dictionary for business rules applied

AUTHOR: Wen Jhe Lee

DATE: 12 April 2017

HISTORY: 
28 Apr 2017 WL added based on feedback domestic Ind =1 and fund codes list
12 Apr 2017 WL port based on code in moe_ter_edu_event.sas from Anotine Merval

*********************************************************************************************************/


 create view {schemaname}.SIAL_MOE_tertiary_events as
(
select
	z.snz_uid,
	'MOE' as department,	
	'TER' as datamart,	
	'ENR' as subject_area,
	left(z.subsector, 7) as event_type,	
	z.moe_enr_provider_code as event_type_2,
	z.qual_code as event_type_3,		
	round( SUM(ter_cost), 3) as cost ,
		0 as revenue,
	cast(z.moe_enr_prog_start_date as datetime) as start_date, 
	cast(z.moe_enr_prog_end_date  as datetime) as end_date

	from (
		select a.*, b.*, a.efts_consumed*b.ter_fund_rates as ter_cost  from (
		select distinct 
			snz_uid
			,moe_enr_year_nbr as cal_year 
			,moe_enr_prog_start_date
			,moe_enr_qual_code as qual_code
			,moe_enr_prog_end_date
			,moe_enr_efts_consumed_nbr as EFTS_consumed
			,CASE WHEN [moe_enr_subsector_code]=1 or [moe_enr_subsector_code]=3 then 'Universities'
				WHEN [moe_enr_subsector_code]=2 then 'Polytechnics' 
				WHEN [moe_enr_subsector_code]=4 then 'Wananga'
				WHEN [moe_enr_subsector_code]=5 or [moe_enr_subsector_code]=6 then 'Private Training Establishments' 
			END AS subsectord
			,moe_enr_provider_code
			,moe_enr_funding_srce_code
		from [IDI_CLEAN].[moe_clean].[enrolment]
			where 2000 <= [moe_enr_year_nbr]   and [moe_enr_year_nbr]  <= 9999
			AND [moe_enr_funding_srce_code] IN ('01','25','26','27','28','29','30','32')
			AND [moe_enr_is_domestic_ind] =1
			AND [moe_enr_efts_consumed_nbr] > 0 ) a
		left join {schemaname}.[moe_ter_fundingrates] b
			on a.cal_year=b.year and  a.subsectord = b.Subsector ) z
group by z.snz_uid,z.subsector,z.qual_code,z.moe_enr_provider_code,z.moe_enr_prog_start_date, z.moe_enr_prog_end_date 

);
