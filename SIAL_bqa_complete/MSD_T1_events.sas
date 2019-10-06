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
PNH Aug 2019 Added a compress statement to limit the space taken up
*********************************************************************************************************/

/* Define source database version*/
%include "&dependfolder./sasautos/ben_formats.sas";

/* Include Marc DeBoer's macros to create benefit spells from the msd_clean.msd_spell table*/ 
/* Call the macros to create the benefit spells data*/ 
%AdltsMainBenSpl(AMBSinfile =
                 ,AMBS_IDIxt = &idi_refresh.
                 ,AMBS_BenSpl = benefitspells);

/* Create the table in sandpit*/
proc sql noprint;

	drop table sand.SIAL_MSD_T1_events;

	create table sand.SIAL_MSD_T1_events as
		select snz_uid,
			'MSD' as department,
			'BEN' as datamart,
			'T1' as subject_area,
			EntitlementSD as start_date,
			EntitlementED as end_date,
			msd_spel_servf_code as event_type,
			msd_spel_add_servf_code as event_type_2,
			BenefitType as event_type_3,
			BenefitName as event_type_4
		from work.benefitspells;
quit;

/* all views now stored in IDI_USercode */
/* create a view to the table! */
/* Note at some point rewrite as a view? */
proc sql;
	&idi_usercode_connect;
	execute(
	create view [&schema].[SIAL_MSD_T1_events] as select * from [IDI_SANDPIT].[&schema].[SIAL_MSD_T1_events]
	;
	) by odbc;
	disconnect from odbc;
quit;


/* to comply with Stats new usuage policy, compress tables over 5GB*/
/* this is not over 5GB, but compress anyway to save space*/
proc sql;
	&idi_connect;
	execute(
ALTER TABLE [IDI_Sandpit].[&Schema].[SIAL_MSD_T1_events] REBUILD PARTITION = ALL WITH (DATA_COMPRESSION = PAGE)
	) by odbc;
quit;