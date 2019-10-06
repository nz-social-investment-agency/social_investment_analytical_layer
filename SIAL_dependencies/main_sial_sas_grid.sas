/*********************************************************************************************************
TITLE: main_sial.sas

DESCRIPTION: 
This script installs all SIAL components in the target database schema provided by the user. The respective
components are explained under OUTPUTS section here.

INPUT:
Ensure that you change the following 3 variable values in this script as per your need. These two variables
can be found at the beginning of the this script.

1. sial_code_path - This is the full path to the root folder where you keep the social_investment_analytical_layer
scripts. Change this to reflect the location where you store the SIAL .


PNH: SAS-GRID APRIL 2019 - This is no longer needed 2. targetschema- This is the target schema on the SQL server in which the SIAL components 
will be created.

3. idi_refresh - This is the IDI Clean refresh version that the SIAL views and tables need to be created from.
This is kept as IDI_Clean by default.

Feb 2019: SAS_GRID Update: IDI_Clean no longer exists 
There is now a macro variable to select the version of the IDI upon which to build the SIAL. 

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
To build the SIAL views, you will need to have select access to the  SIAL IDI tables listed in the document
SIAL_dependencies/IDI Tables required for construction of SIAL.docx

If you do not have access to the underlying tables, an error will be shown in the log created by this code, and a SIAL view will still be created, 
but you will get a "SELECT Permission not allowed" when you try to access the View.



NOTES: 
1. As more of the business QAs are finished the paths to the sas scripts will change. The
script main_sial will be updated to reflect the new paths.
2. You can ignore warnings of the type- "The quoted string currently being processed 
has become more than 262 characters long.  You might have unbalanced quotation marks".
These appear because the SAS code reads in SQL files which tend to be quite long. The code
will still run and create the SIAL components.

HISTORY: 
24 May 2017	v1.1	VB	Updated the main script with more comments and improved functionality
16 Mar 2017	v1
Mar 2019    		PNH Updated to work with SAS-GRID. brought all the automation processing into SAS, rather than SQL as there were 
directory permission issues that Stats have so far been unable to fix.
/*********************************************************************************************************/

/* Change the schema to your own schema*/
/* Change the path to match the location where you put the sial scripts */
%let idi_refresh=IDI_Clean_20190420; /* Example- IDI_Clean_20161010*/
%let schema=DL-MAA2016-15; /* Example, DL-MAA2016-XX*/
%let sial_code_path=/nas/DataLab/MAA/MAA2016-15 Supporting the Social Investment Unit/SIAL;

/* SAS-GRID Update. Feb 2019. Unix environment*/
/* feb 2019 - SAS-GRID requires username and password for ODBC connection. Ensure password is not stored in this code!!*/
/* march 2019 - SAS fixed this. No longer required*/
/* macro variables to hold the connect calls*/
%let sandpit_connect=connect to odbc(dsn=idi_sandpit_srvprd);
%let idi_usercode_connect=connect to odbc(dsn=idi_usercode_srvprd);
%let IDI_connect=connect to odbc(dsn=&idi_refresh._srvprd);
options source source2 nosymbolgen nomprint nomlogic;

/*options source source2 nosymbolgen mprint nomlogic;*/

/*******************************************************************************************************************************
START OF SCRIPT
/*******************************************************************************************************************************/

/* Set up the sand library to the target database/schema to which the SIAL physical tables are to be written to*/
/*SAS GRID - APRIl 2019 - no longer used%let targetschema=%tslit([&schema.]);*/
libname sand ODBC dsn=idi_sandpit_srvprd schema="&schema."; /*bulkload=yes bulkload does not appear to be an option under Unix SAS GRID*/;
libname SIALview ODBC dsn=idi_usercode_srvprd schema="&schema."; /*bulkload=yes bulkload does not appear to be an option under Unix SAS GRID*/;

/* Set up global variables for all the SIAL subdirectories*/
/* PNH: Feb:2019 - Updated for Uniz SAS-Grid Env / not \*/
%let dependfolder = &sial_code_path./SIAL_dependencies/;
%let logfolder = &sial_code_path./SIAL_logs/;
%let bqacfolder = &sial_code_path./SIAL_bqa_complete/;
%let bqaifolder = &sial_code_path./SIAL_bqa_incomplete/;
%let reffolder= &sial_code_path./SIAL_reference_files/;

%let SIAL_DEBUG=FALSE;

/* Read in the remaining libraries needed for the SIAL tables that run in SAS */
/*%include "&dependfolder.\libnames.sas";*/
/* Load macros */
options SASAUTOS=("SASEnvironment/SASMacro" '!SASROOT/sasautos' '/sasdata/code/datalabs/prod/sasautos');
options append=(sasautos=(%tslit(&dependfolder.sasautos/)));

/* Note: SHould be able to do this with sasautos option, but appears not to be working under SAS GRID!*/
/* Set up time stampe with no special characters */
%let time = %sysfunc(time(), time8.0);
%let time_hh = %scan(&time.,1, :);
%let time_mm = %scan(&time.,2, :);
%let time_ss = %scan(&time.,3, :);

/* Uninstall all SIAL procedures, tables and views first, if these already exist in target schema*/;
%include "&dependfolder.uninstall_sial.sas";

/* SAS-GRID has caused permissions issues with populating sql tables from the csv files, use sas infile statment instead as a work around*/
/* PNH- February 2019*/
%macro create_sql_from_csv(output_library,table_name, filetype, infile=);
	%if "&infile"="" %then
		%let infile=&table_name;

	%if %sysfunc(exist(&output_library..&table_name)) %then
		%do;
						proc sql;
							drop table &output_library..&table_name;
						quit;
		%end;

	proc import file="&reffolder./&infile..&filetype" 
		out=&output_library..&table_name;
		%if &filetype=txt %then
			%do;
				delimiter=";";
			%end;

		guessingrows=10000;
	run;

%mend;

%create_sql_from_csv(sand,inflation_index, csv);
%create_sql_from_csv(sand,moe_school_decile_pricing, csv);
%create_sql_from_csv(sand,moe_ter_fundingrates, csv,infile=moe_ter_pricing);
%create_sql_from_csv(sand,moh_b4sc_pricing, csv);
%create_sql_from_csv(sand,moh_primhd_pu_pricing, csv);
%create_sql_from_csv(sand,moh_pu_pricing, csv);
%create_sql_from_csv(sand,moj_offence_to_category_map, csv);
%create_sql_from_csv(sand,moj_offense_cat_pricing, csv);
%create_sql_from_csv(sand,cor_mmc_pricing, csv);
%create_sql_from_csv(sand,moe_itl_fund_rate, csv,infile=moe_itl_fund);

/* This creates all the SIAL related views in the database schema specified.*/
/* Under SAS-GRID this no longer works, something to do with the pathnames and file permissions*/
/* Waiting for Stats NZ to correct */
/* Have rewritted the SQL programs as SAS Pass throughs*/
/* this macro runs through the supplied directory and creates a %include statement for each .sas program found in the directory*/
/*PNH - March 2019- SAS Grid*/
/* creatae table to hold results*/
data work.sialexecresults;
	length logdate 8.;
	format logdate date9.;
	length sqlfilename $100;
	length resultcode $100;
	length resultoutput $200;
	length duration $20.;
run;

%macro drive(dir,ext);
	%local filrf rc rc2 did memcnt name i duration fname;

	/* Assigns a fileref to the directory and opens the directory*/
	%let rc=%sysfunc(filename(filrf,&dir));
	%let did=%sysfunc(dopen(&filrf));

	/* Make sure directory can be open*/
	%if &did eq 0 %then
		%do;
			%put Directory &dir cannot be opened or does not exist;

			%return;
		%end;

	/*Loops through the entire directory*/
	%do i = 1 %to %sysfunc(dnum(&did));
	
		/*%retrieve name of each file*/
		%let name=%qsysfunc(dread(&did,&i));
	
		/* checks to see if the extension matches the parameter value */
		/* If condition is true then print the name to the log*/
		%if %qupcase(%qscan(&name,-1,.))=%upcase(&ext) %then
			%do;
				%let log_pathname&i=%tslit(&logfolder.&name._saslog_&sysdate.&time_hh.&time_mm.&time_ss..txt);
				filename log&i &&log_pathname&i;
				%put running "&dir/&name";

				/* add duration check - Jun 2019*/
				%let _timer_start=%sysfunc(datetime());
				
				proc printto log=log&i new;
				run;

				
				%include "&dir/&name";

				proc printto;
				run;

				data _null_;
					dur=put(datetime()- &_timer_start, time13.2);
					call symput('duration', dur);
				run;

				%geterrors(logfile=log&i);

				proc sql;
					insert into work.sialexecresults select today(), "&name.", 'NA', logline, "&duration" from errors;
				quit;

				/* delete the individual log files*/
				%if &SIAL_DEBUG=FALSE %then %do;
				data _null_;
					fname="tempfile";
					rc2=filename(fname,&&log_pathname&i);

					if rc2=0 and fexist(fname) then
						rc2=fdelete(fname);
					rc2=filename(fname);
				run;
				%end;

			%end;
	%end;

	/* closes the directory and clean the fileref*/
	%let rc=%sysfunc(dclose(&did));
	%let rc=%sysfunc(filename(filrf));
%mend drive;


%drive(&bqacfolder.,sas);
%drive(&bqaifolder.,sas);

/* export the log file for permanent record */
proc export data=work.sialexecresults file="&logfolder./SIAL_execresults_&sysdate.&time_hh.&time_mm.&time_ss..xlsx"
	dbms=xlsx replace;
run;

/*******************************************************************************************************************************
At this point, you will find a list of SIAL related views in your schema. Navigate to
IDI_Usercode -> <schemaname or libname> -> Views, and you should be able to find all
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
/*******************************************************************************************************************************/

/*******************************************************************************************************************************
At this point, you will find a list of SIAL related tables in your schema. Navigate to
IDI_Sandpit -> <schemaname or libname> -> Tables, and you should be able to find all
the created SIAL Tables.

As of SIAL Release v1.1, the tables are-
SIAL_MOE_school_events
SIAL_MSD_T1_events

NOTE: SIAL v1.2 : there are views in IDI_USercode that reference these tables

/*******************************************************************************************************************************/