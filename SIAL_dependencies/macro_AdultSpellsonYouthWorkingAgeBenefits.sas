/*
     TITLE: Creates spells of adults on main (Youth and Working age) benefits.

     PURPOSE: BDD benefit spells split between main and single on the benefit spells
              dataset while partners are stored on a seperate dataset.
              This code combines the two together to each adult is linked to the
              working age main benefit spell.
           

     AUTHOUR: Marc de Boer, MSD
     DATE: Janurary 2014 

     CHANGE HISTROY
     WHEN       WHO           WHY
*/

/*
********************************************************************************************************;
    ** How to use this macro **

 ** run this code to loead macros into memory **

 %AdltsMainBenSpl( AMBSinfile = [dataset with SNZ_uid (if blank then extracts whole dataset)]
                  ,AMBS_IDIxt = [IDI release date (eg 20160305)]
                  ,AMBS_BenSpl = [Name of dataset to write benefitspells to]
*/

/*
********************************************************************************************************
  Code outline

 Dependencies
 MACRO: Subset an SQL IDI table into a SAS dataset macro.sas (on IDI code sharing library)
 MACRO: Spell_Manipulation_Macros.sas (on IDI code sharing library)
 MACRO: BenefitNameTypeMacro.sas (on IDI code sharing library)
 IDI table: msd_clean.msd_spell 
 IDI table: msd_clean.msd_partner

 Code structure
 1.0 Extract for relevent SNZ_uids from msd_clean.msd_partner
 2.0 Extract for relevent SNZ_uids (including primary for partner spells) from msd_clean.msd_spell
 2.1 Convert serv and additional_service_data into benefit name and type 
 3.0 Merge partner and benefit spell histories
 4.0 Create dataset with seperate records for single, partner and primary benefit spells
      
********************************************************************************************************;
*/  

********************************************************************************************************;
          ** Macro code **;


 %MACRO AdltsMainBenSpl( AMBSinfile = 
                        ,AMBS_IDIxt = 
                        ,AMBS_BenSpl =
                        ) ;
/*
 %LET AMBSinfile = PM_PC_matched2 ;
 %LET AMBS_IDIxt = 20160224 ;
 %LET AMBS_BenSpl = BenefitSpells ;
*/

 ** identify if sub set if requested *;
 DATA temp1 ;
  CALL SYMPUTX("InfileYes", LENGTHN(STRIP("&AMBSinfile.") ) ) ;
 run ; 

 %PUT Infile was specified in AMBSinfile (No=0): &InfileYes ;

 ** Spells as a partner  *;
  %IF &InfileYes gt 0 %THEN %DO ;
     DATA AMBS_ParnterId (RENAME = (snz_uid = partner_snz_uid) ) ;
      SET &AMBSinfile. (KEEP = snz_uid ) ;
     run ;

     %Subset_IDIdataset( SIDId_infile = AMBS_ParnterId
                        ,SIDId_Id_var = partner_snz_uid
                        ,SIDId_IDIextDt = &AMBS_IDIxt.
                        ,SIDId_IDIdataset = msd_clean.msd_partner
                        ,SIDIoutfile = MSD_PartnerBen1
                         );
  %END ;
  %ELSE %DO ;
    %Subset_IDIdataset( SIDId_infile = 
                        ,SIDId_Id_var = snz_uid
                        ,SIDId_IDIextDt = &AMBS_IDIxt.
                        ,SIDId_IDIdataset = msd_clean.msd_partner
                        ,SIDIoutfile = MSD_PartnerBen1
                         );
  %END ;

 ** format and tidy partner spells **;
 DATA MSD_PartnerBen2 ;
  SET MSD_PartnerBen1 (KEEP = snz_swn_nbr
                              partner_snz_uid
                              partner_snz_swn_nbr
                              msd_ptnr_ptnr_from_date
                              msd_ptnr_ptnr_to_date
                      );

  LENGTH PartnerSD
         PartnerED 8. ;
  FORMAT PartnerSD
         PartnerED ddmmyy10. ;
  PartnerSD=INPUT(COMPRESS(msd_ptnr_ptnr_from_date,"-"),yymmdd10.);
  PartnerED=INPUT(COMPRESS(msd_ptnr_ptnr_to_date,"-"),yymmdd10.) - 1;
  IF PartnerED = . THEN PartnerED = INPUT("&AMBS_IDIxt.",yymmdd10.);
  DROP msd_ptnr_ptnr_from_date msd_ptnr_ptnr_to_date ;
 run ; 

 ** Subset MSD BDD main benefit spells table to ids of interest *;
  %IF &InfileYes. gt 0 %THEN %DO ;
     DATA AMBS_AllId  ;
      SET &AMBSinfile. (KEEP = snz_uid ) 
          MSD_PartnerBen1 (KEEP = snz_uid )  ;  ** need primary SNZ_uid of any partners *;
     run ;

     %Subset_IDIdataset( SIDId_infile = AMBS_AllId
                        ,SIDId_Id_var = snz_uid
                        ,SIDId_IDIextDt = &AMBS_IDIxt.
                        ,SIDId_IDIdataset = msd_clean.msd_spell
                        ,SIDIoutfile = MSD_MainBen1
                         );
  %END ;
  %ELSE %DO ;
     %Subset_IDIdataset( SIDId_infile = 
                        ,SIDId_Id_var = snz_uid
                        ,SIDId_IDIextDt = &AMBS_IDIxt.
                        ,SIDId_IDIdataset = msd_clean.msd_spell
                        ,SIDIoutfile = MSD_MainBen1
                         );
  %END ;

 ** Format and tidy up spell dataset *;
 DATA MSD_MainBen2 ;
  FORMAT snz_uid
         snz_msd_uid
         snz_swn_nbr
         msd_spel_spell_nbr
         BenefitType
         BenefitName
         EntitlementSD
         EntitlementED
        ;
  SET MSD_MainBen1 (KEEP = snz_uid
                           snz_msd_uid
                           snz_swn_nbr
                           msd_spel_spell_nbr
                           msd_spel_rsn_code
                           msd_spel_servf_code
                           msd_spel_add_servf_code
                           msd_spel_spell_start_date
                           msd_spel_spell_end_date
                   );

  LENGTH EntitlementSD
         EntitlementED 8. ;
  FORMAT EntitlementSD
         EntitlementED ddmmyy10. ;
  EntitlementSD=INPUT(COMPRESS(msd_spel_spell_start_date,"-"),yymmdd10.);
  EntitlementED=INPUT(COMPRESS(msd_spel_spell_end_date,"-"),yymmdd10.) - 1;
  IF EntitlementED = . THEN EntitlementED = INPUT("&AMBS_IDIxt.",yymmdd10.);

  %BNT_BenNmType( BNTserv = msd_spel_servf_code 
               ,BNTasd = msd_spel_add_servf_code
               ,BNTdate = EntitlementSD
               ,BNT_BenNm = BenefitName
               ,BNT_BenTyp = BenefitType
               ) ;

 DROP  msd_spel_servf_code msd_spel_add_servf_code ;

 run ;

 ** Merge main benefit spells and partner spells *;

 %CombineSpell( CSinfile1 =  MSD_MainBen2
               ,CSSpell1_Vars = snz_uid
                                snz_swn_nbr
                                msd_spel_spell_nbr
								msd_spel_servf_code
								msd_spel_add_servf_code
                                BenefitType
                                BenefitName
               ,CSSpell1_SD = EntitlementSD
               ,CSSpell1_ED = EntitlementED
               ,CSinfile2 = MSD_PartnerBen2
               ,CSSpell2_Vars = partner_snz_uid
                              partner_snz_swn_nbr
               ,CSSpell2_SD = PartnerSD
               ,CSSpell2_ED = PartnerED
               ,CSoutfile = MSD_MainBen3
               ,CSidvar =  snz_swn_nbr
               ) ;

/*

    %SplCombineVald( RCVLib = work 
                    ,RCVPrimKey = snz_swn_nbr 
                    ,RCVtestN = 1000000
                    ,RCV1_infile = MSD_MainBen2 
                    ,RCV1_EffFrm = EntitlementSD
                    ,RCV1_EffTo = EntitlementED 
                    ,RCV1_Vars = snz_uid BenefitName msd_spel_spell_nbr
                    ,RCV2_infile = MSD_PartnerBen2
                    ,RCV2_EffFrm = PartnerSD 
                    ,RCV2_EffTo =  PartnerED 
                    ,RCV2_Vars = partner_snz_swn_nbr 
                    ,RCVombinedFile = MSD_MainBen3
                    ) ;
 
 */

  PROC PRINT DATA = &syslast. (obs=20) ; run ;

 ** Create benefit for partner and primary **;
 DATA &AMBS_BenSpl. (RENAME = (CSspellSD = EntitlementSD
                              CSspellED = EntitlementED
                             )
                    );
  FORMAT snz_uid
         snz_swn_nbr
         MnBenCplUnitNbr
         PrimaryBenSwnNbr
		 msd_spel_servf_code
		 msd_spel_add_servf_code
         BenefitName
         BenefitType
         BenefitRole
         CSspellSD    
         CSspellED
         ;
  SET MSD_MainBen3 ;

   LABEL snz_uid = "SNZ unique person id"
         snz_swn_nbr = "SNZ confidentialised social welfare number"
         MnBenCplUnitNbr = "Unqiue couple on benefit id based on snz_uid"
         PrimaryBenSwnNbr = "SNZ_swn_nbr of primary beneficiary"
		 msd_spel_servf_code = "Official name of benefit current at entitlement start date"
		 msd_spel_add_servf_code = "Unofficial grouping of benefitds into commone types"
         BenefitName = "Official name of benefit current at entitlement start date"
         BenefitType = "Unofficial grouping of benefitds into commone types"
         BenefitRole = "Individual position on the beenfit (single, primary or partner)"
         CSspellSD = "Start date of benefit entitlement"   
         CSspellED = "End date of benefit entitlement"
         DataSource = "IDI table data was drawn from" 
         ;

  LENGTH DataSource $50. 
         PrimaryBenSwnNbr 8. ;
  DataSource = "msd_clean.msd_spell" ;

  ** Identify primary beneficiery swn **;
  PrimaryBenSwnNbr = snz_swn_nbr ;

  ** identify couple units *;
  LENGTH MnBenCplUnitNbr $40. ;
  IF partner_snz_swn_nbr = . THEN MnBenCplUnitNbr = STRIP(snz_uid) ;
  ELSE MnBenCplUnitNbr = CATT(MIN(snz_uid,partner_snz_uid),MAX(snz_uid,partner_snz_uid)) ;

  ** primary and single beneficeries **;
  LENGTH BenefitRole $10. ;
  IF partner_snz_swn_nbr = . THEN BenefitRole = "Single" ;
  ELSE BenefitRole = "Primary" ;
  OUTPUT ;
  IF partner_snz_swn_nbr ne . THEN DO ;
      DataSource = "msd_clean.msd_partner" ;
      BenefitRole = "Partner" ;
      snz_swn_nbr = partner_snz_swn_nbr ;
      snz_uid = partner_snz_uid ;
      OUTPUT ;
  END ; 
  DROP partner_snz_swn_nbr partner_snz_uid msd_spel_spell_nbr ;
 run ;
      
 PROC PRINT DATA = &syslast. (obs=20) ; run ;                       

 ** House keeping **;
 PROC DATASETS LIB = work NOLIST ;
  DELETE MSD_MainBen: 
         MSD_PartnerBen: 
         AMBS_AllID
         AMBS_PartnerID
         Temp:;
 run ;


 %MEND ;


/*
     TITLE: Creates variables with offical name of benefit and an unofficial type.

     PURPOSE: Benefit names have changed over time without changes to underlying codes.
              The introduction of YP/YPP in Septermber 1012 resulted in the additional of
              additional_service_data variable alongside the serv code.
              The beenfit changes in July 2013 resuled in the reuse of serv code for very
              different types of benefits.
              Overal, the serv/additional_service_data can be difficult to analyise
              This macro attempts tocreate meaningful beenfit names and typology.
           

     AUTHOUR: Marc de Boer, MSD
     DATE: Janurary 2014 

     CHANGE HISTROY
     WHEN       WHO           WHY
     Aug2014    Marc de Boer  Included output of the official benefit name at the observation date.
     Oct2015    Marc de Boer  For benefit serv and additional_benefit data that is post welfare reform but applies to a 
                              pre-July 2013 date, then impute the pre-welfare reform benefit code (eg "675MED1", "675MED2" = "600").
*/

/*
********************************************************************************************************;
    ** How to use this macro **

 After running the macro into memory insert the following macro call into a data step as shown below

 DATA outputdataset
  SET inputdatadset (KEEP = spellfrom servf additional_service_data);

  %BNT_BenNmType( BNTserv = servf 
               ,BNTasd = additional_service_data
               ,BNTdate = spellfrom
               ,BNT_BenNm = BenefitName
               ,BNT_BenTyp = BenefitType
               ) ;
 run ;
 
 * Based on the servf and additional_service_data the macro will return the official name of the
   benefit as it was on the spellfrom date and what type of benefi it is.

*/


********************************************************************************************************;
          ** Macro code **;

  %MACRO BNT_BenNmType( BNTserv = 
                     ,BNTasd = 
                     ,BNTdate = 
                     ,BNT_BenNm = 
                     ,BNT_BenTyp = 
                     ) ;

  ** Create a single variables of serv and additional_service_data **;

  ** benefit type **;
  TempServ = STRIP(&BNTserv) || STRIP(&BNTasd) ;

  ** remove OLD from Temp Serv *;
  IF STRIP(&BNTasd) = "OLD" THEN TempServ = STRIP(&BNTserv) ;

  ** tidy up some odd combos **;
  IF &BNTserv = "370" 
     AND &BNTasd NOT IN ("CARE", "PSMED")  THEN TempServ = "370PSMED" ;
  IF &BNTserv = "611" THEN TempServ = "611" ;
  IF &BNTserv = "665" THEN TempServ = "665" ;
  IF &BNTserv = "839" THEN TempServ = "839" ;
  IF &BNTserv = "600" THEN TempServ = "600" ;
  IF &BNTserv = "180" THEN TempServ = "180" ;
  IF &BNTserv = "181" THEN TempServ = "181" ;

  ** Pre welfare reform names **;
  IF &BNTdate lt "13jul2013"d THEN DO ;
      IF TempServ IN ("320MED1", "320PSMED") THEN TempServ = "320" ; 
      IF TempServ IN ("330FTJS1", "330MED1") THEN  TempServ = "330" ;
      IF TempServ IN ("365FTJS", "365FTJS1", "365MED1") THEN  TempServ = "365" ;
      IF TempServ IN ("366FTJS1", "366MED1") THEN TempServ = "366" ;
      IF TempServ IN ("367CARE", "370CARE") THEN TempServ = "367" ;
      IF TempServ IN ("370PSMED") THEN TempServ = "320" ;
      IF TempServ IN ("675MED1", "675MED2") THEN TempServ = "600" ;
      IF TempServ IN ("608FTJS3", "608FTJS4", "675FTJS3", "675FTJS4") THEN  TempServ = "608" ;
      IF TempServ IN ("610FTJS2", "610FTJS1", "675FTJS1", "675FTJS2") THEN  TempServ = "610" ;
  END ;
  ELSE DO ;
   IF TempServ IN ( "320MED1"
                   ,"320PSMED"
                  )
      THEN TempServ = "365" ; 
   IF TempServ IN ( "607YP"
                   ,"607YPP"
                  )
      THEN TempServ = "607" ; 
   IF TempServ IN ( "365YPP"
                  )
      THEN TempServ = "365" ; 
  END ;

  IF TempServ IN ("365YPP" 
                 )
          THEN TempServ = "365" ; 

  IF TempServ IN ("610FTJS1" 
                 )
          THEN TempServ = "675FTJS1" ; 

  IF TempServ IN ("675PSMED" 
                 )
          THEN TempServ = "675MED1" ; 
  IF tempServ IN ("180PSMED") THEN TempServ = "180" ;

  ** Convert to benefit types ***;
  &BNT_BenTyp = PUT(TempServ, $BSHbntypPstWR.) ;
  IF &BNTdate lt "13jul2013"d THEN &BNT_BenTyp = PUT(TempServ, $BSHbntypPrWR.) ;
  IF &BNT_BenTyp = TempServ  THEN &BNT_BenTyp = PUT(TempServ, $BSHbntypPstWR.) ; ** spells backdated **;
  IF &BNT_BenTyp = TempServ  THEN &BNT_BenTyp = PUT(TempServ, $BSHbntypPrWR.) ; ; ** left overs **;
  IF &BNT_BenTyp IN ("YP", "YPYP") THEN &BNT_BenTyp = "Youth Payment" ;
  IF &BNT_BenTyp IN ("YPP", "YPPYPP") THEN &BNT_BenTyp = "Young Parent Payment" ;

  DROP TempServ ;

  ** benefit name at observation date **;
  LENGTH &BNT_BenNm $60. ;
  
  ** ensure consistent Additional Service Data fields *;
  TempASD = &BNTasd ;
  IF &BNTserv = "607" THEN TempASD = "" ;
  IF &BNTserv = "611" THEN TempASD = "" ;
  IF &BNTserv = "665" THEN TempASD = "" ;
  IF &BNTserv = "839" THEN TempASD = "" ;
  IF &BNTserv = "365" THEN TempASD = "" ;

  IF      &BNTserv = "370" 
     AND &BNTasd NOT IN ("CARE", "PSMED") THEN TempASD = "PSMED" ;

  ** Post July 2013 benefit names *;
  IF &BNTdate ge "13jul2013"d THEN DO ;
    IF STRIP(TempASD) NOT IN ("", "OLD") THEN &BNT_BenNm = PUT(TempASD, $SWF_ADDITIONAL_SERVICE_LONG.) ;
    ELSE &BNT_BenNm = PUT(TempServ, $ben.) ;
    ** Tidy ups **;
    IF &BNTserv = "370" THEN DO ; ** split SLPs *;
      IF STRIP(TempASD) = "CARE" THEN &BNT_BenNm = "Supported Living Payments Carers" ;
      ELSE &BNT_BenNm = "Supported Living Payments Health Condition & Disability" ; 
    END ;
  END ;

  ** July 2001 to July 2013 benefit names *;
  IF ("01jul2001"d le &BNTdate lt "13jul2013"d) THEN DO ;
    IF STRIP(TempASD) IN ("YP", "YPP") THEN &BNT_BenNm = PUT(TempASD, $SWF_ADDITIONAL_SERVICE_LONG.) ; ** YPP/YP **;
    ELSE &BNT_BenNm = PUT(TempServ, $ben_pre2013wr.) ;
  END ;

  **October 1998 to July 2001 benefit names *;
  IF "01Oct1998"d le &BNTdate lt "01jul2001"d THEN DO ;
    &BNT_BenNm = PUT(TempServ, $benb.) ;
  END ;

  **Pre October 1998 benefit names *;
  IF &BNTdate lt "01Oct1998"d THEN DO ;
      &BNT_BenNm = PUT(TempServ, $bena.) ;
  END ;
  IF TempServ IN ("000", "") THEN &BNT_BenNm = "No benefit" ; 
  DROP TempASD ;
  
  ** tidy up names **;
  IF &BNT_BenNm = "Non Beneficiary" THEN &BNT_BenNm = "Supplementary Only" ;
  IF &BNT_BenNm IN ("YP", "YPYP") THEN &BNT_BenNm = "Youth Payment" ;
  IF &BNT_BenNm IN ("YPP", "YPPYPP") THEN &BNT_BenNm = "Young Parent Payment" ;
  IF &BNT_BenNm = "Invalids Benefit" THEN &BNT_BenNm = "Invalid's Benefit" ;
  IF &BNT_BenNm = "Widows Benefit" THEN &BNT_BenNm = "Widow's Benefit" ;
  IF &BNT_BenNm = "Unemployment Benefit (in Training)" THEN &BNT_BenNm = "Unemployment Benefit (Training)" ;
  IF &BNT_BenNm = "Unemployment Benefit Hardship (in Training)" THEN &BNT_BenNm = "Unemployment Benefit Hardship (Training)" ;
 %PUT *** Benefit grouping macro end ;

 %MEND ;

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
 



 /*
     TITLE: Subset an IDI dataset on the SQL server to a SAS dataset

     PURPOSE: Using SQL Pass through procedure subset an IDI dataset to
     a specific subset of ids.

     AUTHOUR: Marc de Boer, MSD.

     DATE: March 2015

     MODIFICATIONS
     WHO            WHEN        WHAT
     Marc de Boer   March 2016  Included the ability to extract from the IDI sandpit area
*/

 %MACRO Subset_IDIdataset(SIDId_infile =
                         ,SIDId_Id_var =
                         ,SIDId_IDIextDt = 
                         ,SIDId_IDIdataset =
                         ,SIDIoutfile =
                         ,SIDIsandpit =
                         );
 *
 SIDId_infile: dataset containing the IDI subsetting variable [SIDId_Id_var] if left
               null then the macro will extract the whole dataset
 SIDId_Id_var: IDI subsetting variable in the IDI source table [SIDId_IDIdataset]
               eg SIDId_Id_var = SNZ_uid in SIDId_IDIdataset = ir_clean.ird_ems
 SIDId_IDIextDt: IDI dataset version (eg 20151012)
 SIDId_IDIdataset: IDI dataset on the SQL server to be subsetted by the macro.
 SIDIoutfile: output dataset.
 SIDIsandpit:if the table is in the SQL IDI sandpit area then set this value to Y
 *;

 /*  For testing 
   %LET SIDId_infile = &IMMIO_infile;
   %LET SIDId_Id_var = snz_uid ;
   %LET SIDId_IDIextDt = &IMMIO_IDIexDt;
   %LET SIDId_IDIdataset = clean_read_sla.sla_amt_by_trn_type;
   %LET SIDIoutfile = testing  ;
   %LET SIDIsandpit =  ;
 */

********************************************************************************;
    ** identify whether the dataset needs to be subsetted **;
 DATA SIDI_temp1 ;
  IF LENGTHN(STRIP("&SIDId_infile.")) gt 0 THEN CALL SYMPUTX("SIDISubset",1) ;
  ELSE  CALL SYMPUTX("SIDISubset",0) ;
 run ;
  
 %PUT Subset IDI dataset (yes:1): &SIDISubset. ;

********************************************************************************;
    ** identify whether the dataset needs to be come from the sandpit **;

  DATA SIDI_temp2 ;
    IF STRIP("&SIDIsandpit.") = "Y" THEN CALL SYMPUTX("DatabaseCall", "IDI_sandpit") ;
    ELSE CALL SYMPUTX("DatabaseCall", "&SIDId_IDIextDt.")  ;
  run ;

  %PUT Database called: &DatabaseCall &SIDIsandpit.;

********************************************************************************; 
 ** Run extract with subsetting **;

 %IF &SIDISubset. = 1 %THEN %DO ;    * Loop 1*;
   
    ** Identify unqiue ids **;
   PROC SORT DATA = &SIDId_infile (WHERE = (&SIDId_Id_var ne .) ) 
    OUT = SIDI_temp2 (KEEP = &SIDId_Id_var)
    NODUPKEY ;
    BY &SIDId_Id_var ;
   run ;

   ** SQL subsetting function accepts something less than 56,000
      objects. This splits the call into 50,000 object batches *;
   DATA SIDI_temp3 ;
    SET SIDI_temp2 end = eof;

    IF _N_ = 1 THEN DO ;
      count =0 ;
      BatchN = 1 ;
    END ;
    RETAIN count BatchN ;
    count + 1 ;
    IF count gt 50000 THEN DO ;
      count =0 ;
      BatchN + 1 ;
    END ;

    IF eof THEN CALL SYMPUTX("SIDI_BatchT", BatchN) ;
   run ;

   %PUT Number of SIDI batches to run:&SIDI_BatchT. ; 

   ** delete &SIDIoutfile in case it already existed *;
   PROC DATASETS LIB = work NOLIST ;
    DELETE &SIDIoutfile ;
   run ;

   %DO SIDI_BatchN = 1 %TO &SIDI_BatchT ;   * loop 2 *;

    /*
     %LET SIDI_BatchN = 1 ;
    */
     ** Load ids into macro variables *;
     DATA SIDI_temp4 ;
      SET SIDI_temp3 (WHERE = (BatchN = &SIDI_BatchN) );

      CALL SYMPUTX(CATT("int_id",_N_), &SIDId_Id_var) ;
      CALL SYMPUTX("int_id_T",_N_) ;
     run ;

     %MACRO Ids ;
        %DO i = 1 %TO &int_id_T-1 ;
            &&int_id&i,
        %END ;
           &&int_id&int_id_T  
     %MEND ; 

      ** MdB 2016 03 08 Cannot use (SELECT DISTINCT &SIDId_Id_var FROM &IEDinfile) becuase the 
         the &IEDinfile is on the SAS server not the SQL server *;

     ** extract ids from IDI tables in sandpit area using pass through *;
       PROC SQL ;
        CONNECT TO SQLSERVR (SERVER = SNZ-IDIResearch-PRD-SQL\iLEED
                             DATABASE = &DatabaseCall.);
        CREATE TABLE SIDI_temp5 AS
        SELECT a.*
        FROM CONNECTION TO SQLSERVR (SELECT * FROM &SIDId_IDIdataset.
                                     WHERE  &SIDId_Id_var. IN (%IDS)
                                     ) AS a ;
        DISCONNECT FROM SQLSERVR ;
       quit ;

     PROC APPEND BASE = &SIDIoutfile. DATA = SIDI_temp5 ;
   %END ;   * end loop 2*;
 %END ; * end loop 1 *; 

 ** extract the whole dataset *;
 %IF &SIDISubset. = 0 %THEN %DO ; ** loop 3 *;
   PROC SQL ;
    CONNECT TO SQLSERVR (SERVER = SNZ-IDIResearch-PRD-SQL\iLEED
                         DATABASE = &DatabaseCall.
                         );
    CREATE TABLE &SIDIoutfile. AS
    SELECT a.*
    FROM CONNECTION TO SQLSERVR (SELECT * FROM &SIDId_IDIdataset
                                 ) AS a ;
    DISCONNECT FROM SQLSERVR ;
   quit ;
 %END ; * end loop 3 *;

 PROC DATASETS LIB = work NOLIST ;
  DELETE SIDI_temp: ;
 run ;
 %MEND ;


/*  
    TITLE:  Spell Combine Macro

    PURPOSE: Macro combines two spell histories into one
             Any change in one or the other spell history will result in a seperate spell.
             Useful when wanting to track changes in the status of a client in two or more
             spell histories.
             eg spells on different benefits and spells at differnt offices.

    AUTHOR: Marc de Boer, Knowledge and Insights, MSD

    DATE: Feburary 2014

     MODIFCATIONS
     BY             WHEN      WHY
     Marc de Boer   May2015   Allowed CSidvar to be both numeric and character
     Marc de Boer   May2015   Allowed spell sd and ed to be either datetime or date
     Marc de Boer   Jul2015   Allowed spell sd and ed to be time as well
*/

********************************************************************************************************;

        ***                      ***;
        *** Combine Spells macro ***;
        ***                      ***;

/*

 %CombineSpell( CSinfile1 
               ,CSSpell1_Vars
               ,CSSpell1_SD
               ,CSSpell1_ED
               ,CSinfile2 
               ,CSSpell2_Vars
               ,CSSpell2_SD
               ,CSSpell2_ED
               ,CSoutfile
               ,CSidvar
               )

*
Inputs
 CSidvar <required>:  identifier id (eg SNZ_uid). Needs to be one both spell datasets
 CSinfile1: first spell dataset
 CSSpell1_Vars: first dataset spell status variables (can be more than one)
 CSSpell1_SD: first dataset spell start date variable
 CSSpell1_ED: first dataset spell end date variable
 CSinfile2: second spell dataset
 CSSpell2_Vars: second dataset spell status variables (can be more than one)
 CSSpell2_SD: second dataset spell start date variable
 CSSpell2_ED: second dataset spell end date variable
 CSoutfile: name of dataset to write combined spell history to.

Outputs:
 CSidvar: id variable for client
 CSspellSD: combined spell start date variable
 CSspellED: combined spell end date variable
 CSSpell1_Vars
 CSSpell2_Vars: all spell variables identified in the input statement
                if any combination of spell variables changes then a new
                spell is created.
                if one or the other spells is missing the values from that dataset are set to null. 
*;
*/




        ***                      ***;
        *** Combine Spells macro ***;
        ***                      ***;

 %MACRO CombineSpell( CSinfile1 
                     ,CSSpell1_Vars
                     ,CSSpell1_SD
                     ,CSSpell1_ED
                     ,CSinfile2 
                     ,CSSpell2_Vars
                     ,CSSpell2_SD
                     ,CSSpell2_ED
                     ,CSoutfile
                     ,CSidvar
                    ) ;

/*

 %LET CSinfile1 = SCtest1 ;
 %LET CSSpell1_Vars = EA_assist ;
 %LET CSSpell1_SD = participation_sd ;
 %LET CSSpell1_ED = participation_ed ;
 %LET CSinfile2 = SCtest2 ;
 %LET CSSpell2_Vars = Benefit ;
 %LET CSSpell2_SD = SpellFrom ;
 %LET CSSpell2_ED = SpellTo ;
 %LET CSoutfile = SCtest3;
 %LET CSidvar = swn ;
*/

 
 %PUT *** Start of Combine Spell Macro IAP: /r00/msd/shared/ssi/macros/  ** ;

     ** Utility macros **;
 /*
 %INCLUDE "/r00/prod/msd/shared/ssi/macros/spellcondense.sas" ;
 %INCLUDE "/r00/prod/msd/shared/ssi/macros/spellhistoryinverter.sas" ;
 */
    ** set up work space **;

 PROC DATASETS LIB = work NOLIST ; DELETE &CSoutfile ; run ;

 ** work out format for spell starts and ends **;
 PROC CONTENTS DATA = &CSinfile1 (KEEP =&CSSpell1_SD) 
   NOPRINT
   OUT = CStemp1  ;
 run ;

 DATA CStemp1 ;
  SET CStemp1 ;

  ** Marc de Boer 22Jul2015 Included check that format length is not zero *;
  IF formatl gt 0 THEN CALL SYMPUTX("DTformat", STRIP(format)||STRIP(formatl)||".") ;
  ELSE CALL SYMPUTX("DTformat", STRIP(format)||".") ;
 run ;

 ** work out earlest and latest start and ends for spells **;
 ** Marc de Boer 20 Jul 2015 Removed the date formating becuase of 
    formatting problems 
 **;

 PROC MEANS DATA =  &CSinfile1 NOPRINT NWAY MISSING ;
  OUTPUT OUT = CStemp1 (DROP = _TYPE_ _FREQ_ 
                        )
   MIN(&CSSpell1_SD) =  MINspellSD
   MAX(&CSSpell1_ED) =  MAXspellED
    ;
 run ;

 PROC MEANS DATA =  &CSinfile2 NOPRINT NWAY MISSING ;
  OUTPUT OUT = CStemp2 (DROP = _TYPE_ _FREQ_ 
                        )
   MIN(&CSSpell2_SD) =  MINspellSD
   MAX(&CSSpell2_ED) =  MAXspellED
    ;
 run ;

 DATA CStemp3 ;
  SET CStemp1 
      CStemp2;
 run ;

 PROC MEANS DATA =  CStemp3 NOPRINT NWAY MISSING ;
  OUTPUT OUT = CStemp4 (DROP = _TYPE_ _FREQ_ 
                        )
   MIN(MINspellSD) =  MINspellSD
   MAX(MAXspellED) =  MAXspellED
    ;
 run ;

 DATA CStemp4 ;
  SET CStemp4 ;
 
  FORMAT MINspellSD  MAXspellED ;
  CALL SYMPUTX("ShrtEndSD", INT(MINspellSD) ) ;
  CALL SYMPUTX("LongEndED", INT(MAXspellED) ) ;

 run ;

/*
 DATA CStemp1 ;
  SET CStemp1 ;

  FORMAT MINspellSD ;
  IF MINspellSD gt "1Jan2100"d THEN DO ;
      CALL SYMPUTX("ShrtEndSD", "DHMS('01jan1800'd,0,0,0)" ) ;
      CALL SYMPUTX("LongEndED",  'DHMS("01jan2200"d,0,0,0)' ) ;
  END ;
  ELSE DO ;
      CALL SYMPUTX("ShrtEndSD", "'01jan1800'd" ) ;
      CALL SYMPUTX("LongEndED", '"01jan2200"d' ) ;
  END ;
 run ;
*/

 ** identify if id variable is num or char *;
 PROC CONTENTS DATA = &CSinfile1 (KEEP = &CSidvar)
  NOPRINT 
  OUT = CSIDVar1 ;
 run ;

 DATA CSIDVar1 ;
  SET CSIDVar1 ;
  IF Type = 2 THEN DO ;
    CALL SYMPUTX("IDvarNull", "''" ) ;
    CALL SYMPUTX("IDvarLen", CATT("$",Length,"."));
  END ;
  ELSE DO ;
    CALL SYMPUTX("IDvarNull", "." ) ;
    CALL SYMPUTX("IDvarLen", "8.") ;
  END ;
 run ;


 ** Set up input dataset one **;

 ** Identify spell variables **;
 PROC CONTENTS DATA = &CSinfile1 (KEEP = &CSSpell1_Vars)
  NOPRINT 
  OUT = CSinflieVars1 ;
 run ;

 DATA CSinflieVars1 ;
  SET CSinflieVars1 ;

  LENGTH CStat1Lgth 8. ;
  RETAIN CStat1Lgth ;
  IF _N_ = 1 THEN CStat1Lgth = 0 ;
  CALL SYMPUTX("CS1_VarN", STRIP(_N_) ) ;
  CALL SYMPUTX("CS1_Var"||STRIP(_N_) , name) ;

  LENGTH LengthStat $250. ;
  IF Type = 2 THEN DO ;
     LengthStat = "$"||STRIP(Length+1)||"." ; 
     CStat1Lgth = CStat1Lgth + Length + 1 ;
  END ;
  ELSE DO ;
     LengthStat ="8." ;
     CStat1Lgth = CStat1Lgth + 20 ;
  END ;
  CALL SYMPUTX("CS1_Len"||STRIP(_N_) ,LengthStat) ;

  IF format = "" THEN CALL SYMPUTX("CS1_Fmt"||STRIP(_N_) ,LengthStat) ;
  ELSE DO ;
    ** Marc de Boer 22Jul2015 Included check that format length is not zero *;
    IF formatl gt 0 THEN CALL SYMPUTX("CS1_Fmt"||STRIP(_N_),  STRIP(format)||STRIP(formatl)||".");
    ELSE CALL SYMPUTX("CS1_Fmt"||STRIP(_N_), STRIP(format)||".");
  END ;
  
  CALL SYMPUTX("CStat1Lgth", "$"||STRIP(MAX(15, CStat1Lgth))||"." ) ;
 run ;

 DATA CSinfile1_v1 (DROP = &CSSpell1_Vars)  ;
  LENGTH CSidvar &IDvarLen
         CSSpell1_SD 
         CSSpell1_ED 8. ;
  FORMAT CSSpell1_SD 
         CSSpell1_ED &DTformat  ;
  SET &CSinfile1 (KEEP = &CSidvar 
                         &CSSpell1_Vars 
                         &CSSpell1_SD 
                         &CSSpell1_ED
                  RENAME = (&CSidvar = CSidvar 
                            &CSSpell1_SD = CSSpell1_SD 
                            &CSSpell1_ED = CSSpell1_ED
                            )
                 WHERE = (    CSidvar ne &IDvarNull
                          AND CSSpell1_SD ne .
                          AND CSSpell1_ED ne .
                         )   
                 ) ;

  ** MdB 2015 10 27 Enure dates are integer values **;
  CSSpell1_SD = INT(CSSpell1_SD) ;
  CSSpell1_ED = INT(CSSpell1_ED) ;

  ** Convert spell variables into a single string **;
  LENGTH CondStats1 &CStat1Lgth ;
  %MACRO constat1 ;
     %DO i = 1 %TO &CS1_VarN ;
        CondStats1 = STRIP(CondStats1)||"~"||STRIP(&&CS1_Var&i) ;
        %IF &i = 1 %THEN %DO ; 
          CondStats1 = COMPRESS(CondStats1,"~") ;
        %END ;
     %END ;
  %MEND ;
  %constat1 ;
 run ;

 %SpellCondense( SCinfile = CSinfile1_v1
                ,SCoutfile = CSinfile1_v2
                ,SClink = CSidvar 
                ,SCstart = CSSpell1_SD
                ,SCend_d = CSSpell1_ED
                ,SCstatus = CondStats1
                ,SCbuffer = 1) ;

 %SpellHistoryInverter(  SHIinfile = CSinfile1_v2 
                       , SHIoutfile = CSinfile1_v3 
                       , SHIlink = CSidvar
                       , SHIspellSD = CSSpell1_SD
                       , SHIspellED = CSSpell1_ED
                       ) ;
  
 %LET ByVars = CSidvar CSSpell1_SD CSSpell1_ED;
 PROC SORT DATA = CSinfile1_v3  ; BY &ByVars ; run ;
 PROC SORT DATA = CSinfile1_v2; BY &ByVars ; run ;

 DATA CSinfile1_v4  (DROP = OrginalSpell Temp:) ;
  MERGE CSinfile1_v2(IN=A)
        CSinfile1_v3(IN=B) ;
  BY &ByVars ;
  IF B ;
  IF NOT A THEN CondStats1 = "<Blank Spell>" ;
  OUTPUT ;

  Temp1SD = CSSpell1_SD ;
  Temp1ED = CSSpell1_ED ;
  IF first.CSidvar THEN DO ;
      CondStats1 = "<Blank Spell>" ;
      CSSpell1_ED = Temp1SD - 1;
      CSSpell1_SD = &ShrtEndSD - 1;
      OUTPUT ;
      CSSpell1_ED = Temp1ED ; ** Switch end date back MdB 2015 10 15 **;
  END ;
  IF last.CSidvar THEN DO ;
      CondStats1 = "<Blank Spell>" ;
      CSSpell1_SD = Temp1ED + 1;
      CSSpell1_ED = &LongEndED + 1 ;
      OUTPUT ;
  END ;
 run ;

 %LET ByVars = CSidvar CSSpell1_SD ;
 PROC SORT DATA = CSinfile1_v4; BY &ByVars ; run ;

 *PROC PRINT DATA = CSinfile1_v4 (obs=20 WHERE = (CondStats1 = "<Blank Spell>") ) ; run ;

 ** Set up input dataset two **;

 ** Identify spell variables **;
 PROC CONTENTS DATA = &CSinfile2 (KEEP = &CSSpell2_Vars)  
  NOPRINT
  OUT = CSinflieVars2 ;
 run ;

 DATA CSinflieVars2 ;
  SET CSinflieVars2 ;

  LENGTH CStat2Lgth 8. ;
  RETAIN CStat2Lgth ;
  IF _N_ = 1 THEN CStat2Lgth = 0 ;
  CALL SYMPUTX("CS2_VarN", STRIP(_N_) ) ;
  CALL SYMPUTX("CS2_Var"||STRIP(_N_) , name) ;

  LENGTH LengthStat $250. ;
  IF Type = 2 THEN DO ;
     LengthStat = "$"||STRIP(Length+1)||"." ; 
     CStat2Lgth = CStat2Lgth + Length + 1 ;
  END ;
  ELSE DO ;
     LengthStat ="8." ;
     CStat2Lgth = CStat2Lgth + 20 ;
  END ;
  CALL SYMPUTX("CS2_Len"||STRIP(_N_) ,LengthStat) ;

  IF format = "" THEN CALL SYMPUTX("CS2_Fmt"||STRIP(_N_) ,LengthStat) ;
  ELSE DO ;
    ** Marc de Boer 22Jul2015 Included check that format length is not zero *;
    IF formatl gt 0 THEN CALL SYMPUTX("CS2_Fmt"||STRIP(_N_),  STRIP(format)||STRIP(formatl)||".");
    ELSE CALL SYMPUTX("CS2_Fmt"||STRIP(_N_), STRIP(format)||".");
  END ;
 
  CALL SYMPUTX("CStat2Lgth", "$"||STRIP(MAX(15, CStat2Lgth))||"." ) ;
 run ;

 DATA CSinfile2_v1 (DROP = &CSSpell2_Vars)  ;
  LENGTH CSidvar &IDvarLen
         CSSpell2_SD 
         CSSpell2_ED 8. ;
  FORMAT CSSpell2_SD 
         CSSpell2_ED  &DTformat;
  SET &CSinfile2 (KEEP = &CSidvar 
                         &CSSpell2_Vars 
                         &CSSpell2_SD 
                         &CSSpell2_ED
                  RENAME = (&CSidvar = CSidvar 
                            &CSSpell2_SD = CSSpell2_SD 
                            &CSSpell2_ED = CSSpell2_ED
                            )
                 WHERE = (    CSidvar ne &IDvarNull
                          AND CSSpell2_SD ne .
                          AND CSSpell2_ED ne .
                         )   
                 ) ;

  ** MdB 2015 10 27 Ensure dates are integer values **;
  CSSpell2_SD = INT(CSSpell2_SD) ;
  CSSpell2_ED = INT(CSSpell2_ED) ;

  LENGTH CondStats2 &CStat2Lgth ;
  %MACRO constat2 ;
     %DO i = 1 %TO &CS2_VarN ;
        CondStats2 = STRIP(CondStats2)||"~"||STRIP(&&CS2_Var&i) ;
        %IF &i = 1 %THEN %DO ; 
          CondStats2 = COMPRESS(CondStats2,"~") ;
        %END ;
     %END ;
  %MEND ;
  %constat2 ;
 run ;

  %SpellCondense( SCinfile = CSinfile2_v1
                ,SCoutfile = CSinfile2_v2
                ,SClink = CSidvar 
                ,SCstart = CSSpell2_SD
                ,SCend_d = CSSpell2_ED
                ,SCstatus = CondStats2
                ,SCbuffer = 1) ;

 %SpellHistoryInverter(  SHIinfile = CSinfile2_v2 
                       , SHIoutfile = CSinfile2_v3 
                       , SHIlink = CSidvar
                       , SHIspellSD = CSSpell2_SD
                       , SHIspellED = CSSpell2_ED
                       ) ;
  
 %LET ByVars = CSidvar CSSpell2_SD CSSpell2_ED ;
 PROC SORT DATA = CSinfile2_v3  ; BY &ByVars ; run ;
 PROC SORT DATA = CSinfile2_v2; BY &ByVars ; run ;

 DATA CSinfile2_v4  (DROP = OrginalSpell Temp:) ;
  MERGE CSinfile2_v2(IN=A)
        CSinfile2_v3(IN=B) ;
  BY &ByVars ;
  IF B ;
  IF NOT A THEN CondStats2 = "<Blank Spell>" ;
  OUTPUT ;

  Temp1SD = CSSpell2_SD ;
  Temp1ED = CSSpell2_ED ;
  IF first.CSidvar THEN DO ;
      CondStats2 = "<Blank Spell>" ;
      CSSpell2_ED = Temp1SD - 1;
      CSSpell2_SD = &ShrtEndSD -1 ;
      OUTPUT ;
      CSSpell2_ED = Temp1ED ; ** Switch end date back MdB 2015 10 15 **;
  END ;
  IF last.CSidvar THEN DO ;
      CondStats2 = "<Blank Spell>" ;
      CSSpell2_SD = Temp1ED + 1;
      CSSpell2_ED = &LongEndED + 1;
      OUTPUT ;
  END ;
 run ;

 %LET ByVars = CSidvar CSSpell2_SD ;
 PROC SORT DATA = CSinfile2_v4; BY &ByVars ; run ;

* PROC PRINT DATA = CSinfile2_v4 (obs=20 WHERE = (CondStats2 = "<Blank Spell>") ) ; run ;

 ** identify overlapping spells between the two **;
  PROC SQL ;
  CREATE TABLE CSdataset1 AS
  SELECT  a.CSidvar
         ,a.CondStats1
         ,a.CSSpell1_SD
         ,a.CSSpell1_ED
         ,b.CondStats2
         ,b.CSspell2_SD
         ,b.CSSpell2_ED
         ,MAX(CSSpell1_SD, CSSpell2_SD) AS CSspellSD FORMAT=&DTformat
         ,MIN(CSSpell1_ED, CSSpell2_ED) AS CSspellED FORMAT=&DTformat
  FROM CSinfile1_v4 AS a
       JOIN 
       CSinfile2_v4 AS b
  ON       a.CSidvar = b.CSidvar
       AND a.CSSpell1_SD le b.CSSpell2_ED
       AND a.CSSpell1_ED ge b.CSspell2_SD
 ;
 quit ;

 ** Identify any dataset one spells not included in the match *;
 %LET ByVars = CSidvar CSSpell1_SD ;
 PROC SORT DATA = CSdataset1 
     OUT = CStemp1 (KEEP = &ByVars) 
     NODUPKEY ; 
     BY &ByVars ;
 run ;
 PROC SORT DATA = CSinfile1_v4 ; BY &ByVars ; run ;

 DATA  CSinfile1_v5 (SORTEDBY = &ByVars) ;
  MERGE CSinfile1_v4 (IN=A)
        CStemp1 (IN=B) ;
  BY &ByVars ;
  IF A AND NOT B ;
  CondStats2 = "<Blank Spell>" ;
 run ;

  ** Identify any dataset two spells not included in the match *;
 %LET ByVars = CSidvar CSSpell2_SD ;
 PROC SORT DATA = CSinfile2_v4 ; BY &ByVars ; run ;
 PROC SORT DATA = CSdataset1 
     OUT = CStemp2 (KEEP = &ByVars) 
     NODUPKEY ; 
     BY &ByVars ;
 run ;

 DATA  CSinfile2_v5 (SORTEDBY = &ByVars) ;
  MERGE CSinfile2_v4 (IN=A)
        CStemp2 (IN=B) ;
  BY &ByVars ;
  IF A AND NOT B ;
  CondStats1 = "<Blank Spell>" ;
 run ;

 ** Combine all spells into a single file **;
 DATA &CSoutfile (KEEP = CSidvar 
                         CSspellSD 
                         CSspellED 
                         &CSSpell1_Vars 
                         &CSSpell2_Vars
                  RENAME = (CSidvar = &CSidvar) 
                 ) ;
  SET CSdataset1 (KEEP = CSidvar 
                         CSspellSD 
                         CSspellED 
                         CondStats:
                  ) 
      CSinfile1_v5 (KEEP = CSidvar 
                         CSSpell1_SD 
                         CSSpell1_ED 
                         CondStats:
                    RENAME = (CSSpell1_SD = CSspellSD 
                              CSSpell1_ED = CSspellED 
                             )
                   ) 
      CSinfile2_v5 (KEEP = CSidvar 
                         CSSpell2_SD 
                         CSSpell2_ED 
                         CondStats:
                    RENAME = (CSSpell2_SD = CSspellSD 
                              CSSpell2_ED = CSspellED 
                             )
                   );

  ** if both spells have null values then remove from output *;
  IF CondStats1 = "<Blank Spell>" 
     AND CondStats2 = "<Blank Spell>" THEN DELETE ;

  * convert condensed spell variables into their orgianl vraible
    names lengths and formats *;
  * Marc de Boer 2014 05 09 TRANWARD removes multiple values (ie two variables with the same value)
                            re-orged the code to just take the first. *; 
  %MACRO UnpackVars ;
   %DO c = 1 %TO 2 ;
   %DO i = 1 %TO &&CS&c._VarN ;
      LENGTH &&CS&c._Var&i &&CS&c._Len&i ;
      FORMAT &&CS&c._Var&i &&CS&c._Fmt&i ;
      LENGTH temp4 $1000. ;
      IF CondStats&c = "<Blank Spell>" THEN DO ;
          IF SUBSTR("&&CS&c._Len&i", 1, 1) = "$" THEN &&CS&c._Var&i = "" ;
          ELSE &&CS&c._Var&i = . ;
      END ;
      ELSE DO ;
          i = &i ;
          v = &&CS&c._VarN ;
          l = LENGTH(CondStats&c) ;
          CondStatsStart = CondStats&c ;
          IF &i lt &&CS&c._VarN THEN DO ;
             Temp3 = FIND(CondStats&c, "~", "t") ;
             temp4 = SUBSTR(STRIP(CondStats&c), 1, temp3) ;
             LENGTH CondVarStart $500. ;
             CondVarStart = temp4 ;
             CondStats&c = SUBSTR(STRIP(CondStats&c), LENGTH(temp4)+1 ) ;
             *CondStats&c = STRIP(TRANWRD(CondStats&c, STRIP(temp4), "")) ;
          END ;
          ELSE temp4  = CondStats&c ;

          &&CS&c._Var&i = COMPRESS(STRIP(temp4),"~") ; ** temp4 can now convert to numeric *;
      END ;
   %END ;
   %END ;

  %MEND ;
  %UnpackVars ;
 run ;

 PROC DATASETS LIB = work NOLIST ; 
  DELETE CSinfile:
         CSINFLIEVARS: 
         CSdataset: 
         CStemp:
         CSIDVar:
         ; 
 run ;

 %PUT ***;
 %PUT *** End of Combine Spell Macro;
 %PUT ***;
 %PUT ;

 %MEND ;

 
********************************************************************************************************;

  /*
 TITLE: Random checks of records to see if SpellCombine to see
        if the combined dataset produces the same values as 
        the two seperate files. 


 AUTHOR: Marc de Boer

 DATE: October 2015
*/;




 %MACRO SplCombineVald(RCVLib = work 
                      ,RCVPrimKey =  
                      ,RCVtestN = 
                      ,RCV1_infile =
                      ,RCV1_EffFrm =  
                      ,RCV1_EffTo =  
                      ,RCV1_Vars = 
                      ,RCV2_infile = 
                      ,RCV2_EffFrm =  
                      ,RCV2_EffTo =  
                      ,RCV2_Vars = 
                      ,RCVombinedFile =  
                      ) ;


/* for testing **;

%LET SubCaluse = cvid =  348535 ;
DATA test1 ;
  SET JOB_VLicences2 (WHERE = (&SubCaluse ) ) ; 
 run ;

DATA test2 ;
  SET DriverLicenceClassCV2 (WHERE = (&SubCaluse ) ) ; 
 run ;

 %LET RCVLib = work ;
 %LET RCVPrimKey = CVid ;
 %LET RCVtestN = 1 ;

 %LET RCV1_infile =EAtest2 ;
 %LET RCV1_EffFrm = participation_sd ;
 %LET RCV1_EffTo = ValidTo ;
 %LET RCV1_Vars = CVS_DriverLicenceType
                  CVS_DriverLicenceTypeID
                  DriverLicenceExpiryDate ;

 %LET RCV2_infile = test2 ;
 %LET RCV2_EffFrm = ValidFrom ;
 %LET RCV2_EffTo = ValidTo ;
 %LET RCV2_Vars = DriverLicenceClassID
                  DriverLicenceClass
                  DriverLicenceTypeID
                  DriverLicenceType
                  AutomaticTransmission
                  TwoHundredHoursExp ;

 %LET RCVombinedFile = JOB_VLicences3 ;

**/
  ** Detmine spell date format **;
 PROC CONTENTS DATA = &RCVLib..&RCV1_infile. (KEEP = &RCV1_EffFrm. ) 
   OUT = RCVtemp0 (RENAME = (name = variable) )
   NOPRINT ;
 run ;

 DATA RCVtemp0 ;
  SET RCVtemp0 ;
  IF formatl gt 0 THEN CALL SYMPUTX("RCV_SpllFormat", CATT(format,formatl,'.') ) ;
  ELSE CALL SYMPUTX("RCV_SpllFormat", CATT(format,'.') ) ;
 run ;

 %PUT Spell format (based on infile 1 spell start): &RCV_SpllFormat. ;

 PROC PRINT DATA = &syslast. (obs=20) ; run ;
  ** Determine minimum and maximum repdate *;
 PROC MEANS DATA = &RCVLib..&RCV1_infile. NOPRINT NWAY MISSING ;
  OUTPUT OUT = RCVtemp1 (DROP = _TYPE_ _FREQ_ )
   MIN(&RCV1_EffFrm.) = MinEffFrm 
   MAX(&RCV1_EffTo.) = MaxRCCEffTo 
   ;
 run ;

 PROC MEANS DATA = &RCVLib..&RCV2_infile. NOPRINT NWAY MISSING ;
  OUTPUT OUT = RCVtemp2 (DROP = _TYPE_ _FREQ_ )
   MIN(&RCV2_EffFrm.) = MinEffFrm 
   MAX(&RCV2_EffTo.) = MaxRCCEffTo 
   ;
 run ;

 DATA RCVtemp3 ;
  SET RCVtemp1
      RCVtemp2 ;
 run ;

 PROC MEANS DATA = RCVtemp3 NOPRINT NWAY MISSING ;
  OUTPUT OUT = RCVtemp3 (DROP = _TYPE_ _FREQ_ )
   MIN(MinEffFrm) = MinEffFrm 
   MAX(MaxRCCEffTo) = MaxRCCEffTo 
   ;
 run ;

 DATA RCVtemp3 ;
  SET RCVtemp3 ;
  CALL SYMPUTX("MinEffFrm", MinEffFrm ) ;
  CALL SYMPUTX("MaxEffTo", MaxRCCEffTo) ;
 run ;

 %PUT First Replication date: &MinEffFrm. ;
 %PUT Last Replication date: &MaxEffTo. ;

 ** Select sample of primary key ids for testing *;
 %LET ByVars = &RCVPrimKey. ;
 PROC SORT DATA = &RCVLib..&RCV1_infile.
  OUT = RCVtestids1 (KEEP = &ByVars)
  NODUPKEY ;
  BY &ByVars. ;
 run ;

 %LET ByVars = &RCVPrimKey. ;
 PROC SORT DATA = &RCVLib..&RCV2_infile.
  OUT = RCVtestids2 (KEEP = &ByVars)
  NODUPKEY ;
  BY &ByVars. ;
 run ;

 DATA RCVtestids3 ;
  SET RCVtestids1
      RCVtestids2 ;
 run ;

 %LET ByVars = &RCVPrimKey. ;
 PROC SORT DATA = RCVtestids3
  NODUPKEY ;
  BY &ByVars. ;
 run ;

 ** check whether key is character *;
 PROC CONTENTS DATA = RCVtestids3
   OUT = RCVtemp6 (RENAME = (name = variable) )
   NOPRINT ;
 run ;

 DATA RCVtemp6 ;
  SET RCVtemp6 ;
  IF type = 2 THEN CALL SYMPUTX("RCV_PKchar", "$" ) ;
  ELSE CALL SYMPUTX("RCV_PKchar", "" ) ;
 run ;

 %PUT Primary key character format: &RCV_PKchar. ;

 DATA RCVtestids3  ;
  RETAIN &ByVars ;
  SET RCVtestids3;
  Select = NORMAL(0) ;
 run ;

 %LET ByVars = Select ;
 PROC SORT DATA = RCVtestids3 ; BY &ByVars ; run ;

 DATA RCVtestids3 ;
  SET RCVtestids3 (DROP = select OBS = &RCVtestN.);
 run ;

 %USE_FMT(RCVtestids3, &RCVPrimKey., RCV_tst_ids) ;

 ** Generate random list of dates to check *;
 DATA RCVtestidsdates1 (KEEP =  &RCVPrimKey. CheckDate) ;
  SET RCVtestids3  ;
  FORMAT CheckDate &RCV_SpllFormat. ;
  PeriodDur = &MaxEffTo - &MinEffFrm ;
  DO i = 1 TO 100 ;
     DateSelect = INT(UNIFORM(0) * PeriodDur) ;
     CheckDate = &MinEffFrm + DateSelect ;
     OUTPUT ;
  END ;
 run ;

 ** remove any duplicate random check dates *;
 %LET ByVars = &RCVPrimKey. CheckDate;
 PROC SORT DATA = RCVtestidsdates1 NODUPKEY ; BY &ByVars ; run ;

 ** Set up infiles **;

  ** Create a string of the check variables in dataset 1 **;
 PROC CONTENTS DATA = &RCVLib..&RCV1_infile. (KEEP = &RCV1_Vars.)
  NOPRINT 
  OUT = RCVtemp10;
 run ;

 DATA RCVtemp10 ;
  SET RCVtemp10 (WHERE = (LOWCASE(name) ne LOWCASE("&RCVPrimKey.") ) ) ;

  LENGTH RpCbtat1Lgth 8. ;
  RETAIN RpCbtat1Lgth ;
  IF _N_ = 1 THEN RpCbtat1Lgth = 0 ;
  CALL SYMPUTX("RCV1_VarN", STRIP(_N_) ) ;
  CALL SYMPUTX("RCV1_Var"||STRIP(_N_) , name) ;

  LENGTH LengthStat $250. ;
  IF Type = 2 THEN DO ;
     LengthStat = "$"||STRIP(Length+1)||"." ; 
     RpCbtat1Lgth = RpCbtat1Lgth + Length + 1 ;
  END ;
  ELSE DO ;
     LengthStat ="8." ;
     RpCbtat1Lgth = RpCbtat1Lgth + 20 ;
  END ;
  
  CALL SYMPUTX("RCV1Lgth", "$"||STRIP(MAX(15, RpCbtat1Lgth))||"." ) ;
 run ;

 %PUT Number of dataset1 variables: &RCV1_VarN. ;
 %PUT Total length of dataset1 variables: &RCV1Lgth. ;

 ** Create a string of the check variables in dataset 2 **;
 PROC CONTENTS DATA = &RCVLib..&RCV2_infile. (KEEP = &RCV2_Vars.)
  NOPRINT 
  OUT = RCVtemp10;
 run ;

 DATA RCVtemp10 ;
  SET RCVtemp10 (WHERE = (LOWCASE(name) ne LOWCASE("&RCVPrimKey.") ) ) ;

  LENGTH RpCbtat1Lgth 8. ;
  RETAIN RpCbtat1Lgth ;
  IF _N_ = 1 THEN RpCbtat1Lgth = 0 ;
  CALL SYMPUTX("RCV2_VarN", STRIP(_N_) ) ;
  CALL SYMPUTX("RCV2_Var"||STRIP(_N_) , name) ;

  LENGTH LengthStat $250. ;
  IF Type = 2 THEN DO ;
     LengthStat = "$"||STRIP(Length+1)||"." ; 
     RpCbtat1Lgth = RpCbtat1Lgth + Length + 1 ;
  END ;
  ELSE DO ;
     LengthStat ="8." ;
     RpCbtat1Lgth = RpCbtat1Lgth + 20 ;
  END ;
  
  CALL SYMPUTX("RCV2Lgth", "$"||STRIP(MAX(15, RpCbtat1Lgth))||"." ) ;
 run ;

 %PUT Number of dataset1 variables: &RCV2_VarN. ;
 %PUT Total length of dataset1 variables: &RCV2Lgth. ;


 ** prep and subset input and output datasets **;

 ** Input dataset 1 **;
 DATA RCV1_Input1 ;
  SET &RCVLib..&RCV1_infile. (KEEP =&RCVPrimKey. &RCV1_Vars. &RCV1_EffFrm. &RCV1_EffTo.
                             WHERE = (PUT(&RCVPrimKey., &RCV_PKchar.RCV_tst_ids.) = "Y") 
                             ) ;

 run ;

 ** Input dataset 2 **;
 DATA RCV2_Input1 ;
  SET &RCVLib..&RCV2_infile. (KEEP =&RCVPrimKey. &RCV2_Vars. &RCV2_EffFrm. &RCV2_EffTo.
                             WHERE = (PUT(&RCVPrimKey., &RCV_PKchar.RCV_tst_ids.) = "Y") 
                             ) ;

 run ;

 ** Output dataset **;
 DATA RCV_output1 ;
  SET &RCVLib..&RCVombinedFile. (KEEP =&RCVPrimKey. &RCV1_Vars. &RCV2_Vars. CSspellSD CSspellED
                             WHERE = (PUT(&RCVPrimKey., &RCV_PKchar.RCV_tst_ids.) = "Y") 
                             ) ;


 run ;

 ** Extract check vars for select dates **;

 ** Input datasets **;
 PROC SQL ;
  CREATE TABLE RCV1_Input2 (RENAME = (&RCV1_EffFrm. = ValidFrom1_IN
                                      &RCV1_EffTo. = ValidTo1_IN
                                      ) 
                            ) AS
  SELECT a.*
        ,b.*
  FROM RCVtestidsdates1 AS a
       LEFT JOIN 
       RCV1_Input1 AS b
  ON       a.&RCVPrimKey. = b.&RCVPrimKey.  
       AND a.CheckDate BETWEEN b.&RCV1_EffFrm. AND b.&RCV1_EffTo.
 ;
 quit ;

 PROC SQL ;
  CREATE TABLE RCV2_Input2 (RENAME = (&RCV2_EffFrm. = ValidFrom2_IN
                                      &RCV2_EffTo. = ValidTo2_IN
                                      ) 
                            ) AS
  SELECT a.*
        ,b.*
  FROM RCVtestidsdates1 AS a
       LEFT JOIN 
       RCV2_Input1 AS b
  ON       a.&RCVPrimKey. = b.&RCVPrimKey.  
       AND a.CheckDate BETWEEN b.&RCV2_EffFrm. AND b.&RCV2_EffTo.
 ;
 quit ;

 %LET ByVars = &RCVPrimKey. CheckDate ;
 PROC SORT DATA = RCV1_Input2 ; BY &ByVars ; run ;
 PROC SORT DATA = RCV2_Input2 ; BY &ByVars ; run ;

 DATA RCV_InputValid1  (SORTEDBY = &ByVars) ;
  RETAIN &ByVars ;
  MERGE RCV1_Input2 (IN=A)
        RCV2_Input2 (IN=B) ;
  BY &ByVars ;
  IF A OR B ;

  LENGTH CondStats1 &RCV1Lgth.  CondStats2 &RCV2Lgth.;
  %MACRO constat1 ;
     %DO i = 1 %TO &RCV1_VarN ;
        CondStats1 = STRIP(CondStats1)||"~"||STRIP(&&RCV1_Var&i) ;
        %IF &i = 1 %THEN %DO ; 
          CondStats1 = COMPRESS(CondStats1,"~") ;
        %END ;
     %END ;
  %MEND ;
  %constat1 ;
  %MACRO constat2 ;
     %DO i = 1 %TO &RCV2_VarN ;
        CondStats2 = STRIP(CondStats2)||"~"||STRIP(&&RCV2_Var&i) ;
        %IF &i = 1 %THEN %DO ; 
          CondStats2 = COMPRESS(CondStats2,"~") ;
        %END ;
     %END ;
  %MEND ;
  %constat2 ;

  CheckVarAllMD5 = PUT(MD5(COMPRESS(CATT(CondStats1, CondStats2),' ','s')),hex32.) ; ; ;
  DROP &RCV1_Vars. &RCV2_Vars. ;
 run ;

 ** Output dataset **;
 PROC SQL ;
  CREATE TABLE RCV_output2  AS
  SELECT a.*
        ,b.*
  FROM RCVtestidsdates1 AS a
       LEFT JOIN 
       RCV_output1 AS b
  ON       a.&RCVPrimKey. = b.&RCVPrimKey.  
       AND a.CheckDate BETWEEN b.CSspellSD AND b.CSspellED
 ;
 quit ;

 DATA RCV_output3 ;
  SET RCV_output2 ;

  LENGTH CondStats1 &RCV1Lgth.  CondStats2 &RCV2Lgth.;
  %MACRO constat1 ;
     %DO i = 1 %TO &RCV1_VarN ;
        CondStats1 = STRIP(CondStats1)||"~"||STRIP(&&RCV1_Var&i) ;
        %IF &i = 1 %THEN %DO ; 
          CondStats1 = COMPRESS(CondStats1,"~") ;
        %END ;
     %END ;
  %MEND ;
  %constat1 ;
  %MACRO constat2 ;
     %DO i = 1 %TO &RCV2_VarN ;
        CondStats2 = STRIP(CondStats2)||"~"||STRIP(&&RCV2_Var&i) ;
        %IF &i = 1 %THEN %DO ; 
          CondStats2 = COMPRESS(CondStats2,"~") ;
        %END ;
     %END ;
  %MEND ;
  %constat2 ;

  CheckVarAllMD5 = PUT(MD5(COMPRESS(CATT(CondStats1, CondStats2),' ','s')),hex32.) ; ;
  DROP &RCV1_Vars. &RCV2_Vars. ;

 run ;

 ** Compare input and output results **;
 %LET MatchNotOK = 0 ;
 %LET ByVars = &RCVPrimKey. CheckDate CheckVarAllMD5 ;
 PROC SORT DATA = RCV_InputValid1; BY &ByVars ; run ;
 PROC SORT DATA = RCV_output3; BY &ByVars ; run ;

 DATA RCV_ValidationChk1 (DROP = CheckVarAllMD5) ;
  RETAIN &ByVars  ;
  MERGE RCV_InputValid1(IN=A)
        RCV_output3 (IN=B) ;
  BY &ByVars ;
  IF A OR B ;

  LENGTH match $10. ;
  Match = "OK" ;
  IF NOT(A AND B) THEN DO ;
    Match = "Not OK" ; 
    CALL SYMPUTX("MatchNotOK", 1) ;
  END ;
 run ;

 %LET ClassVars = Match ;
 PROC MEANS DATA = RCV_ValidationChk1 NOPRINT NWAY MISSING ;
  CLASS &ClassVars.;
  OUTPUT OUT = RCV_ValidationSum (SORTEDBY = &ClassVars.
                    DROP = _TYPE_ _FREQ_ )
   N(CheckDate) = Observations  
    ;
 run ;

 PROC PRINT DATA = RCV_ValidationSum (obs=20) ; run ;
 PROC PRINT DATA = RCV_ValidationChk1 (obs=20 WHERE = (Match = "Not OK" ) ) ; run ;
 
 %IF &MatchNotOK = 1 %THEN %DO ;
    %LET ByVars = &RCVPrimKey. CheckDate ;
    PROC SORT DATA = RCV_ValidationChk1 (obs=1 WHERE = (Match = "Not OK" ) )
      OUT = ErrorEvents1 (KEEP = &ByVars) NODUPKEY ; 
      BY &ByVars ; 
    run ;
  
    %LET ByVars = &RCVPrimKey. CheckDate ;
    PROC SORT DATA = ErrorEvents1 ; BY &ByVars ; run ;
    PROC SORT DATA = RCV_output3 ; BY &ByVars ; run ;

    DATA RCV_NotOKoutput1  (SORTEDBY = &ByVars) ;
      RETAIN &ByVars ;
      MERGE RCV_output3 (IN=A)
            ErrorEvents1 (IN=B KEEP = &ByVars) ;
      BY &ByVars ;
      IF A AND B ;
     run ;

    %LET ByVars = &RCVPrimKey. CheckDate ;
    PROC SORT DATA = ErrorEvents1 ; BY &ByVars ; run ;
    PROC SORT DATA = RCV_InputValid1 ; BY &ByVars ; run ;

    DATA RCV_NotOKinput1  (SORTEDBY = &ByVars) ;
      RETAIN &ByVars ;
      MERGE RCV_InputValid1 (IN=A   )
            ErrorEvents1 (IN=B KEEP = &ByVars) ;
      BY &ByVars ;
      IF A AND B ;
     run ;

     PROC PRINT DATA = RCV_NotOKinput1 (obs=20) ; run ;
     PROC PRINT DATA = RCV_NotOKoutput1 (obs=20) ; run ;
 %END ;


 PROC DATASETS LIB = work NOLIST ;
  DELETE RCV_output: RCV_InputValid: RCV2_Input: RCV1_Input: RCVtemp: ;
 run ;
 
 %MEND ;

************************************************************************************************************************************; 
 
/*  
    TITLE:  Spell Condense Macro

    PURPOSE: Macro combines consecutive spells of the same status*
        SCLink: the id that identified the spells (eg swn or client_id) 
        SCstart and SCend_d: the spell start and end date (participation_sd and participation_ed)
        SCstatus: the variable(s) the identifies which spells are alike (ie only join consecutive spells of the same programme).
        SCbuffer: the size of the gap between spells which will be joined (eg buffer of 40 will join spells seperated by less than 40 days)

    AUTHOR: Marc de Boer, OWPA RE, CSRE, MSD

    DATE: March 2011

     MODIFCATIONS
     BY             WHEN      WHY
     Marc de Boer   Oct2011   The condense macro was not handelling complex spell history adjusted to loop
                              until all overlapping spells are removed.  Also included batch processing to 
                              reduce load on the SQL.
     Marc de Boer   Oct2011   The condense macro was not condensing adjoing spells into a single spell. Corrected by including the
                              buffer varibale into the SQL statement.
     Marc de Boer   Nov2011   The macro can get into a infanit loop. Included a check to make sure the code exits when this happens
     Marc de Boer   Feb2012   The step that removed nested spells was removing some first spells. Included a clause to stop the 
                              deletion of first spells.
     Marc de Boer   March2012 The merge hist was having a problem with status field made of numerials. Corrected code to handel this.
     Marc de Boer   April2012 Condense: included check when removing nested spells that they have the same status.
     Marc de Boer   Feb2014   Included final step to adjust spell end dates that are equal to the next spell sd
                               subtracted 1 from the spell end date.
     Marc de Boer   Feb2014   CONDdataset4: Calculation included (1+buffer) this missed one interval long spells. 
                              Changed to just (+ buffer)
     Marc de Boer   Jul2015   Removed delete of [SCoutfile] dataset as it is not required
     Marc de Boer   Aug2015   In cases were there are still overlapping spells that cannot be resolved then include
                              them in the final output so the output file has all the spells included in the infile.

*/


       ***                       ***;
       *** Condense Spells Macro ***;
       ***                       ***;

/*
 %SpellCondense( SCinfile =
                ,SCoutfile =
                ,SClink =
                ,SCstart =
                ,SCend_d =
                ,SCstatus =
                ,SCbuffer = ) ;


*
Inputs
 SCinfile: dataset with spells to be condensed
 SClink: unique identifier (eg snz_uid)
 SCstart: start date of spell
 SCend_d: end date of spell
 SCstatus: value of spell (eg benefit type) 
           can include multiple variables (eg benefit type and service centre).
           If multiple variables selected these are treated as a string.
 SCbuffer: specifies the minimum gap between spells (eg 14 would combine spells
           seperated by less than 14 days. Default is 1.
*;
*/




        ***                ***;
        *** Condense macro ***;
        ***                ***;

 %MACRO SpellCondense( SCinfile
                     ,SCoutfile
                     ,SClink
                     ,SCstart
                     ,SCend_d
                     ,SCstatus
                     ,SCbuffer = 1) ;

 
 %PUT *** Start of Condense Macro AT: IAP: /r00/msd/shared/ssi/macros/  ***;                                                                 ***;
 
/*

 DATA test ;
  SET SwiftUi_StaffId1 ;
 run ;

 %LET SCinfile = test  ;
 %LET SCoutfile = test1 ;
 %LET SClink = staff_no ;
 %LET SCstart = CSspellSD ;
 %LET SCend_d = CSspellED ;
 %LET SCstatus =SWFTusrcd  ;
 %LET SCbuffer = 1 ;
*/

 ** Create input file with status variable *;
 /*PROC DATASETS LIB = work NOLIST ; DELETE &SCoutfile ; run ;*/
 * Marc de Boer 2015 07 29 Removed this as it is not required and generates error if the library is
   included on the [SCoutfile] macro variable *;

 ** Create condense status variable **;
  * MdB 2014 05 08 Inculded STRIP to remove trailing blanks *;
 DATA CONDtemp1 ;
  Temp1 = COMPBL("&SCstatus") ;
  CondenseStatement = TRANWRD(STRIP(Temp1), " ", " || ") ;
  CALL SYMPUT("CondenseStatement", "CondenseStats = " || STRIP(CondenseStatement) ) ;
 run ;
 
 DATA CONDdataset1 (RENAME = (&SCstart = t_sd 
                              &SCend_d = t_ed) 
                    KEEP = &SClink &SCstart &SCend_d CondenseStats &SCstatus);
  SET &SCinfile ;

  ** MdB 2011 11 14 Included length statement to aviod appending errors **;  
  LENGTH &SCstart &SCend_d 8. ; 
  &CondenseStatement ;

  ** MdB 2012 04 11 Removed any spaces from statement *;
  CondenseStats = COMPRESS(CondenseStats) ; 
 run ;

 

     *** very large lapse period datasets are inefficient to run through SQL
          this section of the code splits the dataset to process them in batches **;

  ** identify number of records by group variables *;
 PROC MEANS DATA = CONDdataset1 NOPRINT NWAY MISSING ;
  CLASS &SClink ;
  OUTPUT OUT = CONDtemp1  (drop = _TYPE_ _FREQ_)
    N(t_sd) = Obs
    ;
 run ;

  ** determine number of iterations needed to run (in 10 million batches) *;
 DATA CONDtemp2 (DROP = BatchRunTotal obs) ;
  SET CONDtemp1 ;

  RETAIN BatchNo BatchRunTotal 1 ;
  BatchRunTotal = BatchRunTotal + obs ;
  IF BatchRunTotal gt 50000000 THEN DO ;
     BatchNo = BatchNo + 1 ;
     BatchRunTotal = 0 ;
  END ;
  CALL SYMPUT("TotalBatches", STRIP(BatchNo) ) ; 
 run ;

 
  ** add batch number to client infile *;
 %LET ByVars = &SClink ;
 PROC SORT DATA = CONDdataset1 ; BY &ByVars ; run ;
 PROC SORT DATA = CONDtemp2 ; BY &ByVars ; run ;

 DATA CONDdataset1 ;
  MERGE CONDdataset1 (IN=A)
        CONDtemp2 (IN=B) ;
  BY &ByVars ;

 run ;

 *MdB Oct2011 Remove any duplicate records that may exit *;
  PROC SORT DATA = CONDdataset1 NODUPREC ; BY &SClink t_sd t_ed CondenseStats ; run ;
 
 PROC DATASETS LIB = work NOLIST ; DELETE CONDnonoverlap3 ; run ;

 %DO BatchNo = 1 %TO &TotalBatches ;

 
 %PUT *** Start of batch run &BatchNo of &TotalBatches ***;


/*
 OPTIONS NOTES ;
 %LET BatchNo = 1 ;
*/


 %LET overlaps = 1 ;

 DATA CONDdataset2 ;
  SET CONDdataset1 (WHERE = (BatchNo = &BatchNo) ) ;
  count = _N_+ 10 ;
  CALL SYMPUT("no_overlaps", STRIP(count) ) ;
 run ;
 %PUT Intial number of spells in the dataset: %EVAL( &no_overlaps - 10 );

   %DO %WHILE(&overlaps = 1) ; ** Start of overlaps loop *;

** MdB 17Oct 2011 Included buffer to identify overlapping and adjoining records *;
  ** identify which records overalp *;
 PROC SQL ;
  CREATE TABLE CONDtemp1 AS
  SELECT  s1.&SClink
         ,s1.CondenseStats
         ,s1.SD1
         ,s1.ED1
         ,s2.SD2
         ,s2.ED2
  FROM  CONDdataset2 (RENAME = (t_sd = SD1 t_ed = ED1) ) AS s1
        JOIN 
        CONDdataset2 (RENAME = (t_sd = SD2 t_ed = ED2) ) AS s2  
  ON        s1.&SClink = s2.&SClink
        AND s1.CondenseStats = s2.CondenseStats
  WHERE      (    SD1-&SCbuffer le ED2 
              AND ED1+&SCbuffer ge SD2
             )
         AND NOT(    SD1 = SD2 
                 AND ED1 = ED2) ;
 ;
 quit ;

 %LET pre_overlaps = &no_overlaps ; ** store the number of previous overlapse to check against *;
 %LET no_overlaps = 0 ;
 %LET overlaps = 0 ;

 %LET ByVars = &SClink CondenseStats ; **  MdB 2012 01 09  included condense status to account for overlapping spells for different status *;
 PROC SORT DATA = CONDtemp1 NODUPKEY ; BY &ByVars ; run ;
 PROC SORT DATA = CONDdataset2 ; BY &ByVars ; run ;

 DATA CONDnonoverlap1 
      CONDdataset3 ;
  MERGE CONDdataset2 (IN=A)
        CONDtemp1 (IN=B KEEP = &ByVars) ;
  BY &ByVars ;
  IF _N_ = 1 THEN overlaps = 0 ;
  RETAIN overlaps ;

  IF A AND B THEN DO ;
     OUTPUT CONDdataset3 ;
     overlaps = overlaps + 1 ;
     CALL SYMPUT("no_overlaps", STRIP(overlaps) ) ;
  END ;
  ELSE OUTPUT CONDnonoverlap1 ; 
 run ;

 %PUT Previous Number of overlapping spells: &pre_overlaps Current number: &no_overlaps ;
 

  ** MdB 2011 11 14 Check that the previous count of over lapes is larger than the current **;
 DATA CONDtemp1 ;
  ** process with loop if there are overlapping spells and that the number of overlapping spells are less
     than previous iteraction to aviod loop getting stuck *;
  IF     &no_overlaps gt 0
     AND &no_overlaps lt &pre_overlaps THEN CALL SYMPUT("overlaps",STRIP(1) ) ; 
 run ;

 %PUT Proceed with overlaps: &overlaps ;
    
 
  ** prepare OK files for output *;
 DATA CONDnonoverlap2 (KEEP = &SClink &SCstart &SCend_d &SCstatus ) ;
  SET CONDnonoverlap1 (RENAME = (t_sd = &SCstart
                                t_ed = &SCend_d
                                )
                       );
 run ;

 PROC APPEND BASE = CONDnonoverlap3 
  DATA = CONDnonoverlap2 ;
 run ;

 ** MdB 2015 08 03 If there are overlapping spells left 
                   but they cannot be removed 
                   then add them to the output *;
 %IF &overlaps = 0 %THEN %DO ;
    %IF &no_overlaps gt 0 %THEN %DO ;
        ** prepare remaining overllapping spells for output *;
       DATA CONDdataset10 (KEEP = &SClink &SCstart &SCend_d &SCstatus ) ;
        SET CONDdataset3 (RENAME = (t_sd = &SCstart
                                      t_ed = &SCend_d
                                      )
                             );
       run ;

       PROC APPEND BASE = CONDnonoverlap3 
        DATA = CONDdataset10 ;
       run ;
    %END ;
 %END ;

  ** start of remove any overlaps loop *;
  %IF &overlaps = 1 %THEN %DO ;

 ** identify the sequence of spells based on start and status *;
 PROC SORT DATA = CONDdataset3 ; BY &SClink t_sd CondenseStats ; run ;

 DATA CONDdataset4  ;
  SET CONDdataset3 ;
  BY &SClink t_sd CondenseStats ;

  FORMAT prev_sd prev_ed ddmmyy10. ;
  RETAIN seq ;

  prev_st=LAG1(CondenseStats) ;
  prev_sd=LAG1(t_sd) ;
  prev_ed=LAG1(t_ed) ;

  IF first.&SClink THEN DO ; 
     seq=1 ; 
     prev_st =CondenseStats ; 
  END ;

  ** sequence count advances if 
     1, the status changes 
     2, there is a gap longer than the buffer period *;
  IF    prev_st ne CondenseStats 
     OR t_sd - &SCbuffer gt prev_ed THEN seq=seq+1;  * buffer determines the gap between consecutive spells that can be joined *;
  ** Marc de Boer 2014 02 24 Calculation included (1+buffer) this missed 
                             one interval long spells.
                             *;
 run;

  ** MdB 2011 11 14 remove any nested spells (assume the longer spell is the right one) *;
 DATA CONDdataset5 ;
  SET CONDdataset4 ;
  BY &SClink t_sd CondenseStats ;

  * MdB 2012 02 24 This check cannot be applied to the first spell in a set *; 
  IF NOT (first.&SClink) THEN DO ; 
     ** MdB 2012 04 17 Include check that status of the two spells are the same *;
     IF t_sd ge prev_sd AND t_ed le prev_ed AND prev_st = CondenseStats THEN DELETE ; 
  END ;
 run ;
 
  ** identify first and last end date for each sequence **;
 PROC MEANS DATA = CONDdataset5 NOPRINT NWAY MISSING ;
  CLASS &SClink seq CondenseStats Batchno &SCstatus ;
  OUTPUT OUT = CONDdataset2  (drop = _TYPE_ _FREQ_ seq)
    MIN(t_sd) = t_sd
    MAX(t_ed) =t_ed
    ;
 run ;


      %END ; ** end of remove any overlaps loop *;
   %END ; ** End of overlapse loop *;

 %END ; ** end of batch processing loop *;

  ** MdB 2014 02 24 Check if the end date overlaps with next spell start  **;
 %LET ByVars = &SClink DESCENDING &SCstart ;
 PROC SORT DATA = CONDnonoverlap3 ; BY &ByVars ; run ;

 DATA &SCoutfile (DROP = NxtSd) ;
  SET CONDnonoverlap3 ;
  BY &ByVars ;

  FORMAT NxtSd ddmmyy10. ;
  NxtSd = LAG1(&SCstart) ;
  IF NOT first.&SClink THEN DO ;
     ** adjust end dates that overlap next spell start date *;
     IF &SCend_d = NxtSd THEN &SCend_d = &SCend_d - 1 ;
  END ; 
 run ;
 
 PROC DATASETS LIBRARY = work NOLIST ; DELETE CONDdataset: CONDtemp: CONDnonoverlap: ; run ;


 %PUT *** End of Condense Macro IAP: /r00/msd/shared/ssi/macros/ ***;

 %MEND ;


************************************************************************************************************************************; 

 %MACRO SpellCompChk(RCCinfile = 
                  ,RCCLib = 
                  ,RCCCompressedFile = 
                  ,RCCPrimKey = 
                  ,RCCtestN = 
                  ,RCCEffFrm = 
                  ,RCCEffTo = 
                  ,RCCVars = 
                  ) ;


/* * Testing *;

DATA test1 ;
  SET JOB_VLicences1 (WHERE = (cvid =  98576 ) ) ; 
 run ;

 %LET RCCinfile = test1 ;
 %LET RCCLib = work ;
 %LET RCCCompressedFile = JOB_VLicences2 ;
 %LET RCCPrimKey = CVid ;
 %LET RCCtestN = 1 ;
 %LET RCCEffFrm = filedate ;
 %LET RCCEffTo = Repdate ;
 %LET RCCVars = CVS_DriverLicenceType
                             CVS_DriverLicenceTypeID
                             DriverLicenceExpiryDate ;
 */

  ** Detmine spell date format **;
 PROC CONTENTS DATA = &RCVLib..&RCCinfile. (KEEP = &RCCEffFrm. ) 
   OUT = RCVtemp0 (RENAME = (name = variable) )
   NOPRINT ;
 run ;

 DATA RCVtemp0 ;
  SET RCVtemp0 ;
  IF formatl gt 0 THEN CALL SYMPUTX("RCC_SpllFormat", CATT(format,formatl,'.') ) ;
  ELSE CALL SYMPUTX("RCC_SpllFormat", CATT(format,'.') ) ;
 run ;

 %PUT Spell format (based on infile spell start): &RCC_SpllFormat. ;

 ** Determine minimum and maximum repdate *;
 PROC MEANS DATA = &RCCLib..&RCCinfile. NOPRINT NWAY MISSING ;
  OUTPUT OUT = RCCtemp1 (DROP = _TYPE_ _FREQ_ )
   MIN(&RCCEffFrm) = MinEffFrm 
   MAX(&RCCEffTo) = MaxRCCEffTo 
   ;
 run ;

 DATA RCCtemp1 ;
  SET RCCtemp1 ;
  CALL SYMPUTX("MinEffFrm", MinEffFrm ) ;
  CALL SYMPUTX("MaxRCCEffTo", MaxRCCEffTo ) ;
 run ;

 %PUT First Replication date: &MinEffFrm. ;
 %PUT Last Replication date: &MaxRCCEffTo. ;

 ** Select sample of primary key ids for testing *;
 %LET ByVars = &RCCPrimKey. ;
 PROC SORT DATA = &RCCLib..&RCCinfile.
  OUT = RCCtestids1 (KEEP = &ByVars)
  NODUPKEY ;
  BY &ByVars. ;
 run ;

 ** check whether key is character *;
 PROC CONTENTS DATA = RCCtestids1
   OUT = RCCtemp1 (RENAME = (name = variable) )
   NOPRINT ;
 run ;

 DATA RCCtemp1 ;
  SET RCCtemp1 ;
  IF type = 2 THEN CALL SYMPUTX("RCC_PKchar", "$" ) ;
  ELSE CALL SYMPUTX("RCC_PKchar", "" ) ;
 run ;

 %PUT Primary key character format: &RCC_PKchar. ;

 DATA RCCtestids1  ;
  RETAIN &ByVars ;
  SET RCCtestids1;
  Select = NORMAL(0) ;
 run ;

 %LET ByVars = Select ;
 PROC SORT DATA = RCCtestids1 ; BY &ByVars ; run ;

 DATA RCCtestids1 ;
  SET RCCtestids1 (DROP = select OBS = &RCCtestN.);
 run ;

 %USE_FMT(RCCtestids1, &RCCPrimKey., RCC_tst_ids) ;

 ** Generate ranom list of dates to check *;
 DATA RCCtestidsdates1 (KEEP =  &RCCPrimKey. CheckDate) ;
  SET RCCtestids1  ;
  FORMAT CheckDate &RCC_SpllFormat. ;
  PeriodDur =&MaxRCCEffTo &MinEffFrm ;
  DO i = 1 TO 100 ;
     DateSelect = INT(UNIFORM(0) * PeriodDur) ;
     CheckDate = &MinEffFrm +  DateSelect ;
     OUTPUT ;
  END ;
 run ;

 ** remove any duplicate random check dates *;
 %LET ByVars = &RCCPrimKey. CheckDate;
 PROC SORT DATA = RCCtestidsdates1 NODUPKEY ; BY &ByVars ; run ;

 ** Create a string of the check variables **;
 DATA RCCtemp2 ;
  Temp1 = COMPBL("&RCCVars.") ;
  CondenseStatement = TRANWRD(STRIP(Temp1), " ", ",'~', ") ;
  CALL SYMPUT("CondenseStatement", "CheckVars = COMPRESS(CATT(" || STRIP(CondenseStatement)||"),'cs')" ) ;
 run ;

 ** Subset input and output tables to test ids **;
 DATA RCC_indataset1 (DROP = &RCCVars. ) ;
  SET &RCCLib..&RCCinfile. (KEEP =&RCCPrimKey. &RCCVars. &RCCEffFrm. &RCCEffTo.
                             WHERE = (PUT(&RCCPrimKey., &RCC_PKchar.RCC_tst_ids.) = "Y") 
                             ) ;

  &CondenseStatement ;
  CheckVarsMD5 = PUT(MD5(COMPRESS(CheckVars,' ','s')),hex32.) ;
 run ;

 DATA RCC_outdataset1 (DROP = &RCCVars. ) ;
  SET &RCCLib..&RCCCompressedFile. (KEEP =&RCCPrimKey. &RCCVars.  &RCCEffFrm. &RCCEffTo.
                                     WHERE = (PUT(&RCCPrimKey., &RCC_PKchar.RCC_tst_ids.) = "Y") 
                                    ) ;

  &CondenseStatement ;
  CheckVarsMD5 = PUT(MD5(COMPRESS(CheckVars,' ','s')),hex32.) ;

 run ;

 ** Select infile records at selected check dates *;
 PROC SQL ;
  CREATE TABLE RCC_indataset2  AS
  SELECT a.*
        ,b.&RCCEffFrm. AS ValidFrom_IN
        ,b.&RCCEffTo.  AS ValidTo_IN
        ,b.CheckVars
        ,b.CheckVarsMD5
  FROM RCCtestidsdates1 AS a
       LEFT JOIN 
       RCC_indataset1 AS b
  ON       a.&RCCPrimKey. = b.&RCCPrimKey.  
       AND a.CheckDate BETWEEN b.&RCCEffFrm. AND b.&RCCEffTo.
 ;
 quit ;

 ** Select outfile records at selected check dates *;
 PROC SQL ;
  CREATE TABLE RCC_outdataset2  AS
  SELECT a.*
        ,b.&RCCEffFrm. AS ValidFrom_OUT
        ,b.&RCCEffTo.   AS ValidTo_OUT
        ,b.CheckVars
        ,b.CheckVarsMD5
  FROM RCCtestidsdates1 AS a
       LEFT JOIN 
       RCC_outdataset1 AS b
  ON       a.&RCCPrimKey. = b.&RCCPrimKey.  
       AND a.CheckDate BETWEEN  b.&RCCEffFrm. AND b.&RCCEffTo.
 ;
 quit ;

 %LET ByVars = &RCCPrimKey. CheckDate CheckVarsMD5 ;
 PROC SORT DATA = RCC_indataset2 ; BY &ByVars ; run ;
 PROC SORT DATA = RCC_outdataset2; BY &ByVars ; run ;

 DATA RCC_Reconcile1 (DROP = CheckVarsMD5)  ;
  RETAIN &ByVars ;
  MERGE RCC_indataset2 (IN=A)
        RCC_outdataset2 (IN=B) ;
  BY &ByVars ;
  IF A OR B ;

  Match = "Not OK" ;
  IF A AND B THEN Match = "OK" ; 
 run ;

 %LET ClassVars = Match ;
 PROC MEANS DATA = RCC_Reconcile1 NOPRINT NWAY MISSING ;
  CLASS &ClassVars.;
  OUTPUT OUT = RCC_ReconcileSum (SORTEDBY = &ClassVars.
                    DROP = _TYPE_ _FREQ_ )
   N(CheckDate) = Observations  
    ;
 run ;

 PROC PRINT DATA = RCC_ReconcileSum (obs=20) ; run ;
 PROC PRINT DATA = RCC_Reconcile1 (obs=20 WHERE = (Match = "Not OK" ) ) ; run ;

 PROC DATASETS LIB = work NOLIST ;
  DELETE RCC_indataset: RCC_outdataset: RCCtemp: RCCtestidsdates: RCCtestids: ;
 run ;
 %MEND ;

************************************************************************************************************************************; 

 /*  
    TITLE:  Spell History Inverter Macro

    PURPOSE:  Macro takes an existing spell history and generates a file with the additional 
              records for any perdiods between the input spell history.  
              For example, the macro can be used to generate an off main benefit spell 
              dataset from a dataset containing benefit spells.  

    AUTHOR: Marc de Boer, OWPA RE, CSRE, MSD

    DATE: March 2011

     MODIFCATIONS
     BY             WHEN      WHAT
     Marc de Boer   Oct2013   Removed the nonotes options
     
*/

/*

   ***                               ***;
   *** Spelll History Inverter Macro ***;
   ***                               ***;

 %SpellHistoryInverter(  SHIinfile =
                       , SHIoutfile = 
                       , SHIlink = 
                       , SHIspellSD = 
                       , SHIspellED = 
                      ) ;

 *
 INPUTS
 SHIinfile: spell dataset to invert
 SHIoutfile: dataset with orginal and inverted spells
 SHIlink: unqiue indetifier (eg snz_uid)
 SHIspellSD: spell start date
 SHIspellED: spell end date
*;

*/


   ***       ***;
   *** Macro ***;
   ***       ***;


   

 %MACRO SpellHistoryInverter(  SHIinfile =
                             , SHIoutfile = 
                             , SHIlink = 
                             , SHIspellSD = 
                             , SHIspellED = 
                            ) ;

 
 %PUT *** Start of SpellHistoryInverter Macro                                                       ***;

/*
  * for testing *;
 %LET SHIinfile = SRT_Enrol2 ;
 %LET SHIoutfile = test ;
 %LET SHIlink = enrolment_id ;
 %LET SHIspellSD = SRTenrl_VldSrt ;
 %LET SHIspellED = SRTenrl_VldEnd ;
*/

 ** MdB 2014 05 07 Need to allow for datetime formates **;
 ** work out format for dates **;
 PROC CONTENTS DATA = &SHIinfile (KEEP =&SHIspellSD ) 
   NOPRINT
   OUT = SHItemp1  ;
 run ;

 DATA SHItemp1 ;
  SET SHItemp1 ;
  CALL SYMPUTX("DTformat", STRIP(format)||STRIP(formatl)||".") ;
 run ;

  * identify the largest and smallest dates to define the bounds of the spell history file *;
 PROC MEANS DATA = &SHIinfile   NOPRINT NWAY MISSING ;
  OUTPUT OUT = SHItemp1 (COMPRESS = NO DROP = _TYPE_ _FREQ_)
    MIN(&SHIspellSD) = firstSD
    MAX(&SHIspellED) = lastED 
  ;
 run ;

 DATA SHItemp1 ;
  SET SHItemp1 ;
  *CALL SYMPUT("firstSD", PUT(firstSD, date9.) ) ;
  *CALL SYMPUT("lastED", PUT(lastED, date9.) ) ;
  CALL SYMPUT("firstSD", firstSD ) ;
  CALL SYMPUT("lastED", lastED ) ;

 run ;
 
 PROC SORT DATA = &SHIinfile ; BY &SHIlink &SHIspellSD ; run ;

 DATA SHItemp2 (KEEP = &SHIlink &SHIspellSD &SHIspellED OrginalSpell PreviousEd)  ;
  SET &SHIinfile  ;
  BY &SHIlink ;

  FORMAT &SHIspellSD &SHIspellED PreviousEd &DTformat ;
  LENGTH OrginalSpell $1. ;
  OrginalSpell = "Y" ;
  PreviousEd = LAG1(&SHIspellED) ;

  ** MdB 2011 10 Some negtaive spells fail becuase they had another clients pervious end ***;
  IF first.&SHIlink THEN PreviousEd = . ; 
 run ;

 DATA &SHIoutfile (DROP = &SHIspellSD 
                          &SHIspellED 
                           PreviousEd  
                   RENAME = (Nsd = &SHIspellSD
                             Ned = &SHIspellED
                             )

                            );
  LENGTH  Nsd Ned  8. 
          OrginalSpell $1. ;
  SET SHItemp2  ;
  BY &SHIlink &SHIspellSD ;

  FORMAT Nsd Ned &DTformat ;
  OrginalSpell = "N" ;

  Ned = &SHIspellSD - 1 ;
  Nsd = PreviousEd + 1 ;
  IF first.&SHIlink THEN DO ;
      Nsd = &firstSD ;
      Ned = &SHIspellSD - 1 ;
      IF &SHIspellSD gt &firstSD THEN OUTPUT ;
  END ; 
  ELSE DO ;
      ** MdB 2013 06 12 Remove any inverted spells *;
      IF Nsd le Ned THEN OUTPUT ;
  END;
  ** Steven - The next 5 lines of code were inside the ELSE part above. Bring
  ** them outside so that a final additional spell is also created for clients
  ** that had only one original spell ;
  IF last.&SHIlink AND &SHIspellED lt  &lastED  THEN DO ;
      Nsd = &SHIspellED+1 ;
      Ned =  &lastED  ;
      ** MdB 2013 06 12 Remove any inverted spells *;
      IF Nsd le Ned THEN OUTPUT ;
  END ;
 run ; 

  * combine the two histories together *;
 PROC APPEND BASE = &SHIoutfile  DATA = SHItemp2 (DROP = PreviousEd) ; run ;
 PROC SORT DATA = &SHIoutfile ; BY &SHIlink &SHIspellSD ; run ;
 
 PROC DATASETS LIB = work NOLIST ; DELETE SHItemp: ; run ;

 %PUT *** End of SpellHistoryInverter Macro                                                         ***;


 %MEND SpellHistoryInverter ;
 
************************************************************************************************************************************; 

/*  
    TITLE: SpellOverlay

    PURPOSE: The purpose of this Macro is to combine historical records from two sources
           to provide a single continous history.  
             The primary dataset is the one where records will overlay the records of the secondary
             datset.  
             In other words where a person is subject to the both states similtatounsly 
             the primary state will be the one that is recorded on the output file
    

    MACROS: SpellCondense
       SpellHistoryInverter
      

    AUTHOR: Marc de Boer, OWPA RE, CSRE, MSD

    DATE: March 2011

     MODIFCATIONS
     BY             WHEN      WHAT
     Marc de Boer   March2012 The merge hist was having a problem with status field made of
                              numerials. Corrected code to handel this.

     Marc de Boer   Oct2013   Removed the nonotes options
  
*/


/*

   ***                     ***;
   *** Spell overlay macro ***;
   ***                     ***;


      %SpellOverlay( SMlink
                    ,SMprimary
                    ,SMp_sd
                    ,SMp_ed
                    ,SMpstatus
                    ,SMsecond
                    ,SMs_sd 
                    ,SMs_ed
                    ,SMsstatus
                    ,SMoutfile
                    ) ;

*
INPUTS: 
      SMlink: unqiue identifier (eg snz_uid)
      SMprimary: name of SAS dataset with the primary spells you want to overlay 
      SMp_sd: variable name for the start date of primary spells
      SMp_ed: variable name for the end date of primary spells
      SMpstatus: varible that defines the status of the spell 
                 (consecutive spells of the same status are combined)
      SMsecond: name of SAS dataset with the spells that will be overlayed by
                the spells in the primary dataset
      SMs_sd SMs_ed: variables for the secondary spell start and end dates
      SMsstatus: variable the defines the status of each secondary spell

OUTPUTS:
      SMoutfile: name of the file the overlayed history will be written to.
*;
*/




   ***       ***;
   *** Macro ***; 
   ***       ***;



%MACRO SpellOverlay( SMlink
                  ,SMprimary
                  ,SMp_sd
                  ,SMp_ed
                  ,SMpstatus
                  ,SMsecond
                  ,SMs_sd 
                  ,SMs_ed
                  ,SMsstatus
                  ,SMoutfile) ;




 %PUT *** SpellOverlay macro starting                                                                 ***;
 

/*
 

 %LET SASprogrammes = T:\CORE\Projects\487 Sustainable Employment Annual Report\2012\SAS ;
 %INCLUDE "&SASprogrammes\000 Programme Parameters.sas" ;

rsubmit ;
 %LET ReportStartDate = jan2010 ;
 %LET ReportEndDate = Jan2013 ;
 %SYSRPUT ReportStartDate = &ReportStartDate ;
 %SYSRPUT ReportEndDate = &ReportEndDate ;
  %PUT &SEex_dt ;
endrsubmit ;

rsubmit ;
 %EmpProgExt( EPXsd = 01&ReportStartDate
             ,EPXed = 01&ReportEndDate
             ,EPXOutfile = EmpPardataset1
            ) ;
endrsubmit ;

rsubmit ;
  DATA ParSeplls ;
   SET EmpPardataset1 (WHERE = (swn ne .)
                      KEEP = swn participation_sd participation_ed programme_code) ;
   Programme = "EA" ;
 run ; 
endrsubmit ;

rsubmit; ** extract primary spells with children ***;
 %USE_FMT(ParSeplls, swn, usefmt) ;

 data primswns ;

  set BDD.spel&bddversion (WHERE = (PUT(swn, usefmt.) = "Y") 
                           KEEP = swn spell: servf
                          ) ;
 if spellto=. then spellto="&BDDed"d ;
 Primary = "Primary" ;
 run;
endrsubmit;

rsubmit ;
 PROC PRINT DATA = &syslast (obs=20) ; run ;
endrsubmit ;

 * Diagnostics *;
%LET SMlink=FamNo_spell ;
%LET SMprimary=ActiveAdltSpell ;
%LET SMp_sd=FamSD ;
%LET SMp_ed=FamED ;
%LET SMpstatus=FamSpell ;
%LET SMsecond=ActiveChildSpel1 ; 
%LET SMs_sd=ChldSD ; 
%LET SMs_ed=ChldED ;
%LET SMsstatus=chswnT ;
%LET SMoutfile=ActiveChildSpel2 ;
*/


 ** Tidy up the two history files (eg remove overallping spells with the same status) *;
 %SpellCondense( SCinfile=&SMprimary
                ,SCoutfile=SMprimary1
                ,SClink=&SMlink 
                ,SCstart=&SMp_sd
                ,SCend_d=&SMp_ed
                ,SCstatus=&SMpstatus
                ,SCbuffer=1
                ) ;

 %SpellCondense( SCinfile=&SMsecond
                ,SCoutfile=SMsecond1
                ,SClink=&SMlink
                ,SCstart=&SMs_sd
                ,SCend_d=&SMs_ed
                ,SCstatus=&SMsstatus
                ,SCbuffer=1
               ) ;
 

 ** Determine length of p and s status variable **;
 PROC CONTENTS DATA = SMprimary1 (KEEP = &SMpstatus) ;
  ODS OUTPUT variables = temp1 ;
 run ;

 PROC CONTENTS DATA = SMsecond1 (KEEP = &SMsstatus) ;
  ODS OUTPUT variables = temp2 ;
 run ;

 DATA temp3 ;
  SET temp1 
      temp2 ;

  RETAIN MaxLen 0 ;
  IF _N_ = 1 THEN MaxLen = 0 ;
  MaxLen = MAX(MaxLen, Len) ;
  CALL SYMPUTX("StatusLength", "$"||STRIP(MaxLen)||".") ;
 run ;


 PROC SORT DATA = SMprimary1 ; BY &SMlink &SMp_sd ; run ; 

 DATA SMprimary2 (DROP = Min_sd Max_ed) ;
  LENGTH  pstatus &StatusLength ;
  SET  SMprimary1 (KEEP = &SMlink &SMp_sd &SMp_ed &SMpstatus
                   RENAME = (&SMp_sd = p_sd 
                             &SMp_ed = p_ed 
                             &SMpstatus = pstatus)
                   WHERE = (    p_sd ne . 
                            OR  p_ed ne . 
                            AND pstatus ne "" )
               ) ;
  BY &SMlink p_sd ;

  FORMAT p_sd p_ed ddmmyy10. ;
  p_sd = INT(p_sd) ;
  p_ed = INT(p_ed) ;
  duration = (p_ed - p_sd) + 1 ; 
  IF duration lt 1 THEN DELETE ;

  RETAIN Min_sd Max_ed ;
  IF _N_ =1 THEN DO ;
     Min_sd = p_sd ;
     Max_ed  = p_ed ;
  END ;
  Min_sd = MIN(p_sd, Min_sd);
  Max_ed  = MAX(p_ed, Max_ed) ;
  CALL SYMPUTX("Min_psd", PUT(Min_sd, date9.) ) ;
  CALL SYMPUTX("Max_ped", PUT(Max_ed, date9.) ) ;
 run ;

 DATA SMsecond2 (DROP = Min_sd Max_ed) ;
  LENGTH sstatus &StatusLength  ;
  SET SMsecond1 (KEEP = &SMlink &SMs_sd &SMs_ed &SMsstatus
                 RENAME = (&SMs_sd = s_sd 
                           &SMs_ed = s_ed 
                           &SMsstatus = sstatus)
                 WHERE = (    s_sd ne . 
                          OR  s_ed ne . 
                          AND sstatus ne "") 
                  ) ;

  FORMAT s_sd s_ed ddmmyy10. ;
  s_sd = INT(s_sd) ;
  s_ed = INT(s_ed) ;
  duration = (s_ed - s_sd) + 1 ; 
  IF duration lt 1 THEN DELETE ;

  RETAIN Min_sd Max_ed ;
  IF _N_ =1 THEN DO ;
     Min_sd = s_sd ;
     Max_ed  = s_ed ;
  END ;
  Min_sd = MIN(s_sd, Min_sd);
  Max_ed  = MAX(s_ed, Max_ed) ;
  CALL SYMPUTX("Min_ssd", PUT(Min_sd, date9.) ) ;
  CALL SYMPUTX("Max_sed", PUT(Max_ed, date9.) ) ;
 run ;

 
  * remove instances of multiple spells of primary of secondary starting on the same day, 
    the one with the longer duration is favoured *;
 /*

 PROC PRINT DATA = &syslast (obs=20 WHERE = (&SMlink = "317249035_1") ) ; run ;
 */
 PROC SORT DATA = SMprimary2 ; BY &SMlink p_sd duration ; run ;

 DATA SMprimary3 ;
  SET SMprimary2 (DROP = duration);
  BY  &SMlink p_sd ;
  IF last.p_sd THEN OUTPUT ;
 run ;

 PROC SORT DATA = SMsecond2 ; BY &SMlink s_sd duration ; run ;

 DATA SMsecond3 ;
  SET SMsecond2 (DROP = duration);
  BY  &SMlink s_sd ;
  IF last.s_sd THEN OUTPUT ;
 run ;
 

  * assign null history fields for primary table *;

 %SpellHistoryInverter(  SHIinfile = SMprimary3 
                       , SHIoutfile = SMprimary4 
                       , SHIlink = &SMlink 
                       , SHIspellSD = p_sd 
                       , SHIspellED = p_ed 
                       ) ;


 DATA SMprimary5 (DROP = OrginalSpell) ;
  LENGTH  pstatus &StatusLength  ;
  SET SMprimary4 (WHERE = (OrginalSpell = "N") ) ;
  pstatus = "" ;
 run ;

 ** add orginal spells back in **;
 PROC APPEND BASE = SMprimary5 DATA = SMprimary3 ; run ;

 ** Add empity periods to match the secondary spells **;
  %LET ByVars = &SMlink p_sd ;
 PROC SORT DATA = SMprimary5 ; BY &ByVars ; run ;

 DATA Outfill1 (DROP =  p_sd p_ed
                RENAME = (new_p_sd = p_sd
                         new_p_ed = p_ed
                         )
               ) ;
  SET SMprimary5 ; 
  BY &ByVars ;

  FORMAT new_p_sd new_p_ed ddmmyy10. ; 

  IF first.&SMlink THEN DO ; 
    ** first spell starts before the very first start date **;
    IF p_sd gt MIN("&Min_ssd"d, "&Min_psd"d) THEN DO ;
          new_p_ed = p_sd - 1 ;
          new_p_sd = MIN("&Min_ssd"d, "&Min_psd"d) ;
          pstatus = "" ;
          IF new_p_ed ge new_p_sd THEN OUTPUT ;
    END ;
  END ;

  IF last.&SMlink THEN DO ;
      ** first last spell ends before the very last end date **;
      IF p_sd lt MAX("&Max_sed"d, "&Max_ped"d) THEN DO ;
          new_p_sd = p_ed + 1 ;
          new_p_ed = MAX("&Max_sed"d, "&Max_ped"d) ;
          pstatus = "" ;
          IF new_p_ed ge new_p_sd THEN OUTPUT ;
      END ;
  END ;
 run ;

 PROC APPEND BASE = SMprimary5 DATA = Outfill1 ; run ;

 ** Check it all works **;
 %LET ByVars = &SMlink p_sd ;
 PROC SORT DATA = SMprimary5 ; BY &ByVars ; run ;

 DATA PrimaryDuration1 (KEEP = &SMlink SumDur) ;
  SET SMprimary5 ;
  BY &ByVars ;

  RETAIN SumDur 0 ;
  IF first. &SMlink THEN SumDur = 0 ;
  dur = (p_ed - p_sd) + 1 ;
  SumDur = SumDur + dur ;
  IF last. &SMlink THEN OUTPUT ;
 run ;


 * assign following secondary start date *;
 PROC SORT DATA = SMsecond3 ; BY &SMlink DESCENDING s_sd ;

 DATA SMsecond4 ;
  SET SMsecond3 ;
  BY  &SMlink ;

  FORMAT nxt_ssd ddmmyy10. ;
  nxt_ssd = LAG1(s_sd) ;
  IF first.&SMlink THEN nxt_ssd = MAX("&Max_sed"d, "&Max_ped"d+1)  ;
 run;

  * assign previous secondary end date  *;
 PROC SORT DATA = SMsecond4 ; BY &SMlink s_sd ;

 DATA SMsecond5 (DROP = sstatus) ;
  RETAIN &SMlink sstatus pre_sed s_sd s_ed nxt_ssd ;
  SET     SMsecond4 ;
  BY      &SMlink ;

  FORMAT pre_sed ddmmyy10. ;
  pre_sed = LAG1(s_ed) ;
  IF first.&SMlink THEN pre_sed = MIN("&Min_ssd"d, "&Min_psd"d-1) ;
 run;

  * Interleave secondary history with primary history *;
 PROC SQL ;
  CREATE TABLE SMprimary6 AS
        SELECT   p.&SMlink
                ,p.pstatus
                ,p_sd
                ,p_ed
                ,s.pre_sed
                ,s.s_sd
                ,s.s_ed
                ,s.nxt_ssd
         FROM    SMprimary5 AS p 
                 LEFT JOIN 
                 SMsecond5 AS s
           ON        p.&SMlink = s.&SMlink
                 AND p_sd le s_ed 
                 AND p_ed ge s_sd ;
 quit ;

 ** Adjust primary spells with overlapping secondary spells ***;

 PROC SORT DATA = SMprimary6 ; BY &SMlink p_sd s_sd ; run ;

 DATA SMprimary7 ;
  SET SMprimary6 ;

  FORMAT adj_p_sd adj_p_ed ddmmyy10. ;

  ** No overlapping secondary spells ***;
  IF s_sd = . THEN DO ;
     adj_p_sd = p_sd ;
     adj_p_ed = p_ed ;
     OUTPUT ;
  END ;

  ** Nested secondary spell ***;
  IF     s_sd ge p_sd 
     AND s_ed le p_ed THEN DO ;

     ** single nested spell **;
     IF     pre_Sed lt p_sd
        AND nxt_ssd gt p_ed THEN DO ;
          adj_p_sd = p_sd ;
          adj_p_ed = s_sd - 1 ;
          OUTPUT ;
          adj_p_sd = s_ed + 1 ;
          adj_p_ed = p_ed  ;
          OUTPUT ;
     END ;

     ** multiple nested spells ***;
     ** NOTE this will output duplicate spells **;
     ELSE DO ;
          adj_p_sd = MAX(p_sd, pre_sed+1) ; ** start of p spell or end of previous secondary spell **;
          adj_p_ed = s_sd - 1 ; ** day before start of sec spell **;
          OUTPUT ;
          adj_p_sd = s_ed + 1 ; ** day after sec spell ends ***;
          adj_p_ed = MIN(p_ed, nxt_ssd-1)  ; ** end of p spell or start of next sec spell **;
          OUTPUT ;
     END ; 
  END ;

  ** secondary spell overlaps primary spell start date **;
  IF s_sd lt p_sd le s_ed THEN DO ;
     adj_p_sd = s_ed + 1 ; ** start of p spell at end of secondary spell **;
     adj_p_ed = MIN(p_ed, nxt_ssd-1)  ; ** end of p spell or start of next sec spell **;
     OUTPUT ;
  END ;

  ** secondary spell overlaps primary spell end date **;
  IF s_sd le p_ed lt s_ed THEN DO ;
     adj_p_sd = MAX(p_sd, pre_sed+1) ; ** start of p spell or end of previous secondary spell **;
     adj_p_ed = s_sd - 1 ; ** day before start of sec spell **;
     OUTPUT ;
  END ;

  ** secondayr spell enriterly overllaps primary spell **;
  IF     s_sd le p_sd
     AND s_ed ge p_ed THEN DO ;
      adj_p_sd = p_sd ;
      adj_p_ed = p_sd - 1;  ** Turn primary spell into a negative one to be removed in subsequent step **;
      OUTPUT ;
  END ;

  IF adj_p_sd = . THEN OUTPUT ; ** Check: should be none it it all works **;
 run ;

 ** Remove redundent primary spells (where p_sd gt p_ed) *;
 DATA SMprimary8 (KEEP = &SMlink pstatus adj_p_sd adj_p_ed
                  RENAME = (adj_p_sd = sd
                            adj_p_ed = ed
                            pstatus = status
                            ) 
                  ) ;
  SET SMprimary7 (WHERE = (adj_p_sd le adj_p_ed) ) ;
 run ;
 
 ** remove duplicate spells created for multi nested spells **;
 %LET ByVars = &SMlink sd ;
 PROC SORT DATA = SMprimary8 NODUPKEY ; BY &ByVars ; run ;

 ** Convert secondary records for appendeing **; 
 DATA SMsecond4 ;
   SET SMsecond3 (KEEP = &SMlink s_sd s_ed sstatus
                   RENAME = (s_sd = sd 
                             s_ed = ed 
                             sstatus=status
                             )
                  ) ;
 run;

 DATA SMfinalSpells2 ;
  SET SMprimary8
      SMsecond4 ;
  status = STRIP(status) ;
 run ;

 PROC SORT DATA = SMfinalSpells2 ; BY &SMlink sd ; run ;

 DATA &SMoutfile (SORTEDBY = &SMlink sd) ; * some periods overlapped and some duplicate records exist*;
        SET     SMfinalSpells2 ;
        BY      &SMlink sd ;

        IF sd gt ed THEN DELETE ;
        IF first.sd THEN OUTPUT ;
 run;
 
 /*
  ** Check infiles and outfiles for a test id **;
  %LET  TestId = 21006291 ;
  PROC PRINT DATA = SMsecond1 (obs=20 WHERE = ( &SMlink  = &TestId) ) ; run ;
  PROC PRINT DATA = SMprimary5 (obs=20 WHERE = ( &SMlink  = &TestId) ) ; run ;
  PROC PRINT DATA = &SMoutfile (obs=20 WHERE = ( &SMlink  = &TestId) ) ; run ;
  */

  ** Check it all works **;
 %LET ByVars = &SMlink sd ;
 PROC SORT DATA = &SMoutfile ; BY &ByVars ; run ;

 DATA MergedDuration (KEEP = &SMlink SumMergedDur) ;
  SET &SMoutfile ;
  BY &ByVars ;

  RETAIN SumMergedDur 0 ;
  IF first.&SMlink THEN SumMergedDur = 0 ;
  dur = (ed - sd) + 1 ;
  SumMergedDur = SumMergedDur + dur ;
  IF last.&SMlink THEN OUTPUT ;
 run ;

 %LET ByVars =&SMlink ;
 PROC SORT DATA = MergedDuration ; BY &ByVars ; run ;
 PROC SORT DATA = PrimaryDuration1; BY &ByVars ; run ;

 DATA ErrorMergedSpells  (SORTEDBY = &ByVars) ;
  MERGE PrimaryDuration1(IN=A)
        MergedDuration (IN=B) ;
  BY &ByVars ;
  IF A ;

  NOTE = "If durations do not closely match the merge hist as not worked" ;

  IF A AND NOT B THEN OUTPUT ;
  Diff = ABS(SumMergedDur-SumDur) ;
  IF Diff gt 1 THEN OUTPUT ;
 run ;

 PROC SORT DATA = ErrorMergedSpells ; BY DESCENDING Diff ; run ;
 PROC PRINT DATA = &syslast (obs=20) ; run ;

 PROC DATASETS LIBRARY = work NOLIST ; DELETE SMprimary: SMsecond: SMfinalSpells:  SMMergedSpells: ; run ;
 
 
 %PUT *** SpellOverlay macro ending                                          ***;

%MEND ;
 




/*
     TITLE: Creates spells of adults on main (Youth and Working age) benefits.

     PURPOSE: BDD benefit spells split between main and single on the benefit spells
              dataset while partners are stored on a seperate dataset.
              This code combines the two together to each adult is linked to the
              working age main benefit spell.
           

     AUTHOUR: Marc de Boer, MSD
     DATE: Janurary 2014 

     CHANGE HISTROY
     WHEN       WHO           WHY
*/

/*
********************************************************************************************************;
    ** How to use this macro **

 ** run this code to loead macros into memory **

 %AdltsMainBenSpl( AMBSinfile = [dataset with SNZ_uid (if blank then extracts whole dataset)]
                  ,AMBS_IDIxt = [IDI release date (eg 20160305)]
                  ,AMBS_BenSpl = [Name of dataset to write benefitspells to]
*/

/*
********************************************************************************************************
  Code outline

 Dependencies
 MACRO: Subset an SQL IDI table into a SAS dataset macro.sas (on IDI code sharing library)
 MACRO: Spell_Manipulation_Macros.sas (on IDI code sharing library)
 MACRO: BenefitNameTypeMacro.sas (on IDI code sharing library)
 IDI table: msd_clean.msd_spell 
 IDI table: msd_clean.msd_partner

 Code structure
 1.0 Extract for relevent SNZ_uids from msd_clean.msd_partner
 2.0 Extract for relevent SNZ_uids (including primary for partner spells) from msd_clean.msd_spell
 2.1 Convert serv and additional_service_data into benefit name and type 
 3.0 Merge partner and benefit spell histories
 4.0 Create dataset with seperate records for single, partner and primary benefit spells
      
********************************************************************************************************;
*/  

********************************************************************************************************;
          ** Macro code **;


 %MACRO AdltsMainBenSpl( AMBSinfile = 
                        ,AMBS_IDIxt = 
                        ,AMBS_BenSpl =
                        ) ;
/*
 %LET AMBSinfile = PM_PC_matched2 ;
 %LET AMBS_IDIxt = 20160224 ;
 %LET AMBS_BenSpl = BenefitSpells ;
*/

 ** identify if sub set if requested *;
 DATA temp1 ;
  CALL SYMPUTX("InfileYes", LENGTHN(STRIP("&AMBSinfile.") ) ) ;
 run ; 

 %PUT Infile was specified in AMBSinfile (No=0): &InfileYes ;

 ** Spells as a partner  *;
  %IF &InfileYes gt 0 %THEN %DO ;
     DATA AMBS_ParnterId (RENAME = (snz_uid = partner_snz_uid) ) ;
      SET &AMBSinfile. (KEEP = snz_uid ) ;
     run ;

     %Subset_IDIdataset( SIDId_infile = AMBS_ParnterId
                        ,SIDId_Id_var = partner_snz_uid
                        ,SIDId_IDIextDt = &AMBS_IDIxt.
                        ,SIDId_IDIdataset = msd_clean.msd_partner
                        ,SIDIoutfile = MSD_PartnerBen1
                         );
  %END ;
  %ELSE %DO ;
    %Subset_IDIdataset( SIDId_infile = 
                        ,SIDId_Id_var = snz_uid
                        ,SIDId_IDIextDt = &AMBS_IDIxt.
                        ,SIDId_IDIdataset = msd_clean.msd_partner
                        ,SIDIoutfile = MSD_PartnerBen1
                         );
  %END ;

 ** format and tidy partner spells **;
 DATA MSD_PartnerBen2 ;
  SET MSD_PartnerBen1 (KEEP = snz_swn_nbr
                              partner_snz_uid
                              partner_snz_swn_nbr
                              msd_ptnr_ptnr_from_date
                              msd_ptnr_ptnr_to_date
                      );

  LENGTH PartnerSD
         PartnerED 8. ;
  FORMAT PartnerSD
         PartnerED ddmmyy10. ;
  PartnerSD=INPUT(COMPRESS(msd_ptnr_ptnr_from_date,"-"),yymmdd10.);
  PartnerED=INPUT(COMPRESS(msd_ptnr_ptnr_to_date,"-"),yymmdd10.) - 1;
  IF PartnerED = . THEN PartnerED = INPUT("&AMBS_IDIxt.",yymmdd10.);
  DROP msd_ptnr_ptnr_from_date msd_ptnr_ptnr_to_date ;
 run ; 

 ** Subset MSD BDD main benefit spells table to ids of interest *;
  %IF &InfileYes. gt 0 %THEN %DO ;
     DATA AMBS_AllId  ;
      SET &AMBSinfile. (KEEP = snz_uid ) 
          MSD_PartnerBen1 (KEEP = snz_uid )  ;  ** need primary SNZ_uid of any partners *;
     run ;

     %Subset_IDIdataset( SIDId_infile = AMBS_AllId
                        ,SIDId_Id_var = snz_uid
                        ,SIDId_IDIextDt = &AMBS_IDIxt.
                        ,SIDId_IDIdataset = msd_clean.msd_spell
                        ,SIDIoutfile = MSD_MainBen1
                         );
  %END ;
  %ELSE %DO ;
     %Subset_IDIdataset( SIDId_infile = 
                        ,SIDId_Id_var = snz_uid
                        ,SIDId_IDIextDt = &AMBS_IDIxt.
                        ,SIDId_IDIdataset = msd_clean.msd_spell
                        ,SIDIoutfile = MSD_MainBen1
                         );
  %END ;

 ** Format and tidy up spell dataset *;
 DATA MSD_MainBen2 ;
  FORMAT snz_uid
         snz_msd_uid
         snz_swn_nbr
         msd_spel_spell_nbr
         BenefitType
         BenefitName
         EntitlementSD
         EntitlementED
        ;
  SET MSD_MainBen1 (KEEP = snz_uid
                           snz_msd_uid
                           snz_swn_nbr
                           msd_spel_spell_nbr
                           msd_spel_rsn_code
                           msd_spel_servf_code
                           msd_spel_add_servf_code
                           msd_spel_spell_start_date
                           msd_spel_spell_end_date
                   );

  LENGTH EntitlementSD
         EntitlementED 8. ;
  FORMAT EntitlementSD
         EntitlementED ddmmyy10. ;
  EntitlementSD=INPUT(COMPRESS(msd_spel_spell_start_date,"-"),yymmdd10.);
  EntitlementED=INPUT(COMPRESS(msd_spel_spell_end_date,"-"),yymmdd10.) - 1;
  IF EntitlementED = . THEN EntitlementED = INPUT("&AMBS_IDIxt.",yymmdd10.);

  %BNT_BenNmType( BNTserv = msd_spel_servf_code 
               ,BNTasd = msd_spel_add_servf_code
               ,BNTdate = EntitlementSD
               ,BNT_BenNm = BenefitName
               ,BNT_BenTyp = BenefitType
               ) ;

 DROP  msd_spel_spell_end_date msd_spel_spell_start_date ;

 run ;

 ** Merge main benefit spells and partner spells *;

 %CombineSpell( CSinfile1 =  MSD_MainBen2
               ,CSSpell1_Vars = snz_uid
                                snz_swn_nbr
                                msd_spel_spell_nbr
								msd_spel_servf_code
                           		msd_spel_add_servf_code
                                BenefitType
                                BenefitName
               ,CSSpell1_SD = EntitlementSD
               ,CSSpell1_ED = EntitlementED
               ,CSinfile2 = MSD_PartnerBen2
               ,CSSpell2_Vars = partner_snz_uid
                              partner_snz_swn_nbr
               ,CSSpell2_SD = PartnerSD
               ,CSSpell2_ED = PartnerED
               ,CSoutfile = MSD_MainBen3
               ,CSidvar =  snz_swn_nbr
               ) ;



  PROC PRINT DATA = &syslast. (obs=20) ; run ;

 ** Create benefit for partner and primary **;
 DATA &AMBS_BenSpl. (RENAME = (CSspellSD = EntitlementSD
                              CSspellED = EntitlementED
                             )
                    );
  FORMAT snz_uid
         snz_swn_nbr
         MnBenCplUnitNbr
         PrimaryBenSwnNbr
		 msd_spel_servf_code
         msd_spel_add_servf_code
         BenefitName
         BenefitType
         BenefitRole
         CSspellSD    
         CSspellED
         ;
  SET MSD_MainBen3 ;

   LABEL snz_uid = "SNZ unique person id"
         snz_swn_nbr = "SNZ confidentialised social welfare number"
         MnBenCplUnitNbr = "Unqiue couple on benefit id based on snz_uid"
         PrimaryBenSwnNbr = "SNZ_swn_nbr of primary beneficiary"
         BenefitName = "Official name of benefit current at entitlement start date"
         BenefitType = "Unofficial grouping of benefitds into commone types"
         BenefitRole = "Individual position on the beenfit (single, primary or partner)"
         CSspellSD = "Start date of benefit entitlement"   
         CSspellED = "End date of benefit entitlement"
         DataSource = "IDI table data was drawn from" 
         ;

  LENGTH DataSource $50. 
         PrimaryBenSwnNbr 8. ;
  DataSource = "msd_clean.msd_spell" ;

  ** Identify primary beneficiery swn **;
  PrimaryBenSwnNbr = snz_swn_nbr ;

  ** identify couple units *;
  LENGTH MnBenCplUnitNbr $40. ;
  IF partner_snz_swn_nbr = . THEN MnBenCplUnitNbr = STRIP(snz_uid) ;
  ELSE MnBenCplUnitNbr = CATT(MIN(snz_uid,partner_snz_uid),MAX(snz_uid,partner_snz_uid)) ;

  ** primary and single beneficeries **;
  LENGTH BenefitRole $10. ;
  IF partner_snz_swn_nbr = . THEN BenefitRole = "Single" ;
  ELSE BenefitRole = "Primary" ;
  OUTPUT ;
  IF partner_snz_swn_nbr ne . THEN DO ;
      DataSource = "msd_clean.msd_partner" ;
      BenefitRole = "Partner" ;
      snz_swn_nbr = partner_snz_swn_nbr ;
      snz_uid = partner_snz_uid ;
      OUTPUT ;
  END ; 
  DROP partner_snz_swn_nbr partner_snz_uid msd_spel_spell_nbr ;
 run ;
      
 PROC PRINT DATA = &syslast. (obs=20) ; run ;                       

 ** House keeping **;
 PROC DATASETS LIB = work NOLIST ;
  DELETE MSD_MainBen: 
         MSD_PartnerBen: 
         AMBS_AllID
         AMBS_PartnerID
         Temp:;
 run ;


 %MEND ;


/*
     TITLE: Creates variables with offical name of benefit and an unofficial type.

     PURPOSE: Benefit names have changed over time without changes to underlying codes.
              The introduction of YP/YPP in Septermber 1012 resulted in the additional of
              additional_service_data variable alongside the serv code.
              The beenfit changes in July 2013 resuled in the reuse of serv code for very
              different types of benefits.
              Overal, the serv/additional_service_data can be difficult to analyise
              This macro attempts tocreate meaningful beenfit names and typology.
           

     AUTHOUR: Marc de Boer, MSD
     DATE: Janurary 2014 

     CHANGE HISTROY
     WHEN       WHO           WHY
     Aug2014    Marc de Boer  Included output of the official benefit name at the observation date.
     Oct2015    Marc de Boer  For benefit serv and additional_benefit data that is post welfare reform but applies to a 
                              pre-July 2013 date, then impute the pre-welfare reform benefit code (eg "675MED1", "675MED2" = "600").
*/

/*
********************************************************************************************************;
    ** How to use this macro **

 After running the macro into memory insert the following macro call into a data step as shown below

 DATA outputdataset
  SET inputdatadset (KEEP = spellfrom servf additional_service_data);

  %BNT_BenNmType( BNTserv = servf 
               ,BNTasd = additional_service_data
               ,BNTdate = spellfrom
               ,BNT_BenNm = BenefitName
               ,BNT_BenTyp = BenefitType
               ) ;
 run ;
 
 * Based on the servf and additional_service_data the macro will return the official name of the
   benefit as it was on the spellfrom date and what type of benefi it is.

*/


********************************************************************************************************;
          ** Macro code **;

  %MACRO BNT_BenNmType( BNTserv = 
                     ,BNTasd = 
                     ,BNTdate = 
                     ,BNT_BenNm = 
                     ,BNT_BenTyp = 
                     ) ;

  ** Create a single variables of serv and additional_service_data **;

  ** benefit type **;
  TempServ = STRIP(&BNTserv) || STRIP(&BNTasd) ;

  ** remove OLD from Temp Serv *;
  IF STRIP(&BNTasd) = "OLD" THEN TempServ = STRIP(&BNTserv) ;

  ** tidy up some odd combos **;
  IF &BNTserv = "370" 
     AND &BNTasd NOT IN ("CARE", "PSMED")  THEN TempServ = "370PSMED" ;
  IF &BNTserv = "611" THEN TempServ = "611" ;
  IF &BNTserv = "665" THEN TempServ = "665" ;
  IF &BNTserv = "839" THEN TempServ = "839" ;
  IF &BNTserv = "600" THEN TempServ = "600" ;
  IF &BNTserv = "180" THEN TempServ = "180" ;
  IF &BNTserv = "181" THEN TempServ = "181" ;

  ** Pre welfare reform names **;
  IF &BNTdate lt "13jul2013"d THEN DO ;
      IF TempServ IN ("320MED1", "320PSMED") THEN TempServ = "320" ; 
      IF TempServ IN ("330FTJS1", "330MED1") THEN  TempServ = "330" ;
      IF TempServ IN ("365FTJS", "365FTJS1", "365MED1") THEN  TempServ = "365" ;
      IF TempServ IN ("366FTJS1", "366MED1") THEN TempServ = "366" ;
      IF TempServ IN ("367CARE", "370CARE") THEN TempServ = "367" ;
      IF TempServ IN ("370PSMED") THEN TempServ = "320" ;
      IF TempServ IN ("675MED1", "675MED2") THEN TempServ = "600" ;
      IF TempServ IN ("608FTJS3", "608FTJS4", "675FTJS3", "675FTJS4") THEN  TempServ = "608" ;
      IF TempServ IN ("610FTJS2", "610FTJS1", "675FTJS1", "675FTJS2") THEN  TempServ = "610" ;
  END ;
  ELSE DO ;
   IF TempServ IN ( "320MED1"
                   ,"320PSMED"
                  )
      THEN TempServ = "365" ; 
   IF TempServ IN ( "607YP"
                   ,"607YPP"
                  )
      THEN TempServ = "607" ; 
   IF TempServ IN ( "365YPP"
                  )
      THEN TempServ = "365" ; 
  END ;

  IF TempServ IN ("365YPP" 
                 )
          THEN TempServ = "365" ; 

  IF TempServ IN ("610FTJS1" 
                 )
          THEN TempServ = "675FTJS1" ; 

  IF TempServ IN ("675PSMED" 
                 )
          THEN TempServ = "675MED1" ; 
  IF tempServ IN ("180PSMED") THEN TempServ = "180" ;

  ** Convert to benefit types ***;
  &BNT_BenTyp = PUT(TempServ, $BSHbntypPstWR.) ;
  IF &BNTdate lt "13jul2013"d THEN &BNT_BenTyp = PUT(TempServ, $BSHbntypPrWR.) ;
  IF &BNT_BenTyp = TempServ  THEN &BNT_BenTyp = PUT(TempServ, $BSHbntypPstWR.) ; ** spells backdated **;
  IF &BNT_BenTyp = TempServ  THEN &BNT_BenTyp = PUT(TempServ, $BSHbntypPrWR.) ; ; ** left overs **;
  IF &BNT_BenTyp IN ("YP", "YPYP") THEN &BNT_BenTyp = "Youth Payment" ;
  IF &BNT_BenTyp IN ("YPP", "YPPYPP") THEN &BNT_BenTyp = "Young Parent Payment" ;

  DROP TempServ ;

  ** benefit name at observation date **;
  LENGTH &BNT_BenNm $60. ;
  
  ** ensure consistent Additional Service Data fields *;
  TempASD = &BNTasd ;
  IF &BNTserv = "607" THEN TempASD = "" ;
  IF &BNTserv = "611" THEN TempASD = "" ;
  IF &BNTserv = "665" THEN TempASD = "" ;
  IF &BNTserv = "839" THEN TempASD = "" ;
  IF &BNTserv = "365" THEN TempASD = "" ;

  IF      &BNTserv = "370" 
     AND &BNTasd NOT IN ("CARE", "PSMED") THEN TempASD = "PSMED" ;

  ** Post July 2013 benefit names *;
  IF &BNTdate ge "13jul2013"d THEN DO ;
    IF STRIP(TempASD) NOT IN ("", "OLD") THEN &BNT_BenNm = PUT(TempASD, $SWF_ADDITIONAL_SERVICE_LONG.) ;
    ELSE &BNT_BenNm = PUT(TempServ, $ben.) ;
    ** Tidy ups **;
    IF &BNTserv = "370" THEN DO ; ** split SLPs *;
      IF STRIP(TempASD) = "CARE" THEN &BNT_BenNm = "Supported Living Payments Carers" ;
      ELSE &BNT_BenNm = "Supported Living Payments Health Condition & Disability" ; 
    END ;
  END ;

  ** July 2001 to July 2013 benefit names *;
  IF ("01jul2001"d le &BNTdate lt "13jul2013"d) THEN DO ;
    IF STRIP(TempASD) IN ("YP", "YPP") THEN &BNT_BenNm = PUT(TempASD, $SWF_ADDITIONAL_SERVICE_LONG.) ; ** YPP/YP **;
    ELSE &BNT_BenNm = PUT(TempServ, $ben_pre2013wr.) ;
  END ;

  **October 1998 to July 2001 benefit names *;
  IF "01Oct1998"d le &BNTdate lt "01jul2001"d THEN DO ;
    &BNT_BenNm = PUT(TempServ, $benb.) ;
  END ;

  **Pre October 1998 benefit names *;
  IF &BNTdate lt "01Oct1998"d THEN DO ;
      &BNT_BenNm = PUT(TempServ, $bena.) ;
  END ;
  IF TempServ IN ("000", "") THEN &BNT_BenNm = "No benefit" ; 
  DROP TempASD ;
  
  ** tidy up names **;
  IF &BNT_BenNm = "Non Beneficiary" THEN &BNT_BenNm = "Supplementary Only" ;
  IF &BNT_BenNm IN ("YP", "YPYP") THEN &BNT_BenNm = "Youth Payment" ;
  IF &BNT_BenNm IN ("YPP", "YPPYPP") THEN &BNT_BenNm = "Young Parent Payment" ;
  IF &BNT_BenNm = "Invalids Benefit" THEN &BNT_BenNm = "Invalid's Benefit" ;
  IF &BNT_BenNm = "Widows Benefit" THEN &BNT_BenNm = "Widow's Benefit" ;
  IF &BNT_BenNm = "Unemployment Benefit (in Training)" THEN &BNT_BenNm = "Unemployment Benefit (Training)" ;
  IF &BNT_BenNm = "Unemployment Benefit Hardship (in Training)" THEN &BNT_BenNm = "Unemployment Benefit Hardship (Training)" ;
 %PUT *** Benefit grouping macro end ;

 %MEND ;

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
 



 /*
     TITLE: Subset an IDI dataset on the SQL server to a SAS dataset

     PURPOSE: Using SQL Pass through procedure subset an IDI dataset to
     a specific subset of ids.

     AUTHOUR: Marc de Boer, MSD.

     DATE: March 2015

     MODIFICATIONS
     WHO            WHEN        WHAT
     Marc de Boer   March 2016  Included the ability to extract from the IDI sandpit area
*/

 %MACRO Subset_IDIdataset(SIDId_infile =
                         ,SIDId_Id_var =
                         ,SIDId_IDIextDt = 
                         ,SIDId_IDIdataset =
                         ,SIDIoutfile =
                         ,SIDIsandpit =
                         );
 *
 SIDId_infile: dataset containing the IDI subsetting variable [SIDId_Id_var] if left
               null then the macro will extract the whole dataset
 SIDId_Id_var: IDI subsetting variable in the IDI source table [SIDId_IDIdataset]
               eg SIDId_Id_var = SNZ_uid in SIDId_IDIdataset = ir_clean.ird_ems
 SIDId_IDIextDt: IDI dataset version (eg 20151012)
 SIDId_IDIdataset: IDI dataset on the SQL server to be subsetted by the macro.
 SIDIoutfile: output dataset.
 SIDIsandpit:if the table is in the SQL IDI sandpit area then set this value to Y
 *;

 /*  For testing 
   %LET SIDId_infile = &IMMIO_infile;
   %LET SIDId_Id_var = snz_uid ;
   %LET SIDId_IDIextDt = &IMMIO_IDIexDt;
   %LET SIDId_IDIdataset = clean_read_sla.sla_amt_by_trn_type;
   %LET SIDIoutfile = testing  ;
   %LET SIDIsandpit =  ;
 */

********************************************************************************;
    ** identify whether the dataset needs to be subsetted **;
 DATA SIDI_temp1 ;
  IF LENGTHN(STRIP("&SIDId_infile.")) gt 0 THEN CALL SYMPUTX("SIDISubset",1) ;
  ELSE  CALL SYMPUTX("SIDISubset",0) ;
 run ;
  
 %PUT Subset IDI dataset (yes:1): &SIDISubset. ;

********************************************************************************;
    ** identify whether the dataset needs to be come from the sandpit **;

  DATA SIDI_temp2 ;
    IF STRIP("&SIDIsandpit.") = "Y" THEN CALL SYMPUTX("DatabaseCall", "IDI_sandpit") ;
    ELSE CALL SYMPUTX("DatabaseCall", "&SIDId_IDIextDt.")  ;
  run ;

  %PUT Database called: &DatabaseCall &SIDIsandpit.;

********************************************************************************; 
 ** Run extract with subsetting **;

 %IF &SIDISubset. = 1 %THEN %DO ;    * Loop 1*;
   
    ** Identify unqiue ids **;
   PROC SORT DATA = &SIDId_infile (WHERE = (&SIDId_Id_var ne .) ) 
    OUT = SIDI_temp2 (KEEP = &SIDId_Id_var)
    NODUPKEY ;
    BY &SIDId_Id_var ;
   run ;

   ** SQL subsetting function accepts something less than 56,000
      objects. This splits the call into 50,000 object batches *;
   DATA SIDI_temp3 ;
    SET SIDI_temp2 end = eof;

    IF _N_ = 1 THEN DO ;
      count =0 ;
      BatchN = 1 ;
    END ;
    RETAIN count BatchN ;
    count + 1 ;
    IF count gt 50000 THEN DO ;
      count =0 ;
      BatchN + 1 ;
    END ;

    IF eof THEN CALL SYMPUTX("SIDI_BatchT", BatchN) ;
   run ;

   %PUT Number of SIDI batches to run:&SIDI_BatchT. ; 

   ** delete &SIDIoutfile in case it already existed *;
   PROC DATASETS LIB = work NOLIST ;
    DELETE &SIDIoutfile ;
   run ;

   %DO SIDI_BatchN = 1 %TO &SIDI_BatchT ;   * loop 2 *;

    /*
     %LET SIDI_BatchN = 1 ;
    */
     ** Load ids into macro variables *;
     DATA SIDI_temp4 ;
      SET SIDI_temp3 (WHERE = (BatchN = &SIDI_BatchN) );

      CALL SYMPUTX(CATT("int_id",_N_), &SIDId_Id_var) ;
      CALL SYMPUTX("int_id_T",_N_) ;
     run ;

     %MACRO Ids ;
        %DO i = 1 %TO &int_id_T-1 ;
            &&int_id&i,
        %END ;
           &&int_id&int_id_T  
     %MEND ; 

      ** MdB 2016 03 08 Cannot use (SELECT DISTINCT &SIDId_Id_var FROM &IEDinfile) becuase the 
         the &IEDinfile is on the SAS server not the SQL server *;

     ** extract ids from IDI tables in sandpit area using pass through *;
       PROC SQL ;
        CONNECT TO SQLSERVR (SERVER = SNZ-IDIResearch-PRD-SQL\iLEED
                             DATABASE = &DatabaseCall.);
        CREATE TABLE SIDI_temp5 AS
        SELECT a.*
        FROM CONNECTION TO SQLSERVR (SELECT * FROM &SIDId_IDIdataset.
                                     WHERE  &SIDId_Id_var. IN (%IDS)
                                     ) AS a ;
        DISCONNECT FROM SQLSERVR ;
       quit ;

     PROC APPEND BASE = &SIDIoutfile. DATA = SIDI_temp5 ;
   %END ;   * end loop 2*;
 %END ; * end loop 1 *; 

 ** extract the whole dataset *;
 %IF &SIDISubset. = 0 %THEN %DO ; ** loop 3 *;
   PROC SQL ;
    CONNECT TO SQLSERVR (SERVER = SNZ-IDIResearch-PRD-SQL\iLEED
                         DATABASE = &DatabaseCall.
                         );
    CREATE TABLE &SIDIoutfile. AS
    SELECT a.*
    FROM CONNECTION TO SQLSERVR (SELECT * FROM &SIDId_IDIdataset
                                 ) AS a ;
    DISCONNECT FROM SQLSERVR ;
   quit ;
 %END ; * end loop 3 *;

 PROC DATASETS LIB = work NOLIST ;
  DELETE SIDI_temp: ;
 run ;
 %MEND ;


/*  
    TITLE:  Spell Combine Macro

    PURPOSE: Macro combines two spell histories into one
             Any change in one or the other spell history will result in a seperate spell.
             Useful when wanting to track changes in the status of a client in two or more
             spell histories.
             eg spells on different benefits and spells at differnt offices.

    AUTHOR: Marc de Boer, Knowledge and Insights, MSD

    DATE: Feburary 2014

     MODIFCATIONS
     BY             WHEN      WHY
     Marc de Boer   May2015   Allowed CSidvar to be both numeric and character
     Marc de Boer   May2015   Allowed spell sd and ed to be either datetime or date
     Marc de Boer   Jul2015   Allowed spell sd and ed to be time as well
*/

********************************************************************************************************;

        ***                      ***;
        *** Combine Spells macro ***;
        ***                      ***;

/*

 %CombineSpell( CSinfile1 
               ,CSSpell1_Vars
               ,CSSpell1_SD
               ,CSSpell1_ED
               ,CSinfile2 
               ,CSSpell2_Vars
               ,CSSpell2_SD
               ,CSSpell2_ED
               ,CSoutfile
               ,CSidvar
               )

*
Inputs
 CSidvar <required>:  identifier id (eg SNZ_uid). Needs to be one both spell datasets
 CSinfile1: first spell dataset
 CSSpell1_Vars: first dataset spell status variables (can be more than one)
 CSSpell1_SD: first dataset spell start date variable
 CSSpell1_ED: first dataset spell end date variable
 CSinfile2: second spell dataset
 CSSpell2_Vars: second dataset spell status variables (can be more than one)
 CSSpell2_SD: second dataset spell start date variable
 CSSpell2_ED: second dataset spell end date variable
 CSoutfile: name of dataset to write combined spell history to.

Outputs:
 CSidvar: id variable for client
 CSspellSD: combined spell start date variable
 CSspellED: combined spell end date variable
 CSSpell1_Vars
 CSSpell2_Vars: all spell variables identified in the input statement
                if any combination of spell variables changes then a new
                spell is created.
                if one or the other spells is missing the values from that dataset are set to null. 
*;
*/




        ***                      ***;
        *** Combine Spells macro ***;
        ***                      ***;

 %MACRO CombineSpell( CSinfile1 
                     ,CSSpell1_Vars
                     ,CSSpell1_SD
                     ,CSSpell1_ED
                     ,CSinfile2 
                     ,CSSpell2_Vars
                     ,CSSpell2_SD
                     ,CSSpell2_ED
                     ,CSoutfile
                     ,CSidvar
                    ) ;

/*

 %LET CSinfile1 = SCtest1 ;
 %LET CSSpell1_Vars = EA_assist ;
 %LET CSSpell1_SD = participation_sd ;
 %LET CSSpell1_ED = participation_ed ;
 %LET CSinfile2 = SCtest2 ;
 %LET CSSpell2_Vars = Benefit ;
 %LET CSSpell2_SD = SpellFrom ;
 %LET CSSpell2_ED = SpellTo ;
 %LET CSoutfile = SCtest3;
 %LET CSidvar = swn ;
*/

 
 %PUT *** Start of Combine Spell Macro IAP: /r00/msd/shared/ssi/macros/  ** ;

     ** Utility macros **;
 /*
 %INCLUDE "/r00/prod/msd/shared/ssi/macros/spellcondense.sas" ;
 %INCLUDE "/r00/prod/msd/shared/ssi/macros/spellhistoryinverter.sas" ;
 */
    ** set up work space **;

 PROC DATASETS LIB = work NOLIST ; DELETE &CSoutfile ; run ;

 ** work out format for spell starts and ends **;
 PROC CONTENTS DATA = &CSinfile1 (KEEP =&CSSpell1_SD) 
   NOPRINT
   OUT = CStemp1  ;
 run ;

 DATA CStemp1 ;
  SET CStemp1 ;

  ** Marc de Boer 22Jul2015 Included check that format length is not zero *;
  IF formatl gt 0 THEN CALL SYMPUTX("DTformat", STRIP(format)||STRIP(formatl)||".") ;
  ELSE CALL SYMPUTX("DTformat", STRIP(format)||".") ;
 run ;

 ** work out earlest and latest start and ends for spells **;
 ** Marc de Boer 20 Jul 2015 Removed the date formating becuase of 
    formatting problems 
 **;

 PROC MEANS DATA =  &CSinfile1 NOPRINT NWAY MISSING ;
  OUTPUT OUT = CStemp1 (DROP = _TYPE_ _FREQ_ 
                        )
   MIN(&CSSpell1_SD) =  MINspellSD
   MAX(&CSSpell1_ED) =  MAXspellED
    ;
 run ;

 PROC MEANS DATA =  &CSinfile2 NOPRINT NWAY MISSING ;
  OUTPUT OUT = CStemp2 (DROP = _TYPE_ _FREQ_ 
                        )
   MIN(&CSSpell2_SD) =  MINspellSD
   MAX(&CSSpell2_ED) =  MAXspellED
    ;
 run ;

 DATA CStemp3 ;
  SET CStemp1 
      CStemp2;
 run ;

 PROC MEANS DATA =  CStemp3 NOPRINT NWAY MISSING ;
  OUTPUT OUT = CStemp4 (DROP = _TYPE_ _FREQ_ 
                        )
   MIN(MINspellSD) =  MINspellSD
   MAX(MAXspellED) =  MAXspellED
    ;
 run ;

 DATA CStemp4 ;
  SET CStemp4 ;
 
  FORMAT MINspellSD  MAXspellED ;
  CALL SYMPUTX("ShrtEndSD", INT(MINspellSD) ) ;
  CALL SYMPUTX("LongEndED", INT(MAXspellED) ) ;

 run ;

/*
 DATA CStemp1 ;
  SET CStemp1 ;

  FORMAT MINspellSD ;
  IF MINspellSD gt "1Jan2100"d THEN DO ;
      CALL SYMPUTX("ShrtEndSD", "DHMS('01jan1800'd,0,0,0)" ) ;
      CALL SYMPUTX("LongEndED",  'DHMS("01jan2200"d,0,0,0)' ) ;
  END ;
  ELSE DO ;
      CALL SYMPUTX("ShrtEndSD", "'01jan1800'd" ) ;
      CALL SYMPUTX("LongEndED", '"01jan2200"d' ) ;
  END ;
 run ;
*/

 ** identify if id variable is num or char *;
 PROC CONTENTS DATA = &CSinfile1 (KEEP = &CSidvar)
  NOPRINT 
  OUT = CSIDVar1 ;
 run ;

 DATA CSIDVar1 ;
  SET CSIDVar1 ;
  IF Type = 2 THEN DO ;
    CALL SYMPUTX("IDvarNull", "''" ) ;
    CALL SYMPUTX("IDvarLen", CATT("$",Length,"."));
  END ;
  ELSE DO ;
    CALL SYMPUTX("IDvarNull", "." ) ;
    CALL SYMPUTX("IDvarLen", "8.") ;
  END ;
 run ;


 ** Set up input dataset one **;

 ** Identify spell variables **;
 PROC CONTENTS DATA = &CSinfile1 (KEEP = &CSSpell1_Vars)
  NOPRINT 
  OUT = CSinflieVars1 ;
 run ;

 DATA CSinflieVars1 ;
  SET CSinflieVars1 ;

  LENGTH CStat1Lgth 8. ;
  RETAIN CStat1Lgth ;
  IF _N_ = 1 THEN CStat1Lgth = 0 ;
  CALL SYMPUTX("CS1_VarN", STRIP(_N_) ) ;
  CALL SYMPUTX("CS1_Var"||STRIP(_N_) , name) ;

  LENGTH LengthStat $250. ;
  IF Type = 2 THEN DO ;
     LengthStat = "$"||STRIP(Length+1)||"." ; 
     CStat1Lgth = CStat1Lgth + Length + 1 ;
  END ;
  ELSE DO ;
     LengthStat ="8." ;
     CStat1Lgth = CStat1Lgth + 20 ;
  END ;
  CALL SYMPUTX("CS1_Len"||STRIP(_N_) ,LengthStat) ;

  IF format = "" THEN CALL SYMPUTX("CS1_Fmt"||STRIP(_N_) ,LengthStat) ;
  ELSE DO ;
    ** Marc de Boer 22Jul2015 Included check that format length is not zero *;
    IF formatl gt 0 THEN CALL SYMPUTX("CS1_Fmt"||STRIP(_N_),  STRIP(format)||STRIP(formatl)||".");
    ELSE CALL SYMPUTX("CS1_Fmt"||STRIP(_N_), STRIP(format)||".");
  END ;
  
  CALL SYMPUTX("CStat1Lgth", "$"||STRIP(MAX(15, CStat1Lgth))||"." ) ;
 run ;

 DATA CSinfile1_v1 (DROP = &CSSpell1_Vars)  ;
  LENGTH CSidvar &IDvarLen
         CSSpell1_SD 
         CSSpell1_ED 8. ;
  FORMAT CSSpell1_SD 
         CSSpell1_ED &DTformat  ;
  SET &CSinfile1 (KEEP = &CSidvar 
                         &CSSpell1_Vars 
                         &CSSpell1_SD 
                         &CSSpell1_ED
                  RENAME = (&CSidvar = CSidvar 
                            &CSSpell1_SD = CSSpell1_SD 
                            &CSSpell1_ED = CSSpell1_ED
                            )
                 WHERE = (    CSidvar ne &IDvarNull
                          AND CSSpell1_SD ne .
                          AND CSSpell1_ED ne .
                         )   
                 ) ;

  ** MdB 2015 10 27 Enure dates are integer values **;
  CSSpell1_SD = INT(CSSpell1_SD) ;
  CSSpell1_ED = INT(CSSpell1_ED) ;

  ** Convert spell variables into a single string **;
  LENGTH CondStats1 &CStat1Lgth ;
  %MACRO constat1 ;
     %DO i = 1 %TO &CS1_VarN ;
        CondStats1 = STRIP(CondStats1)||"~"||STRIP(&&CS1_Var&i) ;
        %IF &i = 1 %THEN %DO ; 
          CondStats1 = COMPRESS(CondStats1,"~") ;
        %END ;
     %END ;
  %MEND ;
  %constat1 ;
 run ;

 %SpellCondense( SCinfile = CSinfile1_v1
                ,SCoutfile = CSinfile1_v2
                ,SClink = CSidvar 
                ,SCstart = CSSpell1_SD
                ,SCend_d = CSSpell1_ED
                ,SCstatus = CondStats1
                ,SCbuffer = 1) ;

 %SpellHistoryInverter(  SHIinfile = CSinfile1_v2 
                       , SHIoutfile = CSinfile1_v3 
                       , SHIlink = CSidvar
                       , SHIspellSD = CSSpell1_SD
                       , SHIspellED = CSSpell1_ED
                       ) ;
  
 %LET ByVars = CSidvar CSSpell1_SD CSSpell1_ED;
 PROC SORT DATA = CSinfile1_v3  ; BY &ByVars ; run ;
 PROC SORT DATA = CSinfile1_v2; BY &ByVars ; run ;

 DATA CSinfile1_v4  (DROP = OrginalSpell Temp:) ;
  MERGE CSinfile1_v2(IN=A)
        CSinfile1_v3(IN=B) ;
  BY &ByVars ;
  IF B ;
  IF NOT A THEN CondStats1 = "<Blank Spell>" ;
  OUTPUT ;

  Temp1SD = CSSpell1_SD ;
  Temp1ED = CSSpell1_ED ;
  IF first.CSidvar THEN DO ;
      CondStats1 = "<Blank Spell>" ;
      CSSpell1_ED = Temp1SD - 1;
      CSSpell1_SD = &ShrtEndSD - 1;
      OUTPUT ;
      CSSpell1_ED = Temp1ED ; ** Switch end date back MdB 2015 10 15 **;
  END ;
  IF last.CSidvar THEN DO ;
      CondStats1 = "<Blank Spell>" ;
      CSSpell1_SD = Temp1ED + 1;
      CSSpell1_ED = &LongEndED + 1 ;
      OUTPUT ;
  END ;
 run ;

 %LET ByVars = CSidvar CSSpell1_SD ;
 PROC SORT DATA = CSinfile1_v4; BY &ByVars ; run ;

 *PROC PRINT DATA = CSinfile1_v4 (obs=20 WHERE = (CondStats1 = "<Blank Spell>") ) ; run ;

 ** Set up input dataset two **;

 ** Identify spell variables **;
 PROC CONTENTS DATA = &CSinfile2 (KEEP = &CSSpell2_Vars)  
  NOPRINT
  OUT = CSinflieVars2 ;
 run ;

 DATA CSinflieVars2 ;
  SET CSinflieVars2 ;

  LENGTH CStat2Lgth 8. ;
  RETAIN CStat2Lgth ;
  IF _N_ = 1 THEN CStat2Lgth = 0 ;
  CALL SYMPUTX("CS2_VarN", STRIP(_N_) ) ;
  CALL SYMPUTX("CS2_Var"||STRIP(_N_) , name) ;

  LENGTH LengthStat $250. ;
  IF Type = 2 THEN DO ;
     LengthStat = "$"||STRIP(Length+1)||"." ; 
     CStat2Lgth = CStat2Lgth + Length + 1 ;
  END ;
  ELSE DO ;
     LengthStat ="8." ;
     CStat2Lgth = CStat2Lgth + 20 ;
  END ;
  CALL SYMPUTX("CS2_Len"||STRIP(_N_) ,LengthStat) ;

  IF format = "" THEN CALL SYMPUTX("CS2_Fmt"||STRIP(_N_) ,LengthStat) ;
  ELSE DO ;
    ** Marc de Boer 22Jul2015 Included check that format length is not zero *;
    IF formatl gt 0 THEN CALL SYMPUTX("CS2_Fmt"||STRIP(_N_),  STRIP(format)||STRIP(formatl)||".");
    ELSE CALL SYMPUTX("CS2_Fmt"||STRIP(_N_), STRIP(format)||".");
  END ;
 
  CALL SYMPUTX("CStat2Lgth", "$"||STRIP(MAX(15, CStat2Lgth))||"." ) ;
 run ;

 DATA CSinfile2_v1 (DROP = &CSSpell2_Vars)  ;
  LENGTH CSidvar &IDvarLen
         CSSpell2_SD 
         CSSpell2_ED 8. ;
  FORMAT CSSpell2_SD 
         CSSpell2_ED  &DTformat;
  SET &CSinfile2 (KEEP = &CSidvar 
                         &CSSpell2_Vars 
                         &CSSpell2_SD 
                         &CSSpell2_ED
                  RENAME = (&CSidvar = CSidvar 
                            &CSSpell2_SD = CSSpell2_SD 
                            &CSSpell2_ED = CSSpell2_ED
                            )
                 WHERE = (    CSidvar ne &IDvarNull
                          AND CSSpell2_SD ne .
                          AND CSSpell2_ED ne .
                         )   
                 ) ;

  ** MdB 2015 10 27 Ensure dates are integer values **;
  CSSpell2_SD = INT(CSSpell2_SD) ;
  CSSpell2_ED = INT(CSSpell2_ED) ;

  LENGTH CondStats2 &CStat2Lgth ;
  %MACRO constat2 ;
     %DO i = 1 %TO &CS2_VarN ;
        CondStats2 = STRIP(CondStats2)||"~"||STRIP(&&CS2_Var&i) ;
        %IF &i = 1 %THEN %DO ; 
          CondStats2 = COMPRESS(CondStats2,"~") ;
        %END ;
     %END ;
  %MEND ;
  %constat2 ;
 run ;

  %SpellCondense( SCinfile = CSinfile2_v1
                ,SCoutfile = CSinfile2_v2
                ,SClink = CSidvar 
                ,SCstart = CSSpell2_SD
                ,SCend_d = CSSpell2_ED
                ,SCstatus = CondStats2
                ,SCbuffer = 1) ;

 %SpellHistoryInverter(  SHIinfile = CSinfile2_v2 
                       , SHIoutfile = CSinfile2_v3 
                       , SHIlink = CSidvar
                       , SHIspellSD = CSSpell2_SD
                       , SHIspellED = CSSpell2_ED
                       ) ;
  
 %LET ByVars = CSidvar CSSpell2_SD CSSpell2_ED ;
 PROC SORT DATA = CSinfile2_v3  ; BY &ByVars ; run ;
 PROC SORT DATA = CSinfile2_v2; BY &ByVars ; run ;

 DATA CSinfile2_v4  (DROP = OrginalSpell Temp:) ;
  MERGE CSinfile2_v2(IN=A)
        CSinfile2_v3(IN=B) ;
  BY &ByVars ;
  IF B ;
  IF NOT A THEN CondStats2 = "<Blank Spell>" ;
  OUTPUT ;

  Temp1SD = CSSpell2_SD ;
  Temp1ED = CSSpell2_ED ;
  IF first.CSidvar THEN DO ;
      CondStats2 = "<Blank Spell>" ;
      CSSpell2_ED = Temp1SD - 1;
      CSSpell2_SD = &ShrtEndSD -1 ;
      OUTPUT ;
      CSSpell2_ED = Temp1ED ; ** Switch end date back MdB 2015 10 15 **;
  END ;
  IF last.CSidvar THEN DO ;
      CondStats2 = "<Blank Spell>" ;
      CSSpell2_SD = Temp1ED + 1;
      CSSpell2_ED = &LongEndED + 1;
      OUTPUT ;
  END ;
 run ;

 %LET ByVars = CSidvar CSSpell2_SD ;
 PROC SORT DATA = CSinfile2_v4; BY &ByVars ; run ;

* PROC PRINT DATA = CSinfile2_v4 (obs=20 WHERE = (CondStats2 = "<Blank Spell>") ) ; run ;

 ** identify overlapping spells between the two **;
  PROC SQL ;
  CREATE TABLE CSdataset1 AS
  SELECT  a.CSidvar
         ,a.CondStats1
         ,a.CSSpell1_SD
         ,a.CSSpell1_ED
         ,b.CondStats2
         ,b.CSspell2_SD
         ,b.CSSpell2_ED
         ,MAX(CSSpell1_SD, CSSpell2_SD) AS CSspellSD FORMAT=&DTformat
         ,MIN(CSSpell1_ED, CSSpell2_ED) AS CSspellED FORMAT=&DTformat
  FROM CSinfile1_v4 AS a
       JOIN 
       CSinfile2_v4 AS b
  ON       a.CSidvar = b.CSidvar
       AND a.CSSpell1_SD le b.CSSpell2_ED
       AND a.CSSpell1_ED ge b.CSspell2_SD
 ;
 quit ;

 ** Identify any dataset one spells not included in the match *;
 %LET ByVars = CSidvar CSSpell1_SD ;
 PROC SORT DATA = CSdataset1 
     OUT = CStemp1 (KEEP = &ByVars) 
     NODUPKEY ; 
     BY &ByVars ;
 run ;
 PROC SORT DATA = CSinfile1_v4 ; BY &ByVars ; run ;

 DATA  CSinfile1_v5 (SORTEDBY = &ByVars) ;
  MERGE CSinfile1_v4 (IN=A)
        CStemp1 (IN=B) ;
  BY &ByVars ;
  IF A AND NOT B ;
  CondStats2 = "<Blank Spell>" ;
 run ;

  ** Identify any dataset two spells not included in the match *;
 %LET ByVars = CSidvar CSSpell2_SD ;
 PROC SORT DATA = CSinfile2_v4 ; BY &ByVars ; run ;
 PROC SORT DATA = CSdataset1 
     OUT = CStemp2 (KEEP = &ByVars) 
     NODUPKEY ; 
     BY &ByVars ;
 run ;

 DATA  CSinfile2_v5 (SORTEDBY = &ByVars) ;
  MERGE CSinfile2_v4 (IN=A)
        CStemp2 (IN=B) ;
  BY &ByVars ;
  IF A AND NOT B ;
  CondStats1 = "<Blank Spell>" ;
 run ;

 ** Combine all spells into a single file **;
 DATA &CSoutfile (KEEP = CSidvar 
                         CSspellSD 
                         CSspellED 
                         &CSSpell1_Vars 
                         &CSSpell2_Vars
                  RENAME = (CSidvar = &CSidvar) 
                 ) ;
  SET CSdataset1 (KEEP = CSidvar 
                         CSspellSD 
                         CSspellED 
                         CondStats:
                  ) 
      CSinfile1_v5 (KEEP = CSidvar 
                         CSSpell1_SD 
                         CSSpell1_ED 
                         CondStats:
                    RENAME = (CSSpell1_SD = CSspellSD 
                              CSSpell1_ED = CSspellED 
                             )
                   ) 
      CSinfile2_v5 (KEEP = CSidvar 
                         CSSpell2_SD 
                         CSSpell2_ED 
                         CondStats:
                    RENAME = (CSSpell2_SD = CSspellSD 
                              CSSpell2_ED = CSspellED 
                             )
                   );

  ** if both spells have null values then remove from output *;
  IF CondStats1 = "<Blank Spell>" 
     AND CondStats2 = "<Blank Spell>" THEN DELETE ;

  * convert condensed spell variables into their orgianl vraible
    names lengths and formats *;
  * Marc de Boer 2014 05 09 TRANWARD removes multiple values (ie two variables with the same value)
                            re-orged the code to just take the first. *; 
  %MACRO UnpackVars ;
   %DO c = 1 %TO 2 ;
   %DO i = 1 %TO &&CS&c._VarN ;
      LENGTH &&CS&c._Var&i &&CS&c._Len&i ;
      FORMAT &&CS&c._Var&i &&CS&c._Fmt&i ;
      LENGTH temp4 $1000. ;
      IF CondStats&c = "<Blank Spell>" THEN DO ;
          IF SUBSTR("&&CS&c._Len&i", 1, 1) = "$" THEN &&CS&c._Var&i = "" ;
          ELSE &&CS&c._Var&i = . ;
      END ;
      ELSE DO ;
          i = &i ;
          v = &&CS&c._VarN ;
          l = LENGTH(CondStats&c) ;
          CondStatsStart = CondStats&c ;
          IF &i lt &&CS&c._VarN THEN DO ;
             Temp3 = FIND(CondStats&c, "~", "t") ;
             temp4 = SUBSTR(STRIP(CondStats&c), 1, temp3) ;
             LENGTH CondVarStart $500. ;
             CondVarStart = temp4 ;
             CondStats&c = SUBSTR(STRIP(CondStats&c), LENGTH(temp4)+1 ) ;
             *CondStats&c = STRIP(TRANWRD(CondStats&c, STRIP(temp4), "")) ;
          END ;
          ELSE temp4  = CondStats&c ;

          &&CS&c._Var&i = COMPRESS(STRIP(temp4),"~") ; ** temp4 can now convert to numeric *;
      END ;
   %END ;
   %END ;

  %MEND ;
  %UnpackVars ;
 run ;

 PROC DATASETS LIB = work NOLIST ; 
  DELETE CSinfile:
         CSINFLIEVARS: 
         CSdataset: 
         CStemp:
         CSIDVar:
         ; 
 run ;

 %PUT ***;
 %PUT *** End of Combine Spell Macro;
 %PUT ***;
 %PUT ;

 %MEND ;

 
********************************************************************************************************;

  /*
 TITLE: Random checks of records to see if SpellCombine to see
        if the combined dataset produces the same values as 
        the two seperate files. 


 AUTHOR: Marc de Boer

 DATE: October 2015
*/;




 %MACRO SplCombineVald(RCVLib = work 
                      ,RCVPrimKey =  
                      ,RCVtestN = 
                      ,RCV1_infile =
                      ,RCV1_EffFrm =  
                      ,RCV1_EffTo =  
                      ,RCV1_Vars = 
                      ,RCV2_infile = 
                      ,RCV2_EffFrm =  
                      ,RCV2_EffTo =  
                      ,RCV2_Vars = 
                      ,RCVombinedFile =  
                      ) ;


/* for testing **;

%LET SubCaluse = cvid =  348535 ;
DATA test1 ;
  SET JOB_VLicences2 (WHERE = (&SubCaluse ) ) ; 
 run ;

DATA test2 ;
  SET DriverLicenceClassCV2 (WHERE = (&SubCaluse ) ) ; 
 run ;

 %LET RCVLib = work ;
 %LET RCVPrimKey = CVid ;
 %LET RCVtestN = 1 ;

 %LET RCV1_infile =EAtest2 ;
 %LET RCV1_EffFrm = participation_sd ;
 %LET RCV1_EffTo = ValidTo ;
 %LET RCV1_Vars = CVS_DriverLicenceType
                  CVS_DriverLicenceTypeID
                  DriverLicenceExpiryDate ;

 %LET RCV2_infile = test2 ;
 %LET RCV2_EffFrm = ValidFrom ;
 %LET RCV2_EffTo = ValidTo ;
 %LET RCV2_Vars = DriverLicenceClassID
                  DriverLicenceClass
                  DriverLicenceTypeID
                  DriverLicenceType
                  AutomaticTransmission
                  TwoHundredHoursExp ;

 %LET RCVombinedFile = JOB_VLicences3 ;

**/
  ** Detmine spell date format **;
 PROC CONTENTS DATA = &RCVLib..&RCV1_infile. (KEEP = &RCV1_EffFrm. ) 
   OUT = RCVtemp0 (RENAME = (name = variable) )
   NOPRINT ;
 run ;

 DATA RCVtemp0 ;
  SET RCVtemp0 ;
  IF formatl gt 0 THEN CALL SYMPUTX("RCV_SpllFormat", CATT(format,formatl,'.') ) ;
  ELSE CALL SYMPUTX("RCV_SpllFormat", CATT(format,'.') ) ;
 run ;

 %PUT Spell format (based on infile 1 spell start): &RCV_SpllFormat. ;

 PROC PRINT DATA = &syslast. (obs=20) ; run ;
  ** Determine minimum and maximum repdate *;
 PROC MEANS DATA = &RCVLib..&RCV1_infile. NOPRINT NWAY MISSING ;
  OUTPUT OUT = RCVtemp1 (DROP = _TYPE_ _FREQ_ )
   MIN(&RCV1_EffFrm.) = MinEffFrm 
   MAX(&RCV1_EffTo.) = MaxRCCEffTo 
   ;
 run ;

 PROC MEANS DATA = &RCVLib..&RCV2_infile. NOPRINT NWAY MISSING ;
  OUTPUT OUT = RCVtemp2 (DROP = _TYPE_ _FREQ_ )
   MIN(&RCV2_EffFrm.) = MinEffFrm 
   MAX(&RCV2_EffTo.) = MaxRCCEffTo 
   ;
 run ;

 DATA RCVtemp3 ;
  SET RCVtemp1
      RCVtemp2 ;
 run ;

 PROC MEANS DATA = RCVtemp3 NOPRINT NWAY MISSING ;
  OUTPUT OUT = RCVtemp3 (DROP = _TYPE_ _FREQ_ )
   MIN(MinEffFrm) = MinEffFrm 
   MAX(MaxRCCEffTo) = MaxRCCEffTo 
   ;
 run ;

 DATA RCVtemp3 ;
  SET RCVtemp3 ;
  CALL SYMPUTX("MinEffFrm", MinEffFrm ) ;
  CALL SYMPUTX("MaxEffTo", MaxRCCEffTo) ;
 run ;

 %PUT First Replication date: &MinEffFrm. ;
 %PUT Last Replication date: &MaxEffTo. ;

 ** Select sample of primary key ids for testing *;
 %LET ByVars = &RCVPrimKey. ;
 PROC SORT DATA = &RCVLib..&RCV1_infile.
  OUT = RCVtestids1 (KEEP = &ByVars)
  NODUPKEY ;
  BY &ByVars. ;
 run ;

 %LET ByVars = &RCVPrimKey. ;
 PROC SORT DATA = &RCVLib..&RCV2_infile.
  OUT = RCVtestids2 (KEEP = &ByVars)
  NODUPKEY ;
  BY &ByVars. ;
 run ;

 DATA RCVtestids3 ;
  SET RCVtestids1
      RCVtestids2 ;
 run ;

 %LET ByVars = &RCVPrimKey. ;
 PROC SORT DATA = RCVtestids3
  NODUPKEY ;
  BY &ByVars. ;
 run ;

 ** check whether key is character *;
 PROC CONTENTS DATA = RCVtestids3
   OUT = RCVtemp6 (RENAME = (name = variable) )
   NOPRINT ;
 run ;

 DATA RCVtemp6 ;
  SET RCVtemp6 ;
  IF type = 2 THEN CALL SYMPUTX("RCV_PKchar", "$" ) ;
  ELSE CALL SYMPUTX("RCV_PKchar", "" ) ;
 run ;

 %PUT Primary key character format: &RCV_PKchar. ;

 DATA RCVtestids3  ;
  RETAIN &ByVars ;
  SET RCVtestids3;
  Select = NORMAL(0) ;
 run ;

 %LET ByVars = Select ;
 PROC SORT DATA = RCVtestids3 ; BY &ByVars ; run ;

 DATA RCVtestids3 ;
  SET RCVtestids3 (DROP = select OBS = &RCVtestN.);
 run ;

 %USE_FMT(RCVtestids3, &RCVPrimKey., RCV_tst_ids) ;

 ** Generate random list of dates to check *;
 DATA RCVtestidsdates1 (KEEP =  &RCVPrimKey. CheckDate) ;
  SET RCVtestids3  ;
  FORMAT CheckDate &RCV_SpllFormat. ;
  PeriodDur = &MaxEffTo - &MinEffFrm ;
  DO i = 1 TO 100 ;
     DateSelect = INT(UNIFORM(0) * PeriodDur) ;
     CheckDate = &MinEffFrm + DateSelect ;
     OUTPUT ;
  END ;
 run ;

 ** remove any duplicate random check dates *;
 %LET ByVars = &RCVPrimKey. CheckDate;
 PROC SORT DATA = RCVtestidsdates1 NODUPKEY ; BY &ByVars ; run ;

 ** Set up infiles **;

  ** Create a string of the check variables in dataset 1 **;
 PROC CONTENTS DATA = &RCVLib..&RCV1_infile. (KEEP = &RCV1_Vars.)
  NOPRINT 
  OUT = RCVtemp10;
 run ;

 DATA RCVtemp10 ;
  SET RCVtemp10 (WHERE = (LOWCASE(name) ne LOWCASE("&RCVPrimKey.") ) ) ;

  LENGTH RpCbtat1Lgth 8. ;
  RETAIN RpCbtat1Lgth ;
  IF _N_ = 1 THEN RpCbtat1Lgth = 0 ;
  CALL SYMPUTX("RCV1_VarN", STRIP(_N_) ) ;
  CALL SYMPUTX("RCV1_Var"||STRIP(_N_) , name) ;

  LENGTH LengthStat $250. ;
  IF Type = 2 THEN DO ;
     LengthStat = "$"||STRIP(Length+1)||"." ; 
     RpCbtat1Lgth = RpCbtat1Lgth + Length + 1 ;
  END ;
  ELSE DO ;
     LengthStat ="8." ;
     RpCbtat1Lgth = RpCbtat1Lgth + 20 ;
  END ;
  
  CALL SYMPUTX("RCV1Lgth", "$"||STRIP(MAX(15, RpCbtat1Lgth))||"." ) ;
 run ;

 %PUT Number of dataset1 variables: &RCV1_VarN. ;
 %PUT Total length of dataset1 variables: &RCV1Lgth. ;

 ** Create a string of the check variables in dataset 2 **;
 PROC CONTENTS DATA = &RCVLib..&RCV2_infile. (KEEP = &RCV2_Vars.)
  NOPRINT 
  OUT = RCVtemp10;
 run ;

 DATA RCVtemp10 ;
  SET RCVtemp10 (WHERE = (LOWCASE(name) ne LOWCASE("&RCVPrimKey.") ) ) ;

  LENGTH RpCbtat1Lgth 8. ;
  RETAIN RpCbtat1Lgth ;
  IF _N_ = 1 THEN RpCbtat1Lgth = 0 ;
  CALL SYMPUTX("RCV2_VarN", STRIP(_N_) ) ;
  CALL SYMPUTX("RCV2_Var"||STRIP(_N_) , name) ;

  LENGTH LengthStat $250. ;
  IF Type = 2 THEN DO ;
     LengthStat = "$"||STRIP(Length+1)||"." ; 
     RpCbtat1Lgth = RpCbtat1Lgth + Length + 1 ;
  END ;
  ELSE DO ;
     LengthStat ="8." ;
     RpCbtat1Lgth = RpCbtat1Lgth + 20 ;
  END ;
  
  CALL SYMPUTX("RCV2Lgth", "$"||STRIP(MAX(15, RpCbtat1Lgth))||"." ) ;
 run ;

 %PUT Number of dataset1 variables: &RCV2_VarN. ;
 %PUT Total length of dataset1 variables: &RCV2Lgth. ;


 ** prep and subset input and output datasets **;

 ** Input dataset 1 **;
 DATA RCV1_Input1 ;
  SET &RCVLib..&RCV1_infile. (KEEP =&RCVPrimKey. &RCV1_Vars. &RCV1_EffFrm. &RCV1_EffTo.
                             WHERE = (PUT(&RCVPrimKey., &RCV_PKchar.RCV_tst_ids.) = "Y") 
                             ) ;

 run ;

 ** Input dataset 2 **;
 DATA RCV2_Input1 ;
  SET &RCVLib..&RCV2_infile. (KEEP =&RCVPrimKey. &RCV2_Vars. &RCV2_EffFrm. &RCV2_EffTo.
                             WHERE = (PUT(&RCVPrimKey., &RCV_PKchar.RCV_tst_ids.) = "Y") 
                             ) ;

 run ;

 ** Output dataset **;
 DATA RCV_output1 ;
  SET &RCVLib..&RCVombinedFile. (KEEP =&RCVPrimKey. &RCV1_Vars. &RCV2_Vars. CSspellSD CSspellED
                             WHERE = (PUT(&RCVPrimKey., &RCV_PKchar.RCV_tst_ids.) = "Y") 
                             ) ;


 run ;

 ** Extract check vars for select dates **;

 ** Input datasets **;
 PROC SQL ;
  CREATE TABLE RCV1_Input2 (RENAME = (&RCV1_EffFrm. = ValidFrom1_IN
                                      &RCV1_EffTo. = ValidTo1_IN
                                      ) 
                            ) AS
  SELECT a.*
        ,b.*
  FROM RCVtestidsdates1 AS a
       LEFT JOIN 
       RCV1_Input1 AS b
  ON       a.&RCVPrimKey. = b.&RCVPrimKey.  
       AND a.CheckDate BETWEEN b.&RCV1_EffFrm. AND b.&RCV1_EffTo.
 ;
 quit ;

 PROC SQL ;
  CREATE TABLE RCV2_Input2 (RENAME = (&RCV2_EffFrm. = ValidFrom2_IN
                                      &RCV2_EffTo. = ValidTo2_IN
                                      ) 
                            ) AS
  SELECT a.*
        ,b.*
  FROM RCVtestidsdates1 AS a
       LEFT JOIN 
       RCV2_Input1 AS b
  ON       a.&RCVPrimKey. = b.&RCVPrimKey.  
       AND a.CheckDate BETWEEN b.&RCV2_EffFrm. AND b.&RCV2_EffTo.
 ;
 quit ;

 %LET ByVars = &RCVPrimKey. CheckDate ;
 PROC SORT DATA = RCV1_Input2 ; BY &ByVars ; run ;
 PROC SORT DATA = RCV2_Input2 ; BY &ByVars ; run ;

 DATA RCV_InputValid1  (SORTEDBY = &ByVars) ;
  RETAIN &ByVars ;
  MERGE RCV1_Input2 (IN=A)
        RCV2_Input2 (IN=B) ;
  BY &ByVars ;
  IF A OR B ;

  LENGTH CondStats1 &RCV1Lgth.  CondStats2 &RCV2Lgth.;
  %MACRO constat1 ;
     %DO i = 1 %TO &RCV1_VarN ;
        CondStats1 = STRIP(CondStats1)||"~"||STRIP(&&RCV1_Var&i) ;
        %IF &i = 1 %THEN %DO ; 
          CondStats1 = COMPRESS(CondStats1,"~") ;
        %END ;
     %END ;
  %MEND ;
  %constat1 ;
  %MACRO constat2 ;
     %DO i = 1 %TO &RCV2_VarN ;
        CondStats2 = STRIP(CondStats2)||"~"||STRIP(&&RCV2_Var&i) ;
        %IF &i = 1 %THEN %DO ; 
          CondStats2 = COMPRESS(CondStats2,"~") ;
        %END ;
     %END ;
  %MEND ;
  %constat2 ;

  CheckVarAllMD5 = PUT(MD5(COMPRESS(CATT(CondStats1, CondStats2),' ','s')),hex32.) ; ; ;
  DROP &RCV1_Vars. &RCV2_Vars. ;
 run ;

 ** Output dataset **;
 PROC SQL ;
  CREATE TABLE RCV_output2  AS
  SELECT a.*
        ,b.*
  FROM RCVtestidsdates1 AS a
       LEFT JOIN 
       RCV_output1 AS b
  ON       a.&RCVPrimKey. = b.&RCVPrimKey.  
       AND a.CheckDate BETWEEN b.CSspellSD AND b.CSspellED
 ;
 quit ;

 DATA RCV_output3 ;
  SET RCV_output2 ;

  LENGTH CondStats1 &RCV1Lgth.  CondStats2 &RCV2Lgth.;
  %MACRO constat1 ;
     %DO i = 1 %TO &RCV1_VarN ;
        CondStats1 = STRIP(CondStats1)||"~"||STRIP(&&RCV1_Var&i) ;
        %IF &i = 1 %THEN %DO ; 
          CondStats1 = COMPRESS(CondStats1,"~") ;
        %END ;
     %END ;
  %MEND ;
  %constat1 ;
  %MACRO constat2 ;
     %DO i = 1 %TO &RCV2_VarN ;
        CondStats2 = STRIP(CondStats2)||"~"||STRIP(&&RCV2_Var&i) ;
        %IF &i = 1 %THEN %DO ; 
          CondStats2 = COMPRESS(CondStats2,"~") ;
        %END ;
     %END ;
  %MEND ;
  %constat2 ;

  CheckVarAllMD5 = PUT(MD5(COMPRESS(CATT(CondStats1, CondStats2),' ','s')),hex32.) ; ;
  DROP &RCV1_Vars. &RCV2_Vars. ;

 run ;

 ** Compare input and output results **;
 %LET MatchNotOK = 0 ;
 %LET ByVars = &RCVPrimKey. CheckDate CheckVarAllMD5 ;
 PROC SORT DATA = RCV_InputValid1; BY &ByVars ; run ;
 PROC SORT DATA = RCV_output3; BY &ByVars ; run ;

 DATA RCV_ValidationChk1 (DROP = CheckVarAllMD5) ;
  RETAIN &ByVars  ;
  MERGE RCV_InputValid1(IN=A)
        RCV_output3 (IN=B) ;
  BY &ByVars ;
  IF A OR B ;

  LENGTH match $10. ;
  Match = "OK" ;
  IF NOT(A AND B) THEN DO ;
    Match = "Not OK" ; 
    CALL SYMPUTX("MatchNotOK", 1) ;
  END ;
 run ;

 %LET ClassVars = Match ;
 PROC MEANS DATA = RCV_ValidationChk1 NOPRINT NWAY MISSING ;
  CLASS &ClassVars.;
  OUTPUT OUT = RCV_ValidationSum (SORTEDBY = &ClassVars.
                    DROP = _TYPE_ _FREQ_ )
   N(CheckDate) = Observations  
    ;
 run ;

 PROC PRINT DATA = RCV_ValidationSum (obs=20) ; run ;
 PROC PRINT DATA = RCV_ValidationChk1 (obs=20 WHERE = (Match = "Not OK" ) ) ; run ;
 
 %IF &MatchNotOK = 1 %THEN %DO ;
    %LET ByVars = &RCVPrimKey. CheckDate ;
    PROC SORT DATA = RCV_ValidationChk1 (obs=1 WHERE = (Match = "Not OK" ) )
      OUT = ErrorEvents1 (KEEP = &ByVars) NODUPKEY ; 
      BY &ByVars ; 
    run ;
  
    %LET ByVars = &RCVPrimKey. CheckDate ;
    PROC SORT DATA = ErrorEvents1 ; BY &ByVars ; run ;
    PROC SORT DATA = RCV_output3 ; BY &ByVars ; run ;

    DATA RCV_NotOKoutput1  (SORTEDBY = &ByVars) ;
      RETAIN &ByVars ;
      MERGE RCV_output3 (IN=A)
            ErrorEvents1 (IN=B KEEP = &ByVars) ;
      BY &ByVars ;
      IF A AND B ;
     run ;

    %LET ByVars = &RCVPrimKey. CheckDate ;
    PROC SORT DATA = ErrorEvents1 ; BY &ByVars ; run ;
    PROC SORT DATA = RCV_InputValid1 ; BY &ByVars ; run ;

    DATA RCV_NotOKinput1  (SORTEDBY = &ByVars) ;
      RETAIN &ByVars ;
      MERGE RCV_InputValid1 (IN=A   )
            ErrorEvents1 (IN=B KEEP = &ByVars) ;
      BY &ByVars ;
      IF A AND B ;
     run ;

     PROC PRINT DATA = RCV_NotOKinput1 (obs=20) ; run ;
     PROC PRINT DATA = RCV_NotOKoutput1 (obs=20) ; run ;
 %END ;


 PROC DATASETS LIB = work NOLIST ;
  DELETE RCV_output: RCV_InputValid: RCV2_Input: RCV1_Input: RCVtemp: ;
 run ;
 
 %MEND ;

************************************************************************************************************************************; 
 
/*  
    TITLE:  Spell Condense Macro

    PURPOSE: Macro combines consecutive spells of the same status*
        SCLink: the id that identified the spells (eg swn or client_id) 
        SCstart and SCend_d: the spell start and end date (participation_sd and participation_ed)
        SCstatus: the variable(s) the identifies which spells are alike (ie only join consecutive spells of the same programme).
        SCbuffer: the size of the gap between spells which will be joined (eg buffer of 40 will join spells seperated by less than 40 days)

    AUTHOR: Marc de Boer, OWPA RE, CSRE, MSD

    DATE: March 2011

     MODIFCATIONS
     BY             WHEN      WHY
     Marc de Boer   Oct2011   The condense macro was not handelling complex spell history adjusted to loop
                              until all overlapping spells are removed.  Also included batch processing to 
                              reduce load on the SQL.
     Marc de Boer   Oct2011   The condense macro was not condensing adjoing spells into a single spell. Corrected by including the
                              buffer varibale into the SQL statement.
     Marc de Boer   Nov2011   The macro can get into a infanit loop. Included a check to make sure the code exits when this happens
     Marc de Boer   Feb2012   The step that removed nested spells was removing some first spells. Included a clause to stop the 
                              deletion of first spells.
     Marc de Boer   March2012 The merge hist was having a problem with status field made of numerials. Corrected code to handel this.
     Marc de Boer   April2012 Condense: included check when removing nested spells that they have the same status.
     Marc de Boer   Feb2014   Included final step to adjust spell end dates that are equal to the next spell sd
                               subtracted 1 from the spell end date.
     Marc de Boer   Feb2014   CONDdataset4: Calculation included (1+buffer) this missed one interval long spells. 
                              Changed to just (+ buffer)
     Marc de Boer   Jul2015   Removed delete of [SCoutfile] dataset as it is not required
     Marc de Boer   Aug2015   In cases were there are still overlapping spells that cannot be resolved then include
                              them in the final output so the output file has all the spells included in the infile.

*/


       ***                       ***;
       *** Condense Spells Macro ***;
       ***                       ***;

/*
 %SpellCondense( SCinfile =
                ,SCoutfile =
                ,SClink =
                ,SCstart =
                ,SCend_d =
                ,SCstatus =
                ,SCbuffer = ) ;


*
Inputs
 SCinfile: dataset with spells to be condensed
 SClink: unique identifier (eg snz_uid)
 SCstart: start date of spell
 SCend_d: end date of spell
 SCstatus: value of spell (eg benefit type) 
           can include multiple variables (eg benefit type and service centre).
           If multiple variables selected these are treated as a string.
 SCbuffer: specifies the minimum gap between spells (eg 14 would combine spells
           seperated by less than 14 days. Default is 1.
*;
*/




        ***                ***;
        *** Condense macro ***;
        ***                ***;

 %MACRO SpellCondense( SCinfile
                     ,SCoutfile
                     ,SClink
                     ,SCstart
                     ,SCend_d
                     ,SCstatus
                     ,SCbuffer = 1) ;

 
 %PUT *** Start of Condense Macro AT: IAP: /r00/msd/shared/ssi/macros/  ***;                                                                 ***;
 
/*

 DATA test ;
  SET SwiftUi_StaffId1 ;
 run ;

 %LET SCinfile = test  ;
 %LET SCoutfile = test1 ;
 %LET SClink = staff_no ;
 %LET SCstart = CSspellSD ;
 %LET SCend_d = CSspellED ;
 %LET SCstatus =SWFTusrcd  ;
 %LET SCbuffer = 1 ;
*/

 ** Create input file with status variable *;
 /*PROC DATASETS LIB = work NOLIST ; DELETE &SCoutfile ; run ;*/
 * Marc de Boer 2015 07 29 Removed this as it is not required and generates error if the library is
   included on the [SCoutfile] macro variable *;

 ** Create condense status variable **;
  * MdB 2014 05 08 Inculded STRIP to remove trailing blanks *;
 DATA CONDtemp1 ;
  Temp1 = COMPBL("&SCstatus") ;
  CondenseStatement = TRANWRD(STRIP(Temp1), " ", " || ") ;
  CALL SYMPUT("CondenseStatement", "CondenseStats = " || STRIP(CondenseStatement) ) ;
 run ;
 
 DATA CONDdataset1 (RENAME = (&SCstart = t_sd 
                              &SCend_d = t_ed) 
                    KEEP = &SClink &SCstart &SCend_d CondenseStats &SCstatus);
  SET &SCinfile ;

  ** MdB 2011 11 14 Included length statement to aviod appending errors **;  
  LENGTH &SCstart &SCend_d 8. ; 
  &CondenseStatement ;

  ** MdB 2012 04 11 Removed any spaces from statement *;
  CondenseStats = COMPRESS(CondenseStats) ; 
 run ;

 

     *** very large lapse period datasets are inefficient to run through SQL
          this section of the code splits the dataset to process them in batches **;

  ** identify number of records by group variables *;
 PROC MEANS DATA = CONDdataset1 NOPRINT NWAY MISSING ;
  CLASS &SClink ;
  OUTPUT OUT = CONDtemp1  (drop = _TYPE_ _FREQ_)
    N(t_sd) = Obs
    ;
 run ;

  ** determine number of iterations needed to run (in 10 million batches) *;
 DATA CONDtemp2 (DROP = BatchRunTotal obs) ;
  SET CONDtemp1 ;

  RETAIN BatchNo BatchRunTotal 1 ;
  BatchRunTotal = BatchRunTotal + obs ;
  IF BatchRunTotal gt 50000000 THEN DO ;
     BatchNo = BatchNo + 1 ;
     BatchRunTotal = 0 ;
  END ;
  CALL SYMPUT("TotalBatches", STRIP(BatchNo) ) ; 
 run ;

 
  ** add batch number to client infile *;
 %LET ByVars = &SClink ;
 PROC SORT DATA = CONDdataset1 ; BY &ByVars ; run ;
 PROC SORT DATA = CONDtemp2 ; BY &ByVars ; run ;

 DATA CONDdataset1 ;
  MERGE CONDdataset1 (IN=A)
        CONDtemp2 (IN=B) ;
  BY &ByVars ;

 run ;

 *MdB Oct2011 Remove any duplicate records that may exit *;
  PROC SORT DATA = CONDdataset1 NODUPREC ; BY &SClink t_sd t_ed CondenseStats ; run ;
 
 PROC DATASETS LIB = work NOLIST ; DELETE CONDnonoverlap3 ; run ;

 %DO BatchNo = 1 %TO &TotalBatches ;

 
 %PUT *** Start of batch run &BatchNo of &TotalBatches ***;


/*
 OPTIONS NOTES ;
 %LET BatchNo = 1 ;
*/


 %LET overlaps = 1 ;

 DATA CONDdataset2 ;
  SET CONDdataset1 (WHERE = (BatchNo = &BatchNo) ) ;
  count = _N_+ 10 ;
  CALL SYMPUT("no_overlaps", STRIP(count) ) ;
 run ;
 %PUT Intial number of spells in the dataset: %EVAL( &no_overlaps - 10 );

   %DO %WHILE(&overlaps = 1) ; ** Start of overlaps loop *;

** MdB 17Oct 2011 Included buffer to identify overlapping and adjoining records *;
  ** identify which records overalp *;
 PROC SQL ;
  CREATE TABLE CONDtemp1 AS
  SELECT  s1.&SClink
         ,s1.CondenseStats
         ,s1.SD1
         ,s1.ED1
         ,s2.SD2
         ,s2.ED2
  FROM  CONDdataset2 (RENAME = (t_sd = SD1 t_ed = ED1) ) AS s1
        JOIN 
        CONDdataset2 (RENAME = (t_sd = SD2 t_ed = ED2) ) AS s2  
  ON        s1.&SClink = s2.&SClink
        AND s1.CondenseStats = s2.CondenseStats
  WHERE      (    SD1-&SCbuffer le ED2 
              AND ED1+&SCbuffer ge SD2
             )
         AND NOT(    SD1 = SD2 
                 AND ED1 = ED2) ;
 ;
 quit ;

 %LET pre_overlaps = &no_overlaps ; ** store the number of previous overlapse to check against *;
 %LET no_overlaps = 0 ;
 %LET overlaps = 0 ;

 %LET ByVars = &SClink CondenseStats ; **  MdB 2012 01 09  included condense status to account for overlapping spells for different status *;
 PROC SORT DATA = CONDtemp1 NODUPKEY ; BY &ByVars ; run ;
 PROC SORT DATA = CONDdataset2 ; BY &ByVars ; run ;

 DATA CONDnonoverlap1 
      CONDdataset3 ;
  MERGE CONDdataset2 (IN=A)
        CONDtemp1 (IN=B KEEP = &ByVars) ;
  BY &ByVars ;
  IF _N_ = 1 THEN overlaps = 0 ;
  RETAIN overlaps ;

  IF A AND B THEN DO ;
     OUTPUT CONDdataset3 ;
     overlaps = overlaps + 1 ;
     CALL SYMPUT("no_overlaps", STRIP(overlaps) ) ;
  END ;
  ELSE OUTPUT CONDnonoverlap1 ; 
 run ;

 %PUT Previous Number of overlapping spells: &pre_overlaps Current number: &no_overlaps ;
 

  ** MdB 2011 11 14 Check that the previous count of over lapes is larger than the current **;
 DATA CONDtemp1 ;
  ** process with loop if there are overlapping spells and that the number of overlapping spells are less
     than previous iteraction to aviod loop getting stuck *;
  IF     &no_overlaps gt 0
     AND &no_overlaps lt &pre_overlaps THEN CALL SYMPUT("overlaps",STRIP(1) ) ; 
 run ;

 %PUT Proceed with overlaps: &overlaps ;
    
 
  ** prepare OK files for output *;
 DATA CONDnonoverlap2 (KEEP = &SClink &SCstart &SCend_d &SCstatus ) ;
  SET CONDnonoverlap1 (RENAME = (t_sd = &SCstart
                                t_ed = &SCend_d
                                )
                       );
 run ;

 PROC APPEND BASE = CONDnonoverlap3 
  DATA = CONDnonoverlap2 ;
 run ;

 ** MdB 2015 08 03 If there are overlapping spells left 
                   but they cannot be removed 
                   then add them to the output *;
 %IF &overlaps = 0 %THEN %DO ;
    %IF &no_overlaps gt 0 %THEN %DO ;
        ** prepare remaining overllapping spells for output *;
       DATA CONDdataset10 (KEEP = &SClink &SCstart &SCend_d &SCstatus ) ;
        SET CONDdataset3 (RENAME = (t_sd = &SCstart
                                      t_ed = &SCend_d
                                      )
                             );
       run ;

       PROC APPEND BASE = CONDnonoverlap3 
        DATA = CONDdataset10 ;
       run ;
    %END ;
 %END ;

  ** start of remove any overlaps loop *;
  %IF &overlaps = 1 %THEN %DO ;

 ** identify the sequence of spells based on start and status *;
 PROC SORT DATA = CONDdataset3 ; BY &SClink t_sd CondenseStats ; run ;

 DATA CONDdataset4  ;
  SET CONDdataset3 ;
  BY &SClink t_sd CondenseStats ;

  FORMAT prev_sd prev_ed ddmmyy10. ;
  RETAIN seq ;

  prev_st=LAG1(CondenseStats) ;
  prev_sd=LAG1(t_sd) ;
  prev_ed=LAG1(t_ed) ;

  IF first.&SClink THEN DO ; 
     seq=1 ; 
     prev_st =CondenseStats ; 
  END ;

  ** sequence count advances if 
     1, the status changes 
     2, there is a gap longer than the buffer period *;
  IF    prev_st ne CondenseStats 
     OR t_sd - &SCbuffer gt prev_ed THEN seq=seq+1;  * buffer determines the gap between consecutive spells that can be joined *;
  ** Marc de Boer 2014 02 24 Calculation included (1+buffer) this missed 
                             one interval long spells.
                             *;
 run;

  ** MdB 2011 11 14 remove any nested spells (assume the longer spell is the right one) *;
 DATA CONDdataset5 ;
  SET CONDdataset4 ;
  BY &SClink t_sd CondenseStats ;

  * MdB 2012 02 24 This check cannot be applied to the first spell in a set *; 
  IF NOT (first.&SClink) THEN DO ; 
     ** MdB 2012 04 17 Include check that status of the two spells are the same *;
     IF t_sd ge prev_sd AND t_ed le prev_ed AND prev_st = CondenseStats THEN DELETE ; 
  END ;
 run ;
 
  ** identify first and last end date for each sequence **;
 PROC MEANS DATA = CONDdataset5 NOPRINT NWAY MISSING ;
  CLASS &SClink seq CondenseStats Batchno &SCstatus ;
  OUTPUT OUT = CONDdataset2  (drop = _TYPE_ _FREQ_ seq)
    MIN(t_sd) = t_sd
    MAX(t_ed) =t_ed
    ;
 run ;


      %END ; ** end of remove any overlaps loop *;
   %END ; ** End of overlapse loop *;

 %END ; ** end of batch processing loop *;

  ** MdB 2014 02 24 Check if the end date overlaps with next spell start  **;
 %LET ByVars = &SClink DESCENDING &SCstart ;
 PROC SORT DATA = CONDnonoverlap3 ; BY &ByVars ; run ;

 DATA &SCoutfile (DROP = NxtSd) ;
  SET CONDnonoverlap3 ;
  BY &ByVars ;

  FORMAT NxtSd ddmmyy10. ;
  NxtSd = LAG1(&SCstart) ;
  IF NOT first.&SClink THEN DO ;
     ** adjust end dates that overlap next spell start date *;
     IF &SCend_d = NxtSd THEN &SCend_d = &SCend_d - 1 ;
  END ; 
 run ;
 
 PROC DATASETS LIBRARY = work NOLIST ; DELETE CONDdataset: CONDtemp: CONDnonoverlap: ; run ;


 %PUT *** End of Condense Macro IAP: /r00/msd/shared/ssi/macros/ ***;

 %MEND ;


************************************************************************************************************************************; 

 %MACRO SpellCompChk(RCCinfile = 
                  ,RCCLib = 
                  ,RCCCompressedFile = 
                  ,RCCPrimKey = 
                  ,RCCtestN = 
                  ,RCCEffFrm = 
                  ,RCCEffTo = 
                  ,RCCVars = 
                  ) ;


/* * Testing *;

DATA test1 ;
  SET JOB_VLicences1 (WHERE = (cvid =  98576 ) ) ; 
 run ;

 %LET RCCinfile = test1 ;
 %LET RCCLib = work ;
 %LET RCCCompressedFile = JOB_VLicences2 ;
 %LET RCCPrimKey = CVid ;
 %LET RCCtestN = 1 ;
 %LET RCCEffFrm = filedate ;
 %LET RCCEffTo = Repdate ;
 %LET RCCVars = CVS_DriverLicenceType
                             CVS_DriverLicenceTypeID
                             DriverLicenceExpiryDate ;
 */

  ** Detmine spell date format **;
 PROC CONTENTS DATA = &RCVLib..&RCCinfile. (KEEP = &RCCEffFrm. ) 
   OUT = RCVtemp0 (RENAME = (name = variable) )
   NOPRINT ;
 run ;

 DATA RCVtemp0 ;
  SET RCVtemp0 ;
  IF formatl gt 0 THEN CALL SYMPUTX("RCC_SpllFormat", CATT(format,formatl,'.') ) ;
  ELSE CALL SYMPUTX("RCC_SpllFormat", CATT(format,'.') ) ;
 run ;

 %PUT Spell format (based on infile spell start): &RCC_SpllFormat. ;

 ** Determine minimum and maximum repdate *;
 PROC MEANS DATA = &RCCLib..&RCCinfile. NOPRINT NWAY MISSING ;
  OUTPUT OUT = RCCtemp1 (DROP = _TYPE_ _FREQ_ )
   MIN(&RCCEffFrm) = MinEffFrm 
   MAX(&RCCEffTo) = MaxRCCEffTo 
   ;
 run ;

 DATA RCCtemp1 ;
  SET RCCtemp1 ;
  CALL SYMPUTX("MinEffFrm", MinEffFrm ) ;
  CALL SYMPUTX("MaxRCCEffTo", MaxRCCEffTo ) ;
 run ;

 %PUT First Replication date: &MinEffFrm. ;
 %PUT Last Replication date: &MaxRCCEffTo. ;

 ** Select sample of primary key ids for testing *;
 %LET ByVars = &RCCPrimKey. ;
 PROC SORT DATA = &RCCLib..&RCCinfile.
  OUT = RCCtestids1 (KEEP = &ByVars)
  NODUPKEY ;
  BY &ByVars. ;
 run ;

 ** check whether key is character *;
 PROC CONTENTS DATA = RCCtestids1
   OUT = RCCtemp1 (RENAME = (name = variable) )
   NOPRINT ;
 run ;

 DATA RCCtemp1 ;
  SET RCCtemp1 ;
  IF type = 2 THEN CALL SYMPUTX("RCC_PKchar", "$" ) ;
  ELSE CALL SYMPUTX("RCC_PKchar", "" ) ;
 run ;

 %PUT Primary key character format: &RCC_PKchar. ;

 DATA RCCtestids1  ;
  RETAIN &ByVars ;
  SET RCCtestids1;
  Select = NORMAL(0) ;
 run ;

 %LET ByVars = Select ;
 PROC SORT DATA = RCCtestids1 ; BY &ByVars ; run ;

 DATA RCCtestids1 ;
  SET RCCtestids1 (DROP = select OBS = &RCCtestN.);
 run ;

 %USE_FMT(RCCtestids1, &RCCPrimKey., RCC_tst_ids) ;

 ** Generate ranom list of dates to check *;
 DATA RCCtestidsdates1 (KEEP =  &RCCPrimKey. CheckDate) ;
  SET RCCtestids1  ;
  FORMAT CheckDate &RCC_SpllFormat. ;
  PeriodDur =&MaxRCCEffTo &MinEffFrm ;
  DO i = 1 TO 100 ;
     DateSelect = INT(UNIFORM(0) * PeriodDur) ;
     CheckDate = &MinEffFrm +  DateSelect ;
     OUTPUT ;
  END ;
 run ;

 ** remove any duplicate random check dates *;
 %LET ByVars = &RCCPrimKey. CheckDate;
 PROC SORT DATA = RCCtestidsdates1 NODUPKEY ; BY &ByVars ; run ;

 ** Create a string of the check variables **;
 DATA RCCtemp2 ;
  Temp1 = COMPBL("&RCCVars.") ;
  CondenseStatement = TRANWRD(STRIP(Temp1), " ", ",'~', ") ;
  CALL SYMPUT("CondenseStatement", "CheckVars = COMPRESS(CATT(" || STRIP(CondenseStatement)||"),'cs')" ) ;
 run ;

 ** Subset input and output tables to test ids **;
 DATA RCC_indataset1 (DROP = &RCCVars. ) ;
  SET &RCCLib..&RCCinfile. (KEEP =&RCCPrimKey. &RCCVars. &RCCEffFrm. &RCCEffTo.
                             WHERE = (PUT(&RCCPrimKey., &RCC_PKchar.RCC_tst_ids.) = "Y") 
                             ) ;

  &CondenseStatement ;
  CheckVarsMD5 = PUT(MD5(COMPRESS(CheckVars,' ','s')),hex32.) ;
 run ;

 DATA RCC_outdataset1 (DROP = &RCCVars. ) ;
  SET &RCCLib..&RCCCompressedFile. (KEEP =&RCCPrimKey. &RCCVars.  &RCCEffFrm. &RCCEffTo.
                                     WHERE = (PUT(&RCCPrimKey., &RCC_PKchar.RCC_tst_ids.) = "Y") 
                                    ) ;

  &CondenseStatement ;
  CheckVarsMD5 = PUT(MD5(COMPRESS(CheckVars,' ','s')),hex32.) ;

 run ;

 ** Select infile records at selected check dates *;
 PROC SQL ;
  CREATE TABLE RCC_indataset2  AS
  SELECT a.*
        ,b.&RCCEffFrm. AS ValidFrom_IN
        ,b.&RCCEffTo.  AS ValidTo_IN
        ,b.CheckVars
        ,b.CheckVarsMD5
  FROM RCCtestidsdates1 AS a
       LEFT JOIN 
       RCC_indataset1 AS b
  ON       a.&RCCPrimKey. = b.&RCCPrimKey.  
       AND a.CheckDate BETWEEN b.&RCCEffFrm. AND b.&RCCEffTo.
 ;
 quit ;

 ** Select outfile records at selected check dates *;
 PROC SQL ;
  CREATE TABLE RCC_outdataset2  AS
  SELECT a.*
        ,b.&RCCEffFrm. AS ValidFrom_OUT
        ,b.&RCCEffTo.   AS ValidTo_OUT
        ,b.CheckVars
        ,b.CheckVarsMD5
  FROM RCCtestidsdates1 AS a
       LEFT JOIN 
       RCC_outdataset1 AS b
  ON       a.&RCCPrimKey. = b.&RCCPrimKey.  
       AND a.CheckDate BETWEEN  b.&RCCEffFrm. AND b.&RCCEffTo.
 ;
 quit ;

 %LET ByVars = &RCCPrimKey. CheckDate CheckVarsMD5 ;
 PROC SORT DATA = RCC_indataset2 ; BY &ByVars ; run ;
 PROC SORT DATA = RCC_outdataset2; BY &ByVars ; run ;

 DATA RCC_Reconcile1 (DROP = CheckVarsMD5)  ;
  RETAIN &ByVars ;
  MERGE RCC_indataset2 (IN=A)
        RCC_outdataset2 (IN=B) ;
  BY &ByVars ;
  IF A OR B ;

  Match = "Not OK" ;
  IF A AND B THEN Match = "OK" ; 
 run ;

 %LET ClassVars = Match ;
 PROC MEANS DATA = RCC_Reconcile1 NOPRINT NWAY MISSING ;
  CLASS &ClassVars.;
  OUTPUT OUT = RCC_ReconcileSum (SORTEDBY = &ClassVars.
                    DROP = _TYPE_ _FREQ_ )
   N(CheckDate) = Observations  
    ;
 run ;

 PROC PRINT DATA = RCC_ReconcileSum (obs=20) ; run ;
 PROC PRINT DATA = RCC_Reconcile1 (obs=20 WHERE = (Match = "Not OK" ) ) ; run ;

 PROC DATASETS LIB = work NOLIST ;
  DELETE RCC_indataset: RCC_outdataset: RCCtemp: RCCtestidsdates: RCCtestids: ;
 run ;
 %MEND ;

************************************************************************************************************************************; 

 /*  
    TITLE:  Spell History Inverter Macro

    PURPOSE:  Macro takes an existing spell history and generates a file with the additional 
              records for any perdiods between the input spell history.  
              For example, the macro can be used to generate an off main benefit spell 
              dataset from a dataset containing benefit spells.  

    AUTHOR: Marc de Boer, OWPA RE, CSRE, MSD

    DATE: March 2011

     MODIFCATIONS
     BY             WHEN      WHAT
     Marc de Boer   Oct2013   Removed the nonotes options
     
*/

/*

   ***                               ***;
   *** Spelll History Inverter Macro ***;
   ***                               ***;

 %SpellHistoryInverter(  SHIinfile =
                       , SHIoutfile = 
                       , SHIlink = 
                       , SHIspellSD = 
                       , SHIspellED = 
                      ) ;

 *
 INPUTS
 SHIinfile: spell dataset to invert
 SHIoutfile: dataset with orginal and inverted spells
 SHIlink: unqiue indetifier (eg snz_uid)
 SHIspellSD: spell start date
 SHIspellED: spell end date
*;

*/


   ***       ***;
   *** Macro ***;
   ***       ***;


   

 %MACRO SpellHistoryInverter(  SHIinfile =
                             , SHIoutfile = 
                             , SHIlink = 
                             , SHIspellSD = 
                             , SHIspellED = 
                            ) ;

 
 %PUT *** Start of SpellHistoryInverter Macro                                                       ***;

/*
  * for testing *;
 %LET SHIinfile = SRT_Enrol2 ;
 %LET SHIoutfile = test ;
 %LET SHIlink = enrolment_id ;
 %LET SHIspellSD = SRTenrl_VldSrt ;
 %LET SHIspellED = SRTenrl_VldEnd ;
*/

 ** MdB 2014 05 07 Need to allow for datetime formates **;
 ** work out format for dates **;
 PROC CONTENTS DATA = &SHIinfile (KEEP =&SHIspellSD ) 
   NOPRINT
   OUT = SHItemp1  ;
 run ;

 DATA SHItemp1 ;
  SET SHItemp1 ;
  CALL SYMPUTX("DTformat", STRIP(format)||STRIP(formatl)||".") ;
 run ;

  * identify the largest and smallest dates to define the bounds of the spell history file *;
 PROC MEANS DATA = &SHIinfile   NOPRINT NWAY MISSING ;
  OUTPUT OUT = SHItemp1 (COMPRESS = NO DROP = _TYPE_ _FREQ_)
    MIN(&SHIspellSD) = firstSD
    MAX(&SHIspellED) = lastED 
  ;
 run ;

 DATA SHItemp1 ;
  SET SHItemp1 ;
  *CALL SYMPUT("firstSD", PUT(firstSD, date9.) ) ;
  *CALL SYMPUT("lastED", PUT(lastED, date9.) ) ;
  CALL SYMPUT("firstSD", firstSD ) ;
  CALL SYMPUT("lastED", lastED ) ;

 run ;
 
 PROC SORT DATA = &SHIinfile ; BY &SHIlink &SHIspellSD ; run ;

 DATA SHItemp2 (KEEP = &SHIlink &SHIspellSD &SHIspellED OrginalSpell PreviousEd)  ;
  SET &SHIinfile  ;
  BY &SHIlink ;

  FORMAT &SHIspellSD &SHIspellED PreviousEd &DTformat ;
  LENGTH OrginalSpell $1. ;
  OrginalSpell = "Y" ;
  PreviousEd = LAG1(&SHIspellED) ;

  ** MdB 2011 10 Some negtaive spells fail becuase they had another clients pervious end ***;
  IF first.&SHIlink THEN PreviousEd = . ; 
 run ;

 DATA &SHIoutfile (DROP = &SHIspellSD 
                          &SHIspellED 
                           PreviousEd  
                   RENAME = (Nsd = &SHIspellSD
                             Ned = &SHIspellED
                             )

                            );
  LENGTH  Nsd Ned  8. 
          OrginalSpell $1. ;
  SET SHItemp2  ;
  BY &SHIlink &SHIspellSD ;

  FORMAT Nsd Ned &DTformat ;
  OrginalSpell = "N" ;

  Ned = &SHIspellSD - 1 ;
  Nsd = PreviousEd + 1 ;
  IF first.&SHIlink THEN DO ;
      Nsd = &firstSD ;
      Ned = &SHIspellSD - 1 ;
      IF &SHIspellSD gt &firstSD THEN OUTPUT ;
  END ; 
  ELSE DO ;
      ** MdB 2013 06 12 Remove any inverted spells *;
      IF Nsd le Ned THEN OUTPUT ;
  END;
  ** Steven - The next 5 lines of code were inside the ELSE part above. Bring
  ** them outside so that a final additional spell is also created for clients
  ** that had only one original spell ;
  IF last.&SHIlink AND &SHIspellED lt  &lastED  THEN DO ;
      Nsd = &SHIspellED+1 ;
      Ned =  &lastED  ;
      ** MdB 2013 06 12 Remove any inverted spells *;
      IF Nsd le Ned THEN OUTPUT ;
  END ;
 run ; 

  * combine the two histories together *;
 PROC APPEND BASE = &SHIoutfile  DATA = SHItemp2 (DROP = PreviousEd) ; run ;
 PROC SORT DATA = &SHIoutfile ; BY &SHIlink &SHIspellSD ; run ;
 
 PROC DATASETS LIB = work NOLIST ; DELETE SHItemp: ; run ;

 %PUT *** End of SpellHistoryInverter Macro                                                         ***;


 %MEND SpellHistoryInverter ;
 
************************************************************************************************************************************; 

/*  
    TITLE: SpellOverlay

    PURPOSE: The purpose of this Macro is to combine historical records from two sources
           to provide a single continous history.  
             The primary dataset is the one where records will overlay the records of the secondary
             datset.  
             In other words where a person is subject to the both states similtatounsly 
             the primary state will be the one that is recorded on the output file
    

    MACROS: SpellCondense
       SpellHistoryInverter
      

    AUTHOR: Marc de Boer, OWPA RE, CSRE, MSD

    DATE: March 2011

     MODIFCATIONS
     BY             WHEN      WHAT
     Marc de Boer   March2012 The merge hist was having a problem with status field made of
                              numerials. Corrected code to handel this.

     Marc de Boer   Oct2013   Removed the nonotes options
  
*/


/*

   ***                     ***;
   *** Spell overlay macro ***;
   ***                     ***;


      %SpellOverlay( SMlink
                    ,SMprimary
                    ,SMp_sd
                    ,SMp_ed
                    ,SMpstatus
                    ,SMsecond
                    ,SMs_sd 
                    ,SMs_ed
                    ,SMsstatus
                    ,SMoutfile
                    ) ;

*
INPUTS: 
      SMlink: unqiue identifier (eg snz_uid)
      SMprimary: name of SAS dataset with the primary spells you want to overlay 
      SMp_sd: variable name for the start date of primary spells
      SMp_ed: variable name for the end date of primary spells
      SMpstatus: varible that defines the status of the spell 
                 (consecutive spells of the same status are combined)
      SMsecond: name of SAS dataset with the spells that will be overlayed by
                the spells in the primary dataset
      SMs_sd SMs_ed: variables for the secondary spell start and end dates
      SMsstatus: variable the defines the status of each secondary spell

OUTPUTS:
      SMoutfile: name of the file the overlayed history will be written to.
*;
*/




   ***       ***;
   *** Macro ***; 
   ***       ***;



%MACRO SpellOverlay( SMlink
                  ,SMprimary
                  ,SMp_sd
                  ,SMp_ed
                  ,SMpstatus
                  ,SMsecond
                  ,SMs_sd 
                  ,SMs_ed
                  ,SMsstatus
                  ,SMoutfile) ;




 %PUT *** SpellOverlay macro starting                                                                 ***;
 

/*
 

 %LET SASprogrammes = T:\CORE\Projects\487 Sustainable Employment Annual Report\2012\SAS ;
 %INCLUDE "&SASprogrammes\000 Programme Parameters.sas" ;

rsubmit ;
 %LET ReportStartDate = jan2010 ;
 %LET ReportEndDate = Jan2013 ;
 %SYSRPUT ReportStartDate = &ReportStartDate ;
 %SYSRPUT ReportEndDate = &ReportEndDate ;
  %PUT &SEex_dt ;
endrsubmit ;

rsubmit ;
 %EmpProgExt( EPXsd = 01&ReportStartDate
             ,EPXed = 01&ReportEndDate
             ,EPXOutfile = EmpPardataset1
            ) ;
endrsubmit ;

rsubmit ;
  DATA ParSeplls ;
   SET EmpPardataset1 (WHERE = (swn ne .)
                      KEEP = swn participation_sd participation_ed programme_code) ;
   Programme = "EA" ;
 run ; 
endrsubmit ;

rsubmit; ** extract primary spells with children ***;
 %USE_FMT(ParSeplls, swn, usefmt) ;

 data primswns ;

  set BDD.spel&bddversion (WHERE = (PUT(swn, usefmt.) = "Y") 
                           KEEP = swn spell: servf
                          ) ;
 if spellto=. then spellto="&BDDed"d ;
 Primary = "Primary" ;
 run;
endrsubmit;

rsubmit ;
 PROC PRINT DATA = &syslast (obs=20) ; run ;
endrsubmit ;

 * Diagnostics *;
%LET SMlink=FamNo_spell ;
%LET SMprimary=ActiveAdltSpell ;
%LET SMp_sd=FamSD ;
%LET SMp_ed=FamED ;
%LET SMpstatus=FamSpell ;
%LET SMsecond=ActiveChildSpel1 ; 
%LET SMs_sd=ChldSD ; 
%LET SMs_ed=ChldED ;
%LET SMsstatus=chswnT ;
%LET SMoutfile=ActiveChildSpel2 ;
*/


 ** Tidy up the two history files (eg remove overallping spells with the same status) *;
 %SpellCondense( SCinfile=&SMprimary
                ,SCoutfile=SMprimary1
                ,SClink=&SMlink 
                ,SCstart=&SMp_sd
                ,SCend_d=&SMp_ed
                ,SCstatus=&SMpstatus
                ,SCbuffer=1
                ) ;

 %SpellCondense( SCinfile=&SMsecond
                ,SCoutfile=SMsecond1
                ,SClink=&SMlink
                ,SCstart=&SMs_sd
                ,SCend_d=&SMs_ed
                ,SCstatus=&SMsstatus
                ,SCbuffer=1
               ) ;
 

 ** Determine length of p and s status variable **;
 PROC CONTENTS DATA = SMprimary1 (KEEP = &SMpstatus) ;
  ODS OUTPUT variables = temp1 ;
 run ;

 PROC CONTENTS DATA = SMsecond1 (KEEP = &SMsstatus) ;
  ODS OUTPUT variables = temp2 ;
 run ;

 DATA temp3 ;
  SET temp1 
      temp2 ;

  RETAIN MaxLen 0 ;
  IF _N_ = 1 THEN MaxLen = 0 ;
  MaxLen = MAX(MaxLen, Len) ;
  CALL SYMPUTX("StatusLength", "$"||STRIP(MaxLen)||".") ;
 run ;


 PROC SORT DATA = SMprimary1 ; BY &SMlink &SMp_sd ; run ; 

 DATA SMprimary2 (DROP = Min_sd Max_ed) ;
  LENGTH  pstatus &StatusLength ;
  SET  SMprimary1 (KEEP = &SMlink &SMp_sd &SMp_ed &SMpstatus
                   RENAME = (&SMp_sd = p_sd 
                             &SMp_ed = p_ed 
                             &SMpstatus = pstatus)
                   WHERE = (    p_sd ne . 
                            OR  p_ed ne . 
                            AND pstatus ne "" )
               ) ;
  BY &SMlink p_sd ;

  FORMAT p_sd p_ed ddmmyy10. ;
  p_sd = INT(p_sd) ;
  p_ed = INT(p_ed) ;
  duration = (p_ed - p_sd) + 1 ; 
  IF duration lt 1 THEN DELETE ;

  RETAIN Min_sd Max_ed ;
  IF _N_ =1 THEN DO ;
     Min_sd = p_sd ;
     Max_ed  = p_ed ;
  END ;
  Min_sd = MIN(p_sd, Min_sd);
  Max_ed  = MAX(p_ed, Max_ed) ;
  CALL SYMPUTX("Min_psd", PUT(Min_sd, date9.) ) ;
  CALL SYMPUTX("Max_ped", PUT(Max_ed, date9.) ) ;
 run ;

 DATA SMsecond2 (DROP = Min_sd Max_ed) ;
  LENGTH sstatus &StatusLength  ;
  SET SMsecond1 (KEEP = &SMlink &SMs_sd &SMs_ed &SMsstatus
                 RENAME = (&SMs_sd = s_sd 
                           &SMs_ed = s_ed 
                           &SMsstatus = sstatus)
                 WHERE = (    s_sd ne . 
                          OR  s_ed ne . 
                          AND sstatus ne "") 
                  ) ;

  FORMAT s_sd s_ed ddmmyy10. ;
  s_sd = INT(s_sd) ;
  s_ed = INT(s_ed) ;
  duration = (s_ed - s_sd) + 1 ; 
  IF duration lt 1 THEN DELETE ;

  RETAIN Min_sd Max_ed ;
  IF _N_ =1 THEN DO ;
     Min_sd = s_sd ;
     Max_ed  = s_ed ;
  END ;
  Min_sd = MIN(s_sd, Min_sd);
  Max_ed  = MAX(s_ed, Max_ed) ;
  CALL SYMPUTX("Min_ssd", PUT(Min_sd, date9.) ) ;
  CALL SYMPUTX("Max_sed", PUT(Max_ed, date9.) ) ;
 run ;

 
  * remove instances of multiple spells of primary of secondary starting on the same day, 
    the one with the longer duration is favoured *;
 /*

 PROC PRINT DATA = &syslast (obs=20 WHERE = (&SMlink = "317249035_1") ) ; run ;
 */
 PROC SORT DATA = SMprimary2 ; BY &SMlink p_sd duration ; run ;

 DATA SMprimary3 ;
  SET SMprimary2 (DROP = duration);
  BY  &SMlink p_sd ;
  IF last.p_sd THEN OUTPUT ;
 run ;

 PROC SORT DATA = SMsecond2 ; BY &SMlink s_sd duration ; run ;

 DATA SMsecond3 ;
  SET SMsecond2 (DROP = duration);
  BY  &SMlink s_sd ;
  IF last.s_sd THEN OUTPUT ;
 run ;
 

  * assign null history fields for primary table *;

 %SpellHistoryInverter(  SHIinfile = SMprimary3 
                       , SHIoutfile = SMprimary4 
                       , SHIlink = &SMlink 
                       , SHIspellSD = p_sd 
                       , SHIspellED = p_ed 
                       ) ;


 DATA SMprimary5 (DROP = OrginalSpell) ;
  LENGTH  pstatus &StatusLength  ;
  SET SMprimary4 (WHERE = (OrginalSpell = "N") ) ;
  pstatus = "" ;
 run ;

 ** add orginal spells back in **;
 PROC APPEND BASE = SMprimary5 DATA = SMprimary3 ; run ;

 ** Add empity periods to match the secondary spells **;
  %LET ByVars = &SMlink p_sd ;
 PROC SORT DATA = SMprimary5 ; BY &ByVars ; run ;

 DATA Outfill1 (DROP =  p_sd p_ed
                RENAME = (new_p_sd = p_sd
                         new_p_ed = p_ed
                         )
               ) ;
  SET SMprimary5 ; 
  BY &ByVars ;

  FORMAT new_p_sd new_p_ed ddmmyy10. ; 

  IF first.&SMlink THEN DO ; 
    ** first spell starts before the very first start date **;
    IF p_sd gt MIN("&Min_ssd"d, "&Min_psd"d) THEN DO ;
          new_p_ed = p_sd - 1 ;
          new_p_sd = MIN("&Min_ssd"d, "&Min_psd"d) ;
          pstatus = "" ;
          IF new_p_ed ge new_p_sd THEN OUTPUT ;
    END ;
  END ;

  IF last.&SMlink THEN DO ;
      ** first last spell ends before the very last end date **;
      IF p_sd lt MAX("&Max_sed"d, "&Max_ped"d) THEN DO ;
          new_p_sd = p_ed + 1 ;
          new_p_ed = MAX("&Max_sed"d, "&Max_ped"d) ;
          pstatus = "" ;
          IF new_p_ed ge new_p_sd THEN OUTPUT ;
      END ;
  END ;
 run ;

 PROC APPEND BASE = SMprimary5 DATA = Outfill1 ; run ;

 ** Check it all works **;
 %LET ByVars = &SMlink p_sd ;
 PROC SORT DATA = SMprimary5 ; BY &ByVars ; run ;

 DATA PrimaryDuration1 (KEEP = &SMlink SumDur) ;
  SET SMprimary5 ;
  BY &ByVars ;

  RETAIN SumDur 0 ;
  IF first. &SMlink THEN SumDur = 0 ;
  dur = (p_ed - p_sd) + 1 ;
  SumDur = SumDur + dur ;
  IF last. &SMlink THEN OUTPUT ;
 run ;


 * assign following secondary start date *;
 PROC SORT DATA = SMsecond3 ; BY &SMlink DESCENDING s_sd ;

 DATA SMsecond4 ;
  SET SMsecond3 ;
  BY  &SMlink ;

  FORMAT nxt_ssd ddmmyy10. ;
  nxt_ssd = LAG1(s_sd) ;
  IF first.&SMlink THEN nxt_ssd = MAX("&Max_sed"d, "&Max_ped"d+1)  ;
 run;

  * assign previous secondary end date  *;
 PROC SORT DATA = SMsecond4 ; BY &SMlink s_sd ;

 DATA SMsecond5 (DROP = sstatus) ;
  RETAIN &SMlink sstatus pre_sed s_sd s_ed nxt_ssd ;
  SET     SMsecond4 ;
  BY      &SMlink ;

  FORMAT pre_sed ddmmyy10. ;
  pre_sed = LAG1(s_ed) ;
  IF first.&SMlink THEN pre_sed = MIN("&Min_ssd"d, "&Min_psd"d-1) ;
 run;

  * Interleave secondary history with primary history *;
 PROC SQL ;
  CREATE TABLE SMprimary6 AS
        SELECT   p.&SMlink
                ,p.pstatus
                ,p_sd
                ,p_ed
                ,s.pre_sed
                ,s.s_sd
                ,s.s_ed
                ,s.nxt_ssd
         FROM    SMprimary5 AS p 
                 LEFT JOIN 
                 SMsecond5 AS s
           ON        p.&SMlink = s.&SMlink
                 AND p_sd le s_ed 
                 AND p_ed ge s_sd ;
 quit ;

 ** Adjust primary spells with overlapping secondary spells ***;

 PROC SORT DATA = SMprimary6 ; BY &SMlink p_sd s_sd ; run ;

 DATA SMprimary7 ;
  SET SMprimary6 ;

  FORMAT adj_p_sd adj_p_ed ddmmyy10. ;

  ** No overlapping secondary spells ***;
  IF s_sd = . THEN DO ;
     adj_p_sd = p_sd ;
     adj_p_ed = p_ed ;
     OUTPUT ;
  END ;

  ** Nested secondary spell ***;
  IF     s_sd ge p_sd 
     AND s_ed le p_ed THEN DO ;

     ** single nested spell **;
     IF     pre_Sed lt p_sd
        AND nxt_ssd gt p_ed THEN DO ;
          adj_p_sd = p_sd ;
          adj_p_ed = s_sd - 1 ;
          OUTPUT ;
          adj_p_sd = s_ed + 1 ;
          adj_p_ed = p_ed  ;
          OUTPUT ;
     END ;

     ** multiple nested spells ***;
     ** NOTE this will output duplicate spells **;
     ELSE DO ;
          adj_p_sd = MAX(p_sd, pre_sed+1) ; ** start of p spell or end of previous secondary spell **;
          adj_p_ed = s_sd - 1 ; ** day before start of sec spell **;
          OUTPUT ;
          adj_p_sd = s_ed + 1 ; ** day after sec spell ends ***;
          adj_p_ed = MIN(p_ed, nxt_ssd-1)  ; ** end of p spell or start of next sec spell **;
          OUTPUT ;
     END ; 
  END ;

  ** secondary spell overlaps primary spell start date **;
  IF s_sd lt p_sd le s_ed THEN DO ;
     adj_p_sd = s_ed + 1 ; ** start of p spell at end of secondary spell **;
     adj_p_ed = MIN(p_ed, nxt_ssd-1)  ; ** end of p spell or start of next sec spell **;
     OUTPUT ;
  END ;

  ** secondary spell overlaps primary spell end date **;
  IF s_sd le p_ed lt s_ed THEN DO ;
     adj_p_sd = MAX(p_sd, pre_sed+1) ; ** start of p spell or end of previous secondary spell **;
     adj_p_ed = s_sd - 1 ; ** day before start of sec spell **;
     OUTPUT ;
  END ;

  ** secondayr spell enriterly overllaps primary spell **;
  IF     s_sd le p_sd
     AND s_ed ge p_ed THEN DO ;
      adj_p_sd = p_sd ;
      adj_p_ed = p_sd - 1;  ** Turn primary spell into a negative one to be removed in subsequent step **;
      OUTPUT ;
  END ;

  IF adj_p_sd = . THEN OUTPUT ; ** Check: should be none it it all works **;
 run ;

 ** Remove redundent primary spells (where p_sd gt p_ed) *;
 DATA SMprimary8 (KEEP = &SMlink pstatus adj_p_sd adj_p_ed
                  RENAME = (adj_p_sd = sd
                            adj_p_ed = ed
                            pstatus = status
                            ) 
                  ) ;
  SET SMprimary7 (WHERE = (adj_p_sd le adj_p_ed) ) ;
 run ;
 
 ** remove duplicate spells created for multi nested spells **;
 %LET ByVars = &SMlink sd ;
 PROC SORT DATA = SMprimary8 NODUPKEY ; BY &ByVars ; run ;

 ** Convert secondary records for appendeing **; 
 DATA SMsecond4 ;
   SET SMsecond3 (KEEP = &SMlink s_sd s_ed sstatus
                   RENAME = (s_sd = sd 
                             s_ed = ed 
                             sstatus=status
                             )
                  ) ;
 run;

 DATA SMfinalSpells2 ;
  SET SMprimary8
      SMsecond4 ;
  status = STRIP(status) ;
 run ;

 PROC SORT DATA = SMfinalSpells2 ; BY &SMlink sd ; run ;

 DATA &SMoutfile (SORTEDBY = &SMlink sd) ; * some periods overlapped and some duplicate records exist*;
        SET     SMfinalSpells2 ;
        BY      &SMlink sd ;

        IF sd gt ed THEN DELETE ;
        IF first.sd THEN OUTPUT ;
 run;
 

  ** Check it all works **;
 %LET ByVars = &SMlink sd ;
 PROC SORT DATA = &SMoutfile ; BY &ByVars ; run ;

 DATA MergedDuration (KEEP = &SMlink SumMergedDur) ;
  SET &SMoutfile ;
  BY &ByVars ;

  RETAIN SumMergedDur 0 ;
  IF first.&SMlink THEN SumMergedDur = 0 ;
  dur = (ed - sd) + 1 ;
  SumMergedDur = SumMergedDur + dur ;
  IF last.&SMlink THEN OUTPUT ;
 run ;

 %LET ByVars =&SMlink ;
 PROC SORT DATA = MergedDuration ; BY &ByVars ; run ;
 PROC SORT DATA = PrimaryDuration1; BY &ByVars ; run ;

 DATA ErrorMergedSpells  (SORTEDBY = &ByVars) ;
  MERGE PrimaryDuration1(IN=A)
        MergedDuration (IN=B) ;
  BY &ByVars ;
  IF A ;

  NOTE = "If durations do not closely match the merge hist as not worked" ;

  IF A AND NOT B THEN OUTPUT ;
  Diff = ABS(SumMergedDur-SumDur) ;
  IF Diff gt 1 THEN OUTPUT ;
 run ;

 PROC SORT DATA = ErrorMergedSpells ; BY DESCENDING Diff ; run ;
 PROC PRINT DATA = &syslast (obs=20) ; run ;

 PROC DATASETS LIBRARY = work NOLIST ; DELETE SMprimary: SMsecond: SMfinalSpells:  SMMergedSpells: ; run ;
 
 
 %PUT *** SpellOverlay macro ending                                          ***;

%MEND ;
 




