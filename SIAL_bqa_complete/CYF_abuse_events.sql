/**********************************************************************************************************
TITLE: CYF_abuse_events

DESCRIPTION: Reformat and recode CYF abuse data into SIAL format

INPUT: 
[IDI_Clean].[cyf_clean].[cyf_abuse_event]

OUTPUT: 
{schemaname}.SIAL_CYF_abuse_events

DEPENDENCIES: 
NA

NOTES: 
See SIAL data dictionary for business rules applied

AUTHOR: K Maxwell

CREATED: 22 Jul 2016

BUSINESS QA COMPLETE: October 2016

HISTORY: 
14 Oct 2016 EW pulled not found out of unknown category


*********************************************************************************************************/

create view {schemaname}.SIAL_CYF_abuse_events
as select distinct snz_uid,
			'MSD' as department,
			'CYF' as datamart,
			'ABE' as subject_area,			
			max(cast(cyf_abe_event_from_date_wid_date as datetime)) as [start_date],
			max(cast(cyf_abe_event_to_date_wid_date as datetime)) as end_date,
			/* event_type needs to stay as this variable with 3 digit codes as it is a dependency for the MIX_selfharm_events  SIAL table */
			max(case when cyf_abe_source_uk_var2_text in ('**OTHER**', 'UNK', 'XXX') then 'UNK' 
				when cyf_abe_source_uk_var2_text = 'BRD'  then 'BRD'
				when cyf_abe_source_uk_var2_text = 'EMO'  then 'EMO'
				when cyf_abe_source_uk_var2_text = 'NEG'  then 'NEG'
				when cyf_abe_source_uk_var2_text = 'PHY'  then 'PHY'
				when cyf_abe_source_uk_var2_text = 'SEX'  then 'SEX'
				/* addition of not found into a separate category as it means there is not enough evidence for a finding of abuse */
				when cyf_abe_source_uk_var2_text = 'NTF'  then 'NTF'
				when cyf_abe_source_uk_var2_text in ('SHM', 'SHS', 'SUC') then 'SHS'
				else 'Not coded' end) as event_type
		from [IDI_Clean].[cyf_clean].[cyf_abuse_event]
		where cyf_abe_event_type_wid_nbr = 12  /*This indicates an abuse finding */
		group by snz_uid, snz_composite_event_uid;
