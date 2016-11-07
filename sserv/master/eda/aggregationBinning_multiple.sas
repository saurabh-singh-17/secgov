*processbody;
options mprint mlogic symbolgen;

proc datasets library=work kill;
run;
quit;

/*proc printto log="&output_path./Aggregation_Binning_Log.log" new;*/
/*run;*/

proc printto;
run;
quit;
/*input & output paths*/
libname in "&input_path";
libname out "&output_path";
libname report "&bivariate_report_path.";
libname new xml "&input_xml."; 

%MACRO multi_aggBinning;

/*keeping the required bin var*/
%let keepBinVar = bin_&var_list.;
data bindata(keep=&keepBinVar);
	set report.binned_data;
	run;


/*reading the XML required	*/
data bininfo;
	set new.&var_list;
	run;	

/*getting the bin info in a macro*/
proc sql;
select editbins into:binInfoVar separated by "#" from bininfo;
quit;
%let counter=0;
%do i=1 %to %sysfunc(countw("&binInfoVar.","#"));
	%let current_bin=%scan("&binInfoVar.",&i.,"#");
	%let search_n_replace_text=;
	%if %index("&current_bin.",%str(,)) > 0 %then %do;
		%let search_n_replace_text= &keepBinVar. = '&current_bin.';
		data _null_;
			call symput("search_n_replace_text",tranwrd("&search_n_replace_text.",",","' or &keepBinVar. = '"));
 			run;
		%put here is the &search_n_replace_text.;
		data _null_;
			call symput("current_bin_replace",tranwrd("&current_bin.",","," | "));
 			run;
		data bindata(rename=&keepBinVar.=&prefix._&var_list.);
			set bindata;
			if &search_n_replace_text. then &keepBinVar. = "&current_bin_replace.";
			run;
		%let counter=1;
	%end;
%end;
%if "&counter." = "0" %then %do;
data bindata(rename=&keepBinVar.=&prefix._&var_list.);
			set bindata;
			run;
%end;

data in.dataworking;
	merge in.dataworking bindata(keep=&prefix._&var_list.);
	run;

proc export data=bindata(keep=&prefix._&var_list.) outfile="&output_path./MultiAggrBinning_viewPane.csv" dbms=csv replace;

%MEND multi_aggBinning;
%multi_aggBinning;
%include "&genericCode_path./datasetprop_update.sas";



/* flex uses this file to test if the code has finished running */
data _null_;
	v1= "MULTIPLE_AGGREGATION_BINNING_COMPLETED";
	file "&output_path/MULTIPLE_AGGREGATION_BINNING_COMPLETED.txt";
	put v1;
run;



			