/*Successfully converted to SAS Server Format*/
*processbody;
%let completedTXTPath =  &output_path/ADSTOCK_VARIABLE_CREATION_COMPLETED.txt;
/*------------------------------------------------------------------------------------------------------------------------------*/
/*Parameters Required*/
/*------------------------------------------------------------------------------------------------------------------------------*/
/*%let codePath=C:/Program Files/muRx;*/
/*%let input_path=C:/Users/vasanth.mm/MRx/sas/vasanth_06jun2013-6-Jun-2013-22-03-36/1;*/
/*%let output_path=C:/Users/vasanth.mm/MRx/sas/vasanth_06jun2013-6-Jun-2013-22-03-36/1/0/1_1_1/NewVariable/AdstockVariable/1;*/
/*%let mode=check;*/
/*%let eqn_type=simple;*/
/*%let var_name=black_hispanic ACV;*/
/*%let decay_rate=0.1!!0.5;*/
/*%let gamma_value=1!!0.2!!0.5;*/
/*%let base_decay=0.1;*/
/*%let base_gamma=1;*/
/*%let threshold=0.05;*/
/*%let date_variable=Date;*/
/*%let dependent_variable=ACV;*/
/*%let selected_vars=;*/
/*%let genericCode_path=C:/Program Files/muRx/com/musigma/reusablemodules/sascode/common;*/
/*------------------------------------------------------------------------------------------------------------------------------*/



/*------------------------------------------------------------------------------------------------------------------------------*/
/*Options statement and clearing the log*/
/*------------------------------------------------------------------------------------------------------------------------------*/
options mlogic symbolgen mfile mprint;
dm log 'clear';
/*------------------------------------------------------------------------------------------------------------------------------*/



/*------------------------------------------------------------------------------------------------------------------------------*/
/*Assigning library names*/
/*------------------------------------------------------------------------------------------------------------------------------*/
libname in "&input_path.";
libname out "&output_path.";
/*------------------------------------------------------------------------------------------------------------------------------*/

/*------------------------------------------------------------------------------------------------------------------------------*/
/*Log & print statements*/
/*------------------------------------------------------------------------------------------------------------------------------*/
proc printto log="&output_path/AdstockVariableCreation_Log.log";
run;
quit;
/*------------------------------------------------------------------------------------------------------------------------------*/	

/*------------------------------------------------------------------------------------------------------------------------------*/
/*Delete the previously existing files*/
/*------------------------------------------------------------------------------------------------------------------------------*/
%macro delete_files;
%if &mode. = check %then %do;
	FILENAME MyFile "&completedTXTPath.";

	DATA _NULL_ ;
		rc = FDELETE('MyFile') ;
		RUN ;

	FILENAME MyFile "&output_path./adstockVarCreation_viewPane.csv";

	DATA _NULL_ ;
		rc = FDELETE('MyFile') ;
		RUN ;
		
	FILENAME MyFile "&output_path./error.txt";

	DATA _NULL_ ;
		rc = FDELETE('MyFile') ;
		RUN ;

	FILENAME MyFile "&output_path./correlation_table.csv";

	DATA _NULL_ ;
		rc = FDELETE('MyFile') ;
		RUN ;

	%do tempi = 1 %to %sysfunc(countw(&var_name.," "));
		%let fileToBeDeleted = &output_path./%scan(&var_name.,&tempi.," ").csv;

		FILENAME MyFile "&fileToBeDeleted.";

		DATA _NULL_ ;
			rc = FDELETE('MyFile') ;
			RUN ;
	%end;
%end;

%mend;
%delete_files;
/*------------------------------------------------------------------------------------------------------------------------------*/


/*------------------------------------------------------------------------------------------------------------------------------*/
/*Checking for zero and/or negative & missing values if log is selected*/
/*------------------------------------------------------------------------------------------------------------------------------*/
%macro generic_path;
%let codeToBeCalled = &genericCode_path./macrodefn_checkFor.sas;
%include "&codeToBeCalled.";
%let found_status = 0;

%if &eqn_type. = log %then %do;
	%checkFor(dataset=in.dataworking,variables=&var_name.,checkFor=missing negative 0,outputFileName=&output_path./error.txt);
%end;
%if &eqn_type. = exponential %then %do;
	%checkFor(dataset=in.dataworking,variables=&var_name.,checkFor=negative,outputFileName=&output_path./error.txt);
%end;
%if &found_status. = 1 %then %do;
	endsas;
%end;
%if &transform_type. = log %then %do;
	%checkFor(dataset=in.dataworking,variables=&var_name.,checkFor=missing negative,outputFileName=&output_path./error.txt);
%end;
%if &found_status. = 1 %then %do;
	endsas;
%end;
%mend;
%generic_path;
/*------------------------------------------------------------------------------------------------------------------------------*/



/*------------------------------------------------------------------------------------------------------------------------------*/
/*Macro to create a new adstock variable with the specified decay rates and gamma values and add it to the input dataset*/
/*------------------------------------------------------------------------------------------------------------------------------*/
%macro create_adstock_variables(dataset,adstock_variable,dependent_variable,date_variable,decay_rate,gamma_value);
	%global variables_used var_name_i new_adstock_variables extended_decay_rate extended_gamma_value;
	%let new_adstock_variables=;
	%let variables_used=;
	%let var_name_i=;
	
	proc sort data = &dataset. out= &dataset.;
		by &date_variable.;
		run;

	/*If eqn_type is exponential*/
	%if &eqn_type. = exponential %then %do;
		%let extended_decay_rate=;
		%let extended_gamma_value=;
		%do i = 1 %to %sysfunc(countw(&var_name.," "));
			%let current_adstock_variable = %scan(&var_name.,&i.," ");
			%let var_name_i=&var_name_i.!!&i.;
			%do j = 1 %to %sysfunc(countw(&decay_rate.,"!!"));
				%let current_decay_rate = %scan(&decay_rate.,&j.,"!!");
				%let current_decay_rate_value = (1-&current_decay_rate.);
				%do k = 1 %to %sysfunc(countw(&gamma_value.,"!!"));
					%let current_gamma_value = %scan(&gamma_value.,&k.,"!!");

					%let current_new_adstock_variable = &threeLetterWord.&i._%substr(&current_adstock_variable.,1,10)_%substr(%sysfunc(compress(&current_decay_rate.,".")),1,4)_%substr(%sysfunc(compress(&current_gamma_value.,".")),1,4);
					%let new_adstock_variables = &new_adstock_variables. &current_new_adstock_variable.;
					%let extended_decay_rate = &extended_decay_rate.!!&current_decay_rate;
					%let extended_gamma_value = &extended_gamma_value.!!&current_gamma_value.;
					%let variables_used = &variables_used. &current_adstock_variable.;

					data &dataset.(rename = (tempvar = &current_new_adstock_variable.));
						set &dataset.;
						retain tempvar;
						%if &transform_type. = simple %then %do;
							tempvar = (sum(&current_adstock_variable.,&current_decay_rate_value.*tempvar))**&current_gamma_value.;
						%end;
						%if &transform_type. = log %then %do;
							tempvar = (sum(log(&current_adstock_variable.+1),&current_decay_rate_value.*tempvar))**&current_gamma_value.;
						%end;
						run;
				%end;
			%end;
		%end;
	%end;
	/*If eqn_type is simple or log*/
	%if &eqn_type. = log or &eqn_type. = simple %then %do;
		%let extended_decay_rate=;
		%do i = 1 %to %sysfunc(countw(&adstock_variable.," "));
			%let current_adstock_variable = %scan(&adstock_variable.,&i.," ");
			%let var_name_i=&var_name_i.!!&i.;
			%do j = 1 %to %sysfunc(countw(&decay_rate.,"!!"));
				%let current_decay_rate = %scan(&decay_rate.,&j.,"!!");
				%let current_decay_rate_value = (1-&current_decay_rate.);
				%let current_new_adstock_variable = &threeLetterWord.&i._%substr(&current_adstock_variable.,1,10)_%substr(%sysfunc(compress(&current_decay_rate.,".")),1,4);
				%let new_adstock_variables = &new_adstock_variables. &current_new_adstock_variable.;
				%let extended_decay_rate = &extended_decay_rate.!!&current_decay_rate;
				%let variables_used = &variables_used. &current_adstock_variable.;
				
				data &dataset.(rename = (tempvar = &current_new_adstock_variable.));
					set &dataset.;
					retain tempvar;
					%if &eqn_type. = simple %then %do;
						tempvar = (sum(&current_adstock_variable.,&current_decay_rate_value.*tempvar));
					%end;
					%if &eqn_type. = log %then %do;
						tempvar = (sum(log(&current_adstock_variable.),&current_decay_rate_value.*tempvar));
					%end;
					run;
			%end;
		%end;
	%end;
%mend;

/*------------------------------------------------------------------------------------------------------------------------------*/
/*crearion of adstock variable for panel data , this extra piece of code has been included to improve the performance of the code */
/*and reduce the time taken when panel has too many levels as happens in sanofi*/


%macro create_adstock_variables_panel(dataset,adstock_variable,dependent_variable,date_variable,decay_rate,gamma_value);
	
	%global variables_used var_name_i new_adstock_variables extended_decay_rate extended_gamma_value;
	%let new_adstock_variables=;
	%let variables_used=;
	%let var_name_i=;
	
	proc sort data = &dataset. out= &dataset.;
		by &var. &date_variable.;
		run;

	/*If eqn_type is exponential*/
	%if &eqn_type. = exponential %then %do;
		%let extended_decay_rate=;
		%let extended_gamma_value=;
		%do i = 1 %to %sysfunc(countw(&var_name.," "));
			%let current_adstock_variable = %scan(&var_name.,&i.," ");
			%let var_name_i=&var_name_i.!!&i.;
			%do j = 1 %to %sysfunc(countw(&decay_rate.,"!!"));
				%let current_decay_rate = %scan(&decay_rate.,&j.,"!!");
				%let current_decay_rate_value = (1-&current_decay_rate.);
				%do k = 1 %to %sysfunc(countw(&gamma_value.,"!!"));
					%let current_gamma_value = %scan(&gamma_value.,&k.,"!!");

					%let current_new_adstock_variable = &threeLetterWord.&i._%substr(&current_adstock_variable.,1,10)_%substr(%sysfunc(compress(&current_decay_rate.,".")),1,4)_%substr(%sysfunc(compress(&current_gamma_value.,".")),1,4);
					%let new_adstock_variables = &new_adstock_variables. &current_new_adstock_variable.;
					%let extended_decay_rate = &extended_decay_rate.!!&current_decay_rate;
					%let extended_gamma_value = &extended_gamma_value.!!&current_gamma_value.;
					%let variables_used = &variables_used. &current_adstock_variable.;

					data &dataset.(rename = (tempvar = &current_new_adstock_variable.));
						set &dataset.;
						by &var.;
						retain tempvar;
						if first.&var. then tempvar=0;
						%if &transform_type. = simple %then %do;
							tempvar = (sum(&current_adstock_variable.,&current_decay_rate_value.*tempvar))**&current_gamma_value.;
						%end;
						%if &transform_type. = log %then %do;
							tempvar = (sum(log(&current_adstock_variable.+1),&current_decay_rate_value.*tempvar))**&current_gamma_value.;
						%end;
						run;
				%end;
			%end;
		%end;
	%end;
	/*If eqn_type is simple or log*/
	%if &eqn_type. = log or &eqn_type. = simple %then %do;
		%let extended_decay_rate=;
		%do i = 1 %to %sysfunc(countw(&adstock_variable.," "));
			%let current_adstock_variable = %scan(&adstock_variable.,&i.," ");
			%let var_name_i=&var_name_i.!!&i.;
			%do j = 1 %to %sysfunc(countw(&decay_rate.,"!!"));
				%let current_decay_rate = %scan(&decay_rate.,&j.,"!!");
				%let current_decay_rate_value = (1-&current_decay_rate.);
				%let current_new_adstock_variable = &threeLetterWord.&i._%substr(&current_adstock_variable.,1,10)_%substr(%sysfunc(compress(&current_decay_rate.,".")),1,4);
				%let new_adstock_variables = &new_adstock_variables. &current_new_adstock_variable.;
				%let extended_decay_rate = &extended_decay_rate.!!&current_decay_rate;
				%let variables_used = &variables_used. &current_adstock_variable.;
				
				data &dataset.(rename = (tempvar = &current_new_adstock_variable.));
					set &dataset.;
					by &var.;
					retain tempvar;
					if first.&var. then tempvar=0;
					%if &eqn_type. = simple %then %do;
						tempvar = (sum(&current_adstock_variable.,&current_decay_rate_value.*tempvar));
					%end;
					%if &eqn_type. = log %then %do;
						tempvar = (sum(log(&current_adstock_variable.),&current_decay_rate_value.*tempvar));
					%end;
					run;
			%end;
		%end;
	%end;
%mend;


/*------------------------------------------------------------------------------------------------------------------------------*/
/*The adstock workflow macro*/
/*------------------------------------------------------------------------------------------------------------------------------*/
%macro ads;
	%if &mode. = confirm %then
		%do;
			data toBeMerged;
				set in.adstockVarCreation_viewPane(keep = &selected_vars. primary_key_1644);
				run;
				
			proc sort data = toBeMerged;
				by primary_key_1644;
				run;
			
			proc sort data = in.dataworking;
				by primary_key_1644;
				run;
			
			data in.dataworking;
				merge in.dataworking toBeMerged;
				by primary_key_1644;
				run;
				
			/*------------------------------------------------------------------------------------------------------------------------------*/
			/*Create a temporary dataset called exportData(to be exported) from in.adstockVarCreation_viewPane*/
			/*excluding the column grp_vars_column(if it exists)*/
			/*and do whatever is necessary and export it*/
			/*------------------------------------------------------------------------------------------------------------------------------*/
			data exportData;
				set in.adstockVarCreation_viewPane(drop = &dependent_variable.);
				run;

			/*restriction on the no of rows in the output CSV*/
			%let dsid = %sysfunc(open(exportData));
			%let nobs=%sysfunc(attrn(&dsid,nobs));	
			%let rc = %sysfunc(close(&dsid));
			%put &nobs.;

			%if &nobs.>6000 %then %do;
				proc surveyselect data=exportData out=exportData method=SRS
					sampsize=6000 SEED=1234567;
					run;
			%end;
			
			/*Sort the dataset that is about to be exported by primary_key_1644*/
			proc sort data = exportData out = exportData;
				by primary_key_1644;
				run;
			
			/*Drop primary_key_1644 b4 exporting*/
			data exportData;
				set exportData(drop = primary_key_1644);
				run;
			
			/*Now, finally, export it*/
			proc export data=exportData outfile= "&output_path./adstockVarCreation_viewPane.csv" dbms=csv replace;
				run;

			%include %unquote(%str(%'&genericCode_path./datasetprop_update.sas%'));
			
			data _null_;
				v1= "ADSTOCK_VARIABLE_CREATION_COMPLETED";
				file "&output_path/ADSTOCK_VARIABLE_CREATION_COMPLETED.txt";
				put v1;
			run;
		%end;
	%else
		%do;
			%if &eqn_type. ^= exponential %then %do;
				%let gamma_value=;
			%end;
			/*------------------------------------------------------------------------------------------------------------------------------*/
			/*The flow starts*/
			/*------------------------------------------------------------------------------------------------------------------------------*/
			/*------------------------------------------------------------------------------------------------------------------------------*/
			/*This if loop below is for across groupby*/
			/*------------------------------------------------------------------------------------------------------------------------------*/
			%if &grp_no. > 0 %then %do;
				/*------------------------------------------------------------------------------------------------------------------------------*/
				/*Creating the macro variable threeLetterWord & doing validation checks*/
				/*------------------------------------------------------------------------------------------------------------------------------*/
				%if &eqn_type. = simple %then %do;
					%let threeLetterWord = ags;
				%end;
				%if &eqn_type. = log %then %do;
					%let threeLetterWord = agl;
				%end;
				%if &eqn_type. = exponential %then %do;
					%if &transform_type. = simple %then %do;
						%let threeLetterWord = agxs;
					%end;
					%if &transform_type. = log %then %do;
						%let threeLetterWord = agxl;
					%end;
				%end;
				/*------------------------------------------------------------------------------------------------------------------------------*/

				/*Creating a dataset with the adstock variables selected, date variable selected & primary_key_1644*/

				%let var=grp&grp_no._flag;
				%put &var.;

				data in.adstockVarCreation_viewPane;
					set in.dataworking(keep = &grp_vars. &dependent_variable. &var_name. &date_variable. primary_key_1644 &var.);
					run;
				
		/*		data _null_;*/
		/*			call symput("piped_grp_vars",tranwrd("&grp_vars."," ","||"));*/
		/*			run;*/
		/*		%put &piped_grp_vars.;*/
		/**/
		/*		data in.adstockVarCreation_viewPane;*/
		/*			set in.adstockVarCreation_viewPane;*/
		/*			grp_vars_column = &piped_grp_vars.;*/
		/*			run;*/
		/**/
		/*		proc sql;*/
		/*			select distinct(grp_vars_column) into: distinct_grp_vars_column separated by "!!" from in.adstockVarCreation_viewPane;*/
		/*			run;*/
		/*			quit;*/
		/**/
		/*		%put &distinct_grp_vars_column.;*/





				proc sql;
					select distinct(&var.) into: distinct_grp_vars_column separated by "!!" from in.adstockVarCreation_viewPane;
					run;
					quit;

					/* The below macro needs macro variables &threeLetterWord. and &prefix. */
					%create_adstock_variables_panel(dataset=in.adstockVarCreation_viewPane,adstock_variable=&var_name.,dependent_variable=&dependent_variable.,date_variable=&date_variable.,decay_rate=&decay_rate.,gamma_value=&gamma_value.);
			%end;
			/*------------------------------------------------------------------------------------------------------------------------------*/
			/*This else loop below is for across dataset*/
			/*------------------------------------------------------------------------------------------------------------------------------*/
			%else %do;
				/*------------------------------------------------------------------------------------------------------------------------------*/
				/*Creating the macro variable threeLetterWord & doing validation checks*/
				/*------------------------------------------------------------------------------------------------------------------------------*/
				%if &eqn_type. = simple %then %do;
					%let threeLetterWord = ads;
				%end;
				%if &eqn_type. = log %then %do;
					%let threeLetterWord = adl;
				%end;
				%if &eqn_type. = exponential %then %do;
					%if &transform_type. = simple %then %do;
						%let threeLetterWord = adxs;
					%end;
					%if &transform_type. = log %then %do;
						%let threeLetterWord = adxl;
					%end;
				%end;
				/*------------------------------------------------------------------------------------------------------------------------------*/

				/*Creating a dataset with the adstock variables selected, date variable selected & primary_key_1644*/
				data in.adstockVarCreation_viewPane;
					set in.dataworking(keep = &dependent_variable. &var_name. &date_variable. primary_key_1644);
					run;
					
				/* The below macro needs macro variables &threeLetterWord. and &prefix. */
				%create_adstock_variables(dataset=in.adstockVarCreation_viewPane,adstock_variable=&var_name.,dependent_variable=&dependent_variable.,date_variable=&date_variable.,decay_rate=&decay_rate.,gamma_value=&gamma_value.);
			%end;		
			/*------------------------------------------------------------------------------------------------------------------------------*/

			/*------------------------------------------------------------------------------------------------------------------------------*/
			/*Creating a dataset with a column called decay having the decay rates selected*/
			/*This dataset will be merged with the correlation table*/
			/*------------------------------------------------------------------------------------------------------------------------------*/
			%do tempi = 1 %to %sysfunc(countw(&var_name.," "));
				%let current_var_name = %scan(&var_name.,&tempi.," ");
				%let extended_decay_rate = &extended_decay_rate.!!0;
				%let variables_used = &variables_used. &current_var_name.;
			%end;

			data temp_decay_gamma;
				%do tempi = 1 %to %sysfunc(countw(&extended_decay_rate.,"!!"));
					decay=%scan(&extended_decay_rate.,&tempi.,"!!");
					output;
				%end;
				stop;
				run;

			data tempp;
				format variables_used $32.;
				%do tempi = 1 %to %sysfunc(countw(&variables_used.," "));
					variables_used="%trim(%scan(&variables_used.,&tempi.," "))";
					output;
				%end;
				stop;
				run;

			data temp_decay_gamma;
				merge temp_decay_gamma tempp;
				run;
			
			%if &eqn_type. = exponential %then %do;
				%do tempi = 1 %to %sysfunc(countw(&var_name.," "));
					%let extended_gamma_value = &extended_gamma_value.!!1;
				%end;

				data tempp;
					%do tempi = 1 %to %sysfunc(countw(&extended_gamma_value.,"!!"));
						gamma=%scan(&extended_gamma_value.,&tempi.,"!!");
						output;
					%end;
					stop;
					run;

				data temp_decay_gamma;
					merge temp_decay_gamma tempp;
					run;
			%end;
			/*------------------------------------------------------------------------------------------------------------------------------*/

			/*------------------------------------------------------------------------------------------------------------------------------*/
			/*The correlation table*/
			/*------------------------------------------------------------------------------------------------------------------------------*/
			proc corr data = in.adstockVarCreation_viewPane out=in.correlation_table noprint;
				var &dependent_variable.;
				with &new_adstock_variables. &var_name.;
				run;

			data in.correlation_table(drop = _TYPE_ rename = (&dependent_variable. = correlation));
				set in.correlation_table;
				if _TYPE_ ne "CORR" then delete;
				run;
				
			data in.correlation_table(rename = (_NAME_ = actual_name));
				merge in.correlation_table temp_decay_gamma;
				run;

			%if &eqn_type. = exponential %then %do;
				%do tempi = 1 %to %sysfunc(countw(&var_name.," "));
					%let current_var_name = %scan(&var_name.,&tempi.," ");
					data tempp;
						set in.correlation_table;
						if variables_used = "&current_var_name.";
						run;

					proc sql;
						select correlation into: correlation_cutoff from tempp where decay=&base_decay. and gamma = &base_gamma.;
						quit;

					data tempp;
						set tempp;
						significance_flag=3;
						run;

					data tempp;
						set tempp;
						if decay = &base_decay. & gamma = &base_gamma. then significance_flag = 2;
						if correlation > %sysevalf(&correlation_cutoff.+&threshold.) then significance_flag = 1;
						run;

					data tempp;
						set tempp;
						format significance $15.;
						if significance_flag = 3 then significance = "Insignificant";
						if significance_flag = 2 then significance = "Base";
						if significance_flag = 1 then significance = "Significant";
						run;

					proc append base = tempp2 data = tempp force;
						run;
				%end;

				proc sort data = tempp2 out = in.correlation_table;
					by variables_used descending significance_flag;
					run;

				proc datasets;
					delete tempp tempp2 temp_decay_gamma;
					run;
					quit;

				data in.correlation_table;
					set in.correlation_table;
					run;
			%end;
			/*------------------------------------------------------------------------------------------------------------------------------*/
			
			/*------------------------------------------------------------------------------------------------------------------------------*/
			/*Create a temporary dataset called exportData(to be exported) from in.adstockVarCreation_viewPane*/
			/*excluding the column grp_vars_column(if it exists)*/
			/*and do whatever is necessary and export it*/
			/*------------------------------------------------------------------------------------------------------------------------------*/
			data exportData;
				set in.adstockVarCreation_viewPane(drop = &dependent_variable.);
				run;

			/*restriction on the no of rows in the output CSV*/
			%let dsid = %sysfunc(open(exportData));
			%let nobs=%sysfunc(attrn(&dsid,nobs));	
			%let rc = %sysfunc(close(&dsid));
			%put &nobs.;

			%if &nobs.>6000 %then %do;
				proc surveyselect data=exportData out=exportData method=SRS
					sampsize=6000 SEED=1234567;
					run;
			%end;
			
			/*Sort the dataset that is about to be exported by primary_key_1644*/
			proc sort data = exportData out = exportData;
				by primary_key_1644;
				run;
			
			/*Drop primary_key_1644 b4 exporting*/
			data exportData;
				set exportData(drop = primary_key_1644);
				run;
			
			/*Drop group variable if any b4 exporting*/
			%if &grp_no. > 0 %then %do;
			data exportData(drop= &var.);
				set exportData;
				run;
			%end;

			/*Now, finally, export it*/
			proc export data=exportData outfile= "&output_path./adstockVarCreation_viewPane.csv" dbms=csv replace;
				run;

			%if &eqn_type. = exponential %then %do;
				%do tempi = 1 %to %sysfunc(countw(&var_name_i.,"!!"));
					%let current_var_name = %scan(&var_name.,&tempi.," ");
					%let keepThis = &threeLetterWord.&tempi.;
					data tempp;
						set exportData(keep = &current_var_name. &date_variable. &keepThis.:);
						run;

					proc export data=tempp outfile="&output_path./&current_var_name..csv" dbms=csv replace;
						run;
				%end;
			%end;

			/*Export the correlation table*/
			proc export data = in.correlation_table outfile = "&output_path./correlation_table.csv" dbms=csv replace;
				run;
			
			data _null_;
				v1= "ADSTOCK_VARIABLE_CREATION_COMPLETED";
				file "&output_path/ADSTOCK_VARIABLE_CREATION_COMPLETED.txt";
				put v1;
				run;

		%end;
%mend;
/*------------------------------------------------------------------------------------------------------------------------------*/



/*------------------------------------------------------------------------------------------------------------------------------*/
/*Call the above defined macro*/
/*------------------------------------------------------------------------------------------------------------------------------*/
%let grp_vars=;
%ads;
/*------------------------------------------------------------------------------------------------------------------------------*/