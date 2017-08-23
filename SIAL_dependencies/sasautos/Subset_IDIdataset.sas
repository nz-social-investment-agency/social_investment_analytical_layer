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