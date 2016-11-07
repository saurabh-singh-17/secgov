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

proc printto log = "&outputpath./edm_update_and_proceed.log" new;
run;
quit;

libname in "&inputpath.";
libname out "&outputpath.";



/*-----------------------------------------------------------------------------------------
Macro to do
	distance cutoff
	adding the testcontrolindicatorvar to in.dataworking
	adding mapcontroltotestvar and distancevar depending on the conditions selected
-----------------------------------------------------------------------------------------*/
%macro updateandproceed;
/*-----------------------------------------------------------------------------------------
Cutoff by &distance_cutoff.
-----------------------------------------------------------------------------------------*/
%if "&distance_cutoff." ^= "" %then
	%do;
		data out.assign;
			set out.assign;
			if distance <= &distance_cutoff.;
		run;
	%end;
/*-----------------------------------------------------------------------------------------*/



/*-----------------------------------------------------------------------------------------
Add &testcontrolindicatorvar. to in.dataworking
-----------------------------------------------------------------------------------------*/
proc datasets lib=work kill nolist;
run;
quit;

data murx_temp;
	length c_var_c_ind $7 c_var_t_ind $7;
	set out.assign(keep = control test);
	c_var_c_ind = "Control";
	c_var_t_ind = "Test";
run;

data murx_temp_2;
	set murx_temp(keep=control c_var_c_ind rename=(control=&idvar. c_var_c_ind=&testcontrolindicatorvar.));
run;

%if %str(&matchtype1.) = %str(Many to One) %then
	%do;
		proc sort data=murx_temp_2 out=murx_temp_2 nodupkey;
			by &idvar.;
		run;
		quit;
	%end;

proc append base=murx_temp_3 data=murx_temp_2;
run;
quit;

data murx_temp_2;
	set murx_temp(keep=test c_var_t_ind rename=(test=&idvar. c_var_t_ind=&testcontrolindicatorvar.));
run;

proc append base=murx_temp_3 data=murx_temp_2;
run;
quit;

data out.murx_temp_3;
	set murx_temp_3;
run;

proc sql;
	create table in.dataworking as
		select a1.*, a2.&testcontrolindicatorvar.
			from in.dataworking a1
				left join murx_temp_3 a2
					on a1.&idvar. = a2.&idvar.;
run;
quit;

/*-----------------------------------------------------------------------------------------*/



/*-----------------------------------------------------------------------------------------
Add &mapcontroltotestvar. and &distancevar. depending on the conditions selected
-----------------------------------------------------------------------------------------*/
%if "&mapcontroltotestvar." ^= "" %then
	%do;
	
		data murx_temp;
			set out.assign(rename = (test=&idvar. control=&mapcontroltotestvar. %if &distancevarflag. = true %then %do; distance=dist_&mapcontroltotestvar. %end;));
		run;
		
		proc sql;
			create table in.dataworking as
				select *
					from in.dataworking a1
						left join murx_temp a2
							on a1.&idvar. = a2.&idvar.;
		run;
		quit;
		
	%end;
/*-----------------------------------------------------------------------------------------*/



/*-----------------------------------------------------------------------------------------
Creating a CSV with the names of the new variables created
-----------------------------------------------------------------------------------------*/
%let n_dsid   = %sysfunc(open(in.dataworking));
%let n_varnum = %sysfunc(varnum(&n_dsid., &idvar.));
%let c_vartyp = %sysfunc(vartype(&n_dsid., &n_varnum.));
%let n_rc     = %sysfunc(close(&n_dsid.));

data newvarnamesCSV;
	length variable $32 variable_type $11 num_str $7;
	variable = "&testcontrolindicatorvar.";
	variable_type = "categorical";
	num_str = "string";
	output;
	%if "&mapcontroltotestvar." ^= "" %then
		%do;
			variable = "&mapcontroltotestvar.";
			variable_type = "categorical";
			%if &c_vartyp. = C %then
				%do;
					num_str = "string";
				%end;
			%else %if &c_vartyp. = N %then
				%do;
					num_str = "numeric";
				%end;
			output;
		%end;
	%if %str(&distancevarflag.) = %str(true) %then
		%do;
			variable = "dist_&mapcontroltotestvar.";
			variable_type = "continuous";
			num_str = "numeric";
			output;
		%end;
run;

proc export data=newvarnamesCSV outfile="&outputpath./newvarnames.csv" replace;
run;
quit;
/*-----------------------------------------------------------------------------------------*/



/*-----------------------------------------------------------------------------------------
Create the new dataset depending on the flag
-----------------------------------------------------------------------------------------*/
%if &createdatasetflag. = true %then
	%do;
		%let drop=primary_key_1644;

		proc contents data=in.dataworking out=out_contents(keep=name);
		run;
		quit;

		data out_contents_subset;
			set out_contents;
			if index(name,"grp") and index(name,"_flag");
			if index(name,"grp") and index(name,"_flag") then call symput("delleat",name);
		run;

		%if %symexist(delleat) %then
			%do;
				proc sql;
					select name into: drop_temp separated by " " from out_contents_subset;
				run;
				quit;
				
				%let drop = &drop. &drop_temp.;
			%end;

		data out.&newdatasetname.(drop=&drop.);
			set in.dataworking;
			if missing(&testcontrolindicatorvar.) then delete;
		run;
	%end;
/*-----------------------------------------------------------------------------------------*/



/*-----------------------------------------------------------------------------------------
Completed txt
-----------------------------------------------------------------------------------------*/
data _null_;
	v1= "Indicators added to in.dataworking";
	file "&outputpath./edm_update_and_proceed_completed.txt";
	put v1;
run;
/*-----------------------------------------------------------------------------------------*/
%mend updateandproceed;
%updateandproceed;