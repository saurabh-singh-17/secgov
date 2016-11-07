/*Successfully converted to SAS Server Format*/
*processbody;
%let completedTXTPath =  &output_path/CATEGORICAL_VARIABLE_CREATION_COMPLETED.txt;
options mprint mlogic symbolgen mfile;

proc printto log="&output_path./Categorical_Variable_Creation_Log.log";
run;
quit;

proc printto;
run;	

dm log 'clear';
/*input & output paths*/
libname in "&input_path.";
libname out "&output_path.";
libname report "&bivariate_report_path.";
libname new xml "&input_xml.";


%MACRO categoricalVarCreation;
/*keeping the required bin var*/
%let keepBinVar = bin_&newvar_list.;
data bindata(keep=&keepBinVar);
	set report.binned_data;
	run;


/*reading the XML required	*/
data bininfo;
	set new.&newvar_list;
	run;	

/*getting the bin info in a macro*/
proc sql;
select level into:binInfoVar separated by "#" from bininfo;
quit;
data bindata;
	set bindata;
	%do i=1 %to %sysfunc(countw("&binInfoVar.","#"));
		%let current_bin=%scan("&binInfoVar.",&i.,"#");
		%let current_var_name = %sysfunc(compress(&prefix._%substr(&current_bin.,1,12)_%substr(&newvar_list.,1,14)));
		%let current_var_name = %sysfunc(translate(&current_var_name.,'_______________________________','`~!@#$%^&*()_+-=[]\{}|;:",./<>?'));
		if &keepBinVar. =  "&current_bin." then &current_var_name. = 1;
		else &current_var_name. = 0;
	%end;
	run;

data in.dataworking;
	merge in.dataworking bindata(drop=&keepBinVar.);
	run;

%MEND categoricalVarCreation;
%categoricalVarCreation;


/*subset for viewpane*/
data out.temp;
	set bindata;
	run;

%macro rows_restriction3;
	%let dsid = %sysfunc(open(out.temp));
		%let nobs=%sysfunc(attrn(&dsid,nobs));	
		%let rc = %sysfunc(close(&dsid));
	%put &nobs.;

	%if &nobs.>6000 %then %do;
	proc surveyselect data=out.temp out=out.temp method=SRS
		  sampsize=5000 SEED=1234567;
		  run;
	%end;
%mend rows_restriction3;
%rows_restriction3;

/*CSV output for viewpane population*/
proc export data = out.temp
	outfile = "&output_path/categoricalVariableCreation_subsetViewpane.csv"
	dbms = csv replace;
	run;


/*get contents for XML creation*/
proc contents data = out.temp out = contents_temp(keep = name);
	run;

proc sql;
	create table newvar as
	select name as new_varname from contents_temp
	where name not in ("bin_&newvar_list.");
	quit;

/*create XML for new varnames*/
libname newvar xml "&output_path./categoricalVariableCreation_new_varname.xml";
data newvar.new_varname;
	set newvar;
	run;
/*======================================================*/
/* code for updating the dataset properties information*/
/*====================================================== */
%include %unquote(%str(%'&genericCode_path./datasetprop_update.sas%'));
/*--------------------------------------------------------*/
/* flex uses this file to test if the code has finished running */
data _null_;
	v1= "CATEGORICAL_VARIABLE_CREATION_COMPLETED";
	file "&output_path/CATEGORICAL_VARIABLE_CREATION_COMPLETED.txt";
	put v1;
	run;

/*ENDSAS;*/


