# Social Investment Analytical Layer
[![GitHub version](https://badge.fury.io/gh/nz-social-investment-unit%2Fsocial_investment_analytical_layer.svg)](https://badge.fury.io/gh/nz-social-investment-unit%2Fsocial_investment_analytical_layer)

Standardised tables for doing cross agency work in the IDI.
Refer to CHANGELOG.md for summary of changes.


## Overview:

The SIU has created a Social Investment Analytical Layer (SIAL): events-structured tables that arrange a selected subset of the data held in Statistics New Zealand's IDI into a consistent format, making it easier and faster for authorised IDI users (researchers and analysts) to use and understand.

The SIAL is designed to be reusable tool for the purposes of easy creation of variables for analysis and to add extra cost information that is not inherently available in the IDI. It reformats the commonly used social sector tables available in the IDI into tables based on events (events-structured). An event is defined by a start date and an end date during which the individual was engaged in a particular interaction as recorded by an agency (governmental or NGO). The event can be described as being of a particular event-type (like a particular benefit type or a hospitalisation purchase unit code), and the SIAL also attempts to attach a cost for this event. When such costs are not available directly from the IDI, the SIAL augments the IDI data with costing information obtained from specific agencies. For most of the commonly used tables available in the IDI, there is a corresponding events-structured table under the SIAL.

For example, a hospitalisation spell for an individual in SIAL event terms will have the snz_uid, start and end dates of the hospitalisation, the type of event described by the purchase unit code, the cost of that event and the agency and sub-agency information that the individual interacted with. Another example would be a school enrollment, again defined by a start and end date of enrollment, along with the cost of enrollment. If costs are available from the IDI tables, these are directly used. In the above examples, the costs are not readily available in the IDI, but the SIAL has additional cost-related info obtained from the respective govt. agencies that enables putting a price to each of those events. Wherever the costs cannot be quantified, the cost columns are left NULL, or are completely absent. Also, events of an instantaneous nature (for example- purchasing a pharmaceutical drug) will have the same start and end dates.

## Folder Descriptions:
**SIAL_dependencies:** this folder contains the main_sial.sas script that builds all tables/views. It also contains cost data that isn't available in the IDI along with code to load these files in to SQL.  
**SIAL_bqa_complete:** this folder contains scripts that have been reviewed by the corresponding agencies.  
**SIAL_bqa_incomplete:** this folder contains scripts that are currently being reviewed by the corresponding agencies.  
**SIAL_log:** This folder is used to store the output logs that SAS generates. Since SAS does not have easy to use error handling the logs are written to file and scanned for errors.  
**SIAL_docs:** This folder contains the data dictionary for the SIAL and an overview of the datasets timeline.

## Pre-requisites
Running the SIAL requires read privileges for the following schemas in the IDI_Clean (for any archive version)-
* moh_clean
* moe_clean
* msd_clean
* acc_clean
* cyf_clean
* cor_clean
* moj_clean
* pol_clean
* hnz_clean

If you do not have access to any of the above schemas, then the SIAL installation will skip the creation of the tables/views pertaining to that schema alone. It will still create the components that for the schemas that you have access to. At the end of installation, the tool gives you a detailed breakdown of which components were successfully created, and which ones failed. It also gives you the reason for failure. For example, if you do not have access to "moj_clean" but have access to all other schemas above, the installation will not create the SIAL_MOJ_courtcase_events view, but will still create all the other SIAL components in your target schema. This failure will be listed in the output from the installation. To get access to the schemas listed above, please contact Statistics New Zealand.

## Installation:
1. Download the zip file containing the SIAL scripts from github.
2. Email the zipped file to access2microdata@stats.govt.nz and ask them to move it into your project folder.
3. Unzip the files into your project.
4. Within the unzipped folder, navigate to social_investment_analytical_layer\SIAL_dependencies folder. From this folder, open main_sial.sas in SAS EG
5. Go to the main_sial.sas script- At the top of the script there are three macro variables called idi_refresh, targetschema & sial_code_path
6. Change the targetschema to the location you wish to write your files to e.g. the SIU schema is DL-MAA2016-15
7. Change the sial_code_path to the location where you stored the scripts on the network
8. Change idi_refresh to the required version of IDI_Clean database. By default this is kept as IDI_Clean. E.g. for the SIU our location is \\wprdfs08\MAA2016-15 Supporting the Social Investment Unit\social_investment_analytical_layer
9. Run the main_sial.sas script.

The scripts runs in the following fashion- 
* First, it creates all the necessary variables required for execution based on the user's input.
* The script then reads in a few SQL scripts from files and parses these.
* It then uninstalls all SIAL components that are already available in the target schema specified by the user.
* It installs 2 SQL procedures required for running the SIAL views. This is followed by creation of all SQL Views available in the "sial_bqa_complete" folder, and then the ones in "sial_bqa_incomplete" folder.
* Tt deletes the stored procedures from the database as these are not required any more.
* The SIAL tables are then created one by one.

Note that each time you run main_sial.sas it will uninstall all the SIAL tables you currently have before creating the SIAL tables. Expect warnings while running the code, especially around quoted strings being processed becoming more than 262 characters long. This is because the pricing table queries are read in as strings. It does not have an impact on the pricing tables being created.

Once the script finishes running, the WORK.sialexecresults table will give you the errors for each SIAL component from the execution if there are any.

## Output:
The following tables and views will be created in the target schema that you specified under IDI_Sandpit-

SIAL Views (can be found in SQL Management Studio under IDI_Sandpit -> target schema -> Views)-
* SIAL_ACC_injury_events
* SIAL_COR_sentence_events
* SIAL_CYF_abuse_events
* SIAL_CYF_client_events
* SIAL_HNZ_register_events
* SIAL_IRD_income_events
* SIAL_MIX_mortality_events
* SIAL_MIX_selfharm_events
* SIAL_MOE_ece_events
* SIAL_MOE_intervention_events
* SIAL_MOE_itl_events
* SIAL_MOE_tertiary_events
* SIAL_MOH_B4School_events
* SIAL_MOH_cancer_events
* SIAL_MOH_chronic_events
* SIAL_MOH_gms_events
* SIAL_MOH_labtest_events
* SIAL_MOH_nir_events
* SIAL_MOH_nnpac_events
* SIAL_MOH_pfhd_events
* SIAL_MOH_pharm_events
* SIAL_MOH_primhd_events
* SIAL_MOJ_courtcase_events	
* SIAL_MSD_T2_events
* SIAL_MSD_T3_events
* SIAL_POL_offender_events
* SIAL_POL_victim_events

SIAL tables (can be found in SQL Management Studio under IDI_Sandpit -> target schema -> Tables)-
* SIAL_MSD_T1_events
* SIAL_MOE_school_events

SIAL Supporting tables(can be found in SQL Management Studio under IDI_Sandpit -> target schema -> Tables)-
* inflation_index
* moe_school_decile_pricing
* moe_ter_fundingrates
* moh_b4sc_pricing
* moh_primhd_pu_pricing
* moh_pu_pricing
* moj_offence_to_category_map
* moj_offense_cat_pricing
* cor_mmc_pricing


## Uninstallation:
1. Open uninstall_sial.sas under social_investment_analytical_layer\SIAL_dependencies folder in SAS EG
2. Go to the uninstall_sial.sas script- At the top of the script there are 2 macro variables called targetschema & sial_code_path
3. Change the targetschema to the project schema from which the SIAL components are to be removed (for example, the SIU schema is DL-MAA2016-15).
4. Change the sial_code_path to the location where you stored the scripts on the network
5. Run the uninstall.sas script.

## Known Issues:
1. IDI_Clean.moh_clean.mortality_registrations table structure has changed since the latest IDI refresh. The latest SIAL script has been modified to accommodate for this change. What this means is that if the SIAL is repointed to IDI_Clean_20161020, then the script 'MIX_mortality_events.sql' is bound to fail. You will need to obtain the earlier version of this SIAL script from Github and replace the new script with the older version.

2. If the SIAL is to be run pointing to the IDI_Clean_20160715 refresh version, please note that you will have failures for 'MOH_nnpac_events.sql', 'MIX_mortality_events.sql' and 'CYF_client_events.sql'. The underlying IDI tables have changed the strucuture since this refresh, and the latest SIAL tables have also changed to reflect these underlying table-level changes. To circumvent these errors, use an older version of these scripts from Github or make the required changes to these 3 scripts manually by renaming the appropriate columns to reflect what is available in this IDI refresh version. For more guidance/help, contact us at info@siu.govt.nz.

## Getting Help:
For more help/guidance in running the SIAL, email info@sia.govt.nz

Tracking number: SIU-2017-0139

