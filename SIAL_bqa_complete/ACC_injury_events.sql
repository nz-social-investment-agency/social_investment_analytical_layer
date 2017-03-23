/**********************************************************************************************************
 TITLE: ACC_injury_events

 DESCRIPTION: Reformat and recode ACC injury data into SIAL format

 INPUT: 
 idi_clean.acc_clean.claims

 OUTPUT: 
 {schemaname}.SIAL_ACC_injury_events 

 DEPENDENCIES: 
 NA
 
 NOTES: 
 See SIAL data dictionary for business rules applied

 AUTHOR: 
 E Walsh

 CREATED: 
 05 Jul 2016

 HISTORY: 
 Dec 15 K Maxwell changed order of event types to make them more usefulfor roll up processing 
                  (moving read codes to event_type_5 not event_type)
*********************************************************************************************************/

	create view {schemaname}.SIAL_ACC_injury_events as
		select  snz_uid, 
				'ACC' as department,
				'CLA' as datamart,
				'INJ' as subject_area,				
				cast(acc_cla_accident_date as datetime) as [start_date], /*accidents are point in time events*/
				cast(acc_cla_accident_date as datetime) as [end_date],
				acc_cla_tot_med_fee_paid_amt as cost,
				acc_cla_tot_weekly_comp_paid_amt as cost_2,
					case acc_cla_scene_text 
						when 'HOME'	then 'HOM'
						when 'PLACE OF RECREATION OR SPORTS' then 'REC'
						when 'COMMERCIAL / SERVICE LOCATION' then 'COM'
						when 'OTHER' then 'OTH'
						when 'ROAD OR STREET' then 'ROA'
						when 'INDUSTRIAL PLACE' then 'IND'
						when 'SCHOOL' then 'SCH'
						when 'FARM' then 'FAR'
						when 'PLACE OF MEDICAL TREATMENT' then 'MED'
						else 'UNK' 
					end  as event_type,
				/* event_type_2 needs to stay as this variable as it is a dependency for the MIX_selfharm_events  SIAL table */
			case acc_cla_wilful_self_inflicted_status_text
				when 'CONFIRMED' then 'CON' 
				else 'OTH' 
			end 
		as event_type_2,
			acc_cla_gradual_process_ind as event_type_3,
		case acc_cla_fund_account_text
			when 'NON-EARNERS ACCOUNT' then 'NEA'
			when 'EARNERS ACCOUNT' then 'EAR'
			when 'WORK ACCOUNT' then 'WRK'
			when 'MOTOR VEHICLE ACCOUNT' then 'MVH'
			when 'TREATMENT INJURY ACCOUNT' then 'TRI'
			else 'UNK' 
		end 
	as event_type_4,
		acc_cla_read_code as event_type_5,
		cast(acc_cla_weekly_comp_days_nbr as varchar(5)) as event_type_6
	from idi_clean.acc_clean.claims;



