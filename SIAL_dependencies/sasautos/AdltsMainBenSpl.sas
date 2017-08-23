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

 /* Changed 29-Jun-2017, Vinay Benny- Removed the drop for columns 'msd_spel_servf_code' and 'msd_spel_add_servf_code'*/
 DROP  msd_spel_spell_end_date msd_spel_spell_start_date ;

 run ;

 ** Merge main benefit spells and partner spells *;
/* Changed 29-Jun-2017, Vinay Benny- Added the columns 'msd_spel_servf_code' and 'msd_spel_add_servf_code' to the Spell variables*/
 %CombineSpell( CSinfile1 =  MSD_MainBen2
               ,CSSpell1_Vars = snz_uid
                                snz_swn_nbr
                                msd_spel_spell_nbr
                                BenefitType
                                BenefitName
								msd_spel_servf_code 
								msd_spel_add_servf_code
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
 * Check the spell merge worked **;
 * checked 99,417,860 observations no errors

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
 *;
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
