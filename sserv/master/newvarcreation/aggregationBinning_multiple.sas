*processbody;
options mprint mlogic symbolgen;

proc datasets library=work kill;
run;

quit;

proc printto log="&output_path./Aggregation_Binning_Log.log" new;
run;

quit;

/*input & output paths*/
libname in "&input_path";
libname out "&output_path";

%MACRO multi_aggBinning;
	%let var_i = 1;
	%let c_var_new_all = ;

	%do %until (not %length(%scan(&var_list,&var_i)));
		%let temp=%scan(&var_list,&var_i);

		/*get this var*/
		data _null_;
			call symput ("var", "%scan(&var_list,&var_i)");
		run;

		%let var_short=%substr(&var.,1,27);

		%if %length(%scan(&var_list,&var_i)) < 27 %then
			%do;

				data _null_;
					call symput("new_list", "&prefix._&var.");
				run;

			%end;

		%if %length(%scan(&var_list,&var_i)) >= 27 %then
			%do;

				data _null_;
					call symput("new_list", "&prefix._&var_short");
				run;

				%let temp=&var_short.;
			%end;
		%let c_var_new_all = &c_var_new_all. &new_list.;

		/*type of variable*/
		%let dsid = %sysfunc(open(in.dataworking));
		%let varnum = %sysfunc(varnum(&dsid,&var.));
		%let vartyp_&var_i. = %sysfunc(vartype(&dsid,&varnum));
		%let rc = %sysfunc(close(&dsid));

		/*get bins for the var*/
		libname binning xml "&input_xml.";

		proc sql;
			select (bins) into :bins_&var_i. separated by "!!" from binning.&var.;
			select (editBins) into :binNames_&var_i. separated by "!!" from binning.&var.;
		quit;

		/*loop for each bin*/
		%let bin_i = 1;

		%do %until (not %length(%scan(%bquote(&&bins_&var_i.),&bin_i, "!!")));

			data _null_;
				call symput("bin", "%scan(%bquote(&&bins_&var_i.),&bin_i, "!!")");
			run;

			%put &bin;

			data _null_;
				%if "&&vartyp_&var_i." = "C" %then
					%do;
						call symput("bin",cat("'", tranwrd("&bin.", ",", "','"),"'"));
					%end;
			run;

			%put bin &bin;

			data outdata_&var_i._&bin_i.;
				length &new_list. $50.;
				set in.dataworking(keep=primary_key_1644 &var.);

				%if "&&vartyp_&var_i." = "C" %then
					%do;
						where strip(&var.) in (&bin.);
					%end;
				%else
					%do;
						where &var. in (&bin.);
					%end;

				&new_list. = "%scan(%bquote(&&binNames_&var_i.),&bin_i, "!!")";

				%if "&newvar_type." = "replace" %then
					%do;
						drop &var.;
						rename &new_list. = &var.;
					%end;
			run;

			proc append base = binned_&var_i. data = outdata_&var_i._&bin_i. force;
			run;

			%let bin_i = %eval(&bin_i.+1);
		%end;

		/*sort the binned output*/
		proc sort data = binned_&var_i.;
			by primary_key_1644;
		run;

		proc sort data = in.dataworking;
			by primary_key_1644;
		run;

		/*merge binned output with the input dataset*/
		data in.dataworking;
			merge binned_&var_i.(in=a) in.dataworking(in=b);
			by primary_key_1644;

			if a or b;
		run;

		libname format xml "&output_path./newVar_type.xml";

		proc sql;
			select (format) into :format_&var_i. from format.&var.;
		quit;

		%if "&&format_&var_i.."="numeric" %then
			%do;

				data in.dataworking(drop=&new_list.);
					set in.dataworking;
					format new_var 8.;
					new_var=&new_list.*1;
				run;

				data in.dataworking;
					set in.dataworking(rename=(new_var=&new_list.));
				run;

			%end;

		data binned_&var_i.;
			set binned_&var_i.;
			&new_list=tranwrd(&new_list,",","|");
		run;

		%if "&var_i." = "1" %then
			%do;

				data viewPane;
					set binned_&var_i.(drop=primary_key_1644);
				run;

			%end;
		%else
			%do;

				data viewPane;
					merge viewPane binned_&var_i.(drop=primary_key_1644);
				run;

			%end;

		data in.dataworking;
			set in.dataworking;
			&prefix._&temp.=tranwrd(&prefix._&temp.,",","_");
		run;

		%let var_i = %eval(&var_i.+1);
	%end;

	/*restriction on the no of rows*/
	%let dsid = %sysfunc(open(viewPane));
	%let nobs=%sysfunc(attrn(&dsid,nobs));
	%let rc = %sysfunc(close(&dsid));
	%put &nobs.;

	data viewpane;
		set viewpane(keep=&c_var_new_all.);
	run;

	%if &nobs.>6000 %then
		%do;

			proc surveyselect data=viewPane out=viewPane method=SRS
				sampsize=6000 SEED=1234567;
			run;

		%end;

	proc export data = viewPane
		outfile = "&output_path./MultiAggrBinning_viewPane.csv"
		dbms = CSV replace;
	run;

	quit;

	%do l=1 %to %sysfunc(countw("&type."," "));
		%let varname=%scan("&var_list",&l.," ");
		%let varname1=&prefix._%substr(&varname.,1,27);
		%let format=%scan("&type.",&l.," ");

		%if "&format." = "numerical" %then
			%do;

				data in.dataworking(drop=&varname1. rename=(tempvarr=&varname1.));
					set in.dataworking;
					tempvarr=&varname1.*1;
				run;

			%end;
	%end;
%MEND multi_aggBinning;

%multi_aggBinning;
%include "&genericCode_path./datasetprop_update.sas";

/* flex uses this file to test if the code has finished running */
data _null_;
	v1= "MULTIPLE_AGGREGATION_BINNING_COMPLETED";
	file "&output_path/MULTIPLE_AGGREGATION_BINNING_COMPLETED.txt";
	put v1;
run;

proc datasets lib=work kill;
run;

quit;