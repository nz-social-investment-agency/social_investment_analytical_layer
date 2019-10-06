/****************************************************
 TITLE: uninstall_sial_tables_views.sql

 DESCRIPTION: This script is used to uninstall SIAL tables and views in
 the specified schema. It deletes all the SIAL dependency 
 tables, and then deletes all the SQL views/tables under SIAL.

 OUTPUT:  

 DEPENDENCIES: NA

 NOTES:  Note that any object that starts with 'SIAL_XXX_<name>_events'
	will be deleted by this script.

 AUTHOR: V Benny

 CREATED: 10 Mar 2017

 HISTORY: 
 June 2019 - Views now stored in IDI_usercode schema
 24 Aug 2017 EW Added drop for itl fund
 24 May 2017 VB Made the drop table/view script 
				automatically search for SIAL components.
 10 Mar 2017 VB First version

 ISSUES: NA BOB

***************************************************/


use IDI_sandpit

/* Drop the SIAL meta-tables and procedures*/
if object_id('{schemaname}.sialexecresults') is not null  drop table {schemaname}.sialexecresults;
if object_id('sp_createSIALViews') is not null  drop procedure sp_createSIALViews;
if object_id('sp_loadPricingtables') is not null  drop procedure sp_loadPricingtables;

/* Drop the pricing support tables*/
if object_id('{schemaname}.moe_itl_fund_rate') is not null  drop table {schemaname}.moe_itl_fund_rate;
if object_id('{schemaname}.inflation_index') is not null  drop table {schemaname}.inflation_index;
if object_id('{schemaname}.moe_school_decile_pricing') is not null  drop table {schemaname}.moe_school_decile_pricing;
if object_id('{schemaname}.moe_ter_fundingrates') is not null  drop table {schemaname}.moe_ter_fundingrates;
if object_id('{schemaname}.moh_b4sc_pricing') is not null  drop table {schemaname}.moh_b4sc_pricing;
if object_id('{schemaname}.moh_primhd_pu_pricing') is not null  drop table {schemaname}.moh_primhd_pu_pricing;
if object_id('{schemaname}.moh_pu_pricing') is not null  drop table {schemaname}.moh_pu_pricing;
if object_id('{schemaname}.moj_offence_to_category_map') is not null  drop table {schemaname}.moj_offence_to_category_map;
if object_id('{schemaname}.moj_offense_cat_pricing') is not null  drop table {schemaname}.moj_offense_cat_pricing;
if object_id('{schemaname}.COR_MMC_PRICING') is not null  drop table {schemaname}.COR_MMC_PRICING;
if object_id('{schemaname}.SIAL_MSD_T1_events') is not null  drop table {schemaname}.SIAL_MSD_T1_events;


/*Drop any SIAL tables in IDI_sandpit*/;

use IDI_sandpit;

/* Variable to hold the name of the object to be dropped*/
declare @objectname nvarchar(max);
declare @sqlscript1 nvarchar(max);
declare @sqlscript2 nvarchar(max);

/* Cursor for holding the tables/views that need to be removed */
declare objectcursor cursor for

select 
	o.name 
from IDI_sandpit.sys.objects o
	inner join IDI_sandpit.sys.schemas s on (o.schema_id = s.schema_id )
where s.name = substring(substring('{schemaname}', 2, len('{schemaname}') -1), 1, len('{schemaname}') -2)  
	and o.name like 'SIAL[_]___[_]%[_]events'
order by o.name asc;

open objectcursor;
fetch next from objectcursor into @objectname

/* for each script, extract the sql query from the file and execute it */
while @@FETCH_STATUS = 0
begin

	/* Drop the SIAL tables*/
	select @sqlscript2 = 'if object_id(''{schemaname}.' + @objectname +''') is not null drop table {schemaname}.' + @objectname;
	execute sp_ExecuteSQL @sqlscript2;

	fetch next from objectcursor into @objectname
end;
close objectcursor;
deallocate objectcursor;


/* drop the SIAL views from IDI _usercode */
use IDI_usercode;

/* Cursor for holding the tables/views that need to be removed */
declare objectcursor cursor for

select 
	o.name 
from IDI_usercode.sys.objects o
	inner join IDI_usercode.sys.schemas s on (o.schema_id = s.schema_id )
where s.name = substring(substring('{schemaname}', 2, len('{schemaname}') -1), 1, len('{schemaname}') -2)  
	and o.name like 'SIAL[_]___[_]%[_]events'
order by o.name asc;

open objectcursor;
fetch next from objectcursor into @objectname

/* for each script, extract the sql query from the file and execute it */
while @@FETCH_STATUS = 0
begin

	/* Drop the SIAL views*/
	select @sqlscript1 = 'if object_id(''{schemaname}.' + @objectname +''') is not null drop view {schemaname}.' + @objectname;
	execute sp_ExecuteSQL @sqlscript1;
	
	fetch next from objectcursor into @objectname
end;
close objectcursor;
deallocate objectcursor;
