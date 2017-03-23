/****************************************************
 TITLE: uninstall_sial_tables_viuews.sql

 DESCRIPTION: This script is used to uninstall SIAL tables and views in
 the specified schema. It creates all the SIAL dependency 
 tables, and then creates all the SQL views under SIAL.

 OUTPUT:  

 DEPENDENCIES: NA

 NOTES:  

 AUTHOR: V Benny

 CREATED: 10 Mar 2017

 HISTORY: v1

 ISSUES: NA

***************************************************/

/* Drop the SIAL meta-tables and procedures*/
if object_id('{schemaname}.sialexecresults') is not null  drop table {schemaname}.sialexecresults;
if object_id('{schemaname}.sp_createSIALViews') is not null  drop procedure {schemaname}.sp_createSIALViews;
if object_id('{schemaname}.sp_loadPricingtables') is not null  drop procedure {schemaname}.sp_loadPricingtables;

/* Drop the pricing support tables*/
if object_id('{schemaname}.moe_school_decile_pricing') is not null  drop table {schemaname}.moe_school_decile_pricing;
if object_id('{schemaname}.moe_ter_fundingrates') is not null  drop table {schemaname}.moe_ter_fundingrates;
if object_id('{schemaname}.moh_b4sc_pricing') is not null  drop table {schemaname}.moh_b4sc_pricing;
if object_id('{schemaname}.moh_primhd_pu_pricing') is not null  drop table {schemaname}.moh_primhd_pu_pricing;
if object_id('{schemaname}.moh_pu_pricing') is not null  drop table {schemaname}.moh_pu_pricing;
if object_id('{schemaname}.moj_offence_to_category_map') is not null  drop table {schemaname}.moj_offence_to_category_map;
if object_id('{schemaname}.moj_offense_cat_pricing') is not null  drop table {schemaname}.moj_offense_cat_pricing;
if object_id('{schemaname}.cor_mmc_pricing') is not null  drop table {schemaname}.cor_mmc_pricing;

/* Drop the SIAL views*/
if object_id('{schemaname}.SIAL_COR_sentence_events') is not null  drop view {schemaname}.SIAL_COR_sentence_events;
if object_id('{schemaname}.SIAL_IRD_income_events') is not null  drop view {schemaname}.SIAL_IRD_income_events;
if object_id('{schemaname}.SIAL_MIX_mortality_events') is not null  drop view {schemaname}.SIAL_MIX_mortality_events;
if object_id('{schemaname}.SIAL_MIX_selfharm_events') is not null  drop view {schemaname}.SIAL_MIX_selfharm_events;
if object_id('{schemaname}.SIAL_MOE_intervention_events') is not null  drop view {schemaname}.SIAL_MOE_intervention_events;
if object_id('{schemaname}.SIAL_MOH_B4School_events') is not null  drop view {schemaname}.SIAL_MOH_B4School_events;
if object_id('{schemaname}.SIAL_MOH_cancer_events') is not null  drop view {schemaname}.SIAL_MOH_cancer_events;
if object_id('{schemaname}.SIAL_MOH_chronic_events') is not null  drop view {schemaname}.SIAL_MOH_chronic_events;
if object_id('{schemaname}.SIAL_MOH_gms_events') is not null  drop view {schemaname}.SIAL_MOH_gms_events;
if object_id('{schemaname}.SIAL_MOH_labtest_events') is not null  drop view {schemaname}.SIAL_MOH_labtest_events;
if object_id('{schemaname}.SIAL_MOH_nir_events') is not null  drop view {schemaname}.SIAL_MOH_nir_events;
if object_id('{schemaname}.SIAL_MOH_nnpac_events') is not null  drop view {schemaname}.SIAL_MOH_nnpac_events;
if object_id('{schemaname}.SIAL_MOH_pfhd_events') is not null  drop view {schemaname}.SIAL_MOH_pfhd_events;
if object_id('{schemaname}.SIAL_MOH_pharm_events') is not null  drop view {schemaname}.SIAL_MOH_pharm_events;
if object_id('{schemaname}.SIAL_MOH_primhd_events') is not null  drop view {schemaname}.SIAL_MOH_primhd_events;
if object_id('{schemaname}.SIAL_POL_offender_events') is not null  drop view {schemaname}.SIAL_POL_offender_events;
if object_id('{schemaname}.SIAL_POL_victim_events') is not null  drop view {schemaname}.SIAL_POL_victim_events;

if object_id('{schemaname}.SIAL_ACC_injury_events') is not null  drop view {schemaname}.SIAL_ACC_injury_events;
if object_id('{schemaname}.SIAL_CYF_abuse_events') is not null  drop view {schemaname}.SIAL_CYF_abuse_events;
if object_id('{schemaname}.SIAL_CYF_client_events') is not null  drop view {schemaname}.SIAL_CYF_client_events;
if object_id('{schemaname}.SIAL_MOJ_courtcase_events') is not null  drop view {schemaname}.SIAL_MOJ_courtcase_events;
if object_id('{schemaname}.SIAL_MSD_T2_events') is not null  drop view {schemaname}.SIAL_MSD_T2_events;
if object_id('{schemaname}.SIAL_MSD_T3_events') is not null  drop view {schemaname}.SIAL_MSD_T3_events;

/* Drop the SIAL tables*/
if object_id('{schemaname}.SIAL_MOE_school_events') is not null  drop table {schemaname}.SIAL_MOE_school_events;
if object_id('{schemaname}.SIAL_MOE_tertiary_events') is not null  drop table {schemaname}.SIAL_MOE_tertiary_events;