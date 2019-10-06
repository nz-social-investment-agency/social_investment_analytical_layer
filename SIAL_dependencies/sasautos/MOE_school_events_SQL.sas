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

March 2019 -PNH- updated for SAS-GRID migration. Dates now stored as SAS Dates on SAS Server
			MOE_clean adohc data now stored in IDI_Adhoc
*********************************************************************************************************/


/*********************************************************************************************************
Section 0 - Library Set Up
*********************************************************************************************************/


/*libname sandmoe ODBC dsn=idi_sandpit_srvprd schema="clean_read_moe" user=&username password=&pw;*/

libname adhocmoe ODBC dsn=idi_Adhoc schema="clean_read_moe";
libname sandmoe ODBC dsn=idi_sandpit_srvprd schema="clean_read_moe";



/*********************************************************************************************************
Section 1 - Original SIAL Code Commences
*********************************************************************************************************/
%let decileStartYear = 2002; /*The funding data starts in 2002 */


/* Re-written to perform joins on SQL server using explicit passthrough*/

proc sql;
	&sandpit_connect;
	execute(
		IF OBJECT_ID(%tslit([IDI_Sandpit].[&schema].[SIALTMP_master_schooling]),'U') IS NOT NULL
		DROP TABLE [IDI_Sandpit].[&schema].[SIALTMP_master_schooling];
	) by odbc;
	execute(
		select 
				enr.snz_uid, 
				enr.snz_moe_uid, 
				enr.moe_esi_start_date as startdate,
				enr.moe_esi_end_date as enddate, 
				enr.moe_esi_extrtn_date as extractiondate,	/* ST - 2017-05-05 - Extraction Data Added as it is later used in MoJ code */
				enr.moe_esi_provider_code as schoolnumber,
				datefromparts(per.snz_birth_year_nbr, per.snz_birth_month_nbr, 15) as date_of_birth,
				per.snz_birth_year_nbr +18 as year18_birth
			into [&schema].[SIALTMP_master_schooling] 
			from 
				[&idi_refresh.].moe_clean.student_enrol enr
				left join [&idi_refresh.].data.personal_detail per on (enr.snz_uid = per.snz_uid)
			where enr.moe_esi_start_date is not null 
		;
		) by odbc;
	execute(
		IF OBJECT_ID(%tslit([IDI_Sandpit].[&schema].[SIALTMP_missing_end]),'U') IS NOT NULL
		DROP TABLE [IDI_Sandpit].[&schema].[SIALTMP_missing_end];
	) by odbc;
	execute(
		/*Find records with where enddates for enrolment spells are missing*/
		select * into [&schema].[SIALTMP_missing_end]
		from [&schema].[SIALTMP_master_schooling] 
		where enddate is NULL;
		) by odbc;
		execute(
		IF OBJECT_ID(%tslit([IDI_Sandpit].[&schema].[SIALTMP_missing_replace]),'U') IS NOT NULL
		DROP TABLE [IDI_Sandpit].[&schema].[SIALTMP_missing_replace];
	) by odbc;
	execute (
		/* Do these individuals have any later spells at any school? If so, replace null end dates with the earliest record of later start date*/;
		select  a.snz_uid
		   ,a.startdate
	       ,min(b.startdate) as newend
		   into [&schema].[SIALTMP_missing_replace]
			from [&schema].[SIALTMP_missing_end] a
			join [&schema].[SIALTMP_master_schooling]   b
			on a.snz_uid=b.snz_uid
			and a.startdate < b.startdate
		group by a.snz_uid,a.startdate
		having min(b.startdate) is not null
		order by a.snz_uid,a.startdate;
) by odbc;
	disconnect from odbc;
quit;
proc sql;
	&sandpit_connect;
	execute(
		IF OBJECT_ID(%tslit([IDI_Sandpit].[&schema].[SIALTMP_MOE_School]),'U') IS NOT NULL
		DROP TABLE [IDI_Sandpit].[&schema].[SIALTMP_MOE_School];
	) by odbc;
	execute(
		/* Merge this dataset back in to main enrolments dataset on the basis on snz_uid and start date being the same*/
		select distinct 
		a.snz_uid
		,a.snz_moe_uid
		,a.startdate 
		,case when a.enddate is not null then a.enddate
		when a.enddate is null and b.newend is not null then b.newend
		when a.enddate is NULL and extractiondate > dateadd(year,19,date_of_birth) then datefromparts(year18_birth, 12, 31)
		else extractiondate end as enddate 
		,a.schoolnumber
		,a.ExtractionDate
		,a.date_of_birth 
		,year18_birth
		into [&schema].[SIALTMP_MOE_School]
	from [&schema].[SIALTMP_master_schooling] a
	left join [&schema].[SIALTMP_missing_replace] b
	on a.snz_uid=b.snz_uid
	and a.startdate=b.startdate
	having start_date < enddate and year(start_date) <= year(getdate())
	order by a.snz_uid, a.startdate,enddate	;
	) by odbc;
	disconnect from odbc;
quit;

/* Let's make sure no duplicate enrolment records */
proc sql;
	&sandpit_connect;
	execute(
		IF OBJECT_ID(%tslit([IDI_Sandpit].[&schema].[SIALTMP_MOE_School_dedup]),'U') IS NOT NULL
		DROP TABLE [IDI_Sandpit].[&schema].[SIALTMP_MOE_School_dedup];
	) by odbc;
	execute(
	select distinct snz_uid, snz_moe_uid, startdate, enddate, schoolnumber, extractiondate, date_of_birth
	into [&schema].[SIALTMP_MOE_School_dedup]
	from [&schema].[SIALTMP_MOE_School]
	
) by odbc;
	disconnect from odbc;
quit;	


/* Where a single startDate has multiple endDates, use the latest endDate */
/* Check if there are any such nested enrollment records */
proc sql;
	&sandpit_connect;
	execute(
		IF OBJECT_ID(%tslit([IDI_Sandpit].[&schema].[SIALTMP_MOE_School_overlaps]),'U') IS NOT NULL
		DROP TABLE [IDI_Sandpit].[&schema].[SIALTMP_MOE_School_overlaps];
	) by odbc;
	execute(
	select a.snz_uid, a.startDate, a.endDate, a.schoolNumber,
		b.startDate as startDate2 ,b.endDate as endDate2, b.schoolNumber as schoolNumber2
		into  [&schema].[SIALTMP_MOE_School_overlaps]
	from [&schema].[SIALTMP_MOE_School_dedup] a
	left join [&schema].[SIALTMP_MOE_School_dedup] b
	on a.snz_uid=b.snz_uid
	where a.startDate < b.startDate and a.endDate > b.startDate
	) by odbc;
	
	disconnect from odbc;
quit;
/* For each startDate, we need to keep the obs for the earliest startDate2 and recode
	the day before that startDate2 as endDate */;
proc sql;
	&sandpit_connect;
execute(
		IF OBJECT_ID(%tslit([IDI_Sandpit].[&schema].[SIALTMP_MOE_School_replace]),'U') IS NOT NULL
		DROP TABLE [IDI_Sandpit].[&schema].[SIALTMP_MOE_School_replace];
	) by odbc;	
	execute(
	select snz_uid,startdate, dateadd(day,-1,min(startdate2)) as endnewdate
	into [&schema].[SIALTMP_MOE_School_replace]
	from [&schema].[SIALTMP_MOE_School_overlaps]
	group by snz_uid, startdate
	) by odbc;
	disconnect from odbc;
quit;
/* Merge those obs back onto the main enrol table */
/* ST - 2017-05-05 - Rename variables to realign with SIAL code copied below, change dataset name back to _2 so SIAL can flow without changes */
proc sql;
	&sandpit_connect;
execute(
		IF OBJECT_ID(%tslit([IDI_Sandpit].[&schema].[SIALTMP_MOE_School_2]),'U') IS NOT NULL
		DROP TABLE [IDI_Sandpit].[&schema].[SIALTMP_MOE_School_2];
		) by odbc;
		execute (
		select a.snz_uid, a.snz_moe_uid, a.startdate as sdate, a.schoolnumber as event_type, a.extractiondate,date_of_birth as dob,
		case when b.endnewdate is not NULL then b.endnewdate else a.enddate end as edate
		into [IDI_Sandpit].[&schema].[SIALTMP_MOE_School_2]
		from [IDI_Sandpit].[&schema].[SIALTMP_MOE_School] a
		left join 
		[IDI_Sandpit].[&schema].[SIALTMP_MOE_School_replace] b
		on a.snz_uid=b.snz_uid and a.startdate=b.startdate;
			) by odbc;
	disconnect from odbc;
quit;


/*********************************************************************************************************
Section 3 - Original SIAL Code Resumes (coded in SQL - June 2019)
*********************************************************************************************************/
proc sql;
	&sandpit_connect;
execute(
		IF OBJECT_ID(%tslit([IDI_Sandpit].[&schema].[master_schooling]),'U') IS NOT NULL
		DROP TABLE [IDI_Sandpit].[&schema].[master_schooling];
		) by odbc;

		execute (
		with maxend as	
			(select max(edate) maxedate from [IDI_Sandpit].[&schema].[SIALTMP_MOE_School_2])
		select snz_uid,snz_moe_uid, event_type,
		/*Age at which student started school*/

		floor(datediff(day,dob,sdate)/365.25) as start_age,
		/*For spell end date use edate or if missing use 
		end of last school year*/

		case when edate = NULL then maxedate else edate end as enddate,
		sdate as startdate,	
		/*Years in spell*/
		years = floor(datediff(day,sdate,edate)/365.25),
		/*There appears to be an error for some spells*/
		/*If school spell is greater than 14 years or student's
		age is not between 4 and 24 of error years at enrolment then
		assign an error indicator*/
		case when (floor(datediff(day,sdate,edate)/365.25) > 14 or not (floor(datediff(day,dob,sdate)/365.25) between 4 and 24)) then 1 else 0 end as error_ind
		into [IDI_Sandpit].[&schema].[master_schooling]
		from [IDI_Sandpit].[&schema].[SIALTMP_MOE_School_2]
		inner join 
		maxend m
		) by odbc;
	disconnect from odbc;
quit;

/*Generate macro variable for max end date to use in imputation*/
proc sql;
	select max(edate) into :max_end
	from master_schooling;										
quit;

/*%put Max end date is &max_end.;*/
data master_schooling_3;
	/*length event_type $20 start_date end_date 4;*/
	format  start_date end_date ddmmyy10.;
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

	drop edate sdate years start_age dob snz_moe_uid;
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
	set adhocmoe.moe_school_decile_history;
	where decilecode ne 99;
	/* SAS Grid changes - march 2019*/
	sdate = decileStartDate;
	edate = decileEndDate;
/*	sdate = input(decileStartDate,yymmdd10.);*/
/*	edate = input(decileEndDate,yymmdd10.);*/

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
		sand.MOE_SCHOOL_DECILE_PRICING as b		
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
	create view
	sialview.SIAL_MOE_school_events asselect * from 	sand.SIAL_MOE_school_events;

quit;




