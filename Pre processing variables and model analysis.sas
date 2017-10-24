PROC IMPORT OUT= WORK.coil 
            DATAFILE= "F:\IDS462\CoilStuff\Coil1.csv" 
            DBMS=CSV REPLACE;
     GETNAMES=YES;
     DATAROW=2; 
RUN;
/*
PROC IMPORT OUT= WORK.coil 
            DATAFILE= "E:\IDS462\LecturesFall2014\S4.csv" 
            DBMS=CSV REPLACE;
     GETNAMES=YES;
     DATAROW=2; 
RUN;
*/

*proc contents data=work.coil;
*run;

*proc freq data=coil;
*run;

*%FreqReport(coil);
*options mprint;
*%DissGraphMakerLogOdds(coil,10,pwapar,resp);
*options nomprint;

data temp;
set  coil;
SqrMoshoo=(Moshoo-6)**2;
DifMoshoo=abs(Moshoo-6);
run;


proc logistic data=temp;
model resp=Moshoo;
title "Logistic Model for Moshoo";
run;
proc logistic data=temp;
model resp=DifMoshoo;
title "Logistic Model for DifMoshoo";
run;
proc logistic data=temp;
model resp=SqrMoshoo;
title "Logistic Model for SqrMoshoo";
run;
title;


data coil2(keep=seqnum--MGODPR mrelge MFALLE MFWEKI MOPLHO 
mska--mzpart 
minkge--PMOTSC PAANHA
AWAPAR--AMOTSC resp respholdout)
;
set  coil ;
rand=ranuni(092765);
     if rand <=.7 then RespHoldout=.;
else if rand  >.7 then do;
   RespHoldout=Resp;
   Resp=.
   ;
end;
run;


data coil3;
set  coil2;
array orig[10](0, 1, 2,  3,  4,  5,   6,   7,    8,    9);
array new[10] (0,25,75,150,350,750,3000,7500,15000,30000);
retain orig1-orig10 new1-new10; 
do i=1 to dim(orig); 
 if pwapar=orig[i] then pwapar2=new[i];
 if PAANHA=orig[i] then PAANHA2=new[i];
 if PPERSA=orig[i] then PPERSA2=new[i];
end;
drop orig1--orig10 new1--new10 i; 
run;

proc freq data=coil3;
tables 	pwapar*pwapar2
		PAANHA*PAANHA2
		PPERSA*PPERSA2/list;
run;

data coil3;
set  coil3;
drop pwapar paanha ppersa;
run;




data coil4;
set  coil3;
array orig[10](0,  1, 2, 3, 4, 5, 6, 7, 8,  9);
array new[10] (0,5.5,17,30,43,56,69,82,94,100);
retain orig1-orig10 new1-new10; 
do i=1 to dim(orig); 
if MGODRK =orig[i] then MGODRK2 =new[i];
if MGODPR =orig[i] then MGODPR2 =new[i];
if MRELGE =orig[i] then MRELGE2 =new[i];
if MFALLE =orig[i] then MFALLE2 =new[i];
if MFWEKI =orig[i] then MFWEKI2 =new[i];
if MOPLHO =orig[i] then MOPLHO2 =new[i];
if MSKA   =orig[i] then MSKA2 =new[i];
if MSKB1  =orig[i] then MSKB12 =new[i];
if MSKB2  =orig[i] then MSKB22 =new[i];
if MSKC   =orig[i] then MSKC2 =new[i];
if MHHUUR =orig[i] then MHHUUR2 =new[i];
if MAUT1  =orig[i] then MAUT12 =new[i];
if MAUT2  =orig[i] then MAUT22 =new[i];
if MAUT0  =orig[i] then MAUT02 =new[i];
if MINKGE =orig[i] then MINKGE2 =new[i];
end;
drop orig1--orig10 new1--new10 i; 
run;


proc freq data=coil4;
tables
MGODRK*MGODRK2
MGODPR*MGODPR2
MRELGE*MRELGE2
MFALLE*MFALLE2
MFWEKI*MFWEKI2
MOPLHO*MOPLHO2
MSKA*MSKA2
MSKB1*MSKB12
MSKB2*MSKB22
MSKC*MSKC2
MHHUUR*MHHUUR2
MAUT1*MAUT12
MAUT2*MAUT22
MAUT0*MAUT02
MINKGE*MINKGE2
/list;
run;


data coil5;
set  coil4;
drop
MGODRK
MGODPR
MRELGE
MFALLE
MFWEKI
MOPLHO
MSKA
MSKB1
MSKB2
MSKC
MHHUUR
MAUT1
MAUT2
MAUT0
MINKGE
;
run;


data indep;                                                                   
set  coil5 (drop=resp seqnum moshoo mostyp);                                                 
run;                                                                          

/* 
%ObsAndVars(indep);                                                           
%varlist(indep);                                                              
%macro GraphLoop;     
options mprint; 
 %do i=1 %to &nvars;                                                               
   %let variable=%scan(&varlist,&i);                                          
%DissGraphMakerLogOdds(coil5,10,&variable,resp);
 %end;             
options nomprint; 
%mend GraphLoop;                                                              
%GraphLoop; 
*/
%CatToBinWithDrop(coil5,seqnum,mostyp);
%CatToBinWithDrop(coil5,seqnum,MOSHOO);
*/
/*Replicate the programming below to test other variables for quadratic form*/;
data coil5;
set  coil5;
mgemomsq=mgemom**2;
run;

proc logistic data=coil5 descending;
model resp=mgemom;
title "Mgemom LINEAR Model";
run;
title;
proc logistic data=coil5 descending;
model resp=mgemom mgemomsq;
title "Mgemom QUADRATIC Model";
run;
title;

data coil6;
set  coil5;
*Any final changes here;
run;


*This is MY MODEL.  Adjust the variables to make YOUR model;
proc logistic data=coil6 descending;
model resp=
AWAPAR
MAANTH
MAUT02
MAUT12
MAUT22
MFALLE2
MFWEKI2
MGEMLE
MGEMOM
MGODPR2
MGODRK2
MHHUUR2
MINKGE2
MOPLHO2
MOSHOO_6
MOSHOO_7
MOSHOO_8
MOSHOO_9
MOSHOO_10
MRELGE2
MSKA2
MSKB12
MSKB22
MSKC2
PAANHA2
mostyp_11
mostyp_12
mostyp_13
mostyp_15
mostyp_16
mostyp_17
mostyp_18
mostyp_19
mostyp_20
mostyp_21
mostyp_22
mostyp_23
mostyp_24
mostyp_25
mostyp_26
mostyp_27
mostyp_28
mostyp_29
mostyp_30
mostyp_31
mostyp_32
mostyp_33
mostyp_34
mostyp_35
mostyp_36
mostyp_37
mostyp_38
mostyp_39
mostyp_40
mostyp_41
pwapar2
/selection=stepwise;
output out=scored p=pred;
run;

data holdout;
set  scored;
if   respholdout>.;
run;

proc sort data=holdout;
by descending pred;
run;

data RespAnal (keep=reccount respholdout cumcount cumresp);
set  holdout;
reccount=1;
cumcount+reccount;
cumresp+respholdout;
run;

proc freq data=RespAnal;
tables respholdout;
run;

*Change the denominators to match your total number of records and responses;
data RespAnal;
set  RespAnal;
RespPct=cumresp/106;
CountPct=cumcount/1806;
run;


data cutpoint;
set  RespAnal;
lagCountPct=lag(CountPct);
if   CountPct ge .75 and lagCountPct lt .75 then output;
run;

proc print data=cutpoint;
run;

/* Now right click on dataset RespAnal and select Copy to Clipboard*/
/* Create gains chart in Excel.  MAKE SURE YOU UNDERSTAND!! */


proc reg data=coil6;
model resp=MAUT02 MGODPR2 MINKGE2 MOSHOO_10 pwapar2;
run;
quit;
