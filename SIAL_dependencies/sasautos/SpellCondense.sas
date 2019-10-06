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
	Mar 2019  Pete Holmes		Changes for SAS-GRID environment - macro names need to be all lower case for some reason

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

 %MACRO spellcondense( SCinfile
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
