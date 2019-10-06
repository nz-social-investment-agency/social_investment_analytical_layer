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
Mar 2019  Pete Holmes		Changes for SAS-GRID environment - macro names need to be all lower case for some reason
     
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


   

 %MACRO spellhistoryinverter(  SHIinfile =
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