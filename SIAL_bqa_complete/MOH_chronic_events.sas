/*********************************************************************************************************
TITLE: MOH_chronic_events

DESCRIPTION: Create MOH chronic condition events table into SIAL format

INPUT: &idi_refresh..moh_clean.chronic_condition

OUTPUT: [&schema.].SIAL_MOH_chronic_events

DEPENDENCIES: 
NA

NOTES: 
See SIAL data dictionary for business rules applied

AUTHOR: E Walsh

DATE: 22 July 2016

HISTORY: 

v1	EW	First version
v2	WJ	Changed End Date to be either date of death Or when left NZ
PNH Aug 2019 Added a select statement to ensure the user has access to the underlying IDI tables. This will show up in the log

*********************************************************************************************************/

proc sql;
&idi_usercode_connect; 
execute(
create view [&schema.].SIAL_MOH_chronic_events as
select		main.snz_uid, 
			'MOH' as department,
			'TKR' as datamart, /* the tracker */
			'CCC' as subject_area, /* the chronic condition code */				
			cast(moh_chr_fir_incidnt_date as datetime) as [start_date], /*diagnoses are point in time events*/
			case when date_resi is not null 
					then cast(date_resi as datetime)
				when date_dead is not null 
					then cast(date_dead as datetime)
				else cast('9999-12-31' as datetime) 
			end as [end_date],/*end date taken from either dod or left nz*/
			moh_chr_condition_text as event_type,
			moh_chr_collection_text as event_type_2
			from &idi_refresh..moh_clean.chronic_condition main
	left join (	
		select distinct  [snz_uid],
			 cast([pos_applied_date] as datetime) as date_resi 
		from [&idi_refresh.].[data].[person_overseas_spell] where pos_last_departure_ind='y') resi
		on main.snz_uid=resi.snz_uid
	left join (
		select distinct	[snz_uid],
	convert(datetime,cast( [dia_dth_death_year_nbr] as varchar(4))+'-'+cast([dia_dth_death_month_nbr] as varchar(2))+'-'+cast(1 as varchar(2))) as date_dead
		from [&idi_refresh.].[dia_clean].[deaths] ) dead
		on main.snz_uid=dead.snz_uid
		;

	

	) by odbc;
	execute(select top 10 * from [&schema.].SIAL_MOH_chronic_events) by odbc;
	disconnect from odbc;
Quit;