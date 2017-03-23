/*********************************************************************************************************
TITLE: MSD_T2_events

DESCRIPTION: Create MSD Second Tier Benefit costs events table

INPUT: IDI_Clean.[msd_clean].[msd_second_tier_expenditure]

OUTPUT: {schemaname}.SIAL_MSD_T2_events

DEPENDENCIES: 
NA

NOTES: 
See SIAL data dictionary for business rules applied

AUTHOR: V Benny

CREATED: 22 July 2016

BUSINESS QA COMPLETE: OCTOBER 2016

HISTORY: 
14 September 2016 V Benny Changed the daily costs into a lumpsum cost. This is done by 
                          lumpsum_cost = dailycost* (end_date-start_date + 1)

*********************************************************************************************************/


/* Get the MSD tier 2 benefits per individual per supplementary benefit type */
create view {schemaname}.SIAL_MSD_T2_events as
(
	select 
	snz_uid,
	'MSD' as department,
	'BEN' as datamart,
	'T2' as subject_area,
	cast([msd_ste_start_date] as datetime) as [start_date],
	cast([msd_ste_end_date] as datetime) as end_date, 
	[msd_ste_daily_gross_amt] * (datediff(DD, cast([msd_ste_start_date] as datetime), cast([msd_ste_end_date] as datetime)) + 1) as cost,
	[msd_ste_supp_serv_code] as event_type,
	[msd_ste_srvst_code] as event_type_2
	from (
		select 
			[snz_uid], 
			[msd_ste_supp_serv_code], 
			[msd_ste_srvst_code],
			[msd_ste_start_date],
			[msd_ste_end_date],
			sum([msd_ste_daily_gross_amt]) as [msd_ste_daily_gross_amt]
		from IDI_Clean.[msd_clean].[msd_second_tier_expenditure]
		group by [snz_uid], 
			[msd_ste_supp_serv_code], 
			[msd_ste_srvst_code],
			[msd_ste_start_date],
			[msd_ste_end_date] )x
);
