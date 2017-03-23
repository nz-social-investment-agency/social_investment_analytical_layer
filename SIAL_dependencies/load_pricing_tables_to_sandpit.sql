/****************************************************
 TITLE: load_pricing_tables_to_sandpit.sql

 DESCRIPTION: bulk insert the pricing tables into
 the sandpit

 INPUT: 
 @schema the name of your schema e.g. [DL-MAA2016-15]
 @filepath_moe_enr location of the moe school pricing csv
 @filepath_moe_ter location of the moe tertiary pricing csv
 @filepath_moh_b4s location of the before school check 
    pricing csv
 @filepath_moh_prm location of the primhd pricing csv
 @filepath_moh_pfd_npa location of the moh purchase
    unit csv
 @filepath_moj_off location of the offence category csv
 @filepath_moj_off_pri location of the offence category
    pricing table

 OUTPUT: 
 [IDI_Sandpit].[@schema].moe_school_decile_pricing
 [IDI_Sandpit].[@schema].moh_b4sc_pricing
 [IDI_Sandpit].[@schema].moh_primhd_pu_pricing
 [IDI_Sandpit].[@schema].moh_pu_pricing
 [IDI_Sandpit].[@schema].moj_offence_to_category_map
 [IDI_Sandpit].[@schema].moj_offense_cat_pricing


 DEPENDENCIES: 
 

 AUTHOR: 
 E Walsh

 CREATED: 
 20 Jan 2017

 HISTORY: 
 20 Jan 2017 EW v1

***************************************************/

create procedure sp_loadPricingtables
@targetschemaname varchar(25), 
@sourceFolder varchar(250) 
as 
begin 

/* declare and initialise parameters */
declare @schema varchar(25);
declare @filepath_moe_enr varchar(250);
declare @filepath_moe_ter varchar(250);
declare @filepath_moh_b4s varchar(250);
declare @filepath_moh_prm varchar(250);
declare @filepath_moh_pfd_npa varchar(250);
declare @filepath_moj_off varchar(250);
declare @filepath_moj_off_pri varchar(250);
declare @filepath_cor_mmc_pri varchar(250)

/* change these to your schema and location where you have the files saved */
/* watch out for the primhd csv it has commas in the quoted text field that get treated as field separators use the txt file which uses semicolon separators */
set @schema = @targetschemaname;
set @filepath_moe_enr = @sourceFolder + 'moe_school_decile_pricing.csv';
set @filepath_moe_ter = @sourceFolder + 'moe_ter_pricing.csv';
set @filepath_moh_b4s = @sourceFolder + 'moh_b4sc_pricing.csv';
set @filepath_moh_prm = @sourceFolder + 'moh_primhd_pu_pricing.txt';
set @filepath_moh_pfd_npa = @sourceFolder + 'moh_pu_pricing.csv';
set @filepath_moj_off= @sourceFolder + 'moj_offence_to_category_map.csv';
set @filepath_moj_off_pri = @sourceFolder + 'moj_offense_cat_pricing.csv';
set @filepath_cor_mmc_pri = @sourceFolder + 'cor_mmc_pricing.csv'

/*******************************/
/* first up moe pricing table  */
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
exec sp_ExecuteSQL @query_moe_enr;


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
exec sp_ExecuteSQL @query_moe_ter;

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
exec sp_ExecuteSQL @query_moh_b4s;

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
exec sp_ExecuteSQL @query_moh_prm;


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
exec sp_ExecuteSQL @query_moh_pfd_npa;


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
exec sp_ExecuteSQL @query_moj_off;

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
exec sp_ExecuteSQL @query_moj_off_pri;


/******************************************/
/* COR MMC pricing           */
/******************************************/

declare @query_cor_mmc_pri nvarchar(2000);
set @query_cor_mmc_pri='

use IDI_Sandpit;

/* create a shell for the data to go into */
create table '+@schema+'.cor_mmc_pricing
([mmc_code] varchar(8),
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
exec sp_ExecuteSQL @query_cor_mmc_pri;

end;