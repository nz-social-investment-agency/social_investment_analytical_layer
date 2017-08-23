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

/* Define source database version*/
%let dbrefreshversion = &idi_refresh; /* Should be the source DB name, like IDI_Clean or IDI_Clean_20161020*/

/* Include Marc DeBoer's macros to create benefit spells from the msd_clean.msd_spell table*/ 
/* Call the macros to create the benefit spells data*/ 
%AdltsMainBenSpl(AMBSinfile =
                 ,AMBS_IDIxt = &dbrefreshversion.
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
