/*********************************************************************************************************
TITLE: IRD_income_events

DESCRIPTION: Create IRD income event table in SIAL format. The code fetches all known sources of taxable 
	income and deductions at the individual level, except for MSD T1 and T2 related benefits (which can be
	obtained from the respective SIAL tables). This table also has the income tax component and Student 
	loan related income, deductions and student allowances, pensions.

INPUT:  data.income_tax_yr
		ir_clean.ird_ems
		wff_clean.lvl_two_both_primary
		IDI_Clean.sla_clean.MSD_borrowing
		sla_clean.ird_amt_by_trn_type

OUTPUT: {schemaname}.SIAL_IRD_income_events

DEPENDENCIES: 
NA

NOTES: 
	1. See SIAL data dictionary for business rules applied.
	2. This is a very processing intensive piece of code, and takes around 5 minutes
		to start fetching rows.
	3. Keep in mind that this query retrieves a huge number of rows, in the order of
		billions. Judicious use of this query is strongly recommended.

AUTHOR: V Benny, adapted from Marc De Boer's SAS code for income dataset creation

HISTORY: 
08 Jul 2017	v2	Vinay Benny		Re-adapted based on Marc De Boer's SAS code for better detail
01 Oct 2016	v1	Vinay Benny		First version based on IDI_Clean.data.income_cal_yr
*********************************************************************************************************/

create view {schemaname}.SIAL_IRD_income_events as 
(
/* Income for individuals over each year from the income_tax_yr summary table*/
select 
	unpvt.snz_uid, 
	'IRD' as department, 
	case when inc_tax_yr_income_source_code in ('C00', 'P00', 'S00', 'C01','P01','S01', 'C02','P02', 'S02', 'PPL', 'WAS', 'WHP') then 'EMP' /*Employment income for individual*/
		when inc_tax_yr_income_source_code in ('BEN', 'CLM', 'PEN') then 'INS' /* Income Support benefits that individual receives from Govt. (excl. MSD T2 and T3)*/
		when inc_tax_yr_income_source_code = 'STU' then 'STS' /* Student support allowances*/
		when inc_tax_yr_income_source_code = 'S03' then 'RNT' /* Rental Income*/
		else 'UNK' end as datamart, /* If none of the above codes, then use Unknown*/
	inc_tax_yr_income_source_code as subject_area, 
	/* Start of month is calculated from the column name- if month is Jan, Feb or March, then the year should be the current year, else previous year (since tax-year ranges from April to March)*/
	cast(datefromparts( (case when cast(right(monthval, 2) as integer) > 3 then inc_tax_yr_year_nbr - 1 else inc_tax_yr_year_nbr end ), 
							cast(right(monthval, 2) as integer), 1) as datetime) as start_date, 
	cast(eomonth(datefromparts( (case when cast(right(monthval, 2) as integer) > 3 then inc_tax_yr_year_nbr - 1 else inc_tax_yr_year_nbr end ), 
							cast(right(monthval, 2) as integer), 1) ) as datetime) as end_date, /* End of month calculated from column name*/
	abs(unpvt.cost) as cost,
	'Net Income' as event_type
from
(
	select 
		snz_uid, 
		case when inc_tax_yr_income_source_code='W&S' then 'WAS' else inc_tax_yr_income_source_code end as inc_tax_yr_income_source_code, 
		inc_tax_yr_year_nbr, 
		/* In case of Sole trader income(IR3), Partnership income (IR20), Shareholder income(IR4S) and Rental income(IR3), divide it equally among all months of the financial year*/
		sum(case when inc_tax_yr_income_source_code in ('S00','P00','C00','S03') then inc_tax_yr_tot_yr_amt/12.0 else  coalesce(inc_tax_yr_mth_01_amt, 0.00) end) as mth_04,
		sum(case when inc_tax_yr_income_source_code in ('S00','P00','C00','S03') then inc_tax_yr_tot_yr_amt/12.0 else  coalesce(inc_tax_yr_mth_02_amt, 0.00) end) as mth_05,
		sum(case when inc_tax_yr_income_source_code in ('S00','P00','C00','S03') then inc_tax_yr_tot_yr_amt/12.0 else  coalesce(inc_tax_yr_mth_03_amt, 0.00) end) as mth_06,
		sum(case when inc_tax_yr_income_source_code in ('S00','P00','C00','S03') then inc_tax_yr_tot_yr_amt/12.0 else  coalesce(inc_tax_yr_mth_04_amt, 0.00) end) as mth_07,
		sum(case when inc_tax_yr_income_source_code in ('S00','P00','C00','S03') then inc_tax_yr_tot_yr_amt/12.0 else  coalesce(inc_tax_yr_mth_05_amt, 0.00) end) as mth_08,
		sum(case when inc_tax_yr_income_source_code in ('S00','P00','C00','S03') then inc_tax_yr_tot_yr_amt/12.0 else  coalesce(inc_tax_yr_mth_06_amt, 0.00) end) as mth_09,
		sum(case when inc_tax_yr_income_source_code in ('S00','P00','C00','S03') then inc_tax_yr_tot_yr_amt/12.0 else  coalesce(inc_tax_yr_mth_07_amt, 0.00) end) as mth_10,
		sum(case when inc_tax_yr_income_source_code in ('S00','P00','C00','S03') then inc_tax_yr_tot_yr_amt/12.0 else  coalesce(inc_tax_yr_mth_08_amt, 0.00) end) as mth_11,
		sum(case when inc_tax_yr_income_source_code in ('S00','P00','C00','S03') then inc_tax_yr_tot_yr_amt/12.0 else  coalesce(inc_tax_yr_mth_09_amt, 0.00) end) as mth_12,
		sum(case when inc_tax_yr_income_source_code in ('S00','P00','C00','S03') then inc_tax_yr_tot_yr_amt/12.0 else  coalesce(inc_tax_yr_mth_10_amt, 0.00) end) as mth_01,
		sum(case when inc_tax_yr_income_source_code in ('S00','P00','C00','S03') then inc_tax_yr_tot_yr_amt/12.0 else  coalesce(inc_tax_yr_mth_11_amt, 0.00) end) as mth_02,
		sum(case when inc_tax_yr_income_source_code in ('S00','P00','C00','S03') then inc_tax_yr_tot_yr_amt/12.0 else  coalesce(inc_tax_yr_mth_12_amt, 0.00) end) as mth_03
	from IDI_Clean.data.income_tax_yr 
	group by snz_uid, inc_tax_yr_income_source_code, inc_tax_yr_year_nbr
) pvt
unpivot
(cost for monthval in (mth_04,mth_05,mth_06, mth_07,mth_08,mth_09,mth_10,mth_11,mth_12, mth_01,mth_02,mth_03)
) as unpvt

union all

/* Monthly deductions from income (as Income tax and student loan deductions) as part of Income tax and student loans, from the ird_ems table.
	Note that the amounts are in negative values */
select
	snz_uid,
	'IRD' as department, 
	case ir_ems_withholding_type_code when 'P' then 'PYE' else 'WHT' end as datamart, /*PYE is for PAYE deductions and WHT is withheld deductions*/
	case when ir_ems_income_source_code = 'W&S' then 'WAS' else ir_ems_income_source_code end as subject_area,		
	cast(datefromparts(year(ir_ems_return_period_date), month(ir_ems_return_period_date), 1) as datetime) as start_date,
	cast(eomonth(datefromparts(year(ir_ems_return_period_date), month(ir_ems_return_period_date), 1)) as datetime) as end_date,
	sum(ir_ems_paye_deductions_amt) as cost,	
	'Income Tax' as event_type
from IDI_Clean.ir_clean.ird_ems
where ir_ems_paye_deductions_amt is not null and ir_ems_paye_deductions_amt  <> 0
group by snz_uid, ir_ems_income_source_code, year(ir_ems_return_period_date), month(ir_ems_return_period_date), ir_ems_withholding_type_code
union all
select
	snz_uid,
	'IRD' as department, 
	'STL' as datamart, /* Student Loan*/
	'SLD' as subject_area, /* Student loan deduction*/
	cast(datefromparts(year(ir_ems_return_period_date), month(ir_ems_return_period_date), 1) as datetime) as start_date,
	cast(eomonth(datefromparts(year(ir_ems_return_period_date), month(ir_ems_return_period_date), 1)) as datetime) as end_date,
	sum(ir_ems_sl_amt) as cost,
	'Deduction' as event_type
from IDI_Clean.ir_clean.ird_ems
where ir_ems_sl_amt is not null 
	and ir_ems_sl_amt <> 0 
	and year(ir_ems_return_period_date) < 2012 /* Only fetch data until 2012, as the student loan deductions information from 2012 onwards come from sla_clean.ird_amt_by_trn_type table*/
group by snz_uid, year(ir_ems_return_period_date), month(ir_ems_return_period_date)


union all

/* Working for Families tax credits returned to the individual*/
select 
	snz_uid,
	'IRD' as department, 
	'INS' as datamart, /*WFF tax credits are Income support payments*/
	subject_area, 
	cast(month_sd as datetime) as start_date, 
	cast(eomonth(month_sd) as datetime) as end_date,
	sum(amount) as cost,
	'Net Income' as event_type
from (
	select 
		snz_uid,
		'FTCb' as subject_area, /* tax credits from benefits, given by MSD */
		datefromparts(year(wff_lbp_date), month(wff_lbp_date), 1) as month_sd,
		/* If there is a partner availing the tax credit, divide the amount equally between both partners*/
		case when partner_snz_uid is null then wff_lbp_msd_fam_tax_credit_amt else wff_lbp_msd_fam_tax_credit_amt/2.0 end as amount
	from IDI_Clean.wff_clean.lvl_two_both_primary
	where wff_lbp_msd_fam_tax_credit_amt > 0
	union all
	select 
		snz_uid,
		'FTCn' as subject_area, /* tax credits from non-benefit income, given by IRD*/
		datefromparts(year(wff_lbp_date), month(wff_lbp_date), 1) as month_sd,
		/* If there is a partner availing the tax credit, divide the amount equally between both partners*/
		case when partner_snz_uid is null then wff_lbp_ird_fam_tax_credit_amt else wff_lbp_ird_fam_tax_credit_amt/2.0 end as amount
	from IDI_Clean.wff_clean.lvl_two_both_primary
	where wff_lbp_ird_fam_tax_credit_amt > 0
	union all
	/* Tax credits for partners*/
	select 
		partner_snz_uid as snz_uid,
		'FTCb' as subject_area, /* tax credits from benefits, given by MSD */
		datefromparts(year(wff_lbp_date), month(wff_lbp_date), 1) as month_sd,
		wff_lbp_msd_fam_tax_credit_amt/2.0 as amount
	from IDI_Clean.wff_clean.lvl_two_both_primary
	where wff_lbp_msd_fam_tax_credit_amt > 0 and partner_snz_uid > 0
	union all
	select 
		partner_snz_uid as snz_uid,
		'FTCn' as subject_area, /* tax credits from non-benefit income, given by IRD*/
		datefromparts(year(wff_lbp_date), month(wff_lbp_date), 1) as month_sd,
		wff_lbp_ird_fam_tax_credit_amt/2.0 as amount
	from IDI_Clean.wff_clean.lvl_two_both_primary
	where wff_lbp_ird_fam_tax_credit_amt > 0 and partner_snz_uid > 0
)x
group by snz_uid, subject_area, month_sd


union all

/* Student Loans data- use only until 01 January 2012 becuase monthly data is available from this point onwards in the ird_amt_by_trn_type table */
select
	snz_uid,
	'IRD' as department,
	'STL' as datamart,
	'SLA' as subject_area, /* Student Loan lending*/
    cast(msd_sla_sl_study_start_date as datetime) as start_date,
    cast(msd_sla_sl_study_end_date as datetime) as end_date,
	msd_sla_ann_drawn_course_rel_amt as cost,	
	'Advance' as event_type
from IDI_Clean.sla_clean.MSD_borrowing
where msd_sla_ann_drawn_course_rel_amt <> 0 
	and msd_sla_ann_drawn_course_rel_amt is not null
	and msd_sla_year_nbr < 2012
union all
select
	snz_uid,
	'IRD' as department,
	'STL' as datamart,
	'SLA' as subject_area, /* Student Loan lending*/
    msd_sla_sl_study_start_date as start_date,
    msd_sla_sl_study_end_date as end_date,
	msd_sla_ann_drawn_living_cost_amt as cost,
	'Advance' as event_type
from IDI_Clean.sla_clean.MSD_borrowing 
where msd_sla_ann_drawn_living_cost_amt <> 0 
	and msd_sla_ann_drawn_living_cost_amt is not null
	and msd_sla_year_nbr < 2012
union all
select
	snz_uid,
	'IRD' as department,
	'STL' as datamart,
	'SLF' as subject_area, /* Student Loan Deductions- fees penalties*/
    msd_sla_sl_study_start_date as start_date,
    msd_sla_sl_study_end_date as end_date,
	coalesce(msd_sla_ann_fee_refund_amt, 0.00) + coalesce(msd_sla_ann_admin_fee_amt, 0.00) as cost,
	'Deduction' as event_type
from IDI_Clean.sla_clean.MSD_borrowing 
where coalesce(msd_sla_ann_fee_refund_amt, 0.00) + coalesce(msd_sla_ann_admin_fee_amt, 0.00) <> 0
	and msd_sla_year_nbr < 2012
union all
select
	snz_uid,
	'IRD' as department,
	'STL' as datamart,
	'SLD' as subject_area, /* Student Loan deductions*/
    msd_sla_sl_study_start_date as start_date,
    msd_sla_sl_study_end_date as end_date,
	msd_sla_ann_repayment_amt as cost,
	'Deduction' as event_type
from IDI_Clean.sla_clean.MSD_borrowing 
where msd_sla_ann_repayment_amt <> 0 
	and msd_sla_ann_repayment_amt is not null
	and msd_sla_year_nbr < 2012

union all

/* Monthly Student Loan transactions. This data exists from 01 Jan 2012 to now.*/
select 
	snz_uid,
	'IRD' as department,
	'STL' as datamart,
	case when ir_att_trn_type_code = 'L' then 'SLA'  /* Student Loan lending*/
		when ir_att_trn_type_code in ('G', 'I', 'J', 'P', 'Q') then 'SLF' /* Student Loan Deductions- fees penalties*/
		when ir_att_trn_type_code in ('R', 'W') then 'SLD' /* Student Loan Deductions*/
		else ir_att_trn_type_code end as subject_area,
	cast(ir_att_trn_month_date as datetime) as start_date,
	cast(eomonth(ir_att_trn_month_date) as datetime) as end_date,
	ir_att_trn_type_amt  as cost,
	case when ir_att_trn_type_code = 'L' then 'SLA'
		when ir_att_trn_type_code in ('G', 'I', 'J', 'P', 'Q') then 'SLF'
		when ir_att_trn_type_code in ('R', 'W') then 'SLD' 
		else ir_att_trn_type_code end as event_type
from IDI_Clean.sla_clean.ird_amt_by_trn_type
);

