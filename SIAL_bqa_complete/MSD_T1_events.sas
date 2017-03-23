/*********************************************************************************************************
TITLE: MSD_T1_events

DESCRIPTION: Create MSD Tier 1 benefit costs table

INPUT: 
[msd_clean].[msd_first_tier_expenditure]
benefitspells (as created from Marc's macro in the IDI wiki)

OUTPUT:
SIAL_MSD_T1_events

DEPENDENCIES: 
Needs the AdltsMainBenSpl macro to be included.

NOTES: 
See SIAL data dictionary for business rules applied

AUTHOR: V Benny

CREATED: 28 June 2016

BUSINESS QA COMPLETE: OCTOBER 2016

HISTORY: 

*********************************************************************************************************/


/* Include Marc DeBoer's macros to create benefit spells from the msd_clean.msd_spell table*/ 


/* Call the macros to create the benefit spells data*/ 
%AdltsMainBenSpl(AMBSinfile =
                 ,AMBS_IDIxt = 
                 ,AMBS_BenSpl = benefitspells);

/* Get the MSD tier 1 benefits per individual per benefit type */
proc sql noprint;
	connect to odbc(dsn=idi_clean_archive_srvprd);
	create table work.msd_first_tier as
		select  snz_uid,
			snz_swn_nbr,
			msd_fte_servf_code,
			msd_fte_srvst_code,
			input(msd_fte_start_date, yymmdd10.) as msd_fte_start_date,
			input(msd_fte_end_date, yymmdd10.) as msd_fte_end_date,
			msd_fte_daily_gross_amt,
			msd_fte_daily_nett_amt	
		from connection to odbc
			(select 
				[snz_uid],[snz_swn_nbr],[msd_fte_servf_code],[msd_fte_srvst_code],
				[msd_fte_start_date],[msd_fte_end_date],[msd_fte_daily_gross_amt],
				[msd_fte_daily_nett_amt]
			from [msd_clean].[msd_first_tier_expenditure]);
	disconnect from odbc;
quit;

/* Join with the benefit spells data to obtain the additional service code for main benefits*/
proc sql noprint;

	drop table sand.SIAL_MSD_T1_events;

	create table sand.SIAL_MSD_T1_events as
		select snz_uid,
			'MSD' as department,
			'BEN' as datamart,
			'T1' as subject_area,
			msd_fte_start_date as start_date,
			msd_fte_end_date as end_date,
			msd_fte_daily_nett_amt*((msd_fte_end_date-msd_fte_start_date)+1) as cost,
			msd_fte_servf_code as event_type,
			msd_spel_add_servf_code as event_type_2,
			BenefitType as event_type_3,
			BenefitName as event_type_4
		from (
			select 
				a.snz_uid, a.msd_fte_servf_code, a.msd_fte_srvst_code,b.msd_spel_add_servf_code,
				b.BenefitType, b.BenefitName,
				a.msd_fte_start_date format=ddmmyy10., 
				a.msd_fte_end_date format=ddmmyy10., 
				sum(a.msd_fte_daily_nett_amt) as msd_fte_daily_nett_amt
			from  work.msd_first_tier a
				left join work.benefitspells b 
					on (a.snz_swn_nbr = b.snz_swn_nbr 
					and a.msd_fte_servf_code = b.msd_spel_servf_code
					and a.msd_fte_start_date >= b.EntitlementSD
					and a.msd_fte_end_date <= b.EntitlementED)
				group by a.snz_uid, 		
					a.msd_fte_servf_code, 
					a.msd_fte_srvst_code, 
					b.msd_spel_add_servf_code,
					a.msd_fte_start_date, 
					a.msd_fte_end_date) inner_query;
quit;
