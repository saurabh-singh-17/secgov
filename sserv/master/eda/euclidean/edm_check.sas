/*%let inputpath=/home/mrx1/vasanth;*/
/*%let outputpath=/home/mrx1/vasanth/wc;*/
/*%let grpno=0;*/
/*%let grpflag=1_1_1;*/
/*%let testindicatorvar=geography;*/
/*%let testvalue=north;*/
/*%let controlvalue=south;*/
/*%let nostd=nostd;*/
/*%let vars=ACV black_hispanic sales;*/
/*%let categoricalvars=Store_format;*/
/*%let idvar=Date;*/
/*%let testcontrolindicatorvar=dfsfsfae;*/
/*%let matchpreferencevar=sales;*/
/*%let matchpreferenceorder=descending;*/
/*%let matchtype1=Many to One;*/
/*%let matchtype2=simpleeuclidean;*/
/*%let distance_cutoff=150;*/
/*%let mapcontroltotestvar=wwwwwww;*/
/*%let distancevarflag=true;*/
/*%let createdatasetflag=true;*/
/*%let newdatasetname=dfsaddfsaddf;*/

options spool mprint mlogic symbolgen;

libname in "&inputpath.";
libname out "&outputpath.";

/*-----------------------------------------------------------------------------------------
Macro to check after specifying &distance_cutoff.
-----------------------------------------------------------------------------------------*/
%macro edmafterdistancecutoff;
/*-----------------------------------------------------------------------------------------
Subset the assignments based on &distance_cutoff.
-----------------------------------------------------------------------------------------*/
data temp;
	set out.assign;
	if distance <= &distance_cutoff.;
run;
/*-----------------------------------------------------------------------------------------*/



/*-----------------------------------------------------------------------------------------
Get the noof tests and control b4 and after cutting off
-----------------------------------------------------------------------------------------*/
proc sql;
	select count(distinct(test)) into: nooftestb4 from out.assign;
	select count(distinct(control)) into: noofctrlb4 from out.assign;
	select count(distinct(test)) into: nooftestaf from temp;
	select count(distinct(control)) into: noofctrlaf from temp;
run;
quit;
/*-----------------------------------------------------------------------------------------*/



/*-----------------------------------------------------------------------------------------
Create the dataset
-----------------------------------------------------------------------------------------*/
data aftercutoff;
	nooftest = &nooftestaf.;
	noofctrl = &noofctrlaf.;
	nooftestlost = %eval(&nooftestb4.-&nooftestaf.);
	noofctrllost = %eval(&noofctrlb4.-&noofctrlaf.);
run;
/*-----------------------------------------------------------------------------------------*/



/*-----------------------------------------------------------------------------------------
Export the dataset
-----------------------------------------------------------------------------------------*/
proc export data=aftercutoff outfile="&outputpath./aftercutoff.csv" dbms=csv replace;
run;
quit;
/*-----------------------------------------------------------------------------------------*/



/*-----------------------------------------------------------------------------------------
Completed txt
-----------------------------------------------------------------------------------------*/
data _null_;
	v1= "Check after cutoff completed";
	file "&outputpath./edm_check_completed.txt";
	put v1;
run;
/*-----------------------------------------------------------------------------------------*/
%mend edmafterdistancecutoff;
/*-----------------------------------------------------------------------------------------*/
%edmafterdistancecutoff;

proc datasets lib=work kill nolist;
run;
quit;