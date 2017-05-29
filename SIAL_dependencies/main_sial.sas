/*********************************************************************************************************
TITLE: main_sial.sas

DESCRIPTION: 
This scripts installs all SIAL components in the target database schema provided by the user. The respective
components are explained under OUTPUTS section here.

INPUT:
Ensure that you change the following 3 variable values in this script as per your need. These two variables
can be found at the beginning of the this script.

1. sial_code_path - This is the full path to the root folder where you keep the social_investment_analytical_layer
	scripts. Change this to reflect the location where you store the SIAL .

2. targetschema- This is the target schema on the SQL server in which the SIAL components 
	will be created.

3. idi_refresh - This is the IDI Clean refresh version that the SIAL views and tables need to be created from.
	This is kept as IDI_Clean by default.

OUTPUT:
The following tables and views will be created in the target schema that you specified under IDI_Sandpit:
SIAL Views (can be found under IDI_Sandpit -> <target schema> -> Views):
	SIAL_ACC_injury_events
	SIAL_COR_sentence_events
	SIAL_CYF_abuse_events
	SIAL_CYF_client_events
	SIAL_HNZ_register_events
	SIAL_IRD_income_events
	SIAL_MIX_mortality_events
	SIAL_MIX_selfharm_events
	SIAL_MOE_ece_events
	SIAL_MOE_intervention_events
	SIAL_MOE_itl_events
	SIAL_MOE_tertiary_events
	SIAL_MOH_B4School_events
	SIAL_MOH_cancer_events
	SIAL_MOH_chronic_events
	SIAL_MOH_gms_events
	SIAL_MOH_labtest_events
	SIAL_MOH_nir_events
	SIAL_MOH_nnpac_events
	SIAL_MOH_pfhd_events
	SIAL_MOH_pharm_events
	SIAL_MOH_primhd_events
	SIAL_MOJ_courtcase_events	
	SIAL_MSD_T2_events
	SIAL_MSD_T3_events
	SIAL_POL_offender_events
	SIAL_POL_victim_events

SIAL tables (can be found under IDI_Sandpit -> <target schema> -> Tables):
	SIAL_MSD_T1_events
	SIAL_MOE_school_events

SIAL Supporting tables(can be found under IDI_Sandpit -> <target schema> -> Tables):
	inflation_index
	moe_school_decile_pricing
	moe_ter_fundingrates
	moh_b4sc_pricing
	moh_primhd_pu_pricing
	moh_pu_pricing
	moj_offence_to_category_map
	moj_offense_cat_pricing
	cor_mmc_pricing

AUTHOR: E Walsh, V Benny

DATE: 16 March 2017

DEPENDENCIES: 
NA

NOTES: 
1. As more of the business QAs are finishedthe paths to the sas scripts will change. The
	script main_sial will be updated to reflect the new paths.
2. You can ignore warnings of the type- "The quoted string currently being processed 
	has become more than 262 characters long.  You might have unbalanced quotation marks".
	These appear because the SAS code reads in SQL files which tend to be quite long. The code
	will still run and create the SIAL components.

HISTORY: 
24 May 2017	v1.1	VB	Updated the main script with more comments and improved functionality
16 Mar 2017	v1
*********************************************************************************************************/

/* Change the schema to your own schema*/
/* Change the path to match the location where you put the sial scripts */
%let idi_refresh=IDI_Clean; /* Example- IDI_Clean_20161010*/
%let targetschema=DL-MAAXXXX-XX; /* Example, DL-MAA2016-XX*/
%let sial_code_path = \\<path_to_sial_folder>\social_investment_analytical_layer; /* \\wprdfs0x\MAA2016-XX BLAH Project\myfolder\social_investment_analytical_layer */







/*******************************************************************************************************************************
START OF SCRIPT
*******************************************************************************************************************************/

/* Set up the sand library to the target database/schema to which the SIAL physical tables are to be written to*/
libname sand ODBC dsn= idi_sandpit_srvprd schema="&targetschema." bulkload=yes;
%let targetschema=%tslit([&targetschema.]);

/* Set up global variables for all the SIAL subdirectories*/
%let dependfolder = &sial_code_path.\SIAL_dependencies\;
%let logfolder = &sial_code_path.\SIAL_logs\;
%let bqacfolder = &sial_code_path.\SIAL_bqa_complete\;
%let bqaifolder = &sial_code_path.\SIAL_bqa_incomplete\;
%let sqlfolder = &sial_code_path.\;

/* Read in the remaining libraries needed for the SIAL tables that run in SAS */
%include "&dependfolder.\libnames.sas";

/* Load macros */
%include "&dependfolder.macro_geterrors.sas";
%include "&dependfolder.macro_AdultSpellsonYouthWorkingAgeBenefits.sas";

/* Read in the SQL scripts to be executed*/
filename file0 %tslit(&dependfolder.uninstall_sial_tables_views.sql);
filename file1 %tslit(&dependfolder.load_pricing_tables_to_sandpit.sql);
filename file2 %tslit(&dependfolder.create_sial_views.sql);

/* Set up time stampe with no special characters */
%let time = %sysfunc(time(), time8.0);
%let time_hh = %scan(&time.,1, :);
%let time_mm = %scan(&time.,2, :);
%let time_ss = %scan(&time.,3, :);

/* In each of the SQL scripts read, create file references and replace the string 
	"{schemaname}" with the target schema specified by user*/
data _null_;
	infile file0 recfm=f lrecl=32767 pad;
	input @1 sialuninst $32767.;
	sialuninst = tranwrd(sialuninst, "{schemaname}" , &targetschema.);
	call symputx('sialuninst', sialuninst);
run;
data _null_;
	infile file1 recfm=f lrecl=32767 pad;
	input @1 sialpricetabs $32767.;
	call symputx('sialpricetabs', sialpricetabs);
run;
data _null_;
	infile file2 recfm=f lrecl=32767 pad;
	input @1 sialviewsql $32767.;
	call symputx('sialviewsql', sialviewsql);
run;

/* This creates all the SIAL related views in the database schema specified.*/
proc sql;
	connect to odbc(dsn=idi_sandpit_srvprd);
	
	/* Uninstall all SIAL procedures, tables and views first, if these already exist in target schema*/	
	execute(&sialuninst.) by odbc;

	/* Set up the stored procedures required to run the SIAL components in SQL Server. This will be in user's personal schema*/
	execute(&sialpricetabs.) by odbc;
	execute(&sialviewsql.) by odbc;

	/* Run all the SIAL dependency pricing tables*/	
	execute( exec [sp_loadPricingtables] @targetschemaname=&targetschema, @sourceFolder= %tslit(&dependfolder.) ) by odbc;	

	/* Run all the SIAL views in the bqac folder- Business QA Completed*/	
	/* Run all the SIAL views in the bqai folder- Business QA yet to be completed*/	
	execute( exec [sp_createSIALViews] @sourcedbname=&idi_refresh, @targetschemaname=&targetschema, @sourceFolder= %tslit(&bqacfolder.) ) by odbc;
	execute( exec [sp_createSIALViews] @sourcedbname=&idi_refresh, @targetschemaname=&targetschema, @sourceFolder= %tslit(&bqaifolder.) ) by odbc;
	
	/* Drop the SIAL stored procedures from SQL- these are no longer required*/
	execute (drop procedure [sp_loadPricingtables]) by odbc;
	execute (drop procedure [sp_createSIALViews]) by odbc;	

	disconnect from odbc;
quit;


/*******************************************************************************************************************************
At this point, you will find a list of SIAL related views in your schema. Navigate to
IDI_Sandpit -> <schemaname or libname> -> Views, and you should be able to find all
the created SIAL Views.

As of SIAL Release v1.1, the views are-
	SIAL_ACC_injury_events
	SIAL_COR_sentence_events
	SIAL_CYF_abuse_events
	SIAL_CYF_client_events
	SIAL_HNZ_register_events
	SIAL_IRD_income_events
	SIAL_MIX_mortality_events
	SIAL_MIX_selfharm_events
	SIAL_MOE_ece_events
	SIAL_MOE_intervention_events
	SIAL_MOE_itl_events
	SIAL_MOE_tertiary_events
	SIAL_MOH_B4School_events
	SIAL_MOH_cancer_events
	SIAL_MOH_chronic_events
	SIAL_MOH_gms_events
	SIAL_MOH_labtest_events
	SIAL_MOH_nir_events
	SIAL_MOH_nnpac_events
	SIAL_MOH_pfhd_events
	SIAL_MOH_pharm_events
	SIAL_MOH_primhd_events
	SIAL_MOJ_courtcase_events
	SIAL_MSD_T2_events
	SIAL_MSD_T3_events
	SIAL_POL_offender_events
	SIAL_POL_victim_events
*******************************************************************************************************************************/


/* Create the execution log table to report on errors during SIAL execution*/
proc sql;
	create table work.sialexecresults as select * from sand.sialexecresults;
quit;


/* This section creates all the SIAL-related tables in the database schema specified.*/

/* MOE primary and secondary enrolments */
filename log1 %tslit(&logfolder.MOE_school_events_saslog_&sysdate.&time_hh.&time_mm.&time_ss..txt);
proc printto log=log1 new;run;
%include "&bqacfolder.MOE_school_events.sas";
proc printto;run;
%getErrors(logfile=log1);
proc sql;
	insert into work.sialexecresults select today(), 'MOE_school_events.sas', 'NA', logline from errors;
quit;


/* MSD tier 1 main benefits */
filename log2 %tslit(&logfolder.MSD_T1_events_saslog_&sysdate.&time_hh.&time_mm.&time_ss..txt);
proc printto log=log2 new;run;

%include "&bqacfolder.MSD_T1_events.sas";
%getErrors(logfile=log2);
proc printto;run;
proc sql;
	insert into work.sialexecresults select today(), 'MSD_T1_events.sas', 'NA', logline from errors;
quit;

/*******************************************************************************************************************************
At this point, you will find a list of SIAL related tables in your schema. Navigate to
IDI_Sandpit -> <schemaname or libname> -> Tables, and you should be able to find all
the created SIAL Tables.

As of SIAL Release v1.1, the tables are-
	SIAL_MOE_school_events
	SIAL_MSD_T1_events

*******************************************************************************************************************************/
