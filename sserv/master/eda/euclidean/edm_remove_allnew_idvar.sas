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

*processbody;
options spool mlogic mprint symbolgen;

proc printto log = "&outputpath./edm_remove_allnew_idvar.log" new;
run;
quit;

/*-----------------------------------------------------------------------------------------
Completed txt
-----------------------------------------------------------------------------------------*/
data _null_;
	v1= "completed";
	file "&outputpath./edm_remove_allnew_idvar_completed.txt";
	put v1;
run;
/*-----------------------------------------------------------------------------------------*/