/****************************************************
 TITLE: create_sial_views.sql

 DESCRIPTION: This script is used to install SIAL views in
 the specified schema. It creates all the SIAL dependency 
 tables, and then creates all the SQL views under SIAL.

 INPUT: @targetschemaname- the schema in which the SIAL
				components need to be created in.
		@sourceFolder-the source folder where the SIAL scripts
				are placed.

 OUTPUT:  SIAL tables

 DEPENDENCIES: NA

 NOTES:  

 AUTHOR: V Benny

 CREATED: 25 Jan 2017

 HISTORY: v1

 ISSUES: This script is susecptible to SQL injection 
		issues.

***************************************************/
create procedure sp_createSIALViews
/* User-defined variables */
@targetschemaname nvarchar(100), /*= '[DL-MAA2016-15]'*/
@sourceFolder nvarchar(250) /*= '\\wprdfs08\MAA2016-15 Supporting the Social Investment Unit\Vinay\scripts\sql\'*/
as 
begin 

/****************************************************
Script Start
*****************************************************/

/* Declare all variables*/
declare @fileContent nvarchar(max); 
declare @sqlscript nvarchar(max);
declare @varbinaryField varbinary(max) ;
declare @errorstat int = 0; 
declare @errormessage nvarchar(max); 
declare @sourceId int; 
declare @sourceSqlfilename nvarchar(512); 
declare @sourceDepth int; 
declare @sourceIsfile bit;
declare @outputquery varchar(1000); 

/* Create a temp table with list of files in the directory */
if object_id('tempdb..#directorytree') is not null drop table #directorytree;
create  table #directorytree(
	id int identity(1,1),
	subdirectory nvarchar(512),
	depth int,
	isfile bit);
insert #directorytree (subdirectory, depth, isfile) values('SIAL_bqa_complete\ACC_injury_events.sql', 1,1);
insert #directorytree (subdirectory, depth, isfile) values('SIAL_bqa_complete\CYF_abuse_events.sql', 1,1);
insert #directorytree (subdirectory, depth, isfile) values('SIAL_bqa_complete\CYF_client_events.sql', 1,1);
insert #directorytree (subdirectory, depth, isfile) values('SIAL_bqa_complete\MOJ_courtcase_events.sql', 1,1);
insert #directorytree (subdirectory, depth, isfile) values('SIAL_bqa_complete\MSD_T2_events.sql', 1,1);
insert #directorytree (subdirectory, depth, isfile) values('SIAL_bqa_complete\MSD_T3_events.sql', 1,1);
insert #directorytree (subdirectory, depth, isfile) values('SIAL_bqa_incomplete\COR_sentence_events.sql', 1,1);
insert #directorytree (subdirectory, depth, isfile) values('SIAL_bqa_incomplete\IRD_income_events.sql', 1,1);
insert #directorytree (subdirectory, depth, isfile) values('SIAL_bqa_incomplete\MIX_mortality_events.sql', 1,1);
insert #directorytree (subdirectory, depth, isfile) values('SIAL_bqa_incomplete\MIX_selfharm_events.sql', 1,1);
insert #directorytree (subdirectory, depth, isfile) values('SIAL_bqa_incomplete\MOE_intervention_events.sql', 1,1);
insert #directorytree (subdirectory, depth, isfile) values('SIAL_bqa_incomplete\MOH_B4School_events.sql', 1,1);
insert #directorytree (subdirectory, depth, isfile) values('SIAL_bqa_incomplete\MOH_cancer_events.sql', 1,1);
insert #directorytree (subdirectory, depth, isfile) values('SIAL_bqa_incomplete\MOH_chronic_events.sql', 1,1);
insert #directorytree (subdirectory, depth, isfile) values('SIAL_bqa_incomplete\MOH_gms_events.sql', 1,1);
insert #directorytree (subdirectory, depth, isfile) values('SIAL_bqa_incomplete\MOH_labtest_events.sql', 1,1);
insert #directorytree (subdirectory, depth, isfile) values('SIAL_bqa_incomplete\MOH_nir_events.sql', 1,1);
insert #directorytree (subdirectory, depth, isfile) values('SIAL_bqa_incomplete\MOH_nnpac_events.sql', 1,1);
insert #directorytree (subdirectory, depth, isfile) values('SIAL_bqa_incomplete\MOH_pfhd_events.sql', 1,1);
insert #directorytree (subdirectory, depth, isfile) values('SIAL_bqa_incomplete\MOH_pharm_events.sql', 1,1);
insert #directorytree (subdirectory, depth, isfile) values('SIAL_bqa_incomplete\MOH_primhd_events.sql', 1,1);
insert #directorytree (subdirectory, depth, isfile) values('SIAL_bqa_incomplete\POL_offender_events.sql', 1,1);
insert #directorytree (subdirectory, depth, isfile) values('SIAL_bqa_incomplete\POL_victim_events.sql', 1,1);
/*insert #directorytree (subdirectory, depth, isfile) exec master.sys.xp_dirtree @sourceFolder, 1, 1;*/

/* Create a temp table to hold the result log of running the scripts  */
if object_id('tempdb..#resultsummary') is not null drop table #resultsummary;
create table #resultsummary(
	logdate datetime,
	sqlfilename nvarchar(100),
	resultcode nvarchar(100),
	resultoutput nvarchar(max));

/* Cursor for holding the sql files that need to be executed */
declare scriptcursor cursor for
select * from #directorytree
where isfile=1 and right(subdirectory,4) = '.sql' and subdirectory <> 'makefile.sql'
order by subdirectory asc;

open scriptcursor;
fetch next from scriptcursor into @sourceId, @sourceSqlfilename, @sourceDepth, @sourceIsfile

/* for each script, extract the sql query from the file and execute it */
while @@FETCH_STATUS = 0
	begin

	/* Read text from file into variable */
	select @sqlscript = 'select @varbinaryField = BulkColumn from openrowset(bulk''' + @sourceFolder + @sourceSqlfilename + ''', single_blob) x';
	execute sp_ExecuteSQL @sqlscript, N'@varbinaryField varbinary(max) output ', @varbinaryField output;

	/* Replace the schema identifier in the script with the target schema into which the SIAL components need to be created */ 
	set @fileContent = convert(varchar(max), @varbinaryField);
	set @fileContent = replace(@fileContent, '{schemaname}', @targetschemaname);

	/* Execute the text of the file as SQL, and capture the log*/
	begin try
		execute sp_ExecuteSQL @fileContent;
	end try
	begin catch
		set @errorstat = 1
		select @errormessage = 'Error: ' + cast(ERROR_NUMBER() as varchar(10)) +': ' + ERROR_MESSAGE()
	end catch
	/* Write the log into the results table */
	if (@errorstat=0)
		begin
		insert into #resultsummary(logdate, sqlfilename, resultcode, resultoutput) values(current_timestamp, @sourceSqlfilename, 'Execution succeeded', 'No errors');
		end
	else 
		begin
		insert into #resultsummary(logdate, sqlfilename, resultcode, resultoutput) values(current_timestamp, @sourceSqlfilename, 'Execution failed', @errormessage);		
		set @errorstat = 0;
		end

	fetch next from scriptcursor into @sourceId,@sourceSqlfilename,@sourceDepth,@sourceIsfile
end;
close scriptcursor;
deallocate scriptcursor;

set @outputquery = 'if object_id(''' + @targetschemaname + '.sialexecresults'') is null create table ' + @targetschemaname + '.sialexecresults(
	logdate datetime,
	sqlfilename nvarchar(100),
	resultcode nvarchar(100),
	resultoutput nvarchar(max))';
execute(@outputquery);
set @outputquery = 'insert into ' + @targetschemaname + '.sialexecresults select logdate, sqlfilename, resultcode, resultoutput from #resultsummary';
execute(@outputquery);


end;
