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

options spool mlogic mprint symbolgen;

libname in "&inputpath.";
libname out "&outputpath.";

%macro pre_distance_matrix;
/*-----------------------------------------------------------------------------------------
Creating a temporary dataset from in.dataworking
	with appropriate observations depending on the treatment process selected
-----------------------------------------------------------------------------------------*/
%if &grpno. = 0 %then
	%do;
		data temp;
		    set in.dataworking;
		run;
	%end;
%else
	%do;
		data temp;
			set in.dataworking;
			if grp&grpno._flag="&grpflag.";
		run;
	%end;
/*-----------------------------------------------------------------------------------------*/



/*-----------------------------------------------------------------------------------------
If the &testindicatorvar. is categorical then put double quotes around &testvalue. and &controlvalue.
-----------------------------------------------------------------------------------------*/
proc contents data=temp out=out_contents_temp;
run;
quit;

data _null_;
	set out_contents_temp;
	if name="&testindicatorvar." and type=2 then
		do;
			%let testvalue="&testvalue.";
			%let controlvalue="&controlvalue.";
		end;
run;
/*-----------------------------------------------------------------------------------------*/



/*-----------------------------------------------------------------------------------------
Creating a temporary dataset with only the necessary vars
	and the necessary observations to be used for distancing
-----------------------------------------------------------------------------------------*/
data temp;
    set temp(keep=&vars. &idvar. &testindicatorvar. &categoricalvars. &matchpreferencevar.);
	if &testindicatorvar. = &testvalue. or &testindicatorvar. = &controlvalue.;
run;
/*-----------------------------------------------------------------------------------------*/
%mend pre_distance_matrix;
%pre_distance_matrix;



/*-----------------------------------------------------------------------------------------
Macro to calculate the distance matrix
Needs:
	Input dataset
	Output dataset
	Nostd option
	Parameter vars
	idvar variable
	Copy vars
	Test indicatorvar -- Should have only two levels
	The value which indicates test
Assumptions:
	in.dataworking is assumed to exist
		The variable &allnew_idvar. is not there in in.dataworking
		&allnew_idvar. will be added to in.dataworking by this code
-----------------------------------------------------------------------------------------*/
%macro distance_matrix(in,out,nostd,paramvars,idvar,copyvars,testindicatorvar,testvalue);
/*-----------------------------------------------------------------------------------------
Making a temporary copy of the input dataset to work with
-----------------------------------------------------------------------------------------*/
data temp;
	set &in.;
run;
/*-----------------------------------------------------------------------------------------*/



/*-----------------------------------------------------------------------------------------
The idvar variable has to be a character variable
So, if the specified idvar variable is not a character variable
	creating a character variable with the values of the idvar variable
Replace special characters and space by underscore in the idvar variable
-----------------------------------------------------------------------------------------*/
proc contents data=temp out=out_contents;
run;

data _null_;
    set out_contents;
    if name="&idvar." then
        do;
	        call symput("type",type);
	        call symput("format",format);
	        call symput("formatl",formatl);
        end;
run;

%let allnew_idvar = allnew_%substr(&idvar.,1,25);
%let length=%eval(&formatl.+6);

%if &type. ^= 2 %then
    %do;
        data temp(drop=&idvar.);
            set temp;
            &allnew_idvar.=put(&idvar.,%sysfunc(compress(&format.&formatl..)));
        run;
    %end;

data temp;
	length &allnew_idvar. $&length.;
	set temp;
	&allnew_idvar. = translate(&allnew_idvar.,"______________________________"," ,<.>/?;:'[{]}\|=+-(*&^%$#@!`~");
	&allnew_idvar. = translate(&allnew_idvar.,'__','")');
	&allnew_idvar. = cats("idvar_",&allnew_idvar.);
run;
/*-----------------------------------------------------------------------------------------*/



/*-----------------------------------------------------------------------------------------
Adding the all new idvar variable to in.dataworking
P.S.: Order of the observations in both the datasets havent been changed yet.
	So, dont need a by statement
-----------------------------------------------------------------------------------------*/
data in.dataworking;
	merge in.dataworking temp(keep=&allnew_idvar.);
run;
/*-----------------------------------------------------------------------------------------*/



/*-----------------------------------------------------------------------------------------
Sort the temp dataset in ascending order by the testindicatorvar
Create four macro vars containing some useful data
-----------------------------------------------------------------------------------------*/
%if &matchpreferenceorder. = ascending %then
	%do;
		%let matchpreferenceorder = ;
	%end;
	
proc sort data=temp out=temp;
	by &categoricalvars. &testindicatorvar. &matchpreferenceorder. &matchpreferencevar.;
run;
quit;

%let forifwotestindicator=;
%let forifwtestindicator=first.&testindicatorvar.;
%let or=;
%if "&categoricalvars." ^= "" %then
	%do;
		data _null_;
			call symput("cccvars",tranwrd("&categoricalvars."," ",")||'_'||compress("));
		run;
		%let cccvars=compress(&cccvars.);
		%do tempi=1 %to %sysfunc(countw(&categoricalvars.));
			%if &tempi. > 1 %then %let or=or;
			%let forifwotestindicator=&forifwotestindicator. &or. first.%scan(&categoricalvars.,&tempi.);
			%let forifwtestindicator=&forifwtestindicator. or first.%scan(&categoricalvars.,&tempi.);
		%end;
	%end;

data temp;
	retain &categoricalvars. &testindicatorvar.;
	retain flagwti flagwoti 0;
	set temp;
	by &categoricalvars. &testindicatorvar.;
	if &forifwtestindicator. then flagwti = flagwti+1;
	%if "&categoricalvars." ^= "" %then
		%do;
			if &forifwotestindicator. then
				do;
					flagwoti = flagwoti+1;
					call symput("stlevel"||compress(flagwoti),&cccvars.);
				end;
		%end;
	%else
		%do;
			if &forifwtestindicator. then flagwoti = flagwoti+1;
		%end;
run;

%if "&categoricalvars." ^= "" %then
	%do;
		proc sql;
			select max(flagwoti) into: maxValue from temp;
		run;
		quit;
		
		data _null_;
			set temp;
			by flagwti;
			if first.flagwti then
				do;
					if &testindicatorvar.=&testvalue. then
						do;
							call symput("firsttest_"||compress(flagwoti),_n_);
						end;
					else
						do;
							call symput("firstcontrol_"||compress(flagwoti),&allnew_idvar.);
							call symput("nfirstcontrol_"||compress(flagwoti),_n_);
						end;
				end;
			if last.flagwti then
				do;
					if &testindicatorvar.=&testvalue. then
						do;
							call symput("lasttest_"||compress(flagwoti),_n_);
						end;
					else
						do;
							call symput("lastcontrol_"||compress(flagwoti),&allnew_idvar.);
							call symput("nlastcontrol_"||compress(flagwoti),_n_);
						end;
				end;
		run;
	%end;
%else
	%do;		
		data _null_;
			set temp;
			by flagwti;
			if first.flagwti then
				do;
					if &testindicatorvar.=&testvalue. then
						do;
							call symput("firsttest",_n_);
						end;
					else
						do;
							call symput("firstcontrol",&allnew_idvar.);
						end;
				end;
			if last.flagwti then
				do;
					if &testindicatorvar.=&testvalue. then
						do;
							call symput("lasttest",_n_);
						end;
					else
						do;
							call symput("lastcontrol",&allnew_idvar.);
						end;
				end;
		run;
	%end;
/*-----------------------------------------------------------------------------------------*/



/*-----------------------------------------------------------------------------------------
Save these macro variables somewhere
-----------------------------------------------------------------------------------------*/
data out.vmacro;
	set sashelp.vmacro;
	if scope = "DISTANCE_MATRIX" and (index(name,"STTEST") or index(name,"STCONTROL") or index(name,"STLEVEL"));
	%if "&categoricalvars." ^= "" %then
		%do;
			max=&maxValue.;
		%end;
run;

proc sort data=out.vmacro out=out.vmacro;
	by name;
run;
/*-----------------------------------------------------------------------------------------*/



/*-----------------------------------------------------------------------------------------
Calculating the distance and getting the distance matrix
-----------------------------------------------------------------------------------------*/
proc distance data=temp out=&out. method=euclid shape=square &nostd.;
	var interval(&paramvars.);
	id &allnew_idvar.; /*The id variable has to be a character variable*/
run;
/*-----------------------------------------------------------------------------------------*/



/*-----------------------------------------------------------------------------------------
Macro to do error check
-----------------------------------------------------------------------------------------*/
%macro errorcheckdistancematrix;
/*-----------------------------------------------------------------------------------------
Creating the error dataset
-----------------------------------------------------------------------------------------*/
%if "&categoricalvars." = "" %then
	%do;
		%let dsid=%sysfunc(open(in.dataworking));
		%let nobs_dw=%sysfunc(attrn(&dsid.,nobs));
		%let rc=%sysfunc(close(&dsid.));

		%let nooftest=%eval(&lasttest.-&firsttest.+1);
		%let noofctrl=%eval(&nobs_dw.-&nooftest.);

		data error;
			level="Across Dataset";
			nooftest=&nooftest.;
			noofctrl=&noofctrl.;
			matchtype="&matchtype1.";
		run;
	%end;
%else
	%do;
		proc sql;
			select max(max) into: maxValue from out.vmacro;
		run;
		quit;

		%do i = 1 %to &maxValue.;
			%if %symexist(firsttest_&i.) %then
				%do;
					%let nooftest = %eval(&&lasttest_&i..-&&firsttest_&i..+1);
				%end;
			%else
				%do;
					%let nooftest=0;
				%end;

			%if %symexist(nfirstcontrol_&i.) %then
				%do;
					%let noofctrl = %eval(&&nlastcontrol_&i..-&&nfirstcontrol_&i..+1);
				%end;
			%else
				%do;
					%let noofctrl=0;
				%end;

			data temperror;
				length level $200;
				level="&&stlevel&i..";
				nooftest=&nooftest.;
				noofctrl=&noofctrl.;
				matchtype="&matchtype1.";
			run;

			proc append base=error data=temperror force;
			run;
			quit;
		%end;
	%end;
/*-----------------------------------------------------------------------------------------*/



/*-----------------------------------------------------------------------------------------
After creating the error dataset
-----------------------------------------------------------------------------------------*/
%if &matchtype1. = One to One %then
	%do;
		data error;
			set error;
			if noofctrl < nooftest;
		run;
	%end;
%if &matchtype1. = Many to One %then
	%do;
		data error;
			set error;
			if noofctrl = 0 or nooftest = 0 or missing(noofctrl) or missing(nooftest);
		run;
	%end;

%let dsid=%sysfunc(open(error));
%let nobs_error=%sysfunc(attrn(&dsid.,nobs));
%let rc=%sysfunc(close(&dsid.));

%if &nobs_error. = 0 or &nobs_error. = . %then
	%do;
		data _null_;
			v1= "Distance matrix completed";
			file "&outputpath./edm_distance_matrix_completed.txt";
			put v1;
		run;
	%end;
%else %if &nobs_error. = &maxValue. %then
	%do;
		data tempforsum;
			set error;
			tobeadded = min(test,control);
		run;

		proc sql;
			select max(max) into: maxValue from out.vmacro;
			select sum(tobeadded) into: sumValue from tempforsum;
		run;
		quit;

		%if &sumValue. = 0 %then
			%do;
				data _null_;
					v1= "Matching cannot be performed as there are no tests/controls available.";
					file "&outputpath./edm_cant_run_error.txt";
					put v1;
				run;
			%end;
	%end;
%else
	%do;
		proc export data=error outfile="&outputpath./error.csv" dbms=csv replace;
		run;
		quit;
	%end;
/*-----------------------------------------------------------------------------------------*/
%mend errorcheckdistancematrix;
/*-----------------------------------------------------------------------------------------
Calling the errorcheck macro
-----------------------------------------------------------------------------------------*/
%errorcheckdistancematrix;
/*-----------------------------------------------------------------------------------------*/
%mend distance_matrix;
/*-----------------------------------------------------------------------------------------*/



/*-----------------------------------------------------------------------------------------
Calling the above defined macro
-----------------------------------------------------------------------------------------*/
%distance_matrix(in=temp,out=out.distance_matrix,nostd=&nostd.,paramvars=&vars.,idvar=&idvar.,copyvars=&categoricalvars.,testindicatorvar=&testindicatorvar.,testvalue=&testvalue.);
/*-----------------------------------------------------------------------------------------*/

proc datasets lib=work kill nolist;
run;
quit;