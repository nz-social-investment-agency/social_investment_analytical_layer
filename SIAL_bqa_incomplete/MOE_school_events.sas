/*********************************************************************************************************
TITLE: MOE_school_events.sas

DESCRIPTION: Create primary and secondary schooling 
spells and costs in SIAL format

INPUT:
moe.student_enrol
sandmoe.moe_school_decile_history
sand.moe_school_decile_pricing
data.personal_detail

OUTPUT:
sand.SIAL_MOE_school_events

AUTHOR: C Wright, C Maccormick and V Benny

DATE: 27 June 2016

DEPENDENCIES: moe_school_decile_pricing must exist

NOTES:
See SIAL data dictionary for business rules applied

HISTORY: 

*********************************************************************************************************/

%let decileStartYear = 2002; **This was originally hardcoded as 2000 but unsure why since
funding starts in 2002 (so have set to this instead);

data master_schooling;
	length snz_uid 8 department datamart subject_area $3 event_type $7;
	format edate sdate ddmmyy10.;
	set moe.student_enrol;
	department ='MOE';
	datamart ='ENR';
	subject_area ='ENR';

	event_type=moe_esi_provider_code;

	/*Exclude records with no start date*/
	where moe_esi_start_date ne '';

	sdate=input(moe_esi_start_date,yymmdd10.);
	edate=input(moe_esi_end_date,yymmdd10.);
	keep snz_uid snz_moe_uid edate sdate department datamart subject_area 
		event_type;
run;

proc sql;
	create table master_schooling_2 as
	select 
		a.*,
		mdy(b.snz_birth_month_nbr,15,b.snz_birth_year_nbr) as dob format=ddmmyy10.
	from 
		master_schooling as a 
	left join 
		data.personal_detail(keep=snz_uid snz_birth_month_nbr snz_birth_year_nbr) as b
	on a.snz_uid=b.snz_uid;
run;

/*Generate macro variable for max end date to 
use in imputation*/
proc sql;
	select max(edate) into:max_end
	from master_schooling_2;
quit;

/*%put Max end date is &max_end.;*/

data master_schooling_3;
	length event_type $7 start_date end_date 4;
	format year_end_date start_date end_date ddmmyy10.;
	set master_schooling_2;

	/*Age at which student started school*/
	start_age = floor((sdate - dob)/365.25);

	/*For spell end date use edate or if missing use 
		end of last school year*/
	if edate = . then
/*		end_date = year_end_date;*/
		end_date = &max_end.;	
	else end_date = edate;

	start_date = sdate;

	/*Years in spell*/
/*	years = floor((year_end_date - sdate)/365.25);*/
	years = floor((end_date - start_date)/365.25);

	/*There appears to be an error for some spells*/
	/*If school spell is greater than 14 years or student's
		age is not between 4 and 24 of error years at enrolment then
		assign an error indicator*/
	if years > 14 or not (4 <= start_age <= 24) then
		error_ind = 1;
	else error_ind = 0;

	drop edate sdate years start_age year_end_date dob snz_moe_uid;
run;

/*This data step creates a long 'by spell year' dataset*/
data master_schooling_4;
	length spell_year $7 start_date end_date 4;
	format start_date end_date ddmmyy10.;
	set master_schooling_3(rename=(start_date=sdate end_date=edate));

	do i = year(sdate) to year(edate);
		start_date=mdy(1,1,i);

		if i = year(sdate) then
			start_date = sdate;
		end_date=mdy(12,31,i);

		if i = year(edate) then
			end_date = edate;
		spell_year = put(i,4.0);
		output;
	end;

	drop edate sdate i;
run;

/*Link decile history for TFEA and other operational funding types*/
/*Deciles changed part way through the year in some cases*/
/*These changes affect very few student spells so are ignored as not being material*/

data decile;
	set sandmoe.moe_school_decile_history;
	where decilecode ne 99;
	sdate = input(decileStartDate,yymmdd10.);
	edate = input(decileEndDate,yymmdd10.);

	if year(edate) = 9999 then
/*		edate=mdy(12,31,2016);*/
		edate=mdy(12,31,year(&max_end.));

	provider = left(put(InstitutionNumber,6.0));

/*	do year = max(year(sdate), 2000) to year(edate);*/
	do year = max(year(sdate), &decileStartYear.) to year(edate);
		output;
	end;

	keep provider DecileCode year;
run;

proc sort data = decile nodupkey;
	by provider year decilecode;
run;

proc sort data = decile nodupkey;
	by provider year;
run;

/*Merge school decile history*/
proc sql;
	create table 
		master_schooling_5 as
	select 
		a.*,
		left(put(b.decilecode,2.0)) as event_type_2 length = 2
	from 
		master_schooling_4 as a 
	left join 
		decile as b
	on 
		a.event_type = b.provider and a.spell_year = put(b.year,4.0);
quit;

/*Merge costs by year and decile of school*/
proc sql;
	create table 
		master_schooling_6 as
	select 
		a.*,
		b.cost as fte_cost
	from 
		master_schooling_5 as a 
	left join 
		sand.moe_school_decile_pricing as b		
	on
		a.spell_year = left(put(academic_year,4.0)) and a.event_type_2 = left(put(school_number,6.0));
quit;

/*Calculate fraction of funding for part year*/
data master_moe_enr_enr;
	set master_schooling_6;
	year_start_date = mdy(2, 1, input(spell_year, 4.0));
	year_end_date = mdy(12, 20, input(spell_year, 4.0));
	prop_of_year = (1 + min(end_date, year_end_date) - max(start_date, year_start_date)) / (1 + year_end_date - year_start_date);
	cost = fte_cost * prop_of_year;
	drop fte_cost prop_of_year year_start_date year_end_date;
run;

/*Output to IDI sandpit*/
proc sql;
	drop table 
		sand.SIAL_MOE_school_events;		
	create table 
		sand.SIAL_MOE_school_events as
	select 
		snz_uid
		,department
		,datamart
		,subject_area
		,start_date
		,end_date
		,cost
		,event_type /*School number*/
		,event_type_2 /*Decile*/
	from 
		master_moe_enr_enr 
	where 
		error_ind ne 1;
quit;
