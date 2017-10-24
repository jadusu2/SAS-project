
%macro FreqReport(dsn);
proc datasets nolist lib=work;
delete FreqReport;
run;

%global obs vars;
%ObsAndVars(&dsn);
%varlist(&dsn);

%local i j;
 %do j=1 %to &nvars;
proc freq data=&dsn noprint order=freq;
tables %qscan(&varlist,&j)/out=freqout missing missprint;
run;

data missing nonmissing;
set  freqout;
if %qscan(&varlist,&j) =  '' then output missing;
if %qscan(&varlist,&j) ne '' then output nonmissing;
run;

proc summary data=nonmissing;
var count;
output out=nomissfigs n=catnomiss max=countmax;
run;

data top3;
set  nonmissing;
if _n_ <=3;
run;

proc summary data=top3;
var count;
output out=top3count sum=Top3Sum;
run;

data record;
format varname $50.
       pctmiss pctmax pct3 percent6.;
label countmiss="Missing Count"
      CatNoMiss="# Non Missing Categories"
      CountMax= "# In Largest Non-Missing Category"
	  Top3Sum=  "# In Three Largest Categories"
      pctmiss="Missing Percent";;
varname="%qscan(&varlist,&j)";
merge missing    (keep=count rename=(count=countmiss))
      nomissfigs (keep=CatNoMiss CountMax)
      top3count  (keep=Top3Sum)
      ;
pctmiss=countmiss/&nobs;
pctMax =CountMax/&nobs;
pct3   =Top3Sum/&nobs;
run;


proc append data=record base=FreqReport;
run;
%end;

data temp;
set  FreqReport;
len=length(varname);
run;

proc summary data=temp;
var len;
output out=maxlen max=;
run;

data _null_;
set  maxlen;
call symput('len',len);
run;

data FreqReport2;
format varname $&len..;
set  FreqReport;
run;

proc contents data=&dsn varnum noprint out=contents;
run;

proc sort data=contents (rename=(name=varname));
by varname;
run;

proc sort data=freqreport2;
by varname;
run;

data  FreqReportWithLabels;
merge FreqReport2 (in=infreq)
      contents (in=incontents keep=varname label varnum type)
	  ;
by    varname;
if    infreq and incontents;
run;

proc sort data=FreqReportWithLabels;
by varnum;
run;

proc format;
value type 1='Numb' 2='Char';
run;

proc print data=FreqReportWithLabels;
var varname type pctmiss CatNoMiss PctMax pct3 countmiss CountMax Top3Sum;
format type type.;
title "Freq Report for File &dsn";
run;
title;

options nomprint;
%mend FreqReport;


%Macro DissGraphMakerLogOdds(dsn,groups,indep,dep);
proc summary data=&dsn;
var &indep;
output out=Missing&indep nmiss=;
run;

data Missing&indep;
set  Missing&indep;
PctMiss=100*(&indep/_freq_);
rename &indep=NMiss;
run;

data _null_;
set  Missing&indep;
call symput ('Nmiss',Compress(Put(Nmiss,6.)));
call symput ('PctMiss',compress(put(PctMiss,4.)));
run;

proc rank data=&dsn groups=&groups out=RankedFile;
var &indep;
ranks Ranks&indep;
run;

proc summary data=RankedFile nway missing;
class Ranks&indep;
var &dep &indep;
output out=GraphFile mean=;
run;

data graphfile;
set  graphfile;
logodds=log(&dep/(1-&dep));
run;

data graphfile setaside;
set  graphfile;
if &indep=. then output setaside;
else             output graphfile;
run;

data _null_;
set  setaside;
call symput('LogOdds',compress(put(LogOdds,4.2)));
run;

proc plot data=graphfile;
plot LogOdds*&indep=' ' $_FREQ_ /vpos=20;
title "&dep by &groups Groups of &indep NMiss=&Nmiss PctMiss=&PctMiss%  LogOdds in Miss=&LogOdds"
;
run;
title;
quit;
%Mend DissGraphMakerLogOdds;


%macro ObsAndVars(dsn);
%global nobs nvars;
%let dsid=%sysfunc(open(&dsn));   
%let nobs=%sysfunc(attrn(&dsid,nobs));     
%let nvars=%sysfunc(attrn(&dsid,nvars));   
%let rc=%sysfunc(close(&dsid));            
%put nobs=&nobs nvars=&nvars;   
%mend ObsAndVars;


%macro varlist(dsn);
options nosymbolgen;
 %global varlist cnt;
 %let varlist=;

/* open the dataset */
 %let dsid=%sysfunc(open(&dsn));

/* count the number of variables in the dataset */
 %let cnt=%sysfunc(attrn(&dsid,nvars));

 %do i=1 %to &cnt;
 %let varlist=&varlist %sysfunc(varname(&dsid,&i));
 %end;

/* close the dataset */
 %let rc=%sysfunc(close(&dsid));
*%put &varlist;
%mend varlist;

%macro CatToBinWithDrop(filename,id,varname);
data &filename;
set  &filename;
%unquote(&varname._)= &varname; if &varname =' ' then %unquote(&varname._)='x';
run;
proc transreg data=&filename DESIGN;
model class (%unquote(&varname._)/ ZERO='x');
output out = %unquote(&varname._)(drop = Intercept _NAME_ _TYPE_);
id &ID;
run;
proc sort data=%unquote(&varname._);by &ID;
data &filename (drop=&varname %unquote(&varname._));
merge &filename %unquote(&varname._);
by &ID;
run;
proc datasets nolist;
delete %unquote(&varname._);
run;
quit;
%mend CatToBinWithDrop;
