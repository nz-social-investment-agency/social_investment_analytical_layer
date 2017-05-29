/******************************************************************
 TITLE: load_pricing_tables_to_sandpit.sql

 DESCRIPTION: Bulk insert the csv pricing files into
 the IDI_Sandpit as tables

 INPUT: 
 @schema-the name of your schema e.g. [DL-MAA2016-15]
 @sourceFolder-the folder location where the csv files are kept 


 OUTPUT: 
 [IDI_Sandpit].[@schema].inflation_index
 [IDI_Sandpit].[@schema].moe_school_decile_pricing
 [IDI_Sandpit].[@schema].moe_ter_fundingrates
 [IDI_Sandpit].[@schema].moh_b4sc_pricing
 [IDI_Sandpit].[@schema].moh_primhd_pu_pricing
 [IDI_Sandpit].[@schema].moh_pu_pricing
 [IDI_Sandpit].[@schema].moj_offence_to_category_map
 [IDI_Sandpit].[@schema].moj_offense_cat_pricing
 [IDI_Sandpit].[@schema].cor_mmc_pricing


 DEPENDENCIES: 
 

 AUTHOR: 
 E Walsh

 CREATED: 
 20 Jan 2017

 HISTORY:
 24 May 2017	VB	Added inflation_index table, error handling.
 16 Mar 2017	VB	Converted into a stored proc and added extra tables
 20 Jan 2017	EW	v1

******************************************************************************/

create procedure sp_loadPricingtables
@targetschemaname varchar(25), 
@sourceFolder varchar(250) 
as 
begin 

	/* declare and initialise parameters */
	declare @schema varchar(25);
	declare @filepath_inf_idx varchar(250);
	declare @filepath_moe_enr varchar(250);
	declare @filepath_moe_ter varchar(250);
	declare @filepath_moh_b4s varchar(250);
	declare @filepath_moh_prm varchar(250);
	declare @filepath_moh_pfd_npa varchar(250);
	declare @filepath_moj_off varchar(250);
	declare @filepath_moj_off_pri varchar(250);
	declare @filepath_cor_mmc_pri varchar(250);
	declare @errorstat int = 0; 
	declare @errormessage nvarchar(max); 

	/* change these to your schema and location where you have the files saved */
	/* watch out for the primhd csv it has commas in the quoted text field that get treated as field separators use the txt file which uses semicolon separators */
	set @schema = @targetschemaname;
	set @filepath_inf_idx = @sourceFolder + 'inflation_index.csv';
	set @filepath_moe_enr = @sourceFolder + 'moe_school_decile_pricing.csv';
	set @filepath_moe_ter = @sourceFolder + 'moe_ter_pricing.csv';
	set @filepath_moh_b4s = @sourceFolder + 'moh_b4sc_pricing.csv';
	set @filepath_moh_prm = @sourceFolder + 'moh_primhd_pu_pricing.txt';
	set @filepath_moh_pfd_npa = @sourceFolder + 'moh_pu_pricing.csv';
	set @filepath_moj_off= @sourceFolder + 'moj_offence_to_category_map.csv';
	set @filepath_moj_off_pri = @sourceFolder + 'moj_offense_cat_pricing.csv';
	set @filepath_cor_mmc_pri = @sourceFolder + 'cor_mmc_pricing.csv';

	/*******************************************************
	Create an error capture table
	*******************************************************/
	declare @outputquery varchar(1000);
	set @outputquery = 'if object_id(''' + @targetschemaname + '.sialexecresults'') is null create table ' + @targetschemaname + '.sialexecresults(
	logdate datetime,
	sqlfilename nvarchar(100),
	resultcode nvarchar(100),
	resultoutput nvarchar(max))';

	execute(@outputquery);

	/*******************************/
	/* inflation index table  */
	/*******************************/

	declare @query_inf_idx nvarchar(2000);
	set @query_inf_idx='

	use IDI_Sandpit;

	/* create a shell for the data to go into */
	create table '+@schema+'.inflation_index
	([inflation_type] varchar(3) not null,
	 [quarter] varchar(6),
	 [value] float,
	 [start_date] date,
	 [end_date] date,
	 [base_quarter] integer not null
	 );


	/* pull all the data from the csv into the table */
	/* make sure the dates get read in the right way round */
	set dateformat dmy 


	bulk insert ' +@schema+'.inflation_index
	from ''' + @filepath_inf_idx + '''
	 with(
	datafiletype = ''char'',
	fieldterminator = '','',
	rowterminator = ''\n'',
	firstrow = 2)
	';

	/* check everything has been escaped properly */
	/*print @query_inf_idx;*/
	begin try
		exec sp_ExecuteSQL @query_inf_idx;
	end try
	begin catch
		set @errorstat = 1
		select @errormessage = 'Error: ' + cast(ERROR_NUMBER() as varchar(10)) +': ' + ERROR_MESSAGE()
	end catch
	/* Write the log into the results table */
	if (@errorstat=0)
		begin
			set @outputquery = 'insert into ' + @targetschemaname + '.sialexecresults values(current_timestamp, ''inflation_index.csv'', ''Execution succeeded'', ''No errors'')';
			execute(@outputquery);
		end
	else 
		begin
			set @outputquery = 'insert into ' + @targetschemaname + '.sialexecresults values(current_timestamp, ''inflation_index.csv'', ''Execution failed'', '''+ @errormessage + ''')';
				execute(@outputquery);		
			set @errorstat = 0;
		end

	/*******************************/
	/* moe pricing table  */
	/*******************************/

	declare @query_moe_enr nvarchar(2000);
	set @query_moe_enr='

	use IDI_Sandpit;

	/* create a shell for the data to go into */
	create table '+@schema+'.moe_school_decile_pricing
	([school_number] numeric(11),
	 [school_type_id] numeric(11),
	 academic_year float,
	 school_decile numeric(11),
	 cost float
	 );

	/* pull all the data from the csv into the table */
	/* make sure the dates get read in the right way round */
	set dateformat dmy 


	bulk insert ' +@schema+'.moe_school_decile_pricing
	from ''' + @filepath_moe_enr + '''
	 with(
	datafiletype = ''char'',
	fieldterminator = '','',
	rowterminator = ''\n'',
	firstrow = 2)
	';

	/* check everything has been escaped properly */
	/*print @query_moe_enr;*/
	begin try
		exec sp_ExecuteSQL @query_moe_enr;
	end try
	begin catch
		set @errorstat = 1
		select @errormessage = 'Error: ' + cast(ERROR_NUMBER() as varchar(10)) +': ' + ERROR_MESSAGE()
	end catch
	/* Write the log into the results table */
	if (@errorstat=0)
		begin
			set @outputquery = 'insert into ' + @targetschemaname + '.sialexecresults values(current_timestamp, ''moe_school_decile_pricing.csv'', ''Execution succeeded'', ''No errors'')';
			execute(@outputquery);
		end
	else 
		begin
			set @outputquery = 'insert into ' + @targetschemaname + '.sialexecresults values(current_timestamp, ''moe_school_decile_pricing.csv'', ''Execution failed'', '''+ @errormessage + ''')';
				execute(@outputquery);		
			set @errorstat = 0;
		end


	/*******************************/
	/* moe tertiary pricing table  */
	/*******************************/

	declare @query_moe_ter nvarchar(2000);
	set @query_moe_ter='

	use IDI_Sandpit;

	/* create a shell for the data to go into */
	create table '+@schema+'.moe_ter_fundingrates
	([year] numeric(4),
	 [cost_type] varchar(7),
	 [Subsector] varchar(31),
	 Ter_fund_rates float
	 );

	/* pull all the data from the csv into the table */
	/* make sure the dates get read in the right way round */
	set dateformat dmy 


	bulk insert ' +@schema+'.moe_ter_fundingrates
	from ''' + @filepath_moe_ter+ '''
	 with(
	datafiletype = ''char'',
	fieldterminator = '','',
	rowterminator = ''\n'',
	firstrow = 2)
	';

	/* check everything has been escaped properly */
	/*print @query_moe_ter;*/
	begin try
		exec sp_ExecuteSQL @query_moe_ter;
	end try
	begin catch
		set @errorstat = 1
		select @errormessage = 'Error: ' + cast(ERROR_NUMBER() as varchar(10)) +': ' + ERROR_MESSAGE()
	end catch
	/* Write the log into the results table */
	if (@errorstat=0)
		begin
			set @outputquery = 'insert into ' + @targetschemaname + '.sialexecresults values(current_timestamp, ''moe_ter_fundingrates.csv'', ''Execution succeeded'', ''No errors'')';
			execute(@outputquery);
		end
	else 
		begin
			set @outputquery = 'insert into ' + @targetschemaname + '.sialexecresults values(current_timestamp, ''moe_ter_fundingrates.csv'', ''Execution failed'', '''+ @errormessage + ''')';
				execute(@outputquery);		
			set @errorstat = 0;
		end

	/*****************************************/
	/* moh before school check pricing table */
	/*****************************************/

	declare @query_moh_b4s nvarchar(2000);
	set @query_moh_b4s='

	use IDI_Sandpit;

	/* create a shell for the data to go into */
	create table '+@schema+'.moh_b4sc_pricing
	([b4sc_code] varchar(10),
	 [b4sc_type] varchar(50),
	 [fin_year] varchar(7),
	 [b4sc_spend] numeric(38,2),
	 [start_date] date,
	 [end_date] date
	 );

	/* pull all the data from the csv into the table */
	/* make sure the dates get read in the right way round */
	set dateformat dmy 


	bulk insert ' +@schema+'.moh_b4sc_pricing
	from ''' + @filepath_moh_b4s + '''
	 with(
	datafiletype = ''char'',
	fieldterminator = '','',
	rowterminator = ''\n'',
	firstrow = 2)
	';

	/* check everything has been escaped properly */
	/*print @query_moh_b4s*/
	begin try
		exec sp_ExecuteSQL @query_moh_b4s;
	end try
	begin catch
		set @errorstat = 1
		select @errormessage = 'Error: ' + cast(ERROR_NUMBER() as varchar(10)) +': ' + ERROR_MESSAGE()
	end catch
	/* Write the log into the results table */
	if (@errorstat=0)
		begin
			set @outputquery = 'insert into ' + @targetschemaname + '.sialexecresults values(current_timestamp, ''moh_b4sc_pricing.csv'', ''Execution succeeded'', ''No errors'')';
			execute(@outputquery);
		end
	else 
		begin
			set @outputquery = 'insert into ' + @targetschemaname + '.sialexecresults values(current_timestamp, ''moh_b4sc_pricing.csv'', ''Execution failed'', '''+ @errormessage + ''')';
				execute(@outputquery);		
			set @errorstat = 0;
		end

	/*****************************************/
	/* moh primhd pricing table              */
	/*****************************************/


	declare @query_moh_prm nvarchar(2000);
	set @query_moh_prm='

	use IDI_Sandpit;

	/* create a shell for the data to go into */
	create table '+@schema+'.moh_primhd_pu_pricing
	([activity_setting_code] varchar(2),
	 [activity_setting_desc] varchar(36),
	 [activity_type_code] varchar(3),
	 [activity_type_desc] varchar(82),
	 [activity_unit_type] varchar(3),
	 [fin_year] varchar(7),
	 [type_weight] numeric(38,4),
	 [setting_weight] numeric(38,4),
	 [activity_price] numeric(38,4),
	 [start_date] date,
	 [end_date] date
	 );

	/* pull all the data from the csv into the table */
	/* make sure the dates get read in the right way round */
	set dateformat dmy 


	bulk insert ' +@schema+'.moh_primhd_pu_pricing
	from ''' + @filepath_moh_prm + '''
	 with(
	datafiletype = ''char'',
	fieldterminator = '';'',
	rowterminator = ''\n'',
	firstrow = 2)
	';

	/* check everything has been escaped properly */
	/*print @query_moh_b4s*/
	begin try
		exec sp_ExecuteSQL @query_moh_prm;
	end try
	begin catch
		set @errorstat = 1
		select @errormessage = 'Error: ' + cast(ERROR_NUMBER() as varchar(10)) +': ' + ERROR_MESSAGE()
	end catch
	/* Write the log into the results table */
	if (@errorstat=0)
		begin
			set @outputquery = 'insert into ' + @targetschemaname + '.sialexecresults values(current_timestamp, ''moh_primhd_pu_pricing.csv'', ''Execution succeeded'', ''No errors'')';
			execute(@outputquery);
		end
	else 
		begin
			set @outputquery = 'insert into ' + @targetschemaname + '.sialexecresults values(current_timestamp, ''moh_primhd_pu_pricing.csv'', ''Execution failed'', '''+ @errormessage + ''')';
				execute(@outputquery);		
			set @errorstat = 0;
		end


	/******************************************/
	/* moh purchase units used for publically */
	/* funded discharges, out patients and ED */
	/******************************************/
	declare @query_moh_pfd_npa nvarchar(2000);
	set @query_moh_pfd_npa='

	use IDI_Sandpit;

	/* create a shell for the data to go into */
	create table '+@schema+'.moh_pu_pricing
	([pu_code] varchar(20),
	 [fin_year] varchar(7),
	 [pu_price] numeric(38,2),
	 [start_date] date,
	 [end_date] date
	 );

	/* pull all the data from the csv into the table */
	/* make sure the dates get read in the right way round */
	set dateformat dmy 


	bulk insert ' +@schema+'.moh_pu_pricing
	from ''' +  @filepath_moh_pfd_npa + '''
	 with(
	datafiletype = ''char'',
	fieldterminator = '','',
	rowterminator = ''\n'',
	firstrow = 2)
	';

	/* check everything has been escaped properly */
	/*print @query_moh_pfd_npa*/
	begin try
		exec sp_ExecuteSQL @query_moh_pfd_npa;
	end try
	begin catch
		set @errorstat = 1
		select @errormessage = 'Error: ' + cast(ERROR_NUMBER() as varchar(10)) +': ' + ERROR_MESSAGE()
	end catch
	/* Write the log into the results table */
	if (@errorstat=0)
		begin
			set @outputquery = 'insert into ' + @targetschemaname + '.sialexecresults values(current_timestamp, ''moh_pu_pricing.csv'', ''Execution succeeded'', ''No errors'')';
			execute(@outputquery);
		end
	else 
		begin
			set @outputquery = 'insert into ' + @targetschemaname + '.sialexecresults values(current_timestamp, ''moh_pu_pricing.csv'', ''Execution failed'', '''+ @errormessage + ''')';
				execute(@outputquery);		
			set @errorstat = 0;
		end


	/******************************************/
	/* MOJ offence categories                 */
	/******************************************/
	declare @query_moj_off nvarchar(2000);
	set @query_moj_off='

	use IDI_Sandpit;

	/* create a shell for the data to go into */
	create table '+@schema+'.moj_offence_to_category_map
	([offence_code] varchar(7),
	 [offence_category] varchar(4)
	 );

	/* pull all the data from the csv into the table */
	/* make sure the dates get read in the right way round */
	set dateformat dmy 


	bulk insert ' +@schema+'.moj_offence_to_category_map
	from ''' +  @filepath_moj_off + '''
	 with(
	datafiletype = ''char'',
	fieldterminator = '','',
	rowterminator = ''\n'',
	firstrow = 2)
	';

	/* check everything has been escaped properly */
	/*print @query_moj_off*/
	begin try
		exec sp_ExecuteSQL @query_moj_off;
	end try
	begin catch
		set @errorstat = 1
		select @errormessage = 'Error: ' + cast(ERROR_NUMBER() as varchar(10)) +': ' + ERROR_MESSAGE()
	end catch
	/* Write the log into the results table */
	if (@errorstat=0)
		begin
			set @outputquery = 'insert into ' + @targetschemaname + '.sialexecresults values(current_timestamp, ''moj_offence_to_category_map.csv'', ''Execution succeeded'', ''No errors'')';
			execute(@outputquery);
		end
	else 
		begin
			set @outputquery = 'insert into ' + @targetschemaname + '.sialexecresults values(current_timestamp, ''moj_offence_to_category_map.csv'', ''Execution failed'', '''+ @errormessage + ''')';
				execute(@outputquery);		
			set @errorstat = 0;
		end

	/******************************************/
	/* MOJ offence category pricing           */
	/******************************************/

	declare @query_moj_off_pri nvarchar(2000);
	set @query_moj_off_pri='

	use IDI_Sandpit;

	/* create a shell for the data to go into */
	create table '+@schema+'.moj_offense_cat_pricing
	([offence_category] varchar(50),
	 [court_type] varchar(50),
	 [start_date] date,
	 [end_date] date,
	 [price] float
	 );

	/* pull all the data from the csv into the table */
	/* make sure the dates get read in the right way round */
	set dateformat dmy 


	bulk insert ' +@schema+'.moj_offense_cat_pricing
	from ''' +  @filepath_moj_off_pri + '''
	 with(
	datafiletype = ''char'',
	fieldterminator = '','',
	rowterminator = ''\n'',
	firstrow = 2)
	';

	/* check everything has been escaped properly */
	/*print @query_moj_off_pri*/
	begin try
		exec sp_ExecuteSQL @query_moj_off_pri;
	end try
	begin catch
		set @errorstat = 1
		select @errormessage = 'Error: ' + cast(ERROR_NUMBER() as varchar(10)) +': ' + ERROR_MESSAGE()
	end catch
	/* Write the log into the results table */
	if (@errorstat=0)
		begin
			set @outputquery = 'insert into ' + @targetschemaname + '.sialexecresults values(current_timestamp, ''moj_offense_cat_pricing.csv'', ''Execution succeeded'', ''No errors'')';
			execute(@outputquery);
		end
	else 
		begin
			set @outputquery = 'insert into ' + @targetschemaname + '.sialexecresults values(current_timestamp, ''moj_offense_cat_pricing.csv'', ''Execution failed'', '''+ @errormessage + ''')';
				execute(@outputquery);		
			set @errorstat = 0;
		end

	/******************************************/
	/* COR MMC pricing           */
	/******************************************/

	declare @query_cor_mmc_pri nvarchar(2000);
	set @query_cor_mmc_pri='

	use IDI_Sandpit;

	/* create a shell for the data to go into */
	create table '+@schema+'.cor_mmc_pricing
	([mmc_code] varchar(9),
	 [direct_cost] float,
	 [total_cost] float,
	 [start_date] date,
	 [end_date] date,
	 );

	/* pull all the data from the csv into the table */
	/* make sure the dates get read in the right way round */
	set dateformat dmy 


	bulk insert ' +@schema+'.cor_mmc_pricing
	from ''' +  @filepath_cor_mmc_pri + '''
	 with(
	datafiletype = ''char'',
	fieldterminator = '','',
	rowterminator = ''\n'',
	firstrow = 2)
	';

	/* check everything has been escaped properly */
	/*print @query_moj_off_pri*/
	begin try
		exec sp_ExecuteSQL @query_cor_mmc_pri;
	end try
	begin catch
		set @errorstat = 1
		select @errormessage = 'Error: ' + cast(ERROR_NUMBER() as varchar(10)) +': ' + ERROR_MESSAGE()
	end catch
	/* Write the log into the results table */
	if (@errorstat=0)
		begin
			set @outputquery = 'insert into ' + @targetschemaname + '.sialexecresults values(current_timestamp, ''cor_mmc_pricing.csv'', ''Execution succeeded'', ''No errors'')';
			execute(@outputquery);
		end
	else 
		begin
			set @outputquery = 'insert into ' + @targetschemaname + '.sialexecresults values(current_timestamp, ''cor_mmc_pricing.csv'', ''Execution failed'', '''+ @errormessage + ''')';
				execute(@outputquery);		
			set @errorstat = 0;
		end

end;