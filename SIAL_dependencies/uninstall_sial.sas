/*********************************************************************************************************
TITLE: uninstall_sial.sas

DESCRIPTION: 
This scripts uninstalls all SIAL components in the
target database schema provided by the user.

INPUT:
sial_code_path - this is the full path to
the sial folder. Change this to reflect
the location where you stored the SIAL folder

targetschema- this is the schema on the SQL server to which the 
SIAL components need to be removed from.

OUTPUT:
NA

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

%let targetschema=DL-MA20XX-XX;
%let sial_code_path = \\wprdfs08\<project_name>\social_investment_analytical_layer;

/*******************************************************************************************************************************
START OF SCRIPT
*******************************************************************************************************************************/

/* Set up the sand library to the target database/schema to which the SIAL physical tables are to be written to*/
%let targetschema=%tslit([&targetschema.]);

/* Set up global variables for all the SIAL subdirectories*/
%let dependfolder = &sial_code_path.\SIAL_dependencies\;

/* Read in the SQL scripts to be executed*/
filename file0 %tslit(&dependfolder.uninstall_sial_tables_views.sql);

data _null_;
	infile file0 recfm=f lrecl=32767 pad;
	input @1 sialuninst $32767.;
	sialuninst = tranwrd(sialuninst, "{schemaname}" , &targetschema.);
	call symputx('sialuninst', sialuninst);
run;

proc sql;
	connect to odbc(dsn=idi_sandpit_srvprd);
	
	/* Unisnstall SIAL tables, views, procedures*/	
	execute(&sialuninst.) by odbc;

quit;