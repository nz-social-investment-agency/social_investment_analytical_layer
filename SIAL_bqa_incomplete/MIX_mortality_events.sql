/*********************************************************************************************************
TITLE: MIX_mortality_events

DESCRIPTION: Standardised SIAL events table for the MOH and DIA based mortality dataset

INPUT: 
[IDI_Clean].[moh_clean].[mortality_registrations]
[IDI_Clean].[dia_clean].[deaths]

OUTPUT: 
{schemaname}.SIAL_MIX_mortality_events

DEPENDENCIES: 
NA

NOTES: 
See SIAL data dictionary for business rules applied

AUTHOR: 
E Walsh

CREATED: 
04 Oct 2016

HISTORY: 
18 May 2017 EW rewrote to handle new MOH tables
*********************************************************************************************************/

	create view {schemaname}.SIAL_MIX_mortality_events as (
	select snz_uid,
	department,
	datamart,
	subject_area,
	[start_date],
	[end_date],
	event_type, event_type_2, event_type_3
	from (
	select snz_uid,
	'MIX' as department,
	'MOR' as datamart,
	'MOR' as subject_area,
	cast(cast(moh_mor_death_year_nbr as varchar(4))+ '-' +
	cast(moh_mor_death_month_nbr as varchar(2))+'-01' as datetime) as [start_date],
	cast(cast(moh_mor_death_year_nbr as varchar(4))+ '-' +
	cast(moh_mor_death_month_nbr as varchar(2))+'-01' as datetime) as [end_date],
	moh_mor_icd_d_code as event_type,
	moh_mor_death_year_nbr-moh_mor_birth_year_nbr as event_type_2,
	'MOH' as event_type_3
	from [IDI_Clean].[moh_clean].[mortality_registrations]
	union all
	select [snz_uid],
	'MIX' as department,
	'MOR' as datamart,
	'MOR' as subject_area,
	cast(cast(dia_dth_death_year_nbr as varchar(4))+ '-' +
		cast(dia_dth_death_month_nbr as varchar(2))+'-01' as datetime) as [start_date],
	cast(cast(dia_dth_death_year_nbr as varchar(4))+ '-' +
		cast(dia_dth_death_month_nbr as varchar(2))+'-01' as datetime) as [end_date],
	null as event_type, null as event_type_2, 'DIA' as event_type_3
	from [IDI_Clean].[dia_clean].[deaths]
	where [dia_dth_death_year_nbr] > ( select max(moh_mor_death_year_nbr) from [IDI_Clean].[moh_clean].[mortality_registrations])
	)x
	) ;


