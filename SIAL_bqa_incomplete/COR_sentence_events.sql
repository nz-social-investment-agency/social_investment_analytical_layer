/*********************************************************************************************************
TITLE: COR_sentence_events

DESCRIPTION: Reformat and recode corrections data into SIAL format

INPUT: [IDI_Clean].[cor_clean].[ov_major_mgmt_periods]

OUTPUT: {schemaname}.SIAL_COR_sentence_events

DEPENDENCIES: 
NA

NOTES: 

See SIAL data dictionary for business rules applied

AUTHOR: E Walsh

DATE: 20 Jan 2017

CHANGE HISTORY: 

*********************************************************************************************************/

create view {schemaname}.SIAL_COR_sentence_events as
select  distinct 
	a.[snz_uid]
	,'COR' as department
	, 'MMP' as datamart
	, 'SAR' as subject_area
	, cast(a.[cor_mmp_period_start_date] as datetime) as start_date 
	, cast(a.[cor_mmp_period_end_date] as datetime) as end_date
	,b.[direct_cost]*(DATEDIFF(DD, [cor_mmp_period_start_date], 
	case when [cor_mmp_period_end_date] = cast('9999-12-31' as date) 
		then (select max(cor_mmp_modified_date) from [IDI_Clean].[cor_clean].[ov_major_mgmt_periods]) 
		else [cor_mmp_period_end_date] end  )) as cost
	,(b.[total_cost]-b.[direct_cost])*(DATEDIFF(DD, [cor_mmp_period_start_date], 
	case when [cor_mmp_period_end_date] = cast('9999-12-31' as date) 
		then (select max(cor_mmp_modified_date) from [IDI_Clean].[cor_clean].[ov_major_mgmt_periods]) 
		else [cor_mmp_period_end_date] end  )) as cost_2		
	,codes.Group_code as event_type
	,a.[cor_mmp_mmc_code] as event_type_2
FROM [IDI_Clean].[cor_clean].[ov_major_mgmt_periods] a
inner join IDI_Metadata.clean_read_CLASSIFICATIONS.cor_ov_mmc_dim codes on (a.[cor_mmp_mmc_code]=codes.Code)
left join [IDI_Sandpit].{schemaname}.[cor_mmc_pricing] b
on a.cor_mmp_mmc_code = b.mmc_code
where [cor_mmp_mmc_code] IN ('PRISON','REMAND','HD_SENT','HD_REL','ESO','PAROLE','ROC','PDC',
'PERIODIC','COM_DET','CW', 'COM_PROG','COM_SERV','OTH_COM','INT_SUPER','SUPER')
;



