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
	Mar 2019  Pete Holmes		Changes for SAS-GRID environment - macro names need to be all lower case for some reason
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

  %MACRO bnt_bennmtype( BNTserv = 
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