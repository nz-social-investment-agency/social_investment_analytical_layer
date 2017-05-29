/*********************************************************************************************************
TITLE: MOE_ece_events

DESCRIPTION: Create ECE event table in SIAL format.
This table gives the ECE type and the hours spent in ECE by each child enrolling for the programme.
Event_type gives the ECE type that the child attended. In case of students who did not enroll for ECE, 
the hours spent would be null or 0 and the ECE event_type_2 would be 'False'. Cases with no information 
available are listed with a status of 'Unknown'. Event_type_3 would give the number of hours spent in a
particular kind of ECE.
					
The costs for the event is not available at the moment.

INPUT: IDI_Sandpit.[clean_read_MOE].[ECEStudentParticipation2015]
IDI_Clean.moe_clean.nsi
IDI_Sandpit.[clean_read_MOH_B4SC].[moh_B4SC_2015_ECE_IND]


OUTPUT: {schemaname}.SIAL_MOE_ECE_events

DEPENDENCIES: 
NA

NOTES: 
See SIAL data dictionary for business rules applied

AUTHOR: V Benny

DATE: OCT 2016

HISTORY: 
*********************************************************************************************************/

create view {schemaname}.[SIAL_MOE_ece_events] as (
	select 
	snz_uid, 
	'MOE' as department,
	'ECE' as datamart,
	'ENR' as subject_area,
	cast([start_date] as datetime) as [start_date],
	cast(end_date as datetime) as end_date,
	ece_status as event_type,
	ECEClassificationID as event_type_2
	from (
			select 
				coalesce(a.snz_uid, b.snz_uid) as snz_uid, 
				a.ECEClassificationID, 
				a.ECEDurationID,
				/* count number of months backwards from end date of ECE based on the DurationID code to get start date */
				dateadd(m, case a.ECEDurationID when 61052 then -6  /* attended last 6 months*/
					when 61053 then -12  /* attended last 1 year*/
					when 61054 then -24	 /* attended last 2 years*/
					when 61055 then -36  /* attended last 3 years*/
					when 61056 then -48  /* attended last 4 years*/
					when 61057 then -60  /* attended last 5 years*/			
					when 61058 then 0    /* did not attend regularly*/	
					else NULL end,		 
					cast(cast(person.snz_birth_year_nbr + 5 as varchar(4)) + '-' + right('0' + cast(person.snz_birth_month_nbr as varchar(2)), 2) + '-15' as date)) as [start_date],
				/* 5th birthday assumed as end date for ECE*/	
				cast(cast(person.snz_birth_year_nbr + 5 as varchar(4)) + '-' + right('0' + cast(person.snz_birth_month_nbr as varchar(2)), 2) + '-15' as date) as [end_date], 	
				/* Derive ECE attend status based on information from ECE and B4SC datasets*/
				case when a.ECEClassificationID = 20630 then 'False' /* Child did not attend ECE*/
					when a.ECEClassificationID = 20637 or a.ECEClassificationID is null then /* If ECE status is unknown, check for B4SC status*/
						case when b.probablyattendpreschool is null or b.probablyattendpreschool='' then 'Unknown' /* If B4SC status is also unknown, keep status as unknown*/
							else b.probablyattendpreschool end /* Use B4SC status as ECE status if this value is defined */
					else 'True' end as ece_status, /* Child attended ECE based on data from ECE*/
				a.ECEHours
			from 
			(select id.snz_uid, ecepart.ECEClassificationID, ecepart.ECEDurationID, ecepart.ECEHours
				from IDI_Sandpit.[clean_read_MOE].[ECEStudentParticipation2015] ecepart
				inner join (select distinct snz_moe_uid, snz_uid from IDI_Clean.moe_clean.nsi) id 
					on (ecepart.snz_moe_uid = id.snz_moe_uid)
				group by id.snz_uid, ecepart.ECEClassificationID, ecepart.ECEDurationID, ecepart.ECEHours) a
			full outer join 
			(select id.snz_uid, b4sc_att.probablyattendpreschool from IDI_Sandpit.[clean_read_MOH_B4SC].[moh_B4SC_2015_ECE_IND] b4sc_att
				inner join IDI_Clean.moh_clean.pop_cohort_demographics id 
					on (b4sc_att.snz_moh_uid = id.snz_moh_uid)
				where b4sc_att.probablyattendpreschool is not null
				and b4sc_att.probablyattendpreschool <> '' )b
			on (a.snz_uid=b.snz_uid)
			left join IDI_Clean.[data].[personal_detail] person on (coalesce(a.snz_uid, b.snz_uid) = person.snz_uid)
	)inner_query
	where ece_status <> 'False' /*individuals who did not attend ECE are removed from the output*/
);


