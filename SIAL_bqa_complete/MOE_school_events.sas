/*********************************************************************************************************
TITLE: MOE_school_events_SIAL.sas

DESCRIPTION: Create primary and secondary schooling spells and costs in SIAL format

AUTHOR: C Wright, C Maccormick and V Benny

DATE: 27 June 2016

DEPENDENCIES: moe_school_decile_pricing must exist

INPUT: moe.student_enrol, sandmoe.moe_school_decile_history, sand.moe_school_decile_pricing, data.personal_detail

OUTPUT: out_edu.MOE_school_events 			

NOTES:
See SIAL data dictionary for business rules applied

HISTORY: 
05 May 2017 Stephanie Thomson	Adapted SIAL code ("MOE_School_Events") to include business rules for overlapping 
								enrolment spells as per previous year MoJ code which was based on communication 
								with MoE in 2016. 
24 Apr 2017 EW updated max num years in school check to 15 based on MOE business QA
*********************************************************************************************************/


/*********************************************************************************************************
Section 0 - Library Set Up
*********************************************************************************************************/


libname sandmoe ODBC dsn=idi_sandpit_srvprd schema="clean_read_moe";


/*********************************************************************************************************
Section 1 - Original SIAL Code Commences
*********************************************************************************************************/
%let decileStartYear = 2002; /*The funding data starts in 2002 */
%let dbrefreshversion = &idi_refresh; /* Should be the source DB name, like IDI_Clean or IDI_Clean_20161020*/


/* Re-written to perform joins on SQL server using explicit passthrough*/
proc sql;
	connect to odbc(dsn=idi_sandpit_srvprd);

	create table master_schooling as
		select snz_uid, 
			snz_moe_uid, 
			input(sdate, yymmdd10.) as sdate format=ddmmyy10., 
			input(edate, yymmdd10.) as edate format=ddmmyy10., 
			input(extractiondate, yymmdd10.) as extractiondate format=ddmmyy10., 
			event_type, 
			input(dob, yymmdd10.) as dob format=ddmmyy10.
		from connection to odbc(
			select 
				enr.snz_uid, 
				enr.snz_moe_uid, 
				enr.moe_esi_start_date as sdate,
				enr.moe_esi_end_date as edate, 
				enr.moe_esi_extrtn_date as extractiondate,	/* ST - 2017-05-05 - Extraction Data Added as it is later used in MoJ code */
				enr.moe_esi_provider_code as event_type,
				datefromparts(per.snz_birth_year_nbr, per.snz_birth_month_nbr, 15) as dob
			from 
				&dbrefreshversion..moe_clean.student_enrol enr
				left join &dbrefreshversion..data.personal_detail per on (enr.snz_uid = per.snz_uid)
			where enr.moe_esi_start_date is not null ;
		);
	disconnect from odbc;
quit;


/*********************************************************************************************************
Section 2 - MoJ Enrollment Business Rules Inserted here
*********************************************************************************************************/

/* ST - 2017-05-05 - Rename variables to align with MoJ code copied below */
data MOE_2;
set master_schooling;
rename edate =enddate sdate=startdate event_type=schoolnumber dob=date_of_birth;
year18_birth = year(dob)+18;
run;

/* This code has been copied from last years MoJ code with minor revisions to dataset names such that the 
code aligns with the SIAL above and below */

/*Find records with where enddates for enrolment spells are missing*/
proc sql;
	create table missing_end as
	select *
	from MOE_2 
	where enddate=. ;
quit;

/* Do these individuals have any later spells at any school? If so, replace null end dates with the earliest record of later start date*/
proc sql;
	create table missing_replace as
	select  a.snz_uid
		   ,a.startdate
	       ,min(b.startdate) as newend format date9.
	from missing_end a
	join MOE_2  b
	on a.snz_uid=b.snz_uid
	and a.startdate < b.startdate
	group by a.snz_uid,a.startdate
	having newend is not null
	order by a.snz_uid,a.startdate
	;
quit;																		

/* Merge this dataset back in to main enrolments dataset on the basis on snz_uid and start date being the same*/
proc sql;
	create table MOE_3 as
	select distinct 
		a.snz_uid
		,a.snz_moe_uid
		,a.startdate 
		,case when a.enddate is not null then a.enddate
		when a.enddate is null and b.newend is not null then b.newend
		else . end as enddate format date9. 
		,a.schoolnumber
		,a.ExtractionDate
		,a.date_of_birth 
		,year18_birth
	from MOE_2 a
	left join missing_replace b
	on a.snz_uid=b.snz_uid
	and a.startdate=b.startdate
	order by a.snz_uid, a.startdate,enddate	;
quit;


data MOE_3; 
	set MOE_3;

	/* Impute enddates for people aged over 19 years as the last day of the year they turn 19.*/
	if enddate=. and extractionDate>intnx('YEAR',date_of_birth,19,'S')
		then enddate=mdy(12,31,year18_birth+1);
	/* For individuals not yet 19 with missing end dates, use the extraction date of the record as end date*/
	else if enddate = . then enddate=ExtractionDate;

	/* Apply Quality checks*/
	if enddate > startdate;	
	if startdate > 0;
	if year(startdate) > year( today() ) then delete;

	/* Truncate enddate to end of current year */
	if enddate > mdy(12,31,year( today() ) ) then enddate=mdy(12,31,year( today() ) );
run;			

/* Let's make sure no duplicate enrolment records */
proc sort data=MOE_3 nodupkey out=MOE_4;
	by snz_uid startdate enddate schoolnumber;
run;														

/* Where a single startDate has multiple endDates, use the latest endDate */
/* Check if there are any such nested enrollment records */
proc sql;
	create table overlaps as
	select a.snz_uid,a.startDate,a.endDate,a.schoolNumber,
		b.startDate as startDate2,b.endDate as endDate2,b.schoolNumber as schoolNumber2
	from MOE_4 a
	left join MOE_4 b
	on a.snz_uid=b.snz_uid
	where a.startDate < startDate2 and a.endDate > startDate2
	order by snz_uid,startDate,startDate2;
quit;	

/* For each startDate, we need to keep the obs for the earliest startDate2 and recode
	the day before that startDate2 as endDate */
data replace(keep=snz_uid startDate endDateNew);
	set overlaps;
	by snz_uid startdate;
	format endDateNew date9.;
	endDateNew = startDate2-1;
	if first.startDate;
run;

/* Merge those obs back onto the main enrol table */
data MOE_4(drop=endDateNew);
	merge MOE_4(in=a) replace(in=b);
	by snz_uid startDate;
	if a and b then endDate=endDateNew;
	if a;
run;

/* ST - 2017-05-05 - Rename variables to realign with SIAL code copied below, change dataset name back to _2 so SIAL can flow without changes */
data master_schooling;
	set MOE_4;
	rename enddate=edate startdate= sdate schoolnumber= event_type date_of_birth=dob;
run;														


/*********************************************************************************************************
Section 3 - Original SIAL Code Resumes
*********************************************************************************************************/

/*Generate macro variable for max end date to use in imputation*/
proc sql;
	select max(edate) into :max_end
	from master_schooling;										
quit;

/*%put Max end date is &max_end.;*/
data master_schooling_3;
	length event_type $7 start_date end_date 4;
	format year_end_date start_date end_date ddmmyy10.;
	set master_schooling;

	/*Age at which student started school*/
	start_age = floor((sdate - dob)/365.25);

	/*For spell end date use edate or if missing use 
		end of last school year*/
	if edate = . then
		end_date = &max_end.;	
	else end_date = edate;

	start_date = sdate;

	/*Years in spell*/
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
		edate=mdy(12,31,year(&max_end.));

	provider = left(put(InstitutionNumber,6.0));


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
		b.decilecode as event_type_2
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
		a.spell_year = left(put(b.academic_year,4.0)) and a.event_type_2 = b.school_number;
quit;

/*Calculate fraction of funding for part year*/
data master_moe_enr_enr;
	
	set master_schooling_6;
	year_start_date = mdy(2, 1, input(spell_year, 4.0));
	year_end_date = mdy(12, 20, input(spell_year, 4.0));
	prop_of_year = (1 + min(end_date, year_end_date) - max(start_date, year_start_date)) / (1 + year_end_date - year_start_date);
	cost = fte_cost * prop_of_year;
	start_date2 = input(put(start_date,yymmdd10.),yymmdd10. ); 
	end_date2 = input (put(end_date,yymmdd10.),yymmdd10. );
	rename start_date2=start_date end_date2 =end_date;
	drop fte_cost prop_of_year year_start_date year_end_date end_date start_date;

run;

/*Output - ST - 2017-05-05 - Note changes to SIAL Code - Export Locally to allow variable formats to be change prior to export to IDI Sandpit*/
/*Output to IDI sandpit*/
proc sql;
	drop table 
		sand.SIAL_MOE_school_events;
	
	create table 
		sand.SIAL_MOE_school_events as
	select 
		snz_uid
		,'MOE' as department
		,'STU' as datamart
		,'ENR' as subject_area
		,start_date format=ddmmyy10.
		,end_date format=ddmmyy10.
		,cost
		,event_type /*School number*/
		,put(event_type_2 ,2. ) as event_type_2 /*Decile*/
	from 
		master_moe_enr_enr 
	where 
		error_ind ne 1;
quit;