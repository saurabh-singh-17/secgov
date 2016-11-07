/*Successfully converted to SAS Server Format*/
*processbody;
%let completedTXTPath =  &output_path/AGGREGATION_BINNING_COMPLETED.txt;
/*VERSION # 1.3.0*/

options mprint mlogic symbolgen mfile ;

/*PRINT Log & Output*/
proc printto log="&output_path./Aggregation_Binning_Log.log";
run;
quit;
	
/*proc printto print="&output_path./Aggregation_Binning_Output.out";*/
	


/*DEFINE LIBRARIES : input & output*/
libname in "&input_path";
libname out "&output_path";


/*SUBSET the input dataset*/
data temp;
	set in.dataworking(keep=primary_key_1644 &var_name.);
	run;


%MACRO aggregationBinning;

	/*contents of temp dataset*/
	proc contents data = temp out = contents_temp(keep= name type);
		run;

	/*determine the type of variable*/
	proc sql;
		select type into :variable_type from contents_temp where lowcase(name) = lowcase("&var_name.");
		quit;

	/*create a dataset from xml input*/
	libname binning xml "&input_xml.";
	data binning_bins;
		set binning.binning_bins;
		run;

	/*contents of the created dataset*/
	proc contents data = binning_bins out = binning_contents (keep=name);
		run;

	/*create macro variable for unique values of the variable*/
	proc sql;
		select name into :bin_list separated by " " from binning_contents;
		quit;


	%let i = 1;
	%do %until (not %length(%scan(&bin_list, &i)));
		
		/*create macro variable for each bin*/
		proc sql;
			select %scan(&bin_list, &i) into :bin&i. from binning_bins
			%if &variable_type. = 1 %then %do;
				where %scan(&bin_list, &i) ^= .;
			%end;
			%if &variable_type. = 2 %then %do;
				where %scan(&bin_list, &i) ^= " ";
			%end;
			quit;

		/*create macro variable for name of the bin*/
		data _null_;
			set binning_bins;
			call symput("bin_name&i.", (tranwrd("&&bin&i.", ",", "_" )));
			run;

		/*modifying the macro var in case of a character variable*/
		%if &variable_type. = 2 %then %do;
			data _null_;
				call symput("bin&i.", cats("'", tranwrd("&&bin&i.", ",", "', '"), "'"));
				run;
		%end;

		/*create the binned variable*/
		proc sql;
			create table binned&i. as
				select primary_key_1644,
				%if "&var_type." = "create_new" %then %do;
				&var_name, "&&bin_name&i" as &new_var.
				%end;
				%if "&var_type." = "replace" %then %do;
				"&&bin_name&i" as &var_name.
				%end;
				from temp
				where &var_name in (&&bin&i.);
				quit;

		/*append all the bins*/
		%if "&i." = "1" %then %do;
			data binned;
				%if "&var_type." = "create_new" %then %do;
					length &new_var. $50.;
				%end;
				%if "&var_type." = "replace" %then %do;
					length &var_name. $50.;
				%end;
				set binned&i.;
				run;
		%end;
		%else %do;
			data binned;
				set binned binned&i.;
				run;
		%end;

		%let i = %eval(&i.+1);
	%end;

%MEND aggregationBinning;
%aggregationBinning;

/*sort the binned output*/
proc sort data = binned out = binned;
	by primary_key_1644;
	run;

/*merge binned output with the input dataset*/
data in.dataworking;
	merge binned(in=a) in.dataworking(in=b drop=&var_name.);
	by primary_key_1644;
	if a or b;
	run;


/*subset for viewpane output*/
data binned;
	set binned(drop = primary_key_1644);
	run;
/*CSV output for viewpane*/
proc export data = binned (drop=primary_key_1644)
	outfile = "&output_path./aggregationBinning_subsetViewpane.csv"
	dbms=csv replace;


/*delete the unrequired datasets*/
proc datasets library = out;
	delete temp;
	run;

%include %unquote(%str(%'&genericCode_path./datasetprop_update.sas%'));
/* flex uses this file to test if the code has finished running */
data _null_;
	v1= "AGGREGATION_BINNING_COMPLETED";
	file "&output_path/AGGREGATION_BINNING_COMPLETED.txt";
	put v1;
	run;

ENDSAS;


