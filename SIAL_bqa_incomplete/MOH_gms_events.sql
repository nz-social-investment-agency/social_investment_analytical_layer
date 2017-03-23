/*********************************************************************************************************
TITLE: MOH_gms_events

DESCRIPTION: Reformat and recode GMS data into SIAL format

INPUT: IDI_Clean.[moh_clean].[gms_claims]

OUTPUT: {schemaname}.SIAL_MOH_gms_events

DEPENDENCIES: 
NA

NOTES: 
See SIAL data dictionary for business rules applied

AUTHOR: V Benny

DATE: 22 July 2016

HISTORY: 
*********************************************************************************************************/



create view {schemaname}.SIAL_MOH_gms_events as 
	(select snz_uid,
			'MOH' as department,
			'GMS' as datamart,
			'GMS' as subject_area,	
			cast(moh_gms_visit_date as datetime) as [start_date],
			cast(moh_gms_visit_date as datetime) as [end_date],
			sum(moh_gms_amount_paid_amt) as cost,
			cast('GMS' as varchar(10)) as event_type
	from IDI_Clean.[moh_clean].[gms_claims]
	group by snz_uid, moh_gms_visit_date);

