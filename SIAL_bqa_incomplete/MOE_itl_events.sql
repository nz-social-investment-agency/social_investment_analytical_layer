/*********************************************************************************************************
TITLE: MOE_itl_events

DESCRIPTION: create the event table Industry Training and Modern Apprenticeships

INPUT: [IDI_CLEAN].[moe_clean].[tec_it_learner]
	{schemaname}.[inflation_index]

OUTPUT: {schemaname}.SIAL_MOE_ITL_events

DEPENDENCIES: 
{schemaname}.[inflation_index] table must exist

NOTES: 
Reference period start: 
1 January 2003.
Target population: 
People undergoing workplace-based training activity eligible for funding through the Industry Training fund and Modern Apprenticeships funds.
Observed population:  
People undergoing workplace-based training activity which is eligible for funding through the Industry Training fund and Modern Apprenticeships fund.
Analysis Unit: 
Training activity of individuals in programmes administered by Industry Training Organisation in each training fund in a calendar year. 

Cost is selected to be fixed at 2000 for a full course as an estimate based in the year ending 2015, until  actual cost per course from MOE
MoE uses fixed cost for each course - awaiting fixed cost from MoE, till then use fixed figure of 2000
Each row is per course for each snz_uid

Note that from 2011 onwards there is a change of management system

AUTHOR: Wen Jhe Lee

DATE: 21 April 2017

HISTORY: 


*********************************************************************************************************/
create view {schemaname}.SIAL_MOE_itl_events as

(
select snz_uid,
		--snz_moe_uid,		
		'MOE' as department,
		'ITL' as datamart,
		'ENR' as subject_area,
		cast(moe_itl_start_date as datetime) as start_date,
		cast(moe_itl_end_date as datetime) as end_date,
		moe_itl_fund_code as event_type, -- Fund Code of either IT (Industry Training) or MA (Modern Apprenticeships)
		moe_itl_ito_edumis_id_code as event_type_2, -- MOE ID of Industry Training Provider
		moe_itl_nqf_level_code as event_type_3, -- The NZQF level of the training programme
		moe_itl_nzsced_detail_text as event_type_4, -- The NZSCED detail of programme
		round(sum(cost2),2)  as cost
		from  
					(select * ,
						(moe_itl_sum_units_consumed_nbr*2000)*b.adj  as cost2 
						from [IDI_CLEAN].[moe_clean].[tec_it_learner]
					left join (
						select value/(select value from {schemaname}.[inflation_index] where inflation_type='CPI' and quarter='2015Q4') as adj ,
						start_date as sd,
						end_date as ed 
						from  {schemaname}.[inflation_index] where inflation_type='CPI') b
					on moe_itl_start_date between sd and ed ) z 
					where moe_itl_start_date!='' 

		group by snz_uid,moe_itl_start_date,moe_itl_end_date,moe_itl_fund_code,moe_itl_ito_edumis_id_code,	moe_itl_nqf_level_code, moe_itl_nzsced_detail_text

)
;