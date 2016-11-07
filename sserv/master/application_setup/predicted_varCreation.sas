*processbody;
options mprint mlogic symbolgen mfile;

proc printto log="&input_path./Predicted_VarCreation_Log.log" new;run;quit;
/*proc printto;run;quit;*/

filename myfile "&input_path./PREDICTED_VAR_CREATION_COMPLETED.txt";

data _null_;
	rc=fdelete("myfile");
run;

libname in "&input_path.";
libname iter "&iteration_path.";

%MACRO pred_varCreation;

      proc sort data = &dataset_name.;
            by primary_key_1644;
            run;quit;

      %if "&type_model." = "linear" %then %do;
            proc sort data = iter.outdata;
                  by primary_key_1644;
                  run;quit;

            data &dataset_name.(rename=(pred=&newVar_pred.));
                  merge &dataset_name.(in=ds1) iter.outdata(in=ds2 keep=primary_key_1644 pred);
                  by primary_key_1644;
                  if ds1 or ds2;
                  run;

            data &dataset_name.(drop=&newVar_pred.);
                  set &dataset_name.;
                  Predicted = &newVar_pred.*1;
                  run;

            data &dataset_name.(rename = (Predicted=&newVar_pred.));
                  set &dataset_name.;
                  run;

      %end;

      %if "&type_model." = "logistic" %then %do;
            proc sort data = iter.pred;
                  by primary_key_1644;
                  run;quit;

            data &dataset_name.(rename=(%if "&newVar_pred." ^= "" %then %do; phat=&newVar_pred. %end; %if "&newVar_resp." ^= "" %then %do; _INTO_=&newVar_resp. %end;));
                  merge &dataset_name.(in=ds1) iter.pred(in=ds2 keep=primary_key_1644 %if "&newVar_pred." ^= "" %then %do;phat %end; %if "&newVar_resp." ^= "" %then %do; _INTO_ %end;);
                  by primary_key_1644;
                  if ds1 or ds2;
                  run;
            
			%if "&newVar_resp." ^= "" %then %do;
				%let dsid = %sysfunc(open(&dataset_name.));
				%let varnum = %sysfunc(varnum(&dsid,&newVar_resp.));
				%let vartype_newVar_resp = %sysfunc(vartype(&dsid,&varnum));
				%let rc = %sysfunc(close(&dsid));
			%end;
			
            data &dataset_name.(rename=(%if "&newVar_pred." ^= "" %then %do;&newVar_pred. %end; %if "&newVar_resp." ^= "" %then %do; &newVar_resp. %end;));
                set &dataset_name.;
				%if "&newVar_pred." ^= "" %then %do;
					Predicted = &newVar_pred.*1;
				%end;	
				%if "&newVar_resp." ^= "" %then %do;
					%if &vartype_newVar_resp. = N %then %do;
						Response = &newVar_resp.*1;
					%end;
				%end;
				run;

            data &dataset_name.(rename=(%if "&newVar_pred." ^= "" %then %do;Predicted=&newVar_pred. %end; 
                                                      %if "&newVar_resp." ^= "" %then %do; Response = &newVar_resp. %end;));
                  set &dataset_name.;
                  run;

      %end;

	   %if "&type_model." = "mixed" %then %do;
            proc sort data = iter.mixedoutput;
                  by primary_key_1644;
                  run;quit;

            data &dataset_name.(rename=(pred=&newVar_pred.));
                  merge &dataset_name.(in=ds1) iter.mixedoutput(in=ds2 keep=primary_key_1644 Pred);
                  by primary_key_1644;
                  if ds1 or ds2;
                  run;

            data &dataset_name.(drop=&newVar_pred.);
                  set &dataset_name.;
                  Predicted = &newVar_pred.*1;
                  run;

            data &dataset_name.(rename = (Predicted=&newVar_pred.));
                  set &dataset_name.;
                  run;

      %end;

	  %if "&type_model." = "genmod" %then %do;
            proc sort data = iter.pred_var;
                  by primary_key_1644;
                  run;quit;

            data &dataset_name.(rename=(pred=&newVar_pred.));
                  merge &dataset_name.(in=ds1) iter.pred_var(in=ds2 keep=primary_key_1644 pred);
                  by primary_key_1644;
                  if ds1 or ds2;
                  run;

            data &dataset_name.(drop=&newVar_pred.);
                  set &dataset_name.;
                  Predicted = &newVar_pred.*1;
                  run;

            data &dataset_name.(rename = (Predicted=&newVar_pred.));
                  set &dataset_name.;
                  run;

      %end;

	  %if "&type_model." = "arimax" %then %do;

		  data temp;
		  set iter.forecast;
		  run;

		  data temp;
		  set temp;
		  primary_key_1644 = _n_;
		  run;

            proc sort data = temp;
                  by primary_key_1644;
                  run;quit;

            data &dataset_name.(rename=(FORECAST=&newVar_pred.));
                  merge &dataset_name.(in=ds1) temp(in=ds2 keep=primary_key_1644 FORECAST);
                  by primary_key_1644;
                  if ds1 or ds2;
                  run;

            data &dataset_name.(drop=&newVar_pred.);
                  set &dataset_name.;
                  Predicted = &newVar_pred.*1;
                  run;

            data &dataset_name.(rename = (Predicted=&newVar_pred.));
                  set &dataset_name.;
                  run;

      %end;
	  
	  %if &type_model. = lcm %then
	  	%do;
			%let c_var_new = &newVar_pred.;
			%if "&id_var." ^= "" %then %let c_var_id  = &id_var.;
			%else %let c_var_id  = primary_key_1644;
			
			proc import datafile="&iteration_path./residual.csv" out=residual dbms=csv;run;quit;

			proc sql noprint;
				create table in.dataworking as
					select a1.*, a2.cluster as &c_var_new.
						from in.dataworking a1 left join residual a2
							on a1.&c_var_id. = a2.id;
			run;
			quit;
		%end;

	%if &type_model. = lca %then
	  	%do;
			%let c_var_new = &newVar_pred.;

			proc import datafile="&iteration_path./clusterprobability.csv" out=clusterprobability dbms=csv;run;quit;

			proc contents data=clusterprobability(drop=prob_: murx_cluster_variable murx_count_variable) out=temp;run;quit;
			
			%let dsid = %sysfunc(open(clusterprobability));
			%let varnum = %sysfunc(varnum(&dsid, murx_cluster_variable));
			%let vartyp = %sysfunc(vartype(&dsid, &varnum)); /* variable type */
			%let rc = %sysfunc(close(&dsid));
			
			%if &vartyp. = C %then
				%do;
					data clusterprobability(drop = murx_cluster_variable rename = (temp_cluster_variable = murx_cluster_variable));
						set clusterprobability;
						temp_cluster_variable = murx_cluster_variable * 1;
					run;
				%end;
			
			proc sql;
				select name into: c_var_by separated by " " from temp;
			run;
			quit;

			%let c_st_on = ;
			%let c_sep   = ;
			%do tempi = 1 %to %sysfunc(countw(&c_var_by., %str( )));
				%let c_var_by_now = %scan(&c_var_by., &tempi., %str( ));

				%let c_st_on = &c_st_on. &c_sep. a1.&c_var_by_now. = a2.&c_var_by_now.;
				%let c_sep   = and;
			%end;

			proc sql noprint;
				create table in.dataworking as
					select a1.*, a2.murx_cluster_variable as &c_var_new.
						from in.dataworking a1 left join clusterprobability a2
							on &c_st_on.;
			run;
			quit;
		%end;


		%if "&type_model." = "glm" %then %do;
            proc sort data = iter.glmoutput;
                  by primary_key_1644;
                  run;quit;

            data &dataset_name.(rename=(pred=&newVar_pred.));
                  merge &dataset_name.(in=ds1) iter.glmoutput(in=ds2 keep=primary_key_1644 pred);
                  by primary_key_1644;
                  if ds1 or ds2;
                  run;

            data &dataset_name.(drop=&newVar_pred.);
                  set &dataset_name.;
                  Predicted = &newVar_pred.*1;
                  run;

            data &dataset_name.(rename = (Predicted=&newVar_pred.));
                  set &dataset_name.;
                  run;

      %end;
	  
	%if &type_model. = agglomerative %then
		%do;
			%let c_var_key = primary_key_1644;

			proc sql;
				create table in.dataworking as
					select a1.*, a2.cluster as &newVar_pred.
						from in.dataworking a1 left join iter.final_cluster a2
							on a1.&c_var_key. = a2.&c_var_key.;
			quit;
		%end;
		
	%if &type_model. = kmeans %then
		%do;
			%let c_var_key = primary_key_1644;

			proc sql;
				create table in.dataworking as
					select a1.*, a2.murx_n_cluster as &newVar_pred.
						from in.dataworking a1 left join iter.final_cluster a2
							on a1.&c_var_key. = a2.&c_var_key.;
			quit;
		%end;

%MEND pred_varCreation;
%pred_varCreation;

%include "&genericCode_path./datasetprop_update.sas";

/* flex uses this file to test if the code has finished running */
data _null_;
	v1= "PREDICTED_VAR_CREATION_COMPLETED";
	file "&input_path./PREDICTED_VAR_CREATION_COMPLETED.txt";
	put v1;
run;

proc datasets lib=work kill nolist;
quit;