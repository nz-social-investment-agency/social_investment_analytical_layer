/*********************************************************************************************************
TITLE: IRD_income_events

DESCRIPTION: Create IRD income event table in SIAL format

INPUT: IDI_Clean.data.income_cal_yr

OUTPUT: {schemaname}.SIAL_IRD_income_events

DEPENDENCIES: 
NA

NOTES: 
See SIAL data dictionary for business rules applied

AUTHOR: V Benny

DATE: OCT 2016

HISTORY: 
*********************************************************************************************************/


create view {schemaname}.SIAL_IRD_income_events as (
select 
	snz_uid, 
	department, 
	datamart, 
	subject_area, 
	cast(start_date as datetime) as [start_date], 
	cast(end_date as datetime) as end_date,
	case when subject_area in ('C01','P01','S01', 'W&S', 'C02','P02', 'S02', 'WHP', 'C00', 'P00', 'S00', 'S03') 
		then amt
	else 0.00 end as revenue,
	case when subject_area in ('BEN', 'CLM', 'PEN', 'PPL', 'STU')
		then amt 
	else 0.00 end as cost
from (
	select snz_uid, 'IRD' as department, 'INC' as datamart,
	inc_cal_yr_income_source_code as subject_area, cast(cast(inc_cal_yr_year_nbr as varchar(4))+'-01-01' as date) as [start_date], 
	dateadd(d,-1, dateadd(mm, 1, cast(cast(inc_cal_yr_year_nbr as varchar(4))+'-01-01' as date))) as end_date,
	inc_cal_yr_mth_01_amt as amt
	from IDI_Clean.data.income_cal_yr
	union all
	select snz_uid, 'IRD' as department, 'INC' as datamart,
	inc_cal_yr_income_source_code as subject_area, cast(cast(inc_cal_yr_year_nbr as varchar(4))+'-02-01' as date) as [start_date], 
	dateadd(d,-1, dateadd(mm, 1, cast(cast(inc_cal_yr_year_nbr as varchar(4))+'-02-01' as date))) as end_date,
	inc_cal_yr_mth_02_amt as amt
	from IDI_Clean.data.income_cal_yr
	union all
	select snz_uid, 'IRD' as department, 'INC' as datamart,
	inc_cal_yr_income_source_code as subject_area, cast(cast(inc_cal_yr_year_nbr as varchar(4))+'-03-01' as date) as [start_date], 
	dateadd(d,-1, dateadd(mm, 1, cast(cast(inc_cal_yr_year_nbr as varchar(4))+'-03-01' as date))) as end_date,
	inc_cal_yr_mth_03_amt as amt
	from IDI_Clean.data.income_cal_yr
	union all
	select snz_uid,  'IRD' as department, 'INC' as datamart,
	inc_cal_yr_income_source_code as subject_area, cast(cast(inc_cal_yr_year_nbr as varchar(4))+'-04-01' as date) as [start_date], 
	dateadd(d,-1, dateadd(mm, 1, cast(cast(inc_cal_yr_year_nbr as varchar(4))+'-04-01' as date))) as end_date,
	inc_cal_yr_mth_04_amt as amt
	from IDI_Clean.data.income_cal_yr
	union all
	select snz_uid, 'IRD' as department, 'INC' as datamart,
	 inc_cal_yr_income_source_code as subject_area, cast(cast(inc_cal_yr_year_nbr as varchar(4))+'-05-01' as date) as [start_date], 
	dateadd(d,-1, dateadd(mm, 1, cast(cast(inc_cal_yr_year_nbr as varchar(4))+'-05-01' as date))) as end_date,
	inc_cal_yr_mth_05_amt as amt
	from IDI_Clean.data.income_cal_yr
	union all
	select snz_uid, 'IRD' as department, 'INC' as datamart,
	 inc_cal_yr_income_source_code as subject_area, cast(cast(inc_cal_yr_year_nbr as varchar(4))+'-06-01' as date) as [start_date], 
	dateadd(d,-1, dateadd(mm, 1, cast(cast(inc_cal_yr_year_nbr as varchar(4))+'-06-01' as date))) as end_date,
	inc_cal_yr_mth_06_amt as amt
	from IDI_Clean.data.income_cal_yr
	union all
	select snz_uid, 'IRD' as department, 'INC' as datamart,
	 inc_cal_yr_income_source_code as subject_area, cast(cast(inc_cal_yr_year_nbr as varchar(4))+'-07-01' as date) as [start_date], 
	dateadd(d,-1, dateadd(mm, 1, cast(cast(inc_cal_yr_year_nbr as varchar(4))+'-07-01' as date))) as end_date,
	inc_cal_yr_mth_07_amt as amt
	from IDI_Clean.data.income_cal_yr
	union all
	select snz_uid, 'IRD' as department, 'INC' as datamart,
	 inc_cal_yr_income_source_code as subject_area, cast(cast(inc_cal_yr_year_nbr as varchar(4))+'-08-01' as date) as [start_date], 
	dateadd(d,-1, dateadd(mm, 1, cast(cast(inc_cal_yr_year_nbr as varchar(4))+'-08-01' as date))) as end_date,
	inc_cal_yr_mth_08_amt as amt
	from IDI_Clean.data.income_cal_yr
	union all
	select snz_uid, 'IRD' as department, 'INC' as datamart,
	 inc_cal_yr_income_source_code as subject_area, cast(cast(inc_cal_yr_year_nbr as varchar(4))+'-09-01' as date) as [start_date], 
	dateadd(d,-1, dateadd(mm, 1, cast(cast(inc_cal_yr_year_nbr as varchar(4))+'-09-01' as date))) as end_date,
	inc_cal_yr_mth_09_amt as amt
	from IDI_Clean.data.income_cal_yr
	union all
	select snz_uid, 'IRD' as department, 'INC' as datamart,
	 inc_cal_yr_income_source_code as subject_area, cast(cast(inc_cal_yr_year_nbr as varchar(4))+'-10-01' as date) as [start_date], 
	dateadd(d,-1, dateadd(mm, 1, cast(cast(inc_cal_yr_year_nbr as varchar(4))+'-10-01' as date))) as end_date,
	inc_cal_yr_mth_10_amt as amt
	from IDI_Clean.data.income_cal_yr
	union all
	select snz_uid, 'IRD' as department, 'INC' as datamart,
	 inc_cal_yr_income_source_code as subject_area, cast(cast(inc_cal_yr_year_nbr as varchar(4))+'-11-01' as date) as [start_date], 
	dateadd(d,-1, dateadd(mm, 1, cast(cast(inc_cal_yr_year_nbr as varchar(4))+'-11-01' as date))) as end_date,
	inc_cal_yr_mth_11_amt as amt
	from IDI_Clean.data.income_cal_yr
	union all
	select snz_uid, 'IRD' as department, 'INC' as datamart,
	 inc_cal_yr_income_source_code as subject_area, cast(cast(inc_cal_yr_year_nbr as varchar(4))+'-12-01' as date) as [start_date], 
	dateadd(d,-1, dateadd(mm, 1, cast(cast(inc_cal_yr_year_nbr as varchar(4))+'-12-01' as date))) as end_date,
	inc_cal_yr_mth_12_amt as amt
	from IDI_Clean.data.income_cal_yr)x
);





