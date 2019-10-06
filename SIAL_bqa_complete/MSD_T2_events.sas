/*********************************************************************************************************
TITLE: MSD_T1_events

DESCRIPTION: Create MSD Second Tier Benefit costs events table

INPUT: &idi_refresh..[msd_clean].[msd_second_tier_expenditure]

OUTPUT: [&schema.].SIAL_MSD_T2_events

DEPENDENCIES: 
NA

NOTES: 
See SIAL data dictionary for business rules applied

AUTHOR: V Benny

CREATED: 22 July 2016

BUSINESS QA COMPLETE: OCTOBER 2016

HISTORY: 
30 Nov 2017 EW removed working for families as that is now captured in the IRD table
14 Sep 2016 VB Changed the daily costs into a lumpsum cost. This is done by 
lumpsum_cost = dailycost* (end_date-start_date + 1)
PNH Aug 2019 Added a select statement to ensure the user has access to the underlying IDI tables. This will show up in the log
*********************************************************************************************************/

/* Get the MSD tier 2 benefits per individual per supplementary benefit type */
proc sql;
	&idi_usercode_connect;
	execute(
		create view [&schema.].SIAL_MSD_T2_events as
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
			from &idi_refresh..[msd_clean].[msd_second_tier_expenditure]
				where msd_ste_supp_serv_code != '064'
					group by [snz_uid], 
						[msd_ste_supp_serv_code], 
						[msd_ste_srvst_code],
						[msd_ste_start_date],
						[msd_ste_end_date] )x
			);
	) by odbc;
	execute(select top 10 * from [&schema.].SIAL_MSD_T2_events) by odbc;
	disconnect from odbc;
Quit;