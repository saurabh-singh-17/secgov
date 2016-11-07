/*Successfully converted to SAS Server Format*/
*processbody;
%let completedTXTPath =  &output_path./CORRELATION_NEWVAR_COMPLETED.TXT;
options mprint mlogic symbolgen  mfile;

libname in "&input_path.";
libname out "&output_path.";

proc printto log="&output_path/corr_newVar_log.log";
run;
quit;
	
/*proc printto print="&output_path/corr_newVar_output.out";*/
	


%MACRO corr_newVar;
/*extract data from CSV*/
    data corr_varCreation;
    infile "&csv_path./corr_varCreation.csv" delimiter = ',' MISSOVER DSD lrecl=32767 firstobs=2 ;
		length xvar $32.;
		length transform $15.;
		informat xvar $32.; informat transform $15.;
    	format xvar $32.; format transform $15.;
    	input xvar $ transform $;
		run;

proc sql;
select count(*) into :count_tot from corr_varCreation where index(transform,"lead") = 0;
quit;
%put &count_tot.;

%if &count_tot. ^= 0 %then %do;
/*create macro-vars for variables and transforms*/
	proc sql;
		select (xvar) into :xvars separated by " " from corr_varCreation where index(transform,"lead") = 0;
		select (transform) into :tranz separated by "!!" from corr_varCreation where index(transform,"lead") = 0;
		quit;
	%put &xvars;
	%put &tranz;

%if %index(&trans, lag) > 0 or %index(&trans, decay) > 0 or %index(&trans, lead) > 0 %then %do;
	proc sort data=in.&dataset_name.;
	by &dateVarName.;
	run;
	quit;
	%end;	
 
/*create new variables*/
	data in.&dataset_name.;
		set in.&dataset_name.;
		/*loop through all the variables*/
		%let i = 1;
		%do %until (not %length(%scan(&xvars,&i)));
		
			/*get the name of current variable and corresponding transform*/
			%let var = %scan(&xvars,&i);
			%let trans = %scan(&tranz,&i,"!!");

			/*lag*/
			%if %index(&trans, lag) > 0 %then %do;
				%let lag = %scan(&trans,2," - ");
				&prefix._lag&lag._%substr(&var.,1,22) = lag&lag.(&var);
			%end;

			/*adstock*/
			%else %if %index(&trans, decay) > 0 %then %do;
				%let decay = %scan(&trans,2," - ");
				%let decay_label = %sysfunc(tranwrd(&decay., ., _));
				
				/*retain the new adstock variable*/
				retain &prefix._ad_&decay_label._%substr(&var.,1,21);
				
				/*simple adstock transform*/
				%if "&adstock_type." = "simple" %then %do;
					if _n_ = 1 then do;
						&prefix._ad_&decay_label._%substr(&var.,1,21) = &var.;
					end;
					else do;
						&prefix._ad_&decay_label._%substr(&var.,1,21) = &var. + (%sysevalf(&decay.)*(&prefix._ad_&decay_label._%substr(&var.,1,21)));
					end;
				%end;
				/*log adstock transform*/
				%if "&adstock_type." = "log" %then %do;
					if _n_ = 1 then do;
						&prefix._ad_&decay_label._%substr(&var.,1,21) = &var.;
					end;
					else do;
						&prefix._ad_&decay_label._%substr(&var.,1,21) = log(&var.) + (%sysevalf(&decay.)*(&prefix._ad_&decay_label._%substr(&var.,1,21)));
					end;
				%end;
			%end;

			/*transformations*/
			%else %if %index(&trans, Reciprocal) > 0 %then %do;
				&prefix._rec_%substr(&var.,1,22) = (1/&var.);
			%end;
			%else %if %index(&trans, Square) > 0 %then %do;
				&prefix._sqr_%substr(&var.,1,22) = (&var.)*(&var.);
			%end;
			%else %if %index(&trans, Cube) > 0 %then %do;
				&prefix._cub_%substr(&var.,1,22) = (&var.)*(&var.)*(&var.);
			%end;
			%else %if %index(&trans, Log) > 0 %then %do;
				&prefix._log_%substr(&var.,1,22) = log(&var.);
			%end;
			%else %if %index(&trans, Sine) > 0 %then %do;
				&prefix._sin_%substr(&var.,1,22) = sin(&var.);
			%end;
			%else %if %index(&trans, Cosine) > 0 %then %do;
				&prefix._cos_%substr(&var.,1,22) = cos(&var.);
			%end;
			/*  box - cox */
			%else %do;
				&prefix._box_%sysfunc(translate(%scan(&trans ,1, " "),'_______________________________',"~@#$%^&*()_+{}|:<>?`-=[]/,./; '"))_%substr(&var., 1, 15) = &var. ** &trans.;
/*				&prefix._box_%scan(&trans , 2 , "_")_%substr(&var.,1,22) = &var. ** %scan(&trans , 2 , "_");*/
			
			%end;

			%let i = %eval(&i.+1);	
		%end;
		run;
%end;
/*===================================================================================================================*/
/*LEAD VARIABLES*/
	proc sql;
		select count(*) into :count_ld from corr_varCreation where index(transform,"lead") ^= 0;
		quit;
	%put &count_ld.;

	%if &count_ld. ^= 0 %then %do;
		proc sql;
			select (xvar) into :ld_xvars separated by " " from corr_varCreation where index(transform,"lead") ^= 0;
			select (transform) into :ld_tranz separated by "!!" from corr_varCreation where index(transform,"lead") ^= 0;
			quit;
		%put &ld_xvars;
		%put &ld_tranz;


/*		proc sort data = in.dataworking;*/
/*			by descending primary_key_1644;*/
/*			run;*/

		data in.&dataset_name.;
			set in.&dataset_name.;
			/*loop through all the variables*/
			%let i = 1;
			%do %until (not %length(%scan(&ld_xvars,&i)));
			
				/*get the name of current variable and corresponding transform*/
				%let var = %scan(&ld_xvars,&i);
				%let trans = %scan(&ld_tranz,&i,"!!");

				/*lead*/
				%if %index(&trans, lead) > 0 %then %do;
					%let lead = %scan(&trans,2," - ");
					&prefix._ld&lead._%substr(&var.,1,22) = lag&lead.(&var);
				%end;

				%let i = %eval(&i.+1);	
			%end;
			run;

		proc sort data = in.dataworking;
			by primary_key_1644;
			run;
	%end;

/*###################################################################################################################*/
/*list of new variables*/
	proc sql;
		select (xvar) into :all_xvars separated by " " from corr_varCreation;
		select (transform) into :all_tranz separated by "!!" from corr_varCreation;
		quit;
	%put &all_xvars;
	%put &all_tranz;

	data newVar;
		length newVar $32.;
		%let i = 1;
		%do %until (not %length(%scan(&all_xvars,&i)));
		
			%let var = %scan(&all_xvars,&i);
			%let trans = %scan(&all_tranz,&i,"!!");

			%if %index(&trans, lag) > 0 %then %do;
				%let lag = %scan(&trans,2," - ");
				newVar = "&prefix._lag&lag._%substr(&var.,1,22)";
			%end;
			%else %if %index(&trans, lead) > 0 %then %do;
				%let lead = %scan(&trans,2," - ");
				newVar = "&prefix._ld&lead._%substr(&var.,1,22)";
			%end;
			%else %if %index(&trans, decay) > 0 %then %do;
				%let decay = %scan(&trans,2," - ");
				%let decay_label = %sysfunc(tranwrd(&decay., ., _));
				newVar = "&prefix._ad_&decay_label._%substr(&var.,1,21)";
			%end;
			%else %if %index(&trans, Reciprocal) > 0 %then %do;
				newVar = "&prefix._rec_%substr(&var.,1,22)";
			%end;
			%else %if %index(&trans, Square) > 0 %then %do;
				newVar = "&prefix._sqr_%substr(&var.,1,22)";
			%end;
			%else %if %index(&trans, Cube) > 0 %then %do;
				newVar = "&prefix._cub_%substr(&var.,1,22)";
			%end;
			%else %if %index(&trans, Log) > 0 %then %do;
				newVar = "&prefix._log_%substr(&var.,1,22)";
			%end;
			%else %if %index(&trans, Sine) > 0 %then %do;
				newVar = "&prefix._sin_%substr(&var.,1,22)";
			%end;
			%else %if %index(&trans, Cosine) > 0 %then %do;
				newVar = "&prefix._cos_%substr(&var.,1,22)";
			%end;
			/* box-cox */
			%else %do;
				newVar = "&prefix._box_%sysfunc(translate(&trans,'_______________________________','~@#$%^&*()_+{}|:<>?`-=[]/,./; '))_%substr(&var., 1, 15)";
			%end;
			output;
			%let i = %eval(&i.+1);	
		%end;
		run;

	proc export data = newVar
		outfile = "&output_path./corr_newVar.csv"
		dbms = csv replace;
		run;


%MEND corr_newVar;
%corr_newVar;

/*======================================================*/
/* code for updating the dataset properties information*/
/*====================================================== */
%include %unquote(%str(%'&genericCode_path./datasetprop_update.sas%'));
/*--------------------------------------------------------*/

/* flex uses this file to test if the code has finished running */
data _null_;
v1= "EDA - CORRELATION - NEWVAR - COMPLETED";
file "&output_path./CORRELATION_NEWVAR_COMPLETED.TXT";
put v1;
run;


/*ENDSAS;*/



