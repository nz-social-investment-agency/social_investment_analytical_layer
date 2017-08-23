/*********************************************************************************************************
TITLE: MOJ_courtcase_events.sql

DESCRIPTION: Create events table for court cases in SIAL format and derive costs

INPUT: 
IDI_Clean.[moj_clean].[charges]
[IDI_Metadata].[clean_read_CLASSIFICATIONS].[moj_court_id]
IDI_Sandpit.{schemaname}.[moj_offence_to_category_map] 
IDI_Sandpit.{schemaname}.[moj_offense_cat_pricing]

OUTPUT: {schemaname}.[SIAL_moj_courtcase_events]

DEPENDENCIES: 
Tables moj_offence_to_category_map and moj_offense_cat_pricing need to exist

NOTES: 
See SIAL data dictionary for business rules applied

AUTHOR: V Benny

CREATED: 22 July 2016

BUSINESS QA COMPLETE: OCTOBER 2016

HISTORY: 

02 Aug 2017 - Changed the join between charges table and moj_court_id table to account for column name 
				change for court_id column in the IDI Refresh dated 28 July 2017.
19 Oct 2016 - Incorporated the changes suggested during business QA to derive costs in a more accurate way.

*********************************************************************************************************/



create view {schemaname}.[SIAL_MOJ_courtcase_events] as
select 
cases.snz_uid as snz_uid, 
'MOJ' as department,
'COU' as datamart,
'CAS' as subject_area,
cast(cases.start_date as datetime) as [start_date], 
cast(cases.end_date as datetime) as end_date, 
pricing.price as cost,
cases.court_type as event_type, 
cases.outcome_type as event_type_2, 
cases.offence_category as event_type_3
from (
	select snz_uid, start_date, end_date, court_type, outcome_type, offence_category 
	from (
		select snz_uid, start_date, end_date, court_type, outcome_type, offence_category,
		row_number() over (partition by snz_uid, court_type, end_date, outcome_type
						   order by snz_uid, court_type, end_date, outcome_type, offence_category desc, start_date) as row_rank
		from (
			select 
				snz_uid, 
				coalesce([moj_chg_first_court_hearing_date], moj_chg_charge_laid_date) as [start_date],
				coalesce([moj_chg_last_court_hearing_date], [moj_chg_charge_outcome_date]) as [end_date],
				case when court1.court_type in ('Youth Court') then 'Youth' else 'Adult' end as court_type,
				case when c.moj_chg_charge_outcome_type_code in (
					'CONV','CNV','CNVS','COAD','CNVD','COND','DCP','J118','J39J','MIPS34','COCC','COCM','CCMD','CVOC',/*Convicted*/
					'CPSY','CPY','PROV','ADMF','ADFN','ADMN','ADM','ADCH','ADMD','INTRES','YCDIS','YCADM','INTACT',/*Youth Court proved*/
					'DS42','D19C','DWC','DWS','DS19',/*Discharge without conviction*/
					'YDFC','INTSEN','DCYP','YP35','WDC','DDC' /*Adult diversion, Youth Court discharge*/
					)
					then 'PVN' /*Proved*/
					else 'UNP' /*Not proved*/
				end as outcome_type,
				offcatmap.offence_category
			from IDI_Clean.[moj_clean].[charges] c
			inner join [IDI_Metadata].[clean_read_CLASSIFICATIONS].[moj_court_id] court1 on (c.[moj_chg_last_court_id_code] = court1.court_id)
			left join IDI_Sandpit.{schemaname}.[moj_offence_to_category_map] offcatmap on (c.moj_chg_offence_code = offcatmap.offence_code)
		) unordered_charges
	)ordered_charges 
	where ordered_charges.row_rank=1 /*Only pick up first rows from this sorted list of ordered charges. This row best represents the distinct list of cases*/
)cases
left join IDI_Sandpit.{schemaname}.[moj_offense_cat_pricing] pricing on (cases.offence_category = pricing.offence_category and cases.court_type = pricing.court_type and 
													cases.end_date between pricing.start_date and pricing.end_date);