libname data ODBC dsn=idi_clean_archive_srvprd schema=data;

/*DoL*/
libname dol ODBC dsn=idi_clean_archive_srvprd schema=dol_clean;

/*HLFS*/
libname hlfs ODBC dsn=idi_clean_archive_srvprd schema=hlfs_clean;

/*LEED*/
libname leed ODBC dsn=idi_clean_archive_srvprd schema=from_leed_clean;

/*MoE*/
libname moe ODBC dsn=idi_clean_archive_srvprd schema=moe_clean;

/*MSD*/
libname msd_leed ODBC dsn=idi_clean_archive_srvprd schema=from_leed_clean;

libname msd ODBC dsn=idi_clean_archive_srvprd schema=msd_clean;

/*SLA*/
libname sla ODBC dsn=idi_clean_archive_srvprd schema=sla_clean;

/*COR*/
libname cor ODBC dsn=idi_clean_archive_srvprd schema=cor_clean;

/*MOJ*/
libname moj ODBC dsn=idi_clean_archive_srvprd schema=moj_clean;

/*ACC*/
libname acc ODBC dsn=idi_clean_archive_srvprd schema=acc_clean;

/*CUS*/
libname cus ODBC dsn=idi_clean_archive_srvprd schema=cus_clean;

/*LISNZ*/
libname lisnz ODBC dsn=idi_clean_archive_srvprd schema=lisnz_clean;

/*MS*/
libname ms ODBC dsn=idi_clean_archive_srvprd schema=ms_clean;

/*SOFIE*/
libname sofie ODBC dsn=idi_clean_archive_srvprd schema=sofie_clean;

/*DBH*/
libname dbh ODBC dsn=idi_clean_archive_srvprd schema=dbh_clean;

/*IR_restrict*/
libname ir ODBC dsn=idi_clean_archive_srvprd schema=ir_clean;

/*WFF*/
libname wff ODBC dsn=idi_clean_archive_srvprd schema=wff_clean;

/*BR*/
libname br ODBC dsn=idi_clean_archive_srvprd schema=br_clean;

/*CYF*/
libname cyf ODBC dsn=idi_clean_archive_srvprd schema=cyf_clean;

/*DIA*/
libname dia ODBC dsn=idi_clean_archive_srvprd schema=dia_clean;

/*POL*/
libname pol ODBC dsn=idi_clean_archive_srvprd schema=pol_clean;

/*MOH*/
libname moh ODBC dsn=idi_clean_archive_srvprd schema=moh_clean;

/*CEN*/
libname cen ODBC dsn=idi_clean_archive_srvprd schema=cen_clean;

/*HNZ*/
libname hnz ODBC dsn= idi_clean_archive_srvprd schema=hnz_clean;

libname hnz_s ODBC dsn= idi_sandpit_srvprd schema=clean_read_hnz;

/*YST*/
libname yst ODBC dsn= idi_clean_archive_srvprd schema=yst_clean;

/*HES*/
libname hes ODBC dsn= idi_clean_archive_srvprd schema=hes_clean;

libname class ODBC dsn=idi_metadata_srvprd schema=clean_read_CLASSIFICATIONS;
/*libname idi_meta ODBC dsn=idi_clean_archive_srvprd  schema=metadata;*/

libname sandwff ODBC dsn=idi_sandpit_srvprd schema="clean_read_wff";
libname sandDIA ODBC dsn=idi_sandpit_srvprd schema="clean_read_DIA";
libname sandmoh1 ODBC dsn=idi_sandpit_srvprd schema="clean_read_MOH_b4sc";
libname sandmoh2 ODBC dsn=idi_sandpit_srvprd schema="clean_read_MOH_nir";
libname sandmoh3 ODBC dsn=idi_sandpit_srvprd schema="clean_read_MOH_PHARMACEUTICAL";
libname sandmoh4 ODBC dsn=idi_sandpit_srvprd schema="clean_read_MOH_health_tracker";
libname sandmoh5 ODBC dsn=idi_sandpit_srvprd schema="clean_read_MOH_maternity";
libname sandind ODBC dsn=idi_sandpit_srvprd schema="clean_read_INDICATORS";
libname sandcen ODBC dsn=idi_sandpit_srvprd schema="clean_read_cen";
libname sandcyf ODBC dsn=idi_sandpit_srvprd schema="clean_read_cyf";
libname sandmoe ODBC dsn=idi_sandpit_srvprd schema="clean_read_moe";

/* data area */
libname data ODBC dsn=idi_clean_archive_srvprd schema=data ;

/* security - used mainly for concordance */
libname security ODBC dsn=idi_clean_archive_srvprd schema=security ;



