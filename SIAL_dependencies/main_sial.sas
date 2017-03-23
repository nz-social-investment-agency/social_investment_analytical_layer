/*********************************************************************************************************
TITLE: main_sial.sas

DESCRIPTION: 
This scripts installs all SIAl components in the
target database schema provided by the user.

INPUT:
sial_code_path - this is the full path to
the sial folder. Change this to reflect
the location where you stored the folder

targetschema- this is the schema on the SQL server to which the 
SIAL components need to be created in.

OUTPUT:
SIAL components and logs

AUTHOR: E Walsh, V Benny

DATE: 16 March 2017

DEPENDENCIES: 
NA

NOTES: 
As more of the business QAs are finished
the paths to the sas scripts will change. The
script main_sial will be updated to reflect the
new paths. 

HISTORY: 
16 March 2017  v1
*********************************************************************************************************/

/* Change the schema to your own schema*/
/* Change the path to match the location where you put the sial scripts */
%let targetschema=DL-MA20XX-XX;
%let sial_code_path = \\wprdfs08\<project_name>\social_investment_analytical_layer;



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

/* Read in the remaining libraries needed for the SIAL tables that run in SAS */
%include "&dependfolder.\libnames.sas";

/* Load macros */
%include "&dependfolder.macro_geterrors.sas";
%include "&dependfolder.macro_AdultSpellsonYouthWorkingAgeBenefits.sas";

/* Read in the SQL scripts to be executed*/
filename file0 %tslit(&dependfolder.uninstall_sial_tables_views.sql);
filename file1 %tslit(&dependfolder.load_pricing_tables_to_sandpit.sql);
filename file2 %tslit(&dependfolder.create_sial_views.sql);

/* set up time stampe with no special characters */
%let time = %sysfunc(time(), time8.0);
%let time_hh = %scan(&time.,1, :);
%let time_mm = %scan(&time.,2, :);
%let time_ss = %scan(&time.,3, :);

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


proc sql;
	connect to odbc(dsn=idi_sandpit_srvprd);
	
	/* Unisnstall SIAL tables and views first*/	
	execute(&sialuninst.) by odbc;

	/* Set up the stored procs in SQL*/
	execute(&sialpricetabs.) by odbc;
	execute(&sialviewsql.) by odbc;

	/* Run all the SIAL dependency pricing tables*/	
	execute( exec [sp_loadPricingtables] @targetschemaname=&targetschema, @sourceFolder= %tslit(&dependfolder.) ) by odbc;	

	/* Run all the SIAL views in the bqac folder*/	
	execute( exec [sp_createSIALViews] @targetschemaname=&targetschema, @sourceFolder= %tslit(&bqacfolder.) ) by odbc;

	/* Run all the SIAL views in the bqai folder*/	
	execute( exec [sp_createSIALViews] @targetschemaname=&targetschema, @sourceFolder= %tslit(&bqaifolder.) ) by odbc;	
	
	/* Drop the SIAL stored procedures from SQL*/
	execute (drop procedure [sp_loadPricingtables]) by odbc;
	execute (drop procedure [sp_createSIALViews]) by odbc;
	

	disconnect from odbc;
quit;

proc sql;
	connect to odbc(dsn=idi_sandpit_srvprd);
	create table work.sialexecresults as select * from connection to odbc(select * from sialexecresults);
	disconnect from odbc;
quit;



/* MOE primary and secondary enrolments */
filename log1 %tslit(&logfolder.MOE_school_events_saslog_&sysdate.&time_hh.&time_mm.&time_ss..txt);
proc printto log=log1 new;run;
%include "&bqaifolder.MOE_school_events.sas";
proc printto;run;
%getErrors(logfile=log1);
proc sql;
	insert into work.sialexecresults select today(), 'MOE_school_events.sas', 'NA', logline from errors;
quit;


/* MOE tertiary events  */
filename log2 %tslit(&logfolder.MOE_tertiary_events_saslog_&sysdate.&time_hh.&time_mm.&time_ss..txt);
proc printto log=log2 new;run;
%include "&bqaifolder.MOE_tertiary_events.sas";
proc printto;run;
%getErrors(logfile=log2);
proc sql;
	insert into work.sialexecresults select today(), 'MOE_tertiary_events.sas', 'NA', logline from errors;
quit;


/* MSD tier 1 main benefits */
filename log3 %tslit(&logfolder.MSD_T1_events_saslog_&sysdate.&time_hh.&time_mm.&time_ss..txt);
proc printto log=log3 new;run;

%include "&bqacfolder.MSD_T1_events.sas";
%getErrors(logfile=log3);
proc printto;run;
proc sql;
	insert into work.sialexecresults select today(), 'MSD_T1_events.sas', 'NA', logline from errors;
quit;
