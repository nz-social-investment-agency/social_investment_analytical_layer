/*********************************************************************************************************
TITLE: moe_ter_edu_event.sas

DESCRIPTION: create the event table for tertiary 
education spells and costs excluding Industry 
Training

INPUT:
moe.enrolment

OUTPUT:
sand.SIAL_MOE_tertiary_events 

AUTHOR: A Merval

DATE: 17 Oct 2016

DEPENDENCIES: moe_ter_fundingrates table must exist

NOTES: This version produces one line per qualification 
enrolment; students may be engaged in several enrolments
over a given period of time. A roll up of duration may 
not give the right value in these cases. The focus of 
this table is on the computation of costs. As such, 
only qualifications with govt funding are shown.	

HISTORY: 

*********************************************************************************************************/

/* set time window of interest */
%let yearstart = 2000;
%let yearend = 9999;

proc format;
	value $subsector
		"1","3"="Universities"
		"2"="Polytechnics"
		"4"="Wananga"
		"5","6"="Private Training Establishments";
run;

proc sql;
	create table _step1 as

	select distinct 
		snz_uid
		,moe_enr_year_nbr as cal_year
		,moe_enr_prog_start_date
		,moe_enr_qual_code as qual_code
		,moe_enr_prog_end_date
		,moe_enr_efts_consumed_nbr as EFTS_consumed
		,put(moe_enr_subsector_code,$subsector.) as subsector 
		,moe_enr_provider_code
		,moe_enr_funding_srce_code

	from moe.enrolment 
	where &yearstart. <= cal_year <= &yearend.  
	;
quit;

/* Some formatting and data cleansing */
data step1 (drop=moe_enr_prog_start_date moe_enr_prog_end_date
			moe_enr_funding_srce_code fund_source);
	set _step1 ;
	format start_date end_date yymmdd10. 
			moe_enr_funding_srce_code 8.;

	start_date = input(moe_enr_prog_start_date, yymmdd10.) ;
	end_date = input(moe_enr_prog_end_date, yymmdd10.) ;

	fund_source = input(moe_enr_funding_srce_code,8.) ;

	/* Keep only funding source = '01' or '1' as this is
		the govt funded student component. */
	if fund_source = 1;
	if EFTS_consumed > 0;

run;


proc sql;
	create table ter_enrol as select 
		a.*,
		b.ter_fund_rates,
		a.efts_consumed*b.ter_fund_rates as ter_cost
	from step1 as a left join SAND.moe_ter_fundingrates as b 
		on a.cal_year=b.year and a.subsector=b.subsector
	order by snz_uid, qual_code, start_date, cal_year;
quit ;


/* Event table showing spells: collation of multiple years into
	one spell; costs are added */
proc summary data=ter_enrol nway;
	class snz_uid subsector qual_code moe_enr_provider_code start_date end_date;
	var ter_cost;
	output out=step3(drop=_type_ _freq_ 
					rename=(moe_enr_provider_code=provider)) 
			sum=;
run;

proc sql ;
	drop table sand.SIAL_MOE_tertiary_events ;
quit;

data sand.SIAL_MOE_tertiary_events ;
	length snz_uid 8. department datamart subject_area $3.
		event_type event_type_2 event_type_3 $7.
		cost revenue 8.;
	format start_date end_date yymmdd10. ;
	label 	event_type="Tertiary: Subsector"
			event_type_2="Tertiary: Provider code";
			event_type_3="Tertiary: Qual. code";

	set step3 (rename=(ter_cost = cost
			start_date = __start end_date = __end) ) ;
	keep snz_uid department datamart subject_area 
		start_date end_date event_type: cost revenue;

	department ='MOE';
	datamart ='ENR';
	subject_area ='TER';
	
	event_type = subsector ;
	event_type_2 = provider;
	event_type_3 = qual_code;

	start_date = __start ;
	end_date = __end ;

	revenue = 0;

run;

