/*********************************************************************************************************
TITLE: MSD_T3_events

DESCRIPTION: Create MSD Third Tier Benefit costs events table

INPUT: &idi_refresh..msd_clean.msd_third_tier_expenditure

OUTPUT: [&schema.].SIAL_MSD_T3_events

DEPENDENCIES: 
NA

NOTES: 
See SIAL data dictionary for business rules applied

AUTHOR: V Benny

CREATED: 22 July 2016

BUSINESS QA COMPLETE: OCTOBER 2016

HISTORY: 
Jul 2016 V Benny Changed the datatype of start and end dates into datetime to be 
consistent across all tables written into SQL from SAS.
PNH Aug 2019 Added a select statement to ensure the user has access to the underlying IDI tables. This will show up in the log


*********************************************************************************************************/

/* Get the MSD tier 3 benefits per individual per supplementary benefit type */
proc sql;
	&idi_usercode_connect;
	execute(
		create view [&schema.].SIAL_MSD_T3_events as (
			select 
				snz_uid, 
				'MSD' as department,
				'BEN' as datamart,
				'T3' as subject_area,
				cast(msd_tte_decision_date as datetime) as [start_date],
				cast(msd_tte_decision_date as datetime) as [end_date], 
				[msd_tte_pmt_amt] as cost,
				[msd_tte_lump_sum_svc_code] as event_type,
				[msd_tte_recoverable_ind] as event_type_2
			from (
				select 
					snz_uid, msd_tte_decision_date, [msd_tte_lump_sum_svc_code], [msd_tte_recoverable_ind], 
					sum([msd_tte_pmt_amt]) as [msd_tte_pmt_amt]
				from &idi_refresh..msd_clean.msd_third_tier_expenditure
					group by snz_uid, 
						msd_tte_decision_date, 
						[msd_tte_lump_sum_svc_code], 
						[msd_tte_recoverable_ind] )x
						);
	) by odbc;
	execute(select top 10 * from [&schema.].SIAL_MSD_T3_events) by odbc;
	disconnect from odbc;
Quit;