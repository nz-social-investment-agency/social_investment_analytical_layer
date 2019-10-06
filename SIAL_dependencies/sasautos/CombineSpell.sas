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
	 Mar 2019  Pete Holmes		Changes for SAS-GRID environment - macro names need to be all lower case for some reason
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

 %MACRO combinespell( CSinfile1 
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

 %LET CSinfile1 = MSD_MainBen2 ;
 %LET CSSpell1_Vars = snz_uid
                                
                                msd_spel_spell_nbr
                                BenefitType
                                BenefitName
								msd_spel_servf_code 
								msd_spel_add_servf_code ;
 %LET CSSpell1_SD = EntitlementSD ;
 %LET CSSpell1_ED = EntitlementED ;
 %LET CSinfile2 = MSD_PartnerBen2 ;
 %LET CSSpell2_Vars = partner_snz_uid
                              partner_snz_swn_nbr ;
 %LET CSSpell2_SD = PartnerSD ;
 %LET CSSpell2_ED = PartnerED ;
 %LET CSoutfile = MSD_MainBen3;
 %LET CSidvar = snz_swn_nbr ;
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