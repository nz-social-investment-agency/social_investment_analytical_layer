/*********************************************************************************************************
TITLE: MOE_itl_events

DESCRIPTION: create the event table Industry Training and Modern Apprenticeships

INPUT: [&idi_refresh.].[moe_clean].[tec_it_learner]
	[&schema.].[inflation_index]

OUTPUT: [&schema.].SIAL_MOE_ITL_events

DEPENDENCIES: 
[&schema.].[moe_itl_fund_rate] table must exist

NOTES: 
Reference period start: 
1 January 2003.
Target population: 
People undergoing workplace-based training activity eligible for funding through the Industry Training fund and Modern Apprenticeships funds.
Observed population:  
People undergoing workplace-based training activity which is eligible for funding through the Industry Training fund and Modern Apprenticeships fund.
Analysis Unit: 
Training activity of individuals in programmes administered by Industry Training Organisation in each training fund in a calendar year. 

Cost is taken from fixed cost per year by the fund code from MOE - given by David Earle

Each row is per course for each snz_uid

Note that from 2011 onwards there is a change of management system

AUTHOR: Wen Jhe Lee

DATE: 21 April 2017

HISTORY: 
v2 - updated with actual fund cost from MOE -
v1 created 21 Apr 2017
PNH - June 2019 - Views now have to be created in the IDI_UserCode Schema in the IDI
August 2019 - Added a select statement to log if user does not have access to under lying IDI tables
changed event_type_3 to entity_id for output checking summarising
*********************************************************************************************************/
proc sql;
&IDI_usercode_connect; 
execute(
create view [&schema.].SIAL_MOE_itl_events as

(
select snz_uid,
/*		--snz_moe_uid,		*/
		'MOE' as department,
		'ITL' as datamart,
		'ENR' as subject_area,
		cast(moe_itl_start_date as datetime) as start_date,
		cast(moe_itl_end_date as datetime) as end_date,
		moe_itl_fund_code as event_type, /*-- Fund Code of either IT (Industry Training) or MA (Modern Apprenticeships)*/
		moe_itl_ito_edumis_id_code as entity_id, /*-- MOE ID of Industry Training Provider*/
		moe_itl_nqf_level_code as event_type_3, /*-- The NZQF level of the training programme*/
		moe_itl_nzsced_detail_text as event_type_4, /*-- The NZSCED detail of programme*/
		round(sum(cost_sum),2)  as cost
		from  
					(select * ,
						(moe_itl_sum_units_consumed_nbr* moerate.rate) as cost_sum 
						from [&idi_refresh.].[moe_clean].[tec_it_learner] tec_learner
					inner join (
						select rate ,
						start_date as sd_rate,
						end_date as ed_rate,
						moe_itl_fund_code as fund
						from  [IDI_Sandpit].[&schema.].[moe_itl_fund_rate] ) moerate /*-- Table derived from MOE fixed cost by year*/
					on 
					 tec_learner.moe_itl_fund_code=moerate.fund and
					 tec_learner.moe_itl_start_date between sd_rate and ed_rate ) summary
					where moe_itl_start_date!='' 

		group by snz_uid,moe_itl_start_date,moe_itl_end_date,moe_itl_fund_code,moe_itl_ito_edumis_id_code,	moe_itl_nqf_level_code, moe_itl_nzsced_detail_text


)
;	) by odbc;
	execute(select top 10 * from [&schema.].SIAL_MOE_itl_events) by odbc;
	disconnect from odbc;
Quit;