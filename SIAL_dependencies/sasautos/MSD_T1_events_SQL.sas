/*********************************************************************************************************
TITLE: MSD_T1_events

DESCRIPTION: Create MSD Tier 1 benefit costs table

INPUT: 
[msd_clean].[msd_first_tier_expenditure]
benefitspells (as created from Marc's macro in the IDI wiki)
JUNE 2019 - rewritten in SQl by Simon A

OUTPUT:
SIAL_MSD_T1_events

DEPENDENCIES: 


NOTES: 
See SIAL data dictionary for business rules applied

AUTHOR: V Benny

CREATED: 28 June 2016
Re coded in SQl June 2019 - by Simon A

BUSINESS QA COMPLETE: OCTOBER 2016

HISTORY: 
/*
Providing an SQL approach to constructing MSD Tier 1 Benefit Spells.
Equivalent to the table presently included in the SIAL.

Present methodology is based in SAS scripts, 1800 lines.
These scripts include more functionality than SIA makes use of.

Previous SIA data scientists have remarked that the methodology is too
detailed/complex to provide a straight-forward explanation. This represents
a risk to SIA if we are using data but can not track how it was created.

This script undertakes an SQL construction of the MSD T1 main benefit
table from the SIAL. It aims for understandability.

Runtime: 3-4.5 minutes

Simon Anastasiadis
2019-06-05 v1, validation of dates against existing table 99.7% match
2019-04-26 v0, translation to benefit types & name remaining
2019-04-11 begun
*/

*********************************************************************************************************/
/* Define source database version*/;

/********************************************************************************
Interface

Views to provide an ease point of correction if breaks
********************************************************************************/;
options nomlogic nosymbolgen source source2 nomprint;

proc sql;
	&idi_usercode_connect;
	execute(
		/* drop before re-creating */

	IF OBJECT_ID(%tslit([&schema].[tmp_SIAL_spell_input]),'V') IS NOT NULL DROP VIEW [&schema].[tmp_SIAL_spell_input]
	IF OBJECT_ID(%tslit([&schema].[tmp_SIAL_partner_input]),'V') IS NOT NULL DROP VIEW [&schema].[tmp_SIAL_partner_input]
	) by odbc;

	/* table for main recipient spells */;
	execute(
		CREATE view [&schema].[tmp_SIAL_spell_input] as
			(SELECT snz_uid
				,COALESCE(msd_spel_servf_code, 'nul') AS msd_spel_servf_code
				,COALESCE([msd_spel_add_servf_code], 'null') AS msd_spel_add_servf_code 
				,[msd_spel_spell_start_date] AS start_date
				,COALESCE([msd_spel_spell_end_date], '9999-12-31') AS [end_date]
			FROM [&idi_refresh.].[msd_clean].[msd_spell]
				WHERE [msd_spel_spell_start_date] IS NOT NULL
					AND ([msd_spel_spell_end_date] IS NULL
					OR [msd_spel_spell_start_date] <= [msd_spel_spell_end_date]))
			) by odbc;

	/* table for partner spells */;
	execute(
		CREATE view [&schema].[tmp_SIAL_partner_input] AS
			(SELECT [snz_uid]
				,[partner_snz_uid]
				,[msd_ptnr_ptnr_from_date] AS [start_date]
				,COALESCE([msd_ptnr_ptnr_to_date], '9999-12-31') AS [end_date]
			FROM [&idi_refresh.].[msd_clean].[msd_partner]
				WHERE [msd_ptnr_ptnr_from_date] IS NOT NULL
					AND ([msd_ptnr_ptnr_to_date] IS NULL
					OR [msd_ptnr_ptnr_from_date] <= [msd_ptnr_ptnr_to_date])
			)
			) by odbc;
	disconnect from odbc;
quit;

/********************************************************************************
Condense Primary Benefit spells
(AKA packing date intervals OR merging overlapping spells)

Where the same person has overlapping benefit spells, or a new spell
starts the same day/the day after an old spell ends, then merge the spells.

E.g. 
start_date   end_date
2001-01-01   2001-01-05
2001-01-06   2001-01-12
2001-02-09   2001-02-14
2001-02-12   2001-02-18
2001-02-18   2001-02-29
2010-10-10   2010-10-10

becomes
start_date   end_date
2001-01-01   2001-01-12
2001-02-09   2001-02-29
2010-10-10   2010-10-10
****
/* drop table before re-creating */;
proc sql;
	&sandpit_connect;
	execute(
		IF OBJECT_ID(%tslit([IDI_Sandpit].[&schema].[tmp_SIAL_spell_condensed]),'U') IS NOT NULL
	DROP TABLE [IDI_Sandpit].[&schema].[tmp_SIAL_spell_condensed];
	) by odbc;
	/* create table with condensed spells */;
	execute(
		/* exclude start dates that are within another spell */
	WITH
	spell_starts AS (
	SELECT [snz_uid]
		,[msd_spel_servf_code]
		,[msd_spel_add_servf_code]
		,[start_date]
		,[end_date]
		FROM [IDI_UserCode].[&schema].[tmp_SIAL_spell_input] s1
			WHERE NOT EXISTS (
				SELECT 1
					FROM [IDI_UserCode].[&schema].[tmp_SIAL_spell_input] s2
						WHERE s1.snz_uid = s2.snz_uid
							AND s1.[msd_spel_servf_code] = s2.[msd_spel_servf_code]
							AND s1.[msd_spel_add_servf_code] = s2.[msd_spel_add_servf_code]
							AND s2.[start_date] < s1.[start_date] 
							AND s1.[start_date] <= s2.[end_date]
							)
							),
							/* exclude end dates that are within another spell */
	spell_ends AS (
	SELECT [snz_uid]
		,[msd_spel_servf_code]
		,[msd_spel_add_servf_code]
		,[start_date]
		,[end_date]
		FROM [IDI_UserCode].[&schema].[tmp_SIAL_spell_input] t1
			WHERE NOT EXISTS (
				SELECT 1 
					FROM [IDI_UserCode].[&schema].[tmp_SIAL_spell_input]  t2
						WHERE t2.snz_uid = t1.snz_uid
							AND t1.[msd_spel_servf_code] = t2.[msd_spel_servf_code]
							AND t1.[msd_spel_add_servf_code] = t2.[msd_spel_add_servf_code]
							AND t2.[start_date] <= t1.[end_date] 
							AND t1.[end_date] < t2.[end_date]
							)
							)
							SELECT s.snz_uid
								,s.[msd_spel_servf_code]
								,s.[msd_spel_add_servf_code]
								,s.[start_date]
								,MIN(e.[end_date]) as [end_date]
								INTO [IDI_Sandpit].[&schema].[tmp_SIAL_spell_condensed]
									FROM spell_starts s
										INNER JOIN spell_ends e
											ON s.snz_uid = e.snz_uid
											AND s.[msd_spel_servf_code] = e.[msd_spel_servf_code]
											AND s.[msd_spel_add_servf_code] = e.[msd_spel_add_servf_code]
											AND s.[start_date] <= e.[end_date]
											GROUP BY s.snz_uid, s.[start_date], s.[msd_spel_servf_code], s.[msd_spel_add_servf_code]
												ORDER BY s.[start_date];
	) by odbc;

	/********************************************************************************
	Condense Partner Benefit spells
	As per the same logic for primary benefit spells

		Note that we ignore the benefit type of the main beneficiary.
		********************************************************************************/;

	/* drop table before re-creating */
	execute(
		IF OBJECT_ID(%tslit([IDI_Sandpit].[&schema].[tmp_SIAL_partner_condensed]),'U') IS NOT NULL
	DROP TABLE [IDI_Sandpit].[&schema].[tmp_SIAL_partner_condensed];
	) by odbc;
	/* create table with condensed spells */
	execute(
		WITH
		/* exclude start dates that are within another spell */
	spell_starts AS (
	SELECT [snz_uid]
		,[partner_snz_uid]
		,[start_date]
		,[end_date]
		FROM [IDI_UserCode].[&schema].[tmp_SIAL_partner_input] s1
			WHERE NOT EXISTS (
				SELECT * 
					FROM [IDI_UserCode].[&schema].[tmp_SIAL_partner_input] s2
						WHERE s1.snz_uid = s2.snz_uid
							AND s1.[partner_snz_uid] = s2.[partner_snz_uid]
							AND s2.[start_date] < s1.[start_date] 
							AND s1.[start_date] <= s2.[end_date]
							)
							),
							/* exclude end dates that are within another spell */
	spell_ends AS (
	SELECT [snz_uid]
		,[partner_snz_uid]
		,[start_date]
		,[end_date]
		FROM [IDI_UserCode].[&schema].[tmp_SIAL_partner_input] t1
			WHERE NOT EXISTS (
				SELECT * 
					FROM [IDI_UserCode].[&schema].[tmp_SIAL_partner_input]  t2
						WHERE t2.snz_uid = t1.snz_uid
							AND t1.[partner_snz_uid] = t2.[partner_snz_uid]
							AND t2.[start_date] <= t1.[end_date] 
							AND t1.[end_date] < t2.[end_date]
							)
							)
							SELECT s.snz_uid
								,s.[partner_snz_uid]
								,s.[start_date]
								,MIN(e.[end_date]) as [end_date]
								INTO [IDI_Sandpit].[&schema].[tmp_SIAL_partner_condensed]
									FROM spell_starts s
										INNER JOIN spell_ends e
											ON s.snz_uid = e.snz_uid
											AND s.[partner_snz_uid] = e.[partner_snz_uid]
											AND s.[start_date] <= e.[end_date]
											GROUP BY s.snz_uid, s.[start_date], s.[partner_snz_uid]
												ORDER BY s.[start_date]
													) by odbc;
	disconnect from odbc;
quit;

/********************************************************************************
Invert Primary benefit spells

Return periods where the person does not have any spells in the input table.
Requires that input table has already been condensed


E.g. 
start_date   end_date
2001-01-01   2001-01-05
2001-01-06   2001-01-12
2001-02-12   2001-02-18

becomes
start_date   end_date
1900-01-01   2000-12-31
2001-01-13   2001-02-11
2001-02-19   9999-12-31

********************************************************************************/;
proc sql;
	&sandpit_connect;

	/* drop table before re-creating */;
	execute(
		IF OBJECT_ID(%tslit([IDI_Sandpit].[&schema].[tmp_SIAL_spell_invert]),'U') IS NOT NULL
	DROP TABLE [IDI_Sandpit].[&schema].[tmp_SIAL_spell_invert];
	) by odbc;
	/* create table with inverted spells */;
	execute(
		SELECT [snz_uid]
			,'non-benefit' AS [description]
			,[start_date]
			,[end_date]
		INTO [IDI_Sandpit].[&schema].[tmp_SIAL_spell_invert]
			FROM (
				/* all forward looking spells */
			SELECT [snz_uid]
				,DATEADD(DAY, 1, [end_date]) AS [start_date]
				,LEAD(DATEADD(DAY, -1, [start_date]), 1, '9999-12-31') OVER (
				PARTITION BY [snz_uid]
			ORDER BY [start_date] ) AS [end_date]
				FROM [IDI_Sandpit].[&schema].[tmp_SIAL_spell_condensed]

					UNION ALL

					/* back looking spell (to 'origin of time') created separately */
				SELECT [snz_uid]
					,'1900-01-01' AS [start_date]
					,DATEADD(DAY, -1, MIN([start_date])) AS [end_date]
				FROM [IDI_Sandpit].[&schema].[tmp_SIAL_spell_condensed]
					GROUP BY [snz_uid]
						) k
					WHERE [start_date] <= [end_date]
						AND '1900-01-01' <= [start_date] 
						AND [end_date] <= '9999-12-31'
						) by odbc;
	disconnect from odbc;
quit;

/********************************************************************************
Invert Partner Benefit spells
As per the same logic for primary benefit spells
********************************************************************************/;
proc sql;
	&sandpit_connect;

	/* drop table before re-creating */
	execute(
		IF OBJECT_ID(%tslit([IDI_Sandpit].[&schema].[tmp_SIAL_partner_invert]),'U') IS NOT NULL
	DROP TABLE [IDI_Sandpit].[&schema].[tmp_SIAL_partner_invert];
	) by odbc;
	/* create table with inverted spells */
	execute(
		SELECT [snz_uid]
			,NULL AS [partner_snz_uid]
			,[start_date]
			,[end_date]
		INTO [IDI_Sandpit].[&schema].[tmp_SIAL_partner_invert]
			FROM (
				/* all forward looking spells */
			SELECT [snz_uid]
				,DATEADD(DAY, 1, [end_date]) AS [start_date]
				,LEAD(DATEADD(DAY, -1, [start_date]), 1, '9999-12-31') OVER (
				PARTITION BY [snz_uid]
			ORDER BY [start_date] ) AS [end_date]
				FROM [IDI_Sandpit].[&schema].[tmp_SIAL_partner_condensed]

					UNION ALL

					/* back looking spell (to 'origin of time') created separately */
				SELECT [snz_uid]
					,'1900-01-01' AS [start_date]
					,DATEADD(DAY, -1, MIN([start_date])) AS [end_date]
				FROM [IDI_Sandpit].[&schema].[tmp_SIAL_partner_condensed]
					GROUP BY [snz_uid]
						) k
					WHERE [start_date] <= [end_date]
						AND '1900-01-01' <= [start_date] 
						AND [end_date] <= '9999-12-31'
						) by odbc;
	disconnect from odbc;
quit;

/********************************************************************************
Apply catergorisation rules

If in spell AND not in partner THEN 'single'
If in spell AND in partner THEN 'primary'
If partner in partner AND not in spell THEN 'partner'
	ONLY 'single' and 'primary' have additional benefit details (like type & amount)
********************************************************************************/;

/* drop table before re-creating */
proc sql;
	&sandpit_connect;
	execute(
		IF OBJECT_ID(%tslit([&schema].[tmp_SIAL_MSD_T1_final]),'U') IS NOT NULL
	DROP TABLE [&schema].[tmp_SIAL_MSD_T1_final];
	) by odbc;
	/* create final SIAL table */
	execute(
		SELECT k.*
			,code.level1
			,code.level2
			,code.level3
			,code.level4
		INTO [IDI_Sandpit].[DL-MAA2016-15].[tmp_SIAL_MSD_T1_final]
			FROM (
				/* recipient where role = single as no partner during period */
			SELECT ys.[snz_uid]
				,'single' AS [role]
				,
			CASE 
				WHEN ys.[start_date] <= np.[start_date] THEN np.[start_date] 
				ELSE ys.[start_date] 
			END 
		AS [start_date] /*-- latest start date*/
			,
		CASE 
			WHEN ys.[end_date]   <= np.[end_date]   THEN ys.[end_date]   
			ELSE np.[end_date]   
		END 
	AS [end_date]  /* -- earliest 
		end 
		date*/
		,ys.[msd_spel_servf_code]
		,ys.[msd_spel_add_servf_code]
	FROM [IDI_UserCode].[DL-MAA2016-15].[tmp_SIAL_spell_input] ys /*-- yes, spell*/
		INNER JOIN [IDI_Sandpit].[DL-MAA2016-15].[tmp_SIAL_partner_invert] np /*-- no, partner*/
			ON ys.snz_uid = np.snz_uid /*-- identity appears in both tables*/
			AND ys.[start_date] <= np.[end_date]
			AND np.[start_date] <= ys.[end_date] /*-- periods overlap*/
			UNION ALL
			/* recipient where role = single as never had partner */
		SELECT ys.[snz_uid]
			,'single' AS [role]
			,[start_date]
			,[end_date]
			,ys.[msd_spel_servf_code]
			,ys.[msd_spel_add_servf_code]
		FROM [IDI_UserCode].[DL-MAA2016-15].[tmp_SIAL_spell_input] ys /*-- yes, spell*/
			WHERE NOT EXISTS (
				SELECT 1
					FROM [IDI_Sandpit].[DL-MAA2016-15].[tmp_SIAL_partner_invert] np /*-- no, partner*/
						WHERE ys.snz_uid = np.snz_uid /*-- identity appears in both tables*/
							)
							UNION ALL
							/* recipient where role = primary */
						SELECT ys.[snz_uid]
							,'primary' AS [role]
							,
						CASE 
							WHEN ys.[start_date] <= yp.[start_date] THEN yp.[start_date] 
							ELSE ys.[start_date] 
						END 
					AS [start_date] /*-- latest start date*/
						,
					CASE 
						WHEN ys.[end_date]   <= yp.[end_date]   THEN ys.[end_date]   
						ELSE yp.[end_date]   
					END 
				AS [end_date]   /*-- earliest 
					end 
					date*/
					,ys.[msd_spel_servf_code]
					,ys.[msd_spel_add_servf_code]
				FROM [IDI_UserCode].[DL-MAA2016-15].[tmp_SIAL_spell_input] ys /*-- yes, spell*/
					INNER JOIN [IDI_Sandpit].[DL-MAA2016-15].[tmp_SIAL_partner_condensed] yp /*-- yes, partner*/
						ON ys.snz_uid = yp.snz_uid /*-- identity appears in both tables*/
						AND ys.[start_date] <= yp.[end_date]
						AND yp.[start_date] < ys.[end_date] /*-- periods overlap*/
						UNION ALL
						/* receipt as role = partner */
					SELECT yp.[partner_snz_uid] AS [snz_uid]
						,'partner' AS [role]
						,
					CASE 
						WHEN ns.[start_date] <= yp.[start_date] THEN yp.[start_date] 
						ELSE ns.[start_date] 
					END 
				AS [start_date] /*-- latest start date*/
					,
				CASE 
					WHEN ns.[end_date]   <= yp.[end_date]   THEN ns.[end_date]   
					ELSE yp.[end_date]   
				END 
			AS [end_date]   /*-- earliest 
				end 
				date*/
				,ns.[msd_spel_servf_code]
				,ns.[msd_spel_add_servf_code]
			FROM [IDI_UserCode].[DL-MAA2016-15].[tmp_SIAL_partner_input] yp /*-- yes, partner*/
				LEFT JOIN [IDI_UserCode].[DL-MAA2016-15].[tmp_SIAL_spell_input] ns /*-- no, spell*/
					ON ns.snz_uid = yp.snz_uid
					AND yp.[start_date] <= ns.[end_date]
					AND ns.[start_date] < yp.[end_date] /*-- periods overlap*/
					) k
				LEFT JOIN IDI_Sandpit.clean_read_MSD.benefit_codes code
					ON k.msd_spel_servf_code = code.serv
					AND (k.msd_spel_add_servf_code = code.additional_service_data
					OR (code.additional_service_data IS NULL 
					AND (k.msd_spel_add_servf_code ='null' OR k.msd_spel_add_servf_code IS NULL)
					))
					AND code.ValidFromtxt <= k.[start_date]
					AND k.[start_date] <= code.ValidTotxt
					) by odbc;
	disconnect from odbc;
quit;

/* rename columns for final sial table*/
proc sql;
	&sandpit_connect;
	execute(
		IF OBJECT_ID(%tslit([&schema].[SIAL_MSD_T1_Events_new]),'U') IS NOT NULL
	DROP TABLE [&schema].[SIAL_MSD_T1_Events_new];
	) by odbc;
	execute(
			select distinct  role,snz_uid,start_date,end_date,msd_spel_servf_code as event_type, 
				msd_spel_add_servf_code as event_type2, level4 as event_type3, level3 as event_type4
				into [&schema].[SIAL_MSD_T1_Events_new]
			from [&schema].[tmp_SIAL_MSD_T1_final]
			) by odbc;
	disconnect from odbc;
quit;

/* create a view to point to the table in IDI_Usercode, so all the SIAL have views.*/
proc sql;
	&idi_usercode_connect;
	execute(
		create view [&schema].[SIAL_MSD_T1_Events] as select * from [IDI_SANDPIT].[&schema].[SIAL_MSD_T1_Events]
	;
	) by odbc;
	disconnect from odbc;
quit;

/********************************************************************************
Tidy up and remove all temporary tables/views that have been created
********************************************************************************/;
proc sql;
	&idi_usercode_connect;
	execute(
		IF OBJECT_ID(%tslit([&schema].[tmp_SIAL_spell_input]),'v') IS NOT NULL
	DROP view [&schema].[tmp_SIAL_spell_input]

		IF OBJECT_ID(%tslit([&schema].[tmp_SIAL_partner_input]),'v') IS NOT NULL
	DROP view [&schema].[tmp_SIAL_partner_input]
		) by odbc;
	disconnect from odbc;

proc sql;
	&sandpit_connect;
	execute(
		IF OBJECT_ID(%tslit([IDI_Sandpit].[&schema].[tmp_SIAL_spell_condensed]),'U') IS NOT NULL
	DROP TABLE [IDI_Sandpit].[&schema].[tmp_SIAL_spell_condensed]

		IF OBJECT_ID(%tslit([IDI_Sandpit].[&schema].[tmp_SIAL_partner_condensed]),'U') IS NOT NULL
	DROP TABLE [IDI_Sandpit].[&schema].[tmp_SIAL_partner_condensed]

		IF OBJECT_ID(%tslit([IDI_Sandpit].[&schema].[tmp_SIAL_spell_invert]),'U') IS NOT NULL
	DROP TABLE [IDI_Sandpit].[&schema].[tmp_SIAL_spell_invert]

		IF OBJECT_ID(%tslit([IDI_Sandpit].[&schema].[tmp_SIAL_partner_invert]),'U') IS NOT NULL
	DROP TABLE [IDI_Sandpit].[&schema].[tmp_SIAL_partner_invert]
		IF OBJECT_ID(%tslit([IDI_Sandpit].[&schema].[tmp_SIAL_partner_invert]),'U') IS NOT NULL
	DROP TABLE [IDI_Sandpit].[&schema].[tmp_SIAL_partner_invert]
		IF OBJECT_ID(%tslit([IDI_Sandpit].[&schema].[tmp_SIAL_MSD_T1_final]),'U') IS NOT NULL
	DROP TABLE [IDI_Sandpit].[&schema].[tmp_SIAL_MSD_T1_final]


		) by odbc;
	disconnect from odbc;
quit;