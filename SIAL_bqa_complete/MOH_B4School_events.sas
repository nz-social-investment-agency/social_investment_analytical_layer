/*********************************************************************************************************
TITLE: MOH_B4School_events

DESCRIPTION: Create B4 School Check events table into SIAL format

INPUT: &idi_refresh..[moh_clean].b4sc

OUTPUT: [&schema.].SIAL_MOH_B4School_events

DEPENDENCIES: 
moh_b4sc_pricing table must exist

NOTES: 
See SIAL data dictionary for business rules applied

AUTHOR: V Benny

DATE: 22 July 2016

HISTORY: 
PNH Aug 2019 Added a select statement to ensure the user has access to the underlying IDI tables. This will show up in the log
*********************************************************************************************************/
proc sql;
	connect to odbc(dsn=idi_usercode_srvprd);
	execute(

	create view [&schema.].SIAL_MOH_B4School_events as
		(
	select 
		b4sc.snz_uid, 
		'MOH' as department,
		'B4S' as datamart,
		'B4S' as subject_area,
		cast(mindt.[start_date] as datetime) as [start_date],
		cast(b4sc.moh_bsc_check_date as datetime) as [end_date],
		coverage.per_peron_amt as cost,
		b4sc.moh_bsc_check_status_text as event_type
	from &idi_refresh..[moh_clean].b4sc b4sc
		inner join  /* get the earliest test date for the child under the B4SC programme, and use as start date */
			(select snz_uid, min([start_date]) as [start_date] from
			(select snz_uid, coalesce(moh_bsc_general_date, cast('9999-12-31' as date)) as [start_date] from &idi_refresh..[moh_clean].b4sc
				union all
			select snz_uid, coalesce([moh_bsc_vision_date], cast('9999-12-31' as date)) as [start_date] from &idi_refresh..[moh_clean].b4sc
				union all
			select snz_uid, coalesce([moh_bsc_hearing_date], cast('9999-12-31' as date)) as [start_date] from &idi_refresh..[moh_clean].b4sc
				union all
			select snz_uid, coalesce([moh_bsc_growth_date], cast('9999-12-31' as date)) as [start_date] from &idi_refresh..[moh_clean].b4sc
				union all
			select snz_uid, coalesce([moh_bsc_dental_date], cast('9999-12-31' as date)) as [start_date] from &idi_refresh..[moh_clean].b4sc
				union all
			select snz_uid, coalesce([moh_bsc_imms_date], cast('9999-12-31' as date)) as [start_date] from &idi_refresh..[moh_clean].b4sc
				union all
			select snz_uid, coalesce([moh_bsc_peds_date], cast('9999-12-31' as date)) as [start_date] from &idi_refresh..[moh_clean].b4sc
				union all
			select snz_uid, coalesce([moh_bsc_sdqp_date], cast('9999-12-31' as date)) as [start_date] from &idi_refresh..[moh_clean].b4sc
				union all
			select snz_uid, coalesce([moh_bsc_sdqt_date], cast('9999-12-31' as date)) as [start_date] from &idi_refresh..[moh_clean].b4sc)x
				group by snz_uid) mindt
					on (b4sc.snz_uid = mindt.snz_uid)
				left join /* get the count of children for the financial year, and divide the total allocation for this year by the count*/
					(select pr.start_date, pr.end_date, pr.b4sc_spend/count(snz_uid) as per_peron_amt from (select * from &idi_refresh..moh_clean.b4sc 
						where moh_bsc_check_status_text in ('Closed','Completed')) b4sc
							inner join [IDI_Sandpit].[&schema.].[moh_b4sc_pricing] pr
								on (b4sc.moh_bsc_check_date between pr.start_date and pr.end_date)
							group by pr.start_date, pr.end_date, pr.b4sc_spend) coverage 
								on (b4sc.moh_bsc_check_date between coverage.start_date and coverage.end_date)
		);
	) by odbc;
	execute(select top 10 * from [&schema.].SIAL_MOH_B4School_events) by odbc;
	disconnect from odbc;
Quit;