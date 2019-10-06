/*********************************************************************************************************
TITLE: macro_geterrors.sas

DESCRIPTION: 
SAS does not have any easily built in error handling. Consequently this macro has been created.
It scans the log This script was derived from work found in the following SAS paper
Sezen, B., Gaudana S. (2005) Error handling: an approach for a robust production environment.
NESUG 18.


INPUT:
logfile - full path to the SAS log

OUTPUT:
SIAL components and logs

AUTHOR: E Walsh, V Benny

DATE: 16 March 2017

DEPENDENCIES: 
NA

NOTES: 
*********PUT COPY RIGHT NOTICE IN HERE*********

HISTORY: 
17 March 2017  v1
Mar 2019  Pete Holmes		Changes for SAS-GRID environment - macro names need to be all lower case for some reason
*********************************************************************************************************/




%macro geterrors(logfile=);

data errors(keep=logline) log(keep=logline);
	infile &logfile. missover;
	length logline $256 code $20;
	retain code;

	input;

	if index(_infile_, '0D'x) then logline=scan(_infile_,1,'0D'x);
	else logline=_infile_;

	logline= translate(logline, ' ', '%');

	if index(logline, ':') then code=scan(logline,'1', ':');
	else if substr(logline, 1, 5) ne ' ' then code=scan(logline,1,' ');
	output log;

	if index(code, 'ERROR') = 1  and logline ne ' ' then output errors;
run;

proc sql;
	select count(*) into :errcount from errors;
quit;

%if &errcount. eq 0 %then %do;
	proc sql;
		insert into errors select distinct 'No Errors' from log;
	quit;
%end;

%mend;
