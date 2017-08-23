
********************************************************************************************************;
        ** Formats **;

  ** Main benefit type format **;

 PROC FORMAT ;
  VALUE $BSHbntypPrWR
  '607'                          = 'Student'
  '366','666'                    = 'Women Alone'
  '030','330'                    = "Widow"
  '367','667'                    = 'Caring Sick Infirm'
  '600','601'                    = 'Sickness'
  '020','320', '370'             = 'Invalids'
  '603', '603YP'                 = 'Youth Payment'
  '603YPP'                       = 'Young Parent Payment'
  '365','665'                    = 'Sole Parent'
  '611'                          = 'Emergency'
  '313', '613'                   = 'Emergency Maintenance'
  '180', '181','050','350'       = 'Retired'
  '602','125','608', '115', '604','605','610','609', '675' = 'Job Seeker'
  '839','275', '044', '040', '340', '344' = 'Supplementary Only'
  '.', ' ', '', "000" = 'No benefit' 
   ;

  VALUE $BSHbntypPstWR
  '607'                    = 'Student'
  '030'                    = 'Widow'
  '675MED1','675MED2'      = 'Sickness'
  '370CARE'                = 'Caring Sick Infirm'
  '370PSMED', '020'        = 'Invalids'
  '365','665'              = 'Sole Parent'
  '603YP'                  = 'Youth Payment'
  '603YPP'                 = 'Young Parent Payment'
  '611'                    = 'Emergency'
  '313'                    = 'Emergency Maintenance'
  '180', '181','050','350' = 'Retired'
  '675FTJS1', '675FTJS2', '675FTJS3', '675FTJS4' = 'Job Seeker'
  '839','275', '044', '040', '340', '344'    = 'Supplementary Only'
  '.', ' ', '', "000"      = 'No benefit' 
   ;

  VALUE $BSHbengrp 
   "Job Seeker"    
  ,"Emergency"       
  ,"Student"               = "JS"
   "Youth"
  ,"Youth Payment"
  ,"Young Parent Payment" 
  ,"Youth Parent"          = "Yth"
   "Retired"               = "NZS"        
   "Sole Parent"        
  ,"Emergency Maintenance"        
  ,"Caring Sick Infirm"    = "SoleP"  
   "Invalids"              = "Inv"       
   "Sickness"              = "Sck" 
   "Widow"                   
  ,"Women Alone"           = "WAWdw" 
  ;
 run ;

  **  Benefit codes formats **;

proc format ;
******************************************************************;
***    FIRST BATCH - 2013 WELFARE REFORM FORMATS            ******;
******************************************************************;

******************************************************************;
******   First format group: 2013 welfare Reform, short names     ;
******          - Benefit group:  $SWF_ADDITIONAL_SERVICE_GRP     ;
******          - Benefit      :  $SWF_ADDITIONAL_SERVICE_DATA    ;
******************************************************************;

* Benefit sub category group format - post 12 July 2013, for high level grouping;
  VALUE $SWF_ADDITIONAL_SERVICE_GRP
    'YP'             = 'YP'
    'YPP'            = 'YPP'
    'CARE'           = 'Carers'
    'PSMED'          = 'HC&D'
    'FTJS1','FTJS2'  = 'JS Work Ready related'
    'FTJS3','FTJS4'  = 'JS Work Ready Training related'
    'MED1','MED2'    = 'JS HC&D related'
    ' '              = '.'
 ;

* Benefit sub category format - post 12 July 2013, short names;
  VALUE $SWF_ADDITIONAL_SERVICE_DATA
    'YP '            = 'YP'
    'YPP'            = 'YPP'
    'CARE'           = 'Carers'
    'FTJS1'          = 'JS Work Ready'
    'FTJS2'          = 'JS Work Ready Hardship'
    'FTJS3'          = 'JS Work Ready Training'
    'FTJS4'          = 'JS Work Ready Training Hardship'
    'MED1'           = 'JS HC&D'
    'MED2'           = 'JS HC&D Hardship'
    'PSMED'          = 'HC&D'
     ' '             = '.'
 ;

******************************************************************;
******   Second format group: 2013 welfare Reform, long names     ;
******          - Benefit group:  $SWF_ADDITIONAL_SERVICE_GRP_LG  ;
******          - Benefit      :  $SWF_ADDITIONAL_SERVICE_LONG    ;
******************************************************************;

* Benefit sub category group format - post 12 July 2013, for high level grouping;
  VALUE $SWF_ADDITIONAL_SERVICE_GRP_LG
    'YP'             = 'Youth Payment'
    'YPP'            = 'Young Parent Payment'
    'CARE'           = 'Carers'
    'PSMED'          = 'Health Condition & Disability'
    'FTJS1','FTJS2'  = 'Job Seeker Work Ready related'
    'FTJS3','FTJS4'  = 'Job Seeker Work Ready Training related'
    'MED1','MED2'    = 'Job Seeker Health Condition & Disability related'
    ' '              = '.'
 ;

* Benefit sub category format - post 12 July 2013, long names;
  VALUE $SWF_ADDITIONAL_SERVICE_LONG
    'YP '            = 'Youth Payment'
    'YPP'            = 'Young Parent Payment'
    'CARE'           = 'Carers'
    'FTJS1'          = 'Job Seeker Work Ready'
    'FTJS2'          = 'Job Seeker Work Ready Hardship'
    'FTJS3'          = 'Job Seeker Work Ready Training'
    'FTJS4'          = 'Job Seeker Work Ready Training Hardship'
    'MED1'           = 'Job Seeker Health Condition & Disability'
    'MED2'           = 'Job Seeker Health Condition & Disability Hardship'
    'PSMED'          = 'Health Condition & Disability'
     ' '             = '.'
 ;

******************************************************************;
***    FIRST BATCH - CURRENT FORMATS                        ******;
******************************************************************;

******************************************************************;
******   First format group: post 12 July 2013, short names       ;
******          - Benefit group:  $bftgp                          ;
******          - Benefit:     :  $bft                            ;
******          - Service code:   $serv                           ;
******************************************************************;

* Current Benefit group format - for high level grouping;
  VALUE $bftgp
    '020','370'            = 'SLP related'
    '030'                  = 'WBO'
    '040','044','340','344'= 'OB UCB'
    '050','350','180','181'= 'NZS VP TRB'
    '313'                  = 'EMA'
    '365'                  = 'SPS'
    '607'                  = 'JSSH'
    '611'                  = 'EB'
    '665'                  = 'SPSO'
    '675'                  = 'JS related'
    '839','275'            = 'Non Ben'
    'YP ','YPP','603'      = 'YP/YPP' 
    ' '                    = 'No Bft'
    '115','610'            = 'UB related'
    '125','608'            = 'UBT related'
    '320'                  = 'IB'
    '330'                  = 'WB'
    '367'                  = 'DPB related'
    '600','601'            = 'SB related'
 ;

* Current benefit formats - short version;
  VALUE $bft
          '020'  = 'SLPO'    /* Supported Living Payment - Overseas  */
          '030'  = 'WBO'
    '040','340'  = 'OB'
    '044','344'  = 'UCB'
    '050','350'  = 'TRB'
          '060'  = 'FB' 
          '062'  = 'CCS'
          '064'  = 'FTC'
          '065'  = 'CDA'
          '179'  = 'Discont'
          '180'  = 'NZS'
          '181'  = 'VP'
          '188'  = 'SLAR' 
          '190'  = 'FNGRTM'
          '191'  = 'FNGRTS'
          '192'  = 'FNGRTC'
          '193'  = 'WFG'
          '200'  = 'WPP'
          '201'  = 'WP1'
          '202'  = 'WPV'
          '203'  = 'WPPT'
          '204'  = 'WPSA'
          '205'  = 'WPUN'
          '206'  = 'WPMM'
          '207'  = 'WPER'
          '208'  = 'WPGA'
          '209'  = 'WP55'
          '210'  = 'WP2'
          '211'  = 'WJF'
          '213'  = 'WSDA'
          '250'  = 'WTC'
          '255'  = 'WPB'
          '260'  = 'WSA'
          '263'  = 'W11'
          '270'  = 'WMNZ'
          '271'  = 'WMUK'
          '272'  = 'WMOZ'
          '273'  = 'OSP'
          '275'  = 'UKPN'
          '280'  = 'SAD'
          '281'  = 'FSL'
          '283'  = 'WRK'
          '300'  = 'DEBT'
          '315'  = 'CAP'
          '365'  = 'SPS'    /* Sole Parent Support */
          '370'  = 'SLP'    /* Supported Living Payment */
          '425'  = 'DA'
          '440'  = 'DCA'
          '450'  = 'TAS'
          '460'  = 'SPB'
          '470'  = 'AB'
          '471'  = 'AS'
          '472'  = 'TPA'
          '473'  = 'STA'
          '474'  = 'AFHA'
          '475'  = 'TWA'
          '500'  = 'WKB'
          '596'  = 'CA'
          '602'  = 'JSA'
          '603'  = 'YP/YPP'
          '607'  = 'JSSH'
          '609'  = 'EUB-Wkly' 
          '611'  = 'EB'
    '313','613'  = 'EMA'
          '620'  = 'SNG'
          '622'  = 'WSG'
          '623'  = 'PATH'
          '626'  = 'TTW'
          '630'  = 'CPA'
          '652'  = 'HHMB'
          '653'  = 'HHDM'
          '654'  = 'HHDS'
          '655'  = 'HHGC'
          '665'  = 'SPSO'     /* Sole Parent Support Overseas */
    '366','666'  = 'DPB-WA'
          '675'  = 'JS'       /* Job Seeker */ 
          '700'  = 'CGM'
          '710'  = 'CHO'
          '720'  = 'CPP'
          '730'  = 'CHGM'
          '740'  = 'CHHO'
          '750'  = 'CHPP'
          '760'  = 'CPSC'
          '820'  = 'RAP'
          '830'  = 'RSS'
          '831'  = 'ADV'
          '832'  = 'RA'
          '833'  = 'TIA'
          '834'  = 'TIA-Pre'
          '835'  = 'MISC'
          '836'  = 'BS'
          '837'  = 'RHS'
          '838'  = 'SPDA'
          '839'  = 'Non-ben'
          '840'  = 'Civ-Def'
          '841'  = 'HEALTH'
          '842'  = 'BFTD'
          '843'  = 'PRH'
          '850'  = 'VPLS'
          '930'  = 'RRS'
          '931'  = 'PCR'
          '932'  = 'IRRHNZ'
          '933'  = 'IRRCHP'
          '944'  = 'RRU'
          '961'  = 'RRMB'
          '962'  = 'RRMU'
          '969'  = 'RRME'
          '999'  = 'Total'
          'YP '  = 'YP' 
          'YPP'  = 'YPP' 
            ' '  = 'No Bft'
          '115'  = 'UBH'
          '125'  = 'UHT'
          '320'  = 'IB'
          '330'  = 'WB'
          '367'  = 'DPB-CSI'
          '600'  = 'SB'
          '601'  = 'SBH'
          '608'  = 'UBT'
          '610'  = 'UB'
;

* Service code short names - post 12 July 2013;
  VALUE $serv
          '020'  = 'SLPO'    /* Supported Living Payment Overseas */
          '030'  = 'WBO'      /* Widows Benefit Overseas */
          '040'  = 'OB'
          '044'  = 'UCB'
          '050'  = 'TRB'
          '060'  = 'FB'
          '062'  = 'CCS'
          '064'  = 'FTC'
          '065'  = 'CDA'
          '179'  = 'Discont' 
          '180'  = 'NZS'
          '181'  = 'VP'
          '188'  = 'SLAR' 
          '190'  = 'FNGRTM'
          '191'  = 'FNGRTS'
          '192'  = 'FNGRTC'
          '193'  = 'WFG'
          '200'  = 'WPP'
          '201'  = 'WP1'
          '202'  = 'WPV'
          '203'  = 'WPPT'
          '204'  = 'WPSA'
          '205'  = 'WPUN'
          '206'  = 'WPMM'
          '207'  = 'WPER'
          '208'  = 'WPGA'
          '209'  = 'WP55'
          '210'  = 'WP2'
          '211'  = 'WJF'
          '213'  = 'WSDA'
          '250'  = 'WTC'
          '255'  = 'WPB'
          '260'  = 'WSA'
          '263'  = 'W11'
          '270'  = 'WMNZ'
          '271'  = 'WMUK'
          '272'  = 'WMOZ'
          '273'  = 'OSP'
          '275'  = 'UKPN'
          '280'  = 'SAD'
          '281'  = 'FSL'
          '283'  = 'WRK'
          '300'  = 'DEBT' 
          '313'  = 'EMA'
          '315'  = 'CAP'
          '340'  = 'OB-1'
          '344'  = 'UCB-1'
          '350'  = 'TRB-1'
          '365'  = 'SPS'      /* Sole Parent Support */
          '366'  = 'DPBWA-1'
          '370'  = 'SLP'    /* Supported Living Payment */
          '425'  = 'DA'
          '440'  = 'DCA'
          '450'  = 'TAS'
          '460'  = 'SPB'
          '470'  = 'AB'
          '471'  = 'AS'
          '472'  = 'TPA'
          '473'  = 'STA'
          '474'  = 'AFHA'
          '500'  = 'WKB'
          '596'  = 'CA'
          '602'  = 'JSA'
          '603'  = 'YP/YPP'
          '607'  = 'JSSH'     /* Job Search Student Hardship */
          '609'  = 'EUB-Wkly'
          '611'  = 'EB'
          '613'  = 'EMA'
          '620'  = 'SNG'
          '622'  = 'WSG'
          '623'  = 'PATH'
          '626'  = 'TTW'
          '630'  = 'CPA'
          '652'  = 'HHMB'
          '653'  = 'HHDM'
          '654'  = 'HHDS'
          '655'  = 'HHGC'
          '665'  = 'SPSO'     /*Sole Parent Support Overseas*/
          '666'  = 'DPBWA' 
          '675'  = 'JS'       /* Job Seeker */
          '700'  = 'CGM'
          '710'  = 'CHO'
          '720'  = 'CPP'
          '730'  = 'CHGM'
          '740'  = 'CHHO'
          '750'  = 'CHPP'
          '760'  = 'CPSC'
          '820'  = 'RAP'
          '830'  = 'RSS'
          '831'  = 'ADV'
          '832'  = 'RA'
          '833'  = 'TIA'
          '834'  = 'TIA-Pre'
          '835'  = 'MISC'
          '836'  = 'BS'
          '837'  = 'RHS'
          '838'  = 'SPDA'
          '839'  = 'Non-ben'
          '840'  = 'Civ-Def'
          '841'  = 'HEALTH'
          '842'  = 'BFTD'
          '843'  = 'PRH'
          '850'  = 'VPLS'
          '930'  = 'RRS'
          '931'  = 'PCR'
          '932'  = 'IRRHNZ'
          '933'  = 'IRRCHP'
          '944'  = 'RRU'
          '961'  = 'RRMB'
          '962'  = 'RRMU'
          '969'  = 'RRME'
          '999'  = 'Total'
          'YP '  = 'YP' 
          'YPP'  = 'YPP' 
            ' '  = 'No Bft'
          '115'  = 'UBH'
          '125'  = 'UHT'
          '320'  = 'IB-1'
          '330'  = 'WB-1'
          '367'  = 'DPBCSI-1'
          '600'  = 'SB'
          '601'  = 'SBH'
          '608'  = 'UBT'
          '610'  = 'UB'
;

*******************************************************************;
******   Second format group: Current, long names                  ;
******          - Benefit group:  $bengp                           ;
******          - Benefit:     :  $ben                             ;
******          - Service code:   $srvcd                           ;
*******************************************************************;

** Benefit group format - for high level grouping - Post July 2013 **;
** long names.                                                     **;
  VALUE $bengp
    '020','370'       = "Supported Living Payments related"
    '030'             = "Widow's Benefit Overseas"
    '040','044','340','344'
                      = "Orphan's and Unsupported Child's benefits"
    '050','350','180','181'
      ="New Zealand Superannuation and Veteran's and Transitional Retirement Benefit"
    '313'             = "Emergency Maintenance Allowance"
    '365'             = "Sole Parent Support"
    '607'             = "Job Seeker Student Hardship"
    '611'             = "Emergency Benefit"
    '665'             = "Sole Parent Support Overseas"
    '675'             = "Job Seeker related"
    '839','275'       = "Non Beneficiary"
    'YP ','YPP','603' = "Youth Payment and Young Parent Payment"
    ' '               = "No Benefit"
    '115','610'       = "Unemployment Benefit related"
    '125','608'       = "Unemployment Benefit Training related"
    '320'             = "Invalids Benefit"
    '330'             = "Widows Benefit"
    '367'             = "Domestic Purposes Benefit related"
    '600','601'       = "Sickness Benefit related"
;


** Benefit codes - Post 12 July 2013, long names. **;
 VALUE $ben
    '020'        = "Supported Living Payment Overseas"
    '030'        = "Widow's Benefit Overseas"
    '040','340'  = "Orphan's Benefit"
    '044','344'  = "Unsupported Child's Benefit"
    '050','350'  = "Transitional Retirement Benefit"
          '060'  = "Family Benefit"
          '062'  = "Child Care Subsidy"
          '064'  = "Family Tax Credit"
          '065'  = "Child Disability Allowance"
          '180'  = "New Zealand Superannuation"
          '180.2'= "NZ Super. - non qual. spouse"
          '181'  = "Veteran's Pension"
          '181.2'= "Veteran's Pension - non qual. spouse"
          '188'  = "Single Living Alone Rate"
          '190'  = "Funeral Grant - Married"
          '191'  = "Funeral Grant - Single"
          '192'  = "Funeral Grant - Child"
          '193'  = "War Funeral Grant"
          '200'  = "Police"
          '201'  = "1914/18 War"
          '202'  = "Vietnam"
          '203'  = "Peace Time Armed Forces"
          '204'  = "Special Annuity (Service to Society)"
          '205'  = "UN Armed Forces"
          '206'  = "Mercantile Marine"
          '207'  = "Emergency Reserve Corp"
          '208'  = "Gallantry Award"
          '209'  = "Pension Under Section 55"
          '210'  = "1939/45 War"
          '211'  = "J-Force"
          '213'  = "War Servicemens Dependants Allowance"
          '250'  = "War Travel Concessions"
          '255'  = "War Bursaries"
          '260'  = "War Surgical Appliances"
          '263'  = "War 2 Assessment"
          '270'  = "War Medical Treatment - NZ Pensioner"
          '271'  = "War Medical Treatment - UK Pensioner"
          '272'  = "War Medical Treatment - AUS Pensioner"
          '273'  = "Overseas Pension"
          '275'  = "United Kingdom Pension - Non Pensioner"
          '280'  = "Student Allowance Debt"
          '281'  = "Fraudulent Student Loan"
          '283'  = "WINZ Work Debt"
          '365'  = "Sole Parent Support"
          '370'  = "Supported Living Payment"
          '425'  = "Disability Allowance"
          '440'  = "Disabled Civilian Amputee"
          '450'  = "Temporary Additional Support"
          '460'  = "Special Benefit"
          '470'  = "Accommodation Benefit"
          '471'  = "Accommodation Supplement"
          '472'  = "Tenure Protection Allowance"
          '473'  = "Special Transfer Allowance"
          '474'  = "Away From Home Allowance"
          '475'  = "Transition To Work Allowance"
          '500'  = 'Work Bonus'
          '596'  = "Clothing Allowance"
          '602'  = "Job Search Allowance"
          '603'  = "Youth/Young Parent Payment"
          '607'  = "Job Seeker Student Hardship"
          '609'  = "Emergency Unemployment Benefit - Weekly"
          '611'  = "Emergency Benefit"
    '313','613'  = "Emergency Maintenance Allowance"
          '620'  = "Special Needs Grants"
          '622'  = "Work Start Grant"
          '623'  = "Pathways Payment"
          '626'  = "Transition to Work Grant"
          '630'  = "Course Participation Assistance"
          '652'  = "Home Help - Multiple Births"
          '653'  = "Home Help - Domestic Emergency"
          '654'  = "Home Help - Families needing Dom. Serv. "
          '655'  = "Home Help - Family Group Conference"
          '665'  = "Sole Parent Support Overseas"
    '366','666'  = "DPB Woman Alone"
          '675'  = "Job Seeker"
          '700'  = "CSC Reimbursement - General Medical"
          '710'  = "CSC Reimbursement - Hospital Outpatient"
          '720'  = "CSC Reimbursement - Pharmaceutical Prescription"
          '730'  = "High Health User - General Medical"
          '740'  = "High Health User - Hospital Outpatient"
          '750'  = "High Health User - Pharmaceutical Prescription"
          '760'  = "Prescription Subsidy Card"
          '820'  = "Recoverable Assistance Payment"
          '830'  = "Residential Support Service"
          '831'  = "Advance of Benefit"
          '832'  = "Relocation Allowance"
          '833'  = "Training Incentive Allowance"
          '834'  = "Pre-enrolment Fee"
          '835'  = "Miscellaneous Subsidy"
          '836'  = "Blind Subsidy"
          '837'  = "Rest Home Subsidy"
          '838'  = "Special Disability Allowance"
          '839'  = "Non Beneficiary"
          '840'  = "Civil Defence"
          '841'  = "Health Subsidy"
          '842'  = "Benefit Due"
          '843'  = "Partner In Rest Home"
          '850'  = "Veterans Pension Lump Sum Pymt on Death"
          '930'  = "SWIFTT Excess/Non-Current Debt Refund"
          '931'  = "Payment Card Refund"
          '932'  = "Income Related Rent HNZ"
          '933'  = "Income Related Rent CHP"
          '944'  = "Unidentified Receipt Refund"
          '961'  = "Maintenance Refunds - Bank A/C Unknown"
          '962'  = "Maintenance Refunds - Payer Reassessments"
          '969'  = "Maintenance Refunds - Receipt Excess"
          'YP '  = "Youth Payment" 
          'YPP'  = "Young Parent Payment" 
          ' '    = "No Benefit"
          '115'  = "Unemployment Benefit Hardship"
          '125'  = "Unemployment Benefit Hardship Training"
          '320'  = "Invalids Benefit"
          '330'  = "Widows Benefit"
          '367'  = "DPB Caring for Sick or Infirm"
          '600'  = "Sickness Benefit"
          '601'  = "Sickness Benefit Hardship"
          '608'  = "Unemployment Benefit Training"
          '610'  = "Unemployment Benefit"
;

** Service codes - Post 12 July 2013, long names. **;
 VALUE $srvcd
          '020'  = "Supported Living Payment Overseas"
          '030'  = "Widow's Benefit Overseas"
          '040'  = "Orphan's Benefit"
          '044'  = "Unsupported Child's Benefit"
          '050'  = "Transitional Retirement Benefit"
          '060'  = "Family Benefit"
          '062'  = "Child Care Subsidy"
          '064'  = "Family Tax Cedit"
          '065'  = "Child Disability Allowance"
          '180'  = "New Zealand Superannuation"
          '180.2'= "NZ Super. - non qual. spouse"
          '181'  = "Veteran's Pension"
          '181.2'= "Veteran's Pension - non qual. spouse"
          '188'  = "Single Living Alone Rate"
          '190'  = "Funeral Grant - Married"
          '191'  = "Funeral Grant - Single"
          '192'  = "Funeral Grant - Child"
          '193'  = "War Funeral Grant"
          '200'  = "Police"
          '201'  = "1914/18 War"
          '202'  = "Vietnam"
          '203'  = "Peace Time Armed Forces"
          '204'  = "Special Annuity (Service to Society)"
          '205'  = "UN Armed Forces"
          '206'  = "Mercantile Marine"
          '207'  = "Emergency Reserve Corp"
          '208'  = "Gallantry Award"
          '209'  = "Pension Under Section 55"
          '210'  = "1939/45 War"
          '211'  = "J-Force"
          '213'  = "War Servicemens Dependants Allowance"
          '250'  = "War Travel Concessions"
          '255'  = "War Bursaries"
          '260'  = "War Surgical Appliances"
          '263'  = "War 11 Assessment"
          '270'  = "War Medical Treatment - NZ Pensioner"
          '271'  = "War Medical Treatment - UK Pensioner"
          '272'  = "War Medical Treatment - AUS Pensioner"
          '273'  = "Overseas Pension"
          '275'  = "United Kingdom Pension - Non Pensioner"
          '280'  = "Student Allowance Debt"
          '281'  = "Fraudulent Student Loan"
          '283'  = "WINZ Work Debt"
          '313'  = "Emergency Maintenance Allowance-1"
          '315'  = "Family Capitalisation"
          '344'  = "Unsupported Child's Benefit-1"
          '340'  = "Orphan's Benefit-1"
          '350'  = "Transitional Retirement Benefit-1"
          '365'  = "Sole Parent Support"
          '366'  = "DPB Woman Alone-1"
          '370'  = "Supported Living Payment"
          '425'  = "Disability Allowance"
          '440'  = "Disabled Civilian Amputee"
          '450'  = "Temporary Additional Support"
          '460'  = "Special Benefit"
          '470'  = "Accommodation Benefit"
          '471'  = "Accommodation Supplement"
          '472'  = "Tenure Protection Allowance"
          '473'  = "Special Transfer Allowance"
          '474'  = "Away From Home Allowance"
          '475'  = "Transition To Work Allowance"
          '500'  = "Work Bonus"
          '596'  = "Clothing Allowance"
          '602'  = "Job Search Allowance"
          '603'  = "Youth/Young Parent Payment"
          '607'  = "Job Seeker Student Hardship"
          '609'  = "Emergency Unemployment Benefit - Weekly"
          '611'  = "Emergency Benefit"
          '613'  = "Emergency Maintenance Allowance"
          '620'  = "Special Needs Grant"
          '622'  = "Work Start Grant"
          '623'  = "Pathways Payment"
          '626'  = "Transition to Work Grant"
          '630'  = "Course Participation Assistance"
          '652'  = "Home Help - Multiple Births"
          '653'  = "Home Help - Domestic Emergency"
          '654'  = "Home Help - Families needing Dom. Supp."
          '655'  = "Home Help - Family Group Conference"
          '665'  = "Sole Parent Support Overseas"
          '666'  = "DPB Woman Alone"
          '675'  = "Job Seeker"
          '700'  = "CSC Reimbursement - General Medical"
          '710'  = "CSC Reimbursement - Hospital Outpatient"
          '720'  = "CSC Reimbursement - Pharmaceutical Prescription"
          '730'  = "High Health User - General Medical"
          '740'  = "High Health User - Hospital Outpatient"
          '750'  = "High Health User - Pharmaceutical Prescription"
          '760'  = "Prescription Subsidy Card"
          '820'  = "Recoverable Assistance Payment"
          '830'  = "Residential Support Service"
          '831'  = "Advance of Benefit"
          '832'  = "Relocation Allowance"
          '833'  = "Training Incentive Allowance"
          '834'  = "Pre-enrolment Fee"
          '835'  = "Miscellaneous Subsidy"
          '836'  = "Blind Subsidy"
          '837'  = "Rest Home Subsidy"
          '838'  = "Special Disability Allowance"
          '839'  = "Non Beneficiary"
          '840'  = "Civil Defence Payment"
          '841'  = "Health Subsidy"
          '842'  = "Benefit Due Payment"
          '843'  = "Partner in Rest Home"
          '850'  = "Veterans Pension Lump Sum Payment On Death"
          '930'  = "SWIFTT Excess/Non-Current Debt Refund"
          '931'  = "Payment Card Refund"
          '932'  = "Income Related Rent HNZ"
          '933'  = "Income Related Rent CHP"
          '944'  = "Unidentified Receipt Refund"
          '961'  = "Maintenance Refunds - Bank A/C Unknown"
          '962'  = "Maintenance Refunds - Payer Reassessments"
          '969'  = "Maintenance Refunds - Receipt Excess"
          'YP '  = "Youth Payment" 
          'YPP'  = "Young Parent Payment" 
          ' '    = "No Benefit"
          '115'  = "Unemployment Benefit Hardship"
          '125'  = "Unemployment Benefit Hardship Training"
          '320'  = "Invalids Benefit-Weekly"
          '330'  = "Widows Benefit-Weekly"
          '367'  = "DPB Caring for Sick or Infirm-Weekly"
          '600'  = "Sickness Benefit"
          '601'  = "Sickness Benefit Hardship"
          '608'  = "Unemployment Benefit Training"
          '610'  = "Unemployment Benefit"
;

******************************************************************;
***    SECOND BATCH - 1 July 2001 - 12 July 2013 FORMATS    ******;
******************************************************************;

******************************************************************;
******   Third format group: 1 July 2001 - 14 July 2013, short names;
******          - Benefit group:  $bftgp                          ;
******          - Working Age Benefit Group: $swiftt_working_age_group_short ;
******          - Benefit:     :  $bft                            ;
******          - Service code:   $serv                           ;
******************************************************************;

* Benefit group format - 1 July 2001 - 12 July 2013, for high level grouping;
  VALUE $bftgp_pre2013wr
    '020','320'            = 'IB'
    '030','330'            = 'WB'
    '040','044','340','344'= 'OB UCB'
    '050','350','180','181'= 'NZS VP TRB'
    '115','604','605','610'= 'UB related'
    '125','608'            = 'UBT related'
    '313','613','365','665','366','666','367','667'='DPB related'
    '600','601'            = 'SB related'
    '602','603'            = 'JSA IYB'
    '607'                  = 'UHS'
    '609','611'            = 'EB'
    '839','275'            = 'Non Ben'
    'YP ','YPP'            = 'YP/YPP' 
    ' '                    = 'No Bft'
 ;

* Benefit group for working age people on benefit, for high level grouping, short names;
  VALUE $swiftt_working_age_group_short
    '020','320'            = 'IB'
    '030','330'            = 'WB'
    '050','350'            = 'TRB'
    '115','604','605','610'= 'UB related'
    '125','608'            = 'UBT related'
    '313','613','365','665','366','666','367','667'='DPB related'
    '600','601'            = 'SB related'
    '602','603'            = 'JSA IYB'
    '607'                  = 'UHS'
    '609','611'            = 'EB'
    'YP ','YPP'            = 'YP/YPP' 
       other               = 'Not WA Bft'
 ;


* New format including community wage benefits - 1 July 2001 - 12 July 2013, short version;
  VALUE $bft_pre2013wr
    '020','320'  = 'IB'
    '030','330'  = 'WB'
    '040','340'  = 'OB'
    '044','344'  = 'UCB'
    '050','350'  = 'TRB'
          '060'  = 'FB'            /* Not in manual                  */
          '062'  = 'CCS'
          '064'  = 'FTC'
          '065'  = 'CDA'
          '115'  = 'UBH'           /* Unemployment Benefit Hardship */
          '125'  = 'UHT'           /* Unemployment Benefit Hardship (in Training) */
          '179'  = 'Discont'       /* Not in manual                  */
          '180'  = 'NZS'
          '181'  = 'VP'
          '188'  = 'LAP'           /* Not in manual                  */
          '190'  = '61DB'
          '191'  = '61DC'
          '192'  = '61DD'
          '193'  = 'WFG'
          '200'  = 'WPP'
          '201'  = 'WP1'
          '202'  = 'WPV'
          '203'  = 'WPPT'
          '204'  = 'WPSA'
          '205'  = 'WPUN'
          '206'  = 'WPMM'
          '207'  = 'WPER'
          '208'  = 'WPGA'
          '209'  = 'WP55'
          '210'  = 'WP2'
          '211'  = 'WJF'
          '213'  = 'WSDA'
          '250'  = 'WTC'
          '255'  = 'WPB'
          '260'  = 'WSA'
          '263'  = 'W11'
          '270'  = 'WMNZ'
          '271'  = 'WMUK'
          '272'  = 'WMOZ'
          '273'  = 'UKP'
          '275'  = 'UKPN'
          '300'  = 'DEBT'            /* Not in manual                  */
          '315'  = 'CAP'
          '425'  = 'DA'
          '440'  = 'DCA'
          '450'  = 'TAS'
          '460'  = 'SPB'
          '470'  = 'AB'
          '471'  = 'AS'
          '472'  = 'TPA'
          '473'  = 'STA'
          '474'  = 'AFHA'
          '475'  = 'TWA'
          '596'  = 'CA'
          '600'  = 'SB'
          '601'  = 'SBH'
          '602'  = 'JSA'
          '603'  = 'IYB'
'604','605','610'  = 'UB'
          '607'  = 'UHS'                    /* Manual lists as EUB            */
          '608'  = 'UBT'
          '609'  = 'EUB-Wkly'       /* Not in manual                  */
          '611'  = 'EB'
    '313','613'  = 'EMA'
          '620'  = 'SNG'
          '622'  = 'JSG'
          '623'  = 'PATH'
          '626'  = 'TTW'
          '630'  = 'CPA'
          '652'  = 'HHMB'
          '653'  = 'HHDM'
          '654'  = 'HHDS'
          '655'  = 'HHGC'
    '365','665'  = 'DPB-SP'
    '366','666'  = 'DPB-WA'        /* No short code listed in manual */
    '367','667'  = 'DPB-CSI'       /* No short code listed in manual */
          '700'  = 'CGM'
          '710'  = 'CHO'
          '720'  = 'CPP'
          '730'  = 'CHGM'
          '740'  = 'CHHO'
          '750'  = 'CHPP'
          '760'  = 'CPSC'
          '820'  = 'RAP'
          '830'  = 'RSS'
          '831'  = 'ADV'
          '832'  = 'RA'
          '833'  = 'TIA'
          '834'  = 'TIA-Pre'       /* No short code listed in manual */
          '835'  = 'MISC'          /* No short code listed in manual */
          '836'  = 'BS'
          '837'  = 'RHS'           /* Not in manual                  */
          '838'  = 'SPDA'
          '839'  = 'Non-ben'       /* No short code listed in manual */
          '840'  = 'Civ-Def'       /* No short code listed in manual */
          '841'  = 'HEALTH'
          '842'  = 'BFTD'
          '843'  = 'PRH'
          '850'  = 'VPLS'
          '930'  = 'RRS'
          '944'  = 'RRU'
          '961'  = 'RRMB'
          '962'  = 'RRMU'
          '969'  = 'RRME'
          '999'  = 'Total'        /* Not in manual                  */
          'YP '  = 'YP' 
          'YPP'  = 'YPP' 
            ' '  = 'No Bft';

* Service code short names - 1 July 2001 - 12 July 2013;
  VALUE $serv_pre2013wr
          '020'  = 'IB'
          '030'  = 'WB'
          '040'  = 'OB'
          '044'  = 'UCB'
          '050'  = 'TRB'
          '060'  = 'FB'            /* Not in manual                  */
          '062'  = 'CCS'
          '064'  = 'FTC'
          '065'  = 'CDA'
          '115'  = 'UBH'           /* Unemployment Benefit Hardship */
          '125'  = 'UHT'           /* Unemployment Benefit Hardship (in Training) */
          '179'  = 'Discont'       /* Not in manual                  */
          '180'  = 'NZS'
          '181'  = 'VP'
          '188'  = 'LAP'           /* Not in manual                  */
          '190'  = '61DB'
          '191'  = '61DC'
          '192'  = '61DD'
          '193'  = 'WFG'
          '200'  = 'WPP'
          '201'  = 'WP1'
          '202'  = 'WPV'
          '203'  = 'WPPT'
          '204'  = 'WPSA'
          '205'  = 'WPUN'
          '206'  = 'WPMM'
          '207'  = 'WPER'
          '208'  = 'WPGA'
          '209'  = 'WP55'
          '210'  = 'WP2'
          '211'  = 'WJF'
          '213'  = 'WSDA'
          '250'  = 'WTC'
          '255'  = 'WPB'
          '260'  = 'WSA'
          '263'  = 'W11'
          '270'  = 'WMNZ'
          '271'  = 'WMUK'
          '272'  = 'WMOZ'
          '273'  = 'UKP'
          '275'  = 'UKPN'
          '300'  = 'DEBT'            /* Not in manual                  */
          '313'  = 'EMA-1'
          '315'  = 'CAP'
          '320'  = 'IB-1'
          '330'  = 'WB-1'
          '340'  = 'OB-1'
          '344'  = 'UCB-1'
          '350'  = 'TRB-1'
          '365'  = 'DPBSP-1'
          '366'  = 'DPBWA-1'        /* No short code listed in manual */
          '367'  = 'DPBCSI-1'       /* No short code listed in manual */
          '425'  = 'DA'
          '440'  = 'DCA'
          '450'  = 'TAS'
          '460'  = 'SPB'
          '470'  = 'AB'
          '471'  = 'AS'
          '472'  = 'TPA'
          '473'  = 'STA'
          '474'  = 'AFHA'
          '475'  = 'TWA'
          '596'  = 'CA'
          '600'  = 'SB'
          '601'  = 'SBH'
          '602'  = 'JSA'
          '603'  = 'IYB'
          '604'  = 'CW-YJSA'
          '605'  = 'CW-55+'
          '607'  = 'UHS'            /* Manual lists as EUB            */
          '608'  = 'UBT'
          '609'  = 'EUB-Wkly'       /* Not in manual                  */
          '610'  = 'UB'
          '611'  = 'EB'
          '613'  = 'EMA'
          '620'  = 'SNG'
          '622'  = 'JSG'
          '623'  = 'PATH'
          '626'  = 'TTW'
          '630'  = 'CPA'
          '652'  = 'HHMB'
          '653'  = 'HHDM'
          '654'  = 'HHDS'
          '655'  = 'HHGC'
          '665'  = 'DPBSP'
          '666'  = 'DPBWA'        /* No short code listed in manual */
          '667'  = 'DPBCSI'       /* No short code listed in manual */
          '700'  = 'CGM'
          '710'  = 'CHO'
          '720'  = 'CPP'
          '730'  = 'CHGM'
          '740'  = 'CHHO'
          '750'  = 'CHPP'
          '760'  = 'CPSC'
          '820'  = 'RAP'
          '830'  = 'RSS'
          '831'  = 'ADV'
          '832'  = 'RA'
          '833'  = 'TIA'
          '834'  = 'TIA-Pre'       /* No short code listed in manual */
          '835'  = 'MISC'          /* No short code listed in manual */
          '836'  = 'BS'
          '837'  = 'RHS'           /* Not in manual                  */
          '838'  = 'SPDA'
          '839'  = 'Non-ben'       /* No short code listed in manual */
          '840'  = 'Civ-Def'       /* No short code listed in manual */
          '841'  = 'HEALTH'
          '842'  = 'BFTD'
          '843'  = 'PRH'
          '850'  = 'VPLS'
          '930'  = 'RRS'
          '944'  = 'RRU'
          '961'  = 'RRMB'
          '962'  = 'RRMU'
          '969'  = 'RRME'
          '999'  = 'Total'        /* Not in manual                  */
          'YP '  = 'YP' 
          'YPP'  = 'YPP' 
            ' '  = 'No Bft';

*******************************************************************;
******   Forth format group: 1 July 2001 - 12 July 2013, long names;
******          - Benefit group:  $bengp                           ;
******          - Working Age Benefit Group: $swiftt_working_age_group_long ;
******          - Benefit:     :  $ben                             ;
******          - Service code:   $srvcd                           ;
*******************************************************************;

** Benefit group format - for high level grouping - 1 July 2001 - 12 July 2013, long names. **;
  VALUE $bengp_pre2013wr
    '020','320' = "Invalid's Benefit"
    '030','330' = "Widow's Benefit"
    '040','044','340','344'
                = "Orphan's and Unsupported Child's benefits"
    '050','350','180','181'
    = "New Zealand Superannuation and Veteran's and Transitional Retirement Benefit"
    '115','604','605','610'
                = "Unemployment Benefit and Unemployment Benefit Hardship"
    '125','608' = "Unemployment Benefit (in Training) and Unemployment Benefit Hardship (in Training)"
    '313','613','365','665','366','666','367','667'
                = "Domestic Purposes related benefits"
    '600','601' = "Sickness Benefit and Sickness Benefit Hardship"
    '602','603' = "Job Search Allowance and Independant Youth Benefit"
    '607'       = "Unemployment Benefit Student Hardship"
    '609','611' = "Emergency Benefit"
    '839','275' = "Non Beneficiary"
    'YP ','YPP' = "Youth Payment and Young Parent Payment"
        ' '     = "No Benefit"
 ;


** Benefit group for working age people on benefit, for high level grouping, long names. **;
  VALUE $swiftt_working_age_group_long
    '020','320' = "Invalid's Benefit"
    '030','330' = "Widow's Benefit"
    '050','350' = "Transitional Retirement Benefit"
    '115','604','605','610'
                = "Unemployment Benefit and Unemployment Benefit Hardship"
    '125','608' = "Unemployment Benefit (in Training) and Unemployment Benefit Hardship (in Training)"
    '313','613','365','665','366','666','367','667'
                = "Domestic Purposes related benefits"
    '600','601' = "Sickness Benefit and Sickness Benefit Hardship"
    '602','603' = "Job Search Allowance and Independant Youth Benefit"
    '607'       = "Unemployment Benefit Student Hardship"
    '609','611' = "Emergency Benefit"
    'YP ','YPP' = "Youth Payment and Young Parent Payment"
        other   = "Not a Working Age Benefit"
 ;


* Benefit codes - 1 July 2001 - 12 July 2013, long names ;
 VALUE $ben_pre2013wr
    '020','320'  = "Invalid's Benefit"
    '030','330'  = "Widow's Benefit"
    '040','340'  = "Orphan's Benefit"
    '044','344'  = "Unsupported Child's Benefit"
    '050','350'  = "Transitional Retirement Benefit"
          '060'  = "Family Benefit"
          '062'  = "Child Care Subsidy"
          '064'  = "Family Tax Credit"
          '065'  = "Child Disability Allowance"
          '115'  = "Unemployment Benefit Hardship"
          '125'  = "Unemployment Benefit Hardship (in Training)"
          '180'  = "New Zealand Superannuation"
          '180.2'= "NZ Super. - non qual. spouse"
          '181'  = "Veteran's Pension"
          '181.2'= "Veteran's Pension - non qual. spouse"
          '188'  = "Living Alone Payment"
          '190'  = "Funeral Grant - Married"
          '191'  = "Funeral Grant - Single"
          '192'  = "Funeral Grant - Child"
          '193'  = "War Funeral Grant"
          '200'  = "Police"
          '201'  = "1914/18 War"
          '202'  = "Vietnam"
          '203'  = "Peace Time Armed Forces"
          '204'  = "Special Annuity (Service to Society)"
          '205'  = "UN Armed Forces"
          '206'  = "Mercantile Marine"
          '207'  = "Emergency Reserve Corp"
          '208'  = "Gallantry Award"
          '209'  = "Pension Under Section 55"
          '210'  = "1939/45 War"
          '211'  = "J-Force"           '213'  ="War Servicemens Dependants Allowance"
          '250'  = "War Travel Concessions"
          '255'  = "War Bursaries"
          '260'  = "War Surgical Appliances"
          '263'  = "War 2 Assessment"
          '270'  = "War Medical Treatment - NZ Pensioner"
          '271'  = "War Medical Treatment - UK Pensioner"
          '272'  = "War Medical Treatment - AUS Pensioner"
          '273'  = "United Kingdom Pension"
          '274'  = "United Kingdom Pension - Non Pensioner"
          '425'  = "Disability Allowance"
          '440'  = "Disabled Civilian Amputee"
          '450'  = "Temporary Additional Support"
          '460'  = "Special Benefit"
          '470'  = "Accommodation Benefit"
          '471'  = "Accommodation Supplement"
          '472'  = "Tenure Protection Allowance"
          '473'  = "Special Transfer Allowance"
          '474'  = "Away From Home Allowance"
          '475'  = "Transition To Work Allowance"
          '596'  = "Clothing Allowance"
          '600'  = "Sickness Benefit"
          '601'  = "Sickness Benefit Hardship"
          '602'  = "Job Search Allowance"
          '603'  = "Independent Youth Benefit"
'604','605','610'= "Unemployment Benefit"
          '607'  = "Unemployment Benefit Student Hardship"
          '608'  = "Unemployment Benefit (in Training)"
          '609'  = "Emergency Unemployment Benefit - Weekly"
          '611'  = "Emergency Benefit"
    '313','613'  = "Emergency Maintenance Allowance"
          '620'  = "Special Needs Grants"
          '622'  = "Job Start Grant"
          '623'  = "Pathways Payment"
          '626'  = "Transition to Work Grant"
          '630'  = "Course Participation Assistance"
          '652'  = "Home Help - Multiple Births"
          '653'  = "Home Help - Domestic Emergency"
          '654'  = "Home Help - Families needing Dom. Serv. "
          '655'  = "Home Help - Family Group Conference"
    '365','665'  = "DPB Sole Parent"
    '366','666'  = "DPB Woman Alone"
    '367','667'  = "DPB Caring for Sick or Infirm"
          '700'  = "CSC Reimbursement - General Medical"
          '710'  = "CSC Reimbursement - Hospital Outpatient"
          '720'  = "CSC Reimbursement - Pharmaceutical Prescription"
          '730'  = "High Health User - General Medical"
          '740'  = "High Health User - Hospital Outpatient"
          '750'  = "High Health User - Pharmaceutical Prescription"
          '760'  = "Prescription Subsidy Card"
          '820'  = "Recoverable Assistance Payment"
          '830'  = "Residential Support Service"
          '831'  = "Advance of Benefit"
          '832'  = "Relocation Allowance"
          '833'  = "Training Incentive Allowance"
          '834'  = "Pre-enrolment Fee"
          '835'  = "Miscellaneous Subsidy"
          '836'  = "Blind Subsidy"
          '837'  = "Rest Home Subsidy"
          '838'  = "Special Disability Allowance"
          '839'  = "Non Beneficiary"
          '840'  = "Civil Defence"
          '841'  = "Health Subsidy"
          '842'  = "Benefit Due"
          '843'  = "Partner In Rest Home"
          '850'  = "Veterans Pension Lump Sum Pymt on Death"
          '930'  = "SWIFTT Excess/Non-Current Debt Refund"
          '944'  = "Unidentified Receipt Refund"
          '961'  = "Maintenance Refunds - Bank A/C Unknown"
          '962'  = "Maintenance Refunds - Payer Reassessments"
          '969'  = "Maintenance Refunds - Receipt Excess"
          'YP '  = "Youth Payment" 
          'YPP'  = "Young Parent Payment" 
          ' '    = "No Benefit"
  ;

* Service codes - 1 July 2001 - 12 July 2013, long names ;
 VALUE $srvcd_pre2013wr
          '020'  = "Invalid's Benefit"
          '030'  = "Widow's Benefit"
          '040'  = "Orphan's Benefit"
          '044'  = "Unsupported Child's Benefit"
          '050'  = "Transitional Retirement Benefit"
          '060'  = "Family Benefit"
          '062'  = "Child Care Subsidy"
          '064'  = "Family Tax Cedit"
          '065'  = "Child Disability Allowance"
          '115'  = "Unemployment Benefit Hardship"
          '125'  = "Unemployment Benefit Hardship (in Training)"
          '180'  = "New Zealand Superannuation"
          '180.2'= "NZ Super. - non qual. spouse"
          '181'  = "Veteran's Pension"
          '181.2'= "Veteran's Pension - non qual. spouse"
          '188'  = "Living Alone Payment"
          '190'  = "Funeral Grant - Married"
          '191'  = "Funeral Grant - Single"
          '192'  = "Funeral Grant - Child"
          '193'  = "War Funeral Grant"
          '200'  = "Police"
          '201'  = "1914/18 War"
          '202'  = "Vietnam"
          '203'  = "Peace Time Armed Forces"
          '204'  = "Special Annuity (Service to Society)"
          '205'  = "UN Armed Forces"
          '206'  = "Mercantile Marine"
          '207'  = "Emergency Reserve Corp"
          '208'  = "Gallantry Award"
          '209'  = "Pension Under Section 55"
          '210'  = "1939/45 War"
          '211'  = "J-Force"
          '213'  = "War Servicemens Dependants Allowance"
          '250'  = "War Travel Concessions"
          '255'  = "War Bursaries"
          '260'  = "War Surgical Appliances"
          '263'  = "War 11 Assessment"
          '270'  = "War Medical Treatment - NZ Pensioner"
          '271'  = "War Medical Treatment - UK Pensioner"
          '272'  = "War Medical Treatment - AUS Pensioner"
          '273'  = "United Kingdom Pension"
          '275'  = "United Kingdom Pension - Non Pensioner"
          '313'  = "Emergency Maintenance Allowance-1"
          '315'  = "Family Capitalisation"
          '320'  = "Invalid's Benefit-1"
          '330'  = "Widow's Benefit-1"
          '344'  = "Unsupported Child's Benefit-1"
          '340'  = "Orphan's Benefit-1"
          '350'  = "Transitional Retirement Benefit-1"
          '365'  = "DPB Sole Parent-1"
          '366'  = "DPB Woman Alone-1"
          '367'  = "DPB Caring for Sick or Infirm-1"
          '425'  = "Disability Allowance"
          '440'  = "Disabled Civilian Amputee"
          '450'  = "Temporary Additional Support"
          '460'  = "Special Benefit"
          '470'  = "Accommodation Benefit"
          '471'  = "Accommodation Supplement"
          '472'  = "Tenure Protection Allowance"
          '473'  = "Special Transfer Allowance"
          '474'  = "Away From Home Allowance"
          '475'  = "Transition To Work Allowance"
          '596'  = "Clothing Allowance"
          '600'  = "Sickness Benefit"
          '601'  = "Sickness Benefit Hardship"
          '602'  = "Job Search Allowance"
          '603'  = "Independent Youth Benefit"
          '604'  = "Community Wage Job Seekers-Young"
          '605'  = "Community Wage Job Seekers-55+"
          '607'  = "Unemployment Benefit Student Hardship"
          '608'  = "Unemployment Benefit (in Training)"
          '609'  = "Emergency Unemployment Benefit - Weekly"
          '610'  = "Unemployment Benefit"
          '611'  = "Emergency Benefit"
          '613'  = "Emergency Maintenance Allowance"
          '620'  = "Special Needs Grant"
          '622'  = "Job Start Grant"
          '623'  = "Pathways Payment"
          '626'  = "Transition to Work Grant"
          '630'  = "Course Participation Assistance"
          '652'  = "Home Help - Multiple Births"
          '653'  = "Home Help - Domestic Emergency"
          '654'  = "Home Help - Families needing Dom. Supp."
          '655'  = "Home Help - Family Group Conference"
          '665'  = "DPB Sole Parent"
          '666'  = "DPB Woman Alone"
          '667'  = "DPB Caring for Sick or Infirm"
          '700'  = "CSC Reimbursement - General Medical"
          '710'  = "CSC Reimbursement - Hospital Outpatient"
          '720'  = "CSC Reimbursement - Pharmaceutical Prescription"
          '730'  = "High Health User - General Medical"
          '740'  = "High Health User - Hospital Outpatient"
          '750'  = "High Health User - Pharmaceutical Prescription"
          '760'  = "Prescription Subsidy Card"
          '820'  = "Recoverable Assistance Payment"
          '830'  = "Residential Support Service"
          '831'  = "Advance of Benefit"
          '832'  = "Relocation Allowance"
          '833'  = "Training Incentive Allowance"
          '834'  = "Pre-enrolment Fee"
          '835'  = "Miscellaneous Subsidy"
          '836'  = "Blind Subsidy"
          '837'  = "Rest Home Subsidy"
          '838'  = "Special Disability Allowance"
          '839'  = "Non Beneficiary"
          '840'  = "Civil Defence Payment"
          '841'  = "Health Subsidy"
          '842'  = "Benefit Due Payment"
          '843'  = "Partner in Rest Home"
          '850'  = "Veterans Pension Lump Sum Payment On Death"
          '930'  = "SWIFTT Excess/Non-Current Debt Refund"
          '944'  = "Unidentified Receipt Refund"
          '961'  = "Maintenance Refunds - Bank A/C Unknown"
          '962'  = "Maintenance Refunds - Payer Reassessments"
          '969'  = "Maintenance Refunds - Receipt Excess"
          'YP '  = "Youth Payment" 
          'YPP'  = "Young Parent Payment" 
          ' '    = "No Benefit"
  ;
 
******************************************************************;
***    THIRD BATCH - 1Oct98 - 30Jun2001 formats            ******;
******************************************************************;

*********************************************************************;
******  Fifth format group: 1 Oct 1998 to 30 June 2001, short names  ;
******          - Benefit group:  $bftgpb                            ;
******          - Benefit:     :  $bftb                              ;
******          - Service code:   $servb                             ;
****** Note: Although YP & YPP were not available in this period they;
******       have been included here to protect programs that are    ;
******       running with old formats.                               ;
*********************************************************************;

* Benefit group format - 1 Oct 1998 to 30 June 2001, for high level grouping;
  VALUE $bftgpb
    '020','320'            = 'IB'
    '030','330'            = 'WB'
    '040','044','340','344'= 'OB UCB'
    '050','350','180','181'= 'NZS VP TRB'
    '115','604','605','610'= 'CW-JS related'
    '125','608'            = 'CW-TB related'
    '313','613','365','665','366','666','367','667'='DPB related'
    '600','601'            = 'CW-SB related'
    '602','603'            = 'JSA IYB'
    '607'                  = 'CW-ESt'
    '609','611'            = 'EB'
    '839','275'            = 'Non Ben'
    'YP ','YPP'            = 'YP/YPP'
    ' '                    = 'No Bft'

 ;

* New format including community wage benefits - 1 Oct 1998 to 30 June 2001, short version;
  VALUE $bftb
    '020','320'  = 'IB'
    '030','330'  = 'WB'
    '040','340'  = 'OB'
    '044','344'  = 'UCB'
    '050','350'  = 'TRB'
          '060'  = 'FB'            /* Not in manual                  */
          '062'  = 'CCS'
          '064'  = 'FS'
          '065'  = 'CDA'
          '115'  = 'CW-EJS'        /* Community wage emergency job seeker */
          '125'  = 'CW-ETB'           /* Community wage emergency training benefit */
          '179'  = 'Discont'       /* Not in manual                  */
          '180'  = 'NZS'
          '181'  = 'VP'
          '188'  = 'LAP'           /* Not in manual                  */
          '190'  = '61DB'
          '191'  = '61DC'
          '192'  = '61DD'
          '193'  = 'WFG'
          '200'  = 'WPP'
          '201'  = 'WP1'
          '202'  = 'WPV'
          '203'  = 'WPPT'
          '204'  = 'WPSA'
          '205'  = 'WPUN'
          '206'  = 'WPMM'
          '207'  = 'WPER'
          '208'  = 'WPGA'
          '209'  = 'WP55'
          '210'  = 'WP2'
          '211'  = 'WJF'
          '213'  = 'WSDA'
          '250'  = 'WTC'
          '255'  = 'WPB'
          '260'  = 'WSA'
          '263'  = 'W11'
          '270'  = 'WMNZ'
          '271'  = 'WMUK'
          '272'  = 'WMOZ'
          '273'  = 'UKP'
          '275'  = 'UKPN'
          '300'  = 'DEBT'            /* Not in manual                  */
          '315'  = 'CAP'
          '425'  = 'DA'
          '440'  = 'DCA'
          '460'  = 'SPB'
          '470'  = 'AB'
          '471'  = 'AS'
          '472'  = 'TPA'
          '473'  = 'STA'
          '474'  = 'AFHA'
          '475'  = 'TWA'
          '596'  = 'CA'
          '600'  = 'CW-SB'
          '601'  = 'CW-ESB'
          '602'  = 'JSA'
          '603'  = 'IYB'
'604','605','610'  = 'CW-JS'
          '607'  = 'CW-ESt'        /* Manual lists as EUB            */
          '608'  = 'CW-TB'
          '609'  = 'EUB-Wkly'       /* Not in manual                  */
          '611'  = 'EB'
    '313','613'  = 'EMA'
          '620'  = 'SNG'
          '622'  = 'JSG'
          '652'  = 'HHMB'
          '653'  = 'HHDM'
          '654'  = 'HHDS'
          '655'  = 'HHGC'
    '365','665'  = 'DPB-SP'
    '366','666'  = 'DPB-WA'        /* No short code listed in manual */
    '367','667'  = 'DPB-CSI'       /* No short code listed in manual */
          '700'  = 'CGM'
          '710'  = 'CHO'
          '720'  = 'CPP'
          '730'  = 'CHGM'
          '740'  = 'CHHO'
          '750'  = 'CHPP'
          '760'  = 'CPSC'
          '830'  = 'RSS'
          '831'  = 'ADV'
          '832'  = 'RA'
          '833'  = 'TIA'
          '834'  = 'TIA-Pre'       /* No short code listed in manual */
          '835'  = 'MISC'          /* No short code listed in manual */
          '836'  = 'BS'
          '837'  = 'RHS'           /* Not in manual                  */
          '838'  = 'SPDA'
          '839'  = 'Non-ben'       /* No short code listed in manual */
          '840'  = 'Civ-Def'       /* No short code listed in manual */
          '841'  = 'HEALTH'
          '842'  = 'BFTD'
          '843'  = 'PRH'
          '850'  = 'VPLS'
          '930'  = 'RRS'
          '944'  = 'RRU'
          '961'  = 'RRMB'
          '962'  = 'RRMU'
          '969'  = 'RRME'
          '999'  = 'Total'        /* Not in manual                  */
          'YP '  = 'YP' 
          'YPP'  = 'YPP'  
          ' '    = 'No Bft';

* Service code short names - 1 Oct 1998 to 30 June 2001;
  VALUE $servb
          '020'  = 'IB'
          '030'  = 'WB'
          '040'  = 'OB'
          '044'  = 'UCB'
          '050'  = 'TRB'
          '060'  = 'FB'            /* Not in manual                  */
          '062'  = 'CCS'
          '064'  = 'FS'
          '065'  = 'CDA'
          '115'  = 'CW-EJS'        /* Community wage emergency job seeker */
          '125'  = 'CW-ETB'           /* Community wage emergency training benefit */
          '179'  = 'Discont'       /* Not in manual                  */
          '180'  = 'NZS'
          '181'  = 'VP'
          '188'  = 'LAP'           /* Not in manual                  */
          '190'  = '61DB'
          '191'  = '61DC'
          '192'  = '61DD'
          '193'  = 'WFG'
          '200'  = 'WPP'
          '201'  = 'WP1'
          '202'  = 'WPV'
          '203'  = 'WPPT'
          '204'  = 'WPSA'
          '205'  = 'WPUN'
          '206'  = 'WPMM'
          '207'  = 'WPER'
          '208'  = 'WPGA'
          '209'  = 'WP55'
          '210'  = 'WP2'
          '211'  = 'WJF'
          '213'  = 'WSDA'
          '250'  = 'WTC'
          '255'  = 'WPB'
          '260'  = 'WSA'
          '263'  = 'W11'
          '270'  = 'WMNZ'
          '271'  = 'WMUK'
          '272'  = 'WMOZ'
          '273'  = 'UKP'
          '275'  = 'UKPN'
          '300'  = 'DEBT'            /* Not in manual                  */
          '313'  = 'EMA-1'
          '315'  = 'CAP'
          '320'  = 'IB-1'
          '330'  = 'WB-1'
          '340'  = 'OB-1'
          '344'  = 'UCB-1'
          '350'  = 'TRB-1'
          '365'  = 'DPBSP-1'
          '366'  = 'DPBWA-1'        /* No short code listed in manual */
          '367'  = 'DPBCSI-1'       /* No short code listed in manual */
          '425'  = 'DA'
          '440'  = 'DCA'
          '460'  = 'SPB'
          '470'  = 'AB'
          '471'  = 'AS' 
          '472'  = 'TPA'
          '473'  = 'STA'
          '474'  = 'AFHA'
          '475'  = 'TWA'
          '596'  = 'CA'
          '600'  = 'CW-SB'
          '601'  = 'CW-ESB'
          '602'  = 'JSA'
          '603'  = 'IYB'
          '604'  = 'CW-YJSA'
          '605'  = 'CW-55+'
          '607'  = 'CW-ESt'        /* Manual lists as EUB            */
          '608'  = 'CW-TB'
          '609'  = 'EUB-Wkly'       /* Not in manual                  */
          '610'  = 'CW-JS'
          '611'  = 'EB'
          '613'  = 'EMA'
          '620'  = 'SNG'
          '622'  = 'JSG'
          '652'  = 'HHMB'
          '653'  = 'HHDM'
          '654'  = 'HHDS'
          '655'  = 'HHGC'
          '665'  = 'DPBSP'
          '666'  = 'DPBWA'        /* No short code listed in manual */
          '667'  = 'DPBCSI'       /* No short code listed in manual */
          '700'  = 'CGM'
          '710'  = 'CHO'
          '720'  = 'CPP'
          '730'  = 'CHGM'
          '740'  = 'CHHO'
          '750'  = 'CHPP'
          '760'  = 'CPSC'
          '830'  = 'RSS'
          '831'  = 'ADV'
          '832'  = 'RA'
          '833'  = 'TIA'
          '834'  = 'TIA-Pre'       /* No short code listed in manual */
          '835'  = 'MISC'          /* No short code listed in manual */ 
          '836'  = 'BS'
          '837'  = 'RHS'           /* Not in manual                  */
          '838'  = 'SPDA'
          '839'  = 'Non-ben'       /* No short code listed in manual */
          '840'  = 'Civ-Def'       /* No short code listed in manual */
          '841'  = 'HEALTH'
          '842'  = 'BFTD'
          '843'  = 'PRH'
          '850'  = 'VPLS'
          '930'  = 'RRS'
          '944'  = 'RRU'
          '961'  = 'RRMB'
          '962'  = 'RRMU'
          '969'  = 'RRME'
          '999'  = 'Total'        /* Not in manual                  */
          'YP '  = 'YP' 
          'YPP'  = 'YPP'  
          ' '    = 'No Bft';

*********************************************************************;
******  Sixth format group: 1 Oct 1998 to 30 June 2001, long names   ;
******          - Benefit group:  $bengpb                            ;
******          - Benefit:     :  $benb                              ;
******          - Service code:   $srvcdb                            ;
****** Note: Although YP & YPP were not available in this period they;
******       have been included here to protect programs that are    ;
******       running with old formats.                               ;
*********************************************************************;

* Benefit group format - for high level grouping - 1 Oct 1998 to 30 June 2001, long names;
  VALUE $bengpb
    '020','320' = 'Invalids Benefit'
    '030','330' = 'Widows Benefit'
    '040','044','340','344'
                = 'Orphans and Unsupported Child benefits'
    '050','350','180','181'
    = 'New Zealand Superannuation and Veterans and Transitional Retirement Benefit'
    '115','604','605','610'
                = 'Community Wage Job Seeker and Emergency Job Seeker benefits'
    '125','608' = 'Community Wage Training and Emergency Training benefits'
    '313','613','365','665','366','666','367','667'
                = 'Domestic Purposes related benefits'
    '600','601' = 'Community Wage Sickness and Emergency Sickness benefits'
    '602','603' = 'Job Search Allowance and Independant Youth Benefit'
    '607'       = 'Community Wage Emergency Student'
    '609','611' = 'Emergency Benefit'
    '839','275' = 'Non Beneficiary'
    ' '         = 'No Benefit'
    'YP ','YPP' = 'Youth Payment and Young Parent Payment'
 ;

* Benefit codes - 1 Oct 1998 to 30 June 2001, long names ;
 VALUE $benb
    '020','320'  = 'Invalids Benefit'
    '030','330'  = 'Widows Benefit'
    '040','340'  = 'Orphans Benefit'
    '044','344'  = 'Unsupported Child Benefit'
    '050','350'  = 'Transitional Retirement Benefit'
          '060'  = 'Family Benefit'
          '062'  = 'Child Care Subsidy'
          '064'  = 'Family Support'
          '065'  = 'Child Disability Allowance'
          '115'  = 'Community Wage Emergency Job Seeker'
          '125'  = 'Community Wage Emergency Training'
          '180'  = 'New Zealand Superannuation'
          '180.2'= 'NZ Super. - non qual. spouse'
          '181'  = 'Veterans'
          '181.2'= 'VP - non qual. spouse'
          '188'  = 'Living Alone Payment'
          '190'  = 'Funeral Grant - Married'
          '191'  = 'Funeral Grant - Single'
          '192'  = 'Funeral Grant - Child'
          '193'  = 'War Funeral Grant'
          '200'  = 'Police'
          '201'  = '1914/18 War'
          '202'  = 'Vietnam'
          '203'  = 'Peace Time Armed Forces'
          '204'  = 'Special Annuity (Service to Society)'
          '205'  = 'UN Armed Forces'
          '206'  = 'Mercantile Marine'
          '207'  = 'Emergency Reserve Corp'
          '208'  = 'Gallantry Award'
          '209'  = 'Pension Under Section 55'
          '210'  = '1939/45 War'
          '211'  = 'J-Force'
          '213'  = 'War Servicemens Dependants Allowance'
          '250'  = 'War Travel Concessions'
          '255'  = 'War Bursaries'
          '260'  = 'War Surgical Appliances'
          '263'  = 'War 2 Assessment'
          '270'  = 'War Medical Treatment - NZ Pensioner'
          '271'  = 'War Medical Treatment - UK Pensioner'
          '272'  = 'War Medical Treatment - AUS Pensioner'
          '273'  = 'United Kingdom Pension'
          '274'  = 'United Kingdom Pension - Non Pensioner'
          '425'  = 'Disability Allowance'
          '440'  = 'Disabled Civilian Amputee'
          '460'  = 'Special Benefit'
          '470'  = 'Accommodation Benefit'
          '471'  = 'Accommodation Supplement'
          '472'  = 'Tenure Protection Allowance'
          '473'  = 'Special Transfer Allowance'
          '474'  = 'Away From Home Allowance'
          '475'  = 'Transition To Work Allowance'
          '596'  = 'Clothing Allowance'
          '600'  = 'Community Wage Sickness Benefit'
          '601'  = 'Community Wage Emergency Sickness Benefit'
          '602'  = 'Job Search Allowance'
          '603'  = 'Independent Youth Benefit' 
'604','605','610'= 'Community Wage Job Seekers'
          '607'  = 'Community Wage Emergency Student'
          '608'  = 'Community Wage Training Benefit'
          '609'  = 'Emergency Unemployment Benefit - Weekly'
          '611'  = 'Emergency Benefit'
    '313','613'  = 'Emergency Maintenance Allowance'
          '620'  = 'Special Needs Grants'
          '622'  = 'Job Start Grant'
          '652'  = 'Home Help - Multiple Births'
          '653'  = 'Home Help - Domestic Emergency'
          '654'  = 'Home Help - Families needing Dom. Serv.'
          '655'  = 'Home Help - Family Group Conference'
    '365','665'  = 'DPB Sole Parent'
    '366','666'  = 'DPB Woman Alone'
    '367','667'  = 'DPB Caring for Sick or Infirm'
          '700'  = 'CSC Reimbursement - General Medical'
          '710'  = 'CSC Reimbursement - Hospital Outpatient'
          '720'  = 'CSC Reimbursement - Pharmaceutical Prescription'
          '730'  = 'High Health User - General Medical'
          '740'  = 'High Health User - Hospital Outpatient'
          '750'  = 'High Health User - Pharmaceutical Prescription'
          '760'  = 'Prescription Subsidy Card'
          '830'  = 'Residential Support Service'
          '831'  = 'Advance of Benefit'
          '832'  = 'Relocation Allowance' 
          '833'  = 'Training Incentive Allowance'
          '834'  = 'Pre-enrolment Fee'
          '835'  = 'Miscellaneous Subsidy'
          '836'  = 'Blind Subsidy'
          '837'  = 'Rest Home Subsidy'
          '838'  = 'Special Disability Allowance' 
          '839'  = 'Non Beneficiary'
          '840'  = 'Civil Defence'
          '841'  = 'Health Subsidy'
          '842'  = 'Benefit Due'
          '843'  = 'Partner In Rest Home'
          '850'  = 'Veterans Pension Lump Sum Pymt on Death'
          '930'  = 'SWIFTT Excess/Non-Current Debt Refund'
          '944'  = 'Unidentified Receipt Refund'
          '961'  = 'Maintenance Refunds - Bank A/C Unknown'
          '962'  = 'Maintenance Refunds - Payer Reassessments'
          '969'  = 'Maintenance Refunds - Receipt Excess'
          'YP '  = 'Youth Payment'
          'YPP'  = 'Young Parent Payment'
          ' '    = 'No Benefit'
  ;

* Service codes - 1 Oct 1998 to 30 June 2001, long names ;
 VALUE $srvcdb
          '020'  = 'Invalids Benefit'
          '030'  = 'Widows Benefit'
          '040'  = 'Orphans Benefit'
          '044'  = 'Unsupported Child Benefit'
          '050'  = 'Transitional Retirement Benefit'
          '060'  = 'Family Benefit'
          '062'  = 'Child Care Subsidy'
          '064'  = 'Family Support'
          '065'  = 'Child Disability Allowance'
          '115'  = 'Community Wage Emergency Job Seeker'
          '125'  = 'Community Wage Emergency Training'
          '180'  = 'New Zealand Superannuation'
          '180.2'= 'NZ Super. - non qual. spouse'
          '181'  = 'Veterans Pension'
          '181.2'= 'Veterans Pension - non qual. spouse'
          '188'  = 'Living Alone Payment'
          '190'  = 'Funeral Grant - Married'
          '191'  = 'Funeral Grant - Single'
          '192'  = 'Funeral Grant - Child'
          '193'  = 'War Funeral Grant'
          '200'  = 'Police'
          '201'  = '1914/18 War'
          '202'  = 'Vietnam'
          '203'  = 'Peace Time Armed Forces'
          '204'  = 'Special Annuity (Service to Society)'
          '205'  = 'UN Armed Forces '
          '206'  = 'Mercantile Marine'
          '207'  = 'Emergency Reserve Corp'
          '208'  = 'Gallantry Award'
          '209'  = 'Pension Under Section 55'
          '210'  = '1939/45 War'
          '211'  = 'J-Force'
          '213'  = 'War Servicemens Dependants Allowance'
          '250'  = 'War Travel Concessions'
          '255'  = 'War Bursaries'
          '260'  = 'War Surgical Appliances'
          '263'  = 'War 11 Assessment'
          '270'  = 'War Medical Treatment - NZ Pensioner'
          '271'  = 'War Medical Treatment - UK Pensioner'
          '272'  = 'War Medical Treatment - AUS Pensioner'
          '273'  = 'United Kingdom Pension'
          '275'  = 'United Kingdom Pension - Non Pensioner'
          '313'  = 'Emergency Maintenance Allowance-1'
          '315'  = 'Family Capitalisation'
          '320'  = 'Invalids Benefit-1'
          '330'  = 'Widows Benefit-1'
          '344'  = 'Unsupported Child Benefit-1'
          '340'  = 'Orphans Benefit-1'
          '350'  = 'Transitional Retirement Benefit-1'
          '365'  = 'DPB Sole Parent-1'
          '366'  = 'DPB Woman Alone-1'
          '367'  = 'DPB Caring for Sick or Infirm-1'
          '425'  = 'Disability Allowance'
          '440'  = 'Disabled Civilian Amputee'
          '460'  = 'Special Benefit'
          '470'  = 'Accommodation Benefit'
          '471'  = 'Accommodation Supplement'
          '472'  = 'Tenure Protection Allowance'
          '473'  = 'Special Transfer Allowance'
          '474'  = 'Away From Home Allowance'
          '475'  = 'Transition To Work Allowance'
          '596'  = 'Clothing Allowance'
          '600'  = 'Community Wage Sickness Benefit'
          '601'  = 'Community Wage Emergency Sickness Benefit'
          '602'  = 'Job Search Allowance'
          '603'  = 'Independent Youth Benefit'
          '604'  = 'Community Wage Job Seekers-Young'
          '605'  = 'Community Wage Job Seekers-55+'
          '607'  = 'Community Wage Emergency Student'
          '608'  = 'Community Wage Training Benefit'
          '609'  = 'Emergency Unemployment Benefit - Weekly'
          '610'  = 'Community Wage Job Seekers'
          '611'  = 'Emergency Benefit'
          '613'  = 'Emergency Maintenance Allowance'
          '620'  = 'Special Needs Grant'
          '622'  = 'Job Start Grant'
          '652'  = 'Home Help - Multiple Births'
          '653'  = 'Home Help - Domestic Emergency'
          '654'  = 'Home Help - Families needing Dom. Supp.'
          '655'  = 'Home Help - Family Group Conference'
          '665'  = 'DPB Sole Parent'
          '666'  = 'DPB Woman Alone'
          '667'  = 'DPB Caring for Sick or Infirm'
          '700'  = 'CSC Reimbursement - General Medical'
          '710'  = 'CSC Reimbursement - Hospital Outpatient'
          '720'  = 'CSC Reimbursement - Pharmaceutical Prescription'
          '730'  = 'High Health User - General Medical'
          '740'  = 'High Health User - Hospital Outpatient'
          '750'  = 'High Health User - Pharmaceutical Prescription'
          '760'  = 'Prescription Subsidy Card'
          '830'  = 'Residential Support Service'
          '831'  = 'Advance of Benefit'
          '832'  = 'Relocation Allowance'
          '833'  = 'Training Incentive Allowance'
          '834'  = 'Pre-enrolment Fee'
          '835'  = 'Miscellaneous Subsidy'
          '836'  = 'Blind Subsidy'
          '837'  = 'Rest Home Subsidy'
          '838'  = 'Special Disability Allowance'
          '839'  = 'Non Beneficiary'
          '840'  = 'Civil Defence Payment'
          '841'  = 'Health Subsidy'
          '842'  = 'Benefit Due Payment'
          '843'  = 'Partner in Rest Home'
          '850'  = 'Veterans Pension Lump Sum Payment On Death'
          '930'  = 'SWIFTT Excess/Non-Current Debt Refund'
          '944'  = 'Unidentified Receipt Refund'
          '961'  = 'Maintenance Refunds - Bank A/C Unknown'
          '962'  = 'Maintenance Refunds - Payer Reassessments'
          '969'  = 'Maintenance Refunds - Receipt Excess'
          'YP '  = 'Youth Payment'
          'YPP'  = 'Young Parent Payment'
          ' '    = 'No Benefit'
  ;

******************************************************************;
***    FORTH BATCH - pre 1Oct98 formats                     ******;
******************************************************************;

*****************************************************************;
******   Seventh format group: pre 1 Oct 98, short names         ;
******          - Benefit group:  $bftgpa                        ;
******          - Benefit:     :  $bfta                          ;
******          - Service code:   $serva                         ;
****** Note: Although YP & YPP were not available in this period ;
******       they have been included here to protect programs    ;
******       that are running with old formats.                  ;
*****************************************************************;

* Benefit group format - for high level grouping - pre 1Oct98, short names;
  VALUE $bftgpa
    '020','320'                                    = 'IB'
    '030','330'                                    = 'WB'
    '040','044','340','344'                        = 'OB UCB'
    '050','350','180','181'                        = 'NZS VP TRB'
    '604','605','610'                              = 'UB Related'
    '608'                                          = 'TB'
    '313','613','365','665','366','666','367','667'= 'DPB related'
    '600','601'                                    = 'SB related'
    '602','603'                                    = 'JSA IYB'
    '607'                                          = 'ESt'
    '609','611'                                    = 'EUB'
    '839','275'                                    = 'Non Ben'
    'YP ','YPP'                                    = 'YP/YPP'
    ' '                                            = 'No Bft'
 ;

  value $bfta
    '020','320'  = 'IB'
    '030','330'  = 'WB'
    '040','340'  = 'OB'
    '044','344'  = 'UCB'
    '050','350'  = 'TRB'
          '060'  = 'FB'            /* Not in manual                  */
          '062'  = 'CCS'
          '064'  = 'FS'
          '065'  = 'HCA'
          '179'  = 'Discont'       /* Not in manual                  */
          '180'  = 'NZS'
         '180.2' = 'NZS-NQS'       /* Not in manual                  */
          '181'  = 'VP'
         '181.2' = 'VP-NQS'        /* Not in manual                  */
          '188'  = 'LAP'           /* Not in manual                  */
          '190'  = '61DB'
          '191'  = '61DC'
          '192'  = '61DD'
          '193'  = 'WFG'
          '200'  = 'WPP'
          '201'  = 'WP1'
          '202'  = 'WPV'
          '203'  = 'WPPT'
          '204'  = 'WPSA'
          '205'  = 'WPUN'
          '206'  = 'WPMM'
          '207'  = 'WPER'
          '208'  = 'WPGA'
          '209'  = 'WP55'
          '210'  = 'WP2'
          '211'  = 'WJF'
          '213'  = 'WSDA'
          '250'  = 'WTC'
          '255'  = 'WPB'
          '260'  = 'WSA'
          '263'  = 'W11'
          '270'  = 'WMNZ'
          '271'  = 'WMUK'
          '272'  = 'WMOZ'
          '273'  = 'UKP'
          '275'  = 'UKPN'
          '300'  = 'DEBT'            /* Not in manual                  */
          '315'  = 'CAP'
          '425'  = 'DA'
          '440'  = 'DCA'
          '460'  = 'SPB'
          '470'  = 'AB'
          '471'  = 'AS'
          '472'  = 'TPA'
          '473'  = 'STA'
          '474'  = 'AFHA'
          '475'  = 'TWA'
          '596'  = 'CA'
          '600'  = 'SB'
          '601'  = 'ESB'
          '602'  = 'JSA'
          '603'  = 'IYB'
          '604'  = 'YJSA'
          '605'  = 'UB55+'         /* Manual lists as EUB            */
          '607'  = 'EUB-St'        /* Manual lists as EUB            */
          '608'  = 'TB'
          '609'  = 'EUB-Wkly'       /* Not in manual                  */
          '610'  = 'UB'
          '611'  = 'EUB'
    '313','613'  = 'EMA'
          '620'  = 'SNG'
          '622'  = 'JSG'
          '652'  = 'HHMB'
          '653'  = 'HHDM'
          '654'  = 'HHDS'
          '655'  = 'HHGC'
    '365','665'  = 'DPB-SP'
    '366','666'  = 'DPB-WA'        /* No short code listed in manual */
    '367','667'  = 'DPB-CSI'       /* No short code listed in manual */
          '700'  = 'CGM'
          '710'  = 'CHO'
          '720'  = 'CPP'
          '730'  = 'CHGM'
          '740'  = 'CHHO'
          '750'  = 'CHPP'
          '760'  = 'CPSC'
          '830'  = 'RSS'
          '831'  = 'ADV'
          '832'  = 'RA'
          '833'  = 'TIA'
          '834'  = 'TIA-Pre'       /* No short code listed in manual */
          '835'  = 'MISC'          /* No short code listed in manual */
          '836'  = 'BS'
          '837'  = 'RHS'           /* Not in manual                  */
          '838'  = 'SPDA'
          '839'  = 'Non-ben'       /* No short code listed in manual */
          '840'  = 'Civ-Def'       /* No short code listed in manual */
          '841'  = 'Health'
          '842'  = 'BFTD'
          '843'  = 'PRH'
          '850'  = 'VPLS'
          '930'  = 'RRS'
          '944'  = 'RRU'
          '961'  = 'RRMB'
          '962'  = 'RRMU'
          '969'  = 'RRME'
          '999'  = 'Total'        /* Not in manual                  */
          'YP '  = 'YP'
          'YPP'  = 'YPP'
          ' '    = 'No Bft';

  value $serva
          '020'  = 'IB'
          '030'  = 'WB'
          '040'  = 'OB'
          '044'  = 'UCB'
          '050'  = 'TRB'
          '060'  = 'FB'            /* Not in manual                  */
          '062'  = 'CCS'
          '064'  = 'FS'
          '065'  = 'HCA'
          '179'  = 'Discont'       /* Not in manual                  */
          '180'  = 'NZS'
         '180.2' = 'NZS-NQS'       /* Not in manual                  */
          '181'  = 'VP'
         '181.2' = 'VP-NQS'        /* Not in manual                  */
          '188'  = 'LAP'           /* Not in manual                  */
          '190'  = '61DB'
          '191'  = '61DC'
          '192'  = '61DD'
          '193'  = 'WFG'
          '200'  = 'WPP'
          '201'  = 'WP1'
          '202'  = 'WPV'
          '203'  = 'WPPT'
          '204'  = 'WPSA'
          '205'  = 'WPUN'
          '206'  = 'WPMM'
          '207'  = 'WPER'
          '208'  = 'WPGA'
          '209'  = 'WP55'
          '210'  = 'WP2'
          '211'  = 'WJF'
          '213'  = 'WSDA'
          '250'  = 'WTC'
          '255'  = 'WPB'
          '260'  = 'WSA'
          '263'  = 'W11'
          '270'  = 'WMNZ'
          '271'  = 'WMUK'
          '272'  = 'WMOZ'
          '273'  = 'UKP'
          '275'  = 'UKPN'
          '300'  = 'DEBT'            /* Not in manual                  */
          '313'  = 'EMA-1'
          '315'  = 'CAP'
          '320'  = 'IB-1'
          '330'  = 'WB-1'
          '340'  = 'OB-1'
          '344'  = 'UCB-1'
          '350'  = 'TRB-1'
          '365'  = 'DPBSP-1'
          '366'  = 'DPBWA-1'        /* No short code listed in manual */
          '367'  = 'DPBCSI-1'       /* No short code listed in manual */
          '425'  = 'DA'
          '440'  = 'DCA'
          '460'  = 'SPB'
          '470'  = 'AB'
          '471'  = 'AS'
          '472'  = 'TPA'
          '473'  = 'STA'
          '474'  = 'AFHA'
          '475'  = 'TWA'
          '596'  = 'CA'
          '600'  = 'SB'
          '601'  = 'ESB'
          '602'  = 'JSA'
          '603'  = 'IYB'
          '604'  = 'YJSA'
          '605'  = 'UB55+'         /* Manual lists as EUB            */
          '607'  = 'EUB-St'        /* Manual lists as EUB            */
          '608'  = 'TB'
          '609'  = 'EUB-Wkly'       /* Not in manual                  */
          '610'  = 'UB'
          '611'  = 'EUB'
          '613'  = 'EMA'
          '620'  = 'SNG'
          '622'  = 'JSG'
          '652'  = 'HHMB'
          '653'  = 'HHDM'
          '654'  = 'HHDS'
          '655'  = 'HHGC'
          '665'  = 'DPB-SP'
          '666'  = 'DPB-WA'        /* No short code listed in manual */
          '667'  = 'DPB-CSI'       /* No short code listed in manual */
          '700'  = 'CGM'
          '710'  = 'CHO'
          '720'  = 'CPP'
          '730'  = 'CHGM'
          '740'  = 'CHHO'
          '750'  = 'CHPP'
          '760'  = 'CPSC'
          '830'  = 'RSS'
          '831'  = 'ADV'
          '832'  = 'RA'
          '833'  = 'TIA'
          '834'  = 'TIA-Pre'       /* No short code listed in manual */
          '835'  = 'MISC'          /* No short code listed in manual */
          '836'  = 'BS'
          '837'  = 'RHS'           /* Not in manual                  */
          '838'  = 'SPDA'
          '839'  = 'Non-ben'       /* No short code listed in manual */
          '840'  = 'Civ-Def'       /* No short code listed in manual */
          '841'  = 'Health'
          '842'  = 'BFTD'
          '843'  = 'PRH'
          '850'  = 'VPLS'
          '930'  = 'RRS'
          '944'  = 'RRU'
          '961'  = 'RRMB'
          '962'  = 'RRMU'
          '969'  = 'RRME'
          '999'  = 'Total'        /* Not in manual                  */
          'YP '  = 'YP'
          'YPP'  = 'YPP'
          ' '    = 'No Bft';



*******************************************************************;
******   Eighth format group: pre 1 Oct 98, long names             ;
******          - Benefit group:  $bengpa                          ;
******          - Benefit:     :  $bena                            ;
******          - Service code:   $srvcda                          ;
****** Note: Although YP & YPP were not available in this period   ;
******       they have been included here to protect programs that ;
******       are running with old formats.                         ;
*******************************************************************;

* Benefit group format - for high level grouping - pre 1Oct98, long names;
  VALUE $bengpa
    '020','320'                   = 'Invalids Benefit'
    '030','330'                   = 'Widows Benefit'
    '040','044','340','344'       = 'Orphans Benefit/Unsupported Child Benefit'
    '050','350','180','181'       = 'New Zealand Superannuation/Veterans/Transitional Retirement'
    '313','613','365','665','366','666','367','667'= 'DPB related'
    '600','601'                   = 'Sickness Benefit related'
    '602','603'                   = 'Job Search Allowance and Independant Youth Benefit'
    '604','605','610'             = 'Unemployment Benefit Related'
    '607'                         = 'Emergency Student'
    '608'                         = 'Training Benefit'
    '609','611'                   = 'Emergency Unemployment Benefit'
    '839','275'                   = 'Non Beneficiary'
    'YP ','YPP'                   = 'Youth Payment and Young Parent Payment'
    ' '                           = 'No Benefit'
 ;

* Benefit codes - pre 1 Oct 98 - long names;
 value $bena
   '020','320'  = 'Invalids Benefit'
   '030','330'  = 'Widows Benefit'
   '040','340'  = 'Orphans Benefit'
   '044','344'  = 'Unsupported Child Benefit'
   '050','350'  = 'Transitional Retirement Benefit'
         '060'  = 'Family Benefit'
         '062'  = 'Child Care Subsidy'
         '064'  = 'Family Support'
         '065'  = 'Handicapped Child Allowance'
         '180'  = 'New Zealand Superannuation'
        '180.2' = 'NZ Super. - non qual. spouse'
         '181'  = 'Veterans'
        '181.2' = 'VP - non qual. spouse'
         '188'  = 'Living Alone Payment'
         '190'  = 'Funeral Grant - Married'
         '191'  = 'Funeral Grant - Single'
         '192'  = 'Funeral Grant - Child'
         '193'  = 'War Funeral Grant'
         '200'  = 'Police'
         '201'  = '1914/18 War'
         '202'  = 'Vietnam'
         '203'  = 'Peace Time Armed Forces'
         '204'  = 'Special Annuity (Service to Society)'
         '205'  = 'UN Armed Forces'
         '206'  = 'Mercantile Marine'
         '207'  = 'Emergency Reserve Corp'
         '208'  = 'Gallantry Award'
         '209'  = 'Pension Under Section 55'
         '210'  = '1939/45 War'
         '211'  = 'J-Force'
         '213'  = 'War Servicemens Dependants Allowance'
         '250'  = 'War Travel Concessions'
         '255'  = 'War Bursaries'
         '260'  = 'War Surgical Appliances'
         '263'  = 'War 11 Assessment'
         '270'  = 'War Medical Treatment - NZ Pensioner'
         '271'  = 'War Medical Treatment - UK Pensioner'
         '272'  = 'War Medical Treatment - AUS Pensioner'
         '273'  = 'United Kingdom Pension'
         '275'  = 'United Kingdom Pension - Non Pensioner'
         '315'  = 'Family Capitalisation'
         '425'  = 'Disability Allowance'
         '440'  = 'Disabled Civilian Amputee'
         '460'  = 'Special Benefit'
         '470'  = 'Accommodation Benefit'
         '471'  = 'Accommodation Supplement'
         '472'  = 'Tenure Protection Allowance'
         '473'  = 'Special Transfer Allowance'
         '474'  = 'Away From Home Allowance'
         '475'  = 'Transition To Work Allowance'
         '596'  = 'Clothing Allowance'
         '600'  = 'Sickness Benefit'
         '601'  = 'Emergency Sickness Benefit'
         '602'  = 'Job Search Allowance'
         '603'  = 'Independent Youth Benefit'
         '604'  = 'Young Job Seekers Allowance'
         '605'  = '55 Plus Benefit'
         '607'  = 'Emergency Unemployment Student'
         '608'  = 'Training Benefit'
         '609'  = 'Emergency Unemployment Benefit - Weekly'
         '610'  = 'Unemployment Benefit'
         '611'  = 'Emergency Unemployment Benefit'
   '313','613'  = 'Emergency Maintenance Allowance'
         '620'  = 'Special Needs Grant'
         '622'  = 'Job Start Grant'
         '652'  = 'Home Help - Multiple Births'
         '653'  = 'Home Help - Domestic Emergency'
         '654'  = 'Home Help - Families needing Dom. Supp.'
         '655'  = 'Home Help - Family Group Conference'
   '365','665'  = 'DPB Sole Parent'
   '366','666'  = 'DPB Woman Alone'
   '367','667'  = 'DPB Caring for Sick or Infirm'
         '700'  = 'CSC Reimbursement - General Medical'
         '710'  = 'CSC Reimbursement - Hospital Outpatient'
         '720'  = 'CSC Reimbursement - Pharmaceutical Prescription'
         '730'  = 'High Health User - General Medical'
         '740'  = 'High Health User - Hospital Outpatient'
         '750'  = 'High Health User - Pharmaceutical Prescription'
         '760'  = 'Prescription Subsidy Card'
         '830'  = 'Residential Support Service'
         '831'  = 'Advance of Benefit'
         '832'  = 'Relocation Allowance'
         '833'  = 'Training Incentive Allowance'
         '834'  = 'Pre-enrolment Fee'
         '835'  = 'Miscellaneous Subsidy'
         '836'  = 'Blind Subsidy'
         '837'  = 'Rest Home Subsidy'
         '838'  = 'Special Disability Allowance'
         '839'  = 'Non Beneficiary'
         '840'  = 'Civil Defence'
         '841'  = 'Health Subsidy'
         '842'  = 'Benefit Due'
         '843'  = 'Partner in Rest Home'
         '850'  = 'Veterans Pension Lump Sum'
         '930'  = 'SWIFTT Excess/Non-Current Debt Refund'
         '944'  = 'Unidentified Receipt Refund'
         '961'  = 'Maintenance Refunds - Bank A/C Unknown'
         '962'  = 'Maintenance Refunds - Payer Reassessments'
         '969'  = 'Maintenance Refunds - Receipt Excess'
         'YP '  = 'Youth Payment'
         'YPP'  = 'Young Parent Payment'
         ' '    = 'No Benefit'
  ;

* Service code descriptions - pre 1 Oct 98 - long names;
 value $srvcda
         '020'  = 'Invalids Benefit'
         '030'  = 'Widows Benefit'
         '040'  = 'Orphans Benefit'
         '044'  = 'Unsupported Child Benefit'
         '050'  = 'Transitional Retirement Benefit'
         '060'  = 'Family Benefit'
         '062'  = 'Child Care Subsidy'
         '064'  = 'Family Support'
         '065'  = 'Handicapped Child Allowance'
         '180'  = 'New Zealand Superannuation'
        '180.2' = 'NZ Super. - non qual. spouse'
         '181'  = 'Veterans'
        '181.2' = 'VP - non qual. spouse'
         '188'  = 'Living Alone Payment'
         '190'  = 'Funeral Grant - Married'
         '191'  = 'Funeral Grant - Single'
         '192'  = 'Funeral Grant - Child'
         '193'  = 'War Funeral Grant'
         '200'  = 'Police'
         '201'  = '1914/18 War'
         '202'  = 'Vietnam'
         '203'  = 'Peace Time Armed Forces'
         '204'  = 'Special Annuity (Service to Society)'
         '205'  = 'UN Armed Forces'
         '206'  = 'Mercantile Marine'
         '207'  = 'Emergency Reserve Corp'
         '208'  = 'Gallantry Award'
         '209'  = 'Pension Under Section 55'
         '210'  = '1939/45 War'
         '211'  = 'J-Force'
         '213'  = 'War Servicemens Dependants Allowance'
         '250'  = 'War Travel Concessions'
         '255'  = 'War Bursaries'
         '260'  = 'War Surgical Appliances'
         '263'  = 'War 11 Assessment'
         '270'  = 'War Medical Treatment - NZ Pensioner'
         '271'  = 'War Medical Treatment - UK Pensioner'
         '272'  = 'War Medical Treatment - AUS Pensioner'
         '273'  = 'United Kingdom Pension'
         '275'  = 'United Kingdom Pension = Non Pensioner'
         '313'  = 'Emergency Maintenance Allowance-1'
         '315'  = 'Family Capitalisation'
         '320'  = 'Invalids Benefit-1'
         '330'  = 'Widows Benefit-1'
         '340'  = 'Orphans Benefit-1'
         '344'  = 'Unsupported Child Benefit-1'
         '350'  = 'Transitional Retirement Benefit-1'
         '365'  = 'DPB Sole Parent-1'
         '366'  = 'DPB Woman Alone-1'
         '367'  = 'DPB Caring for Sick or Infirm-1'
         '425'  = 'Disability Allowance'
         '440'  = 'Disabled Civilian Amputee'
         '460'  = 'Special Benefit'
         '470'  = 'Accommodation Benefit'
         '471'  = 'Accommodation Supplement'
         '472'  = 'Tenure Protection Allowance'
         '473'  = 'Special Transfer Allowance'
         '474'  = 'Away From Home Allowance'
         '475'  = 'Transition to Work Allowance'
         '596'  = 'Clothing Allowance'
         '600'  = 'Sickness Benefit'
         '601'  = 'Emergency Sickness Benefit'
         '602'  = 'Job Search Allowance'
         '603'  = 'Independent Youth Benefit'
         '604'  = 'Young Job Seekers Allowance'
         '605'  = '55 Plus Benefit'
         '607'  = 'Emergency Unemployment Student'
         '608'  = 'Training Benefit'
         '609'  = 'Emergency Unemployment Benefit - Weekly'
         '610'  = 'Unemployment Benefit'
         '611'  = 'Emergency Unemployment Benefit'
         '613'  = 'Emergency Maintenance Allowance'
         '620'  = 'Special Needs Grants'
         '622'  = 'Job Start Grant'
         '652'  = 'Home Help - Multiple Births'
         '653'  = 'Home Help - Domestic Emergency'
         '654'  = 'Home Help - Families needing Dom. Supp.'
         '655'  = 'Home Help - Family Group Conference'
         '665'  = 'DPB Sole Parent'
         '666'  = 'DPB Woman Alone'
         '667'  = 'DPB Caring for Sick or Infirm'
         '700'  = 'CSC Reimbursement - General Medical'
         '710'  = 'CSC Reimbursement - Hospital Outpatient'
         '720'  = 'CSC Reimbursement - Pharmaceutical Prescription'
         '730'  = 'High Health User - General Medical'
         '740'  = 'High Health User - Hospital Outpatient'
         '750'  = 'High Health User - Pharmaceutical Prescription'
         '760'  = 'Prescription Subsidy Card'
         '830'  = 'Residential Support Service'
         '831'  = 'Advance of Benefit'
         '832'  = 'Relocation Allowance'
         '833'  = 'Training Incentive Allowance'
         '834'  = 'Pre-enrolment Fee'
         '835'  = 'Miscellaneous Subsidy'
         '836'  = 'Blind Subsidy'
         '837'  = 'Rest Home Subsidy'
         '838'  = 'Special Disability Allowance'
         '839'  = 'Non Beneficiary'
         '840'  = 'Civil Defence'
         '841'  = 'Health Subsidy'
         '842'  = 'Benefit Due'
         '843'  = 'Partner in Rest Home'
         '850'  = 'Veterans Pension Lump Sum'
         '930'  = 'SWIFTT Excess/Non-Current Debt Refund'
         '944'  = 'Unidentified Receipt Refund'
         '961'  = 'Maintenance Refunds - Bank A/C Unknown'
         '962'  = 'Maintenance Refunds - Payer Reassessments'
         '969'  = 'Maintenance Refunds - Receipt Excess'
         'YP '  = 'Youth Payment'
         'YPP'  = 'Young Parent Payment'
         ' '    = 'No Benefit'
  ;

*************************************************************************;
****  WARNING  WARNING  WARNING  WARNING  WARNING  WARNING  WARNING  ****;
*************************************************************************;
**** The following three formats have been created for the Point and ****;
**** Click environment in order to ensure continuity in a time series****;
**** spanning the pre and post 2013 welfare reform changes.          ****;
**** These formats should only be applied after similar code to the  ****;
**** following code has been applied against SERV.                   ****;
*************************************************************************;
****  WARNING  WARNING  WARNING  WARNING  WARNING  WARNING  WARNING  ****;
*************************************************************************;
/*    summary_serv = serv;      
      if "&extdate"d > "12jul13"d 
            then do;
                      if serv = '020' then summary_serv = 'SLO';
                      else if serv = '030' then summary_serv = 'WBO';
                      else if serv = '313' then summary_serv = 'EM1';
                      else if serv = '613' then summary_serv = 'EMA';
                      else if serv = '365' then summary_serv = 'SPS';
                      else if serv = '607' then summary_serv = 'JSH';
                      else if serv = '665' then summary_serv = 'SPO';
            end;
*/
* Group short names - Point and Click *;
  VALUE $bftgp_2013wr_summary
    '020','320'            = 'IB'
    '030','330'            = 'WB'
    '040','044','340','344'= 'OB UCB'
    '050','350','180','181'= 'NZS VP TRB'
    '115','604','605','610'= 'UB related'
    '125','608'            = 'UBT related'
    '313','613','365','665','366','666','367','667'='DPB related'
    '600','601'            = 'SB related'
    '602'                  = 'JSA'
    '607'                  = 'UHS'
    '609','611'            = 'EB'
    '675'                  = 'JS related'
    '839','275'            = 'Non Ben'
    '370','SLO'            = 'SLP related'
    'EMA','EM1'            = 'EMA'
    'JSH'                  = 'JSSH'
    'SPS'                  = 'SPS' 
    'SPO'                  = 'SPSO' 
    'WBO'                  = 'WBO' 
    'YP ','YPP','603'      = 'YP/YPP' 
    ' '                    = 'No Bft'
 ;

* Benefit group for working age people on benefit, for high level grouping, short names;
  VALUE $swiftt_wa_gp_2013wr_summary
    '020','320'            = 'IB'
    '030','330'            = 'WB'
    '050','350'            = 'TRB'
    '115','604','605','610'= 'UB related'
    '125','608'            = 'UBT related'
    '313','613','365','665','366','666','367','667'='DPB related'
    '600','601'            = 'SB related'
    '602'                  = 'JSA IYB'
    '607'                  = 'UHS'
    '609','611'            = 'EB'
    '675'                  = 'JS related'
    '370','SLO'            = 'SLP related'
    'EMA','EM1'            = 'EMA'
    'JSH'                  = 'JSSH'
    'SPS'                  = 'SPS' 
    'SPO'                  = 'SPSO' 
    'WBO'                  = 'WBO' 
    'YP ','YPP','603'      = 'YP/YPP' 
       other               = 'Not WA Bft'
 ;

* Benefit short names - Point and Click. *;
VALUE $bft_2013wr_summary
    '020','320'  = 'IB'
    '030','330'  = 'WB'
    '040','340'  = 'OB'
    '044','344'  = 'UCB'
    '050','350'  = 'TRB'
          '060'  = 'FB'
          '062'  = 'CCS'
          '064'  = 'FTC'
          '065'  = 'CDA'
          '115'  = 'UBH' 
          '125'  = 'UHT' 
          '179'  = 'Discont' 
          '180'  = 'NZS'
          '181'  = 'VP'
          '188'  = 'SLAR' 
          '190'  = 'FNGRTM'
          '191'  = 'FNGRTS'
          '192'  = 'FNGRTC'
          '193'  = 'WFG'
          '200'  = 'WPP'
          '201'  = 'WP1'
          '202'  = 'WPV'
          '203'  = 'WPPT'
          '204'  = 'WPSA'
          '205'  = 'WPUN'
          '206'  = 'WPMM'
          '207'  = 'WPER'
          '208'  = 'WPGA'
          '209'  = 'WP55'
          '210'  = 'WP2'
          '211'  = 'WJF'
          '213'  = 'WSDA'
          '250'  = 'WTC'
          '255'  = 'WPB'
          '260'  = 'WSA'
          '263'  = 'W11'
          '270'  = 'WMNZ'
          '271'  = 'WMUK'
          '272'  = 'WMOZ'
          '273'  = 'OSP'
          '275'  = 'UKPN'
          '280'  = 'SAD'
          '281'  = 'FSL'
          '283'  = 'WRK'
          '300'  = 'DEBT' 
          '315'  = 'CAP'
          '370'  = 'SLP'
          '425'  = 'DA'
          '440'  = 'DCA'
          '450'  = 'TAS'
          '460'  = 'SPB'
          '470'  = 'AB'
          '471'  = 'AS'
          '472'  = 'TPA'
          '473'  = 'STA'
          '474'  = 'AFHA'
          '475'  = 'TWA'
          '500'  = 'WKB'
          '596'  = 'CA'
          '600'  = 'SB'
          '601'  = 'SBH'
          '602'  = 'JSA'
          '603'  = 'YP/YPP'
'604','605','610'  = 'UB'
          '607'  = 'UHS'
          '608'  = 'UBT'
          '609'  = 'EUB-Wkly' 
          '611'  = 'EB'
    '313','613'  = 'EMA'
          '620'  = 'SNG'
          '622'  = 'WSG'
          '623'  = 'PATH'
          '626'  = 'TTW'
          '630'  = 'CPA'
          '652'  = 'HHMB'
          '653'  = 'HHDM'
          '654'  = 'HHDS'
          '655'  = 'HHGC'
    '365','665'  = 'DPB-SP'
    '366','666'  = 'DPB-WA' 
    '367','667'  = 'DPB-CSI' 
          '675'  = 'JS'
          '700'  = 'CGM'
          '710'  = 'CHO'
          '720'  = 'CPP'
          '730'  = 'CHGM'
          '740'  = 'CHHO'
          '750'  = 'CHPP'
          '760'  = 'CPSC'
          '820'  = 'RAP'
          '830'  = 'RSS'
          '831'  = 'ADV'
          '832'  = 'RA'
          '833'  = 'TIA'
          '834'  = 'TIA-Pre' 
          '835'  = 'MISC' 
          '836'  = 'BS'
          '837'  = 'RHS' 
          '838'  = 'SPDA'
          '839'  = 'Non-ben' 
          '840'  = 'Civ-Def' 
          '841'  = 'HEALTH'
          '842'  = 'BFTD'
          '843'  = 'PRH'
          '850'  = 'VPLS'
          '930'  = 'RRS'
          '931'  = 'PCR'
          '932'  = 'IRRHNZ'
          '933'  = 'IRRCHP'
          '944'  = 'RRU'
          '961'  = 'RRMB'
          '962'  = 'RRMU'
          '969'  = 'RRME'
          '999'  = 'Total' 
   'EMA', 'EM1'  = 'EMA'
          'JSH'  = 'JSSH'
          'SLO'  = 'SLPO'
          'SPS'  = 'SPS' 
          'SPO'  = 'SPSO' 
          'WBO'  = 'WBO' 
          'YP '  = 'YP' 
          'YPP'  = 'YPP' 
            ' '  = 'No Bft';

* Service code short names - Point and Click;
  VALUE $serv_2013wr_summary
          '020'  = 'IB'
          '030'  = 'WB'
          '040'  = 'OB'
          '044'  = 'UCB'
          '050'  = 'TRB'
          '060'  = 'FB'
          '062'  = 'CCS'
          '064'  = 'FTC'
          '065'  = 'CDA'
          '115'  = 'UBH' 
          '125'  = 'UHT' 
          '179'  = 'Discont' 
          '180'  = 'NZS'
          '181'  = 'VP'
          '188'  = 'SLAR' 
          '190'  = 'FNGRTM'
          '191'  = 'FNGRTS'
          '192'  = 'FNGRTC'
          '193'  = 'WFG'
          '200'  = 'WPP'
          '201'  = 'WP1'
          '202'  = 'WPV'
          '203'  = 'WPPT'
          '204'  = 'WPSA'
          '205'  = 'WPUN'
          '206'  = 'WPMM'
          '207'  = 'WPER'
          '208'  = 'WPGA'
          '209'  = 'WP55'
          '210'  = 'WP2'
          '211'  = 'WJF'
          '213'  = 'WSDA'
          '250'  = 'WTC'
          '255'  = 'WPB'
          '260'  = 'WSA'
          '263'  = 'W11'
          '270'  = 'WMNZ'
          '271'  = 'WMUK'
          '272'  = 'WMOZ'
          '273'  = 'OSP'
          '275'  = 'UKPN'
          '280'  = 'SAD'
          '281'  = 'FSL'
          '283'  = 'WRK'
          '300'  = 'DEBT' 
    '313','EM1'  = 'EMA-1'
          '315'  = 'CAP'
          '320'  = 'IB-1'
          '330'  = 'WB-1'
          '340'  = 'OB-1'
          '344'  = 'UCB-1'
          '350'  = 'TRB-1'
          '365'  = 'DPBSP-1'
          '366'  = 'DPBWA-1' 
          '367'  = 'DPBCSI-1' 
          '370'  = 'SLP'
          '425'  = 'DA'
          '440'  = 'DCA'
          '450'  = 'TAS'
          '460'  = 'SPB'
          '470'  = 'AB'
          '471'  = 'AS'
          '472'  = 'TPA'
          '473'  = 'STA'
          '474'  = 'AFHA'
          '475'  = 'TWA'
          '500'  = 'WKB'
          '596'  = 'CA'
          '600'  = 'SB'
          '601'  = 'SBH'
          '602'  = 'JSA'
          '603'  = 'YP/YPP'
          '604'  = 'CW-YJSA'
          '605'  = 'CW-55+'
          '607'  = 'UHS' 
          '608'  = 'UBT'
          '609'  = 'EUB-Wkly'
          '610'  = 'UB'
          '611'  = 'EB'
    '613','EMA'  = 'EMA'
          '620'  = 'SNG'
          '622'  = 'WSG'
          '623'  = 'PATH'
          '626'  = 'TTW'
          '630'  = 'CPA'
          '652'  = 'HHMB'
          '653'  = 'HHDM'
          '654'  = 'HHDS'
          '655'  = 'HHGC'
          '665'  = 'DPBSP'
          '666'  = 'DPBWA'
          '667'  = 'DPBCSI' 
          '675'  = 'JS'
          '700'  = 'CGM'
          '710'  = 'CHO'
          '720'  = 'CPP'
          '730'  = 'CHGM'
          '740'  = 'CHHO'
          '750'  = 'CHPP'
          '760'  = 'CPSC'
          '820'  = 'RAP'
          '830'  = 'RSS'
          '831'  = 'ADV'
          '832'  = 'RA'
          '833'  = 'TIA'
          '834'  = 'TIA-Pre'
          '835'  = 'MISC' 
          '836'  = 'BS'
          '837'  = 'RHS' 
          '838'  = 'SPDA'
          '839'  = 'Non-ben'
          '840'  = 'Civ-Def'
          '841'  = 'HEALTH'
          '842'  = 'BFTD'
          '843'  = 'PRH'
          '850'  = 'VPLS'
          '930'  = 'RRS'
          '931'  = 'PCR'
          '932'  = 'IRRHNZ'
          '933'  = 'IRRCHP'
          '944'  = 'RRU'
          '961'  = 'RRMB'
          '962'  = 'RRMU'
          '969'  = 'RRME'
          '999'  = 'Total'
          'JSH'  = 'JSSH'
          'SLO'  = 'SLPO'
          'SPS'  = 'SPS' 
          'SPO'  = 'SPSO' 
          'WBO'  = 'WBO' 
          'YP '  = 'YP' 
          'YPP'  = 'YPP' 
            ' '  = 'No Bft';
run;