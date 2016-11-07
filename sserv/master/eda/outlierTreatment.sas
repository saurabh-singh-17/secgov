/*Successfully converted to SAS Server Format*/
*processbody;
%let completedTXTPath =  &output_path/TREATMENT_COMPLETED.txt;
/* Version 2.4.1 */
dm log 'clear';
options mprint mlogic symbolgen mfile ;

proc printto log="&output_path/OutlierTreatment_Log.log";
run;
quit;
	
/*proc printto print="&output_path/OutlierTreatment_Output.out";*/
	

libname in "&input_path.";
libname out "&output_path.";
data _null_(keep=&var_list.);
	set in.Dataworking nobs=n;
	call symput('frequency',n);
	run;

%MACRO outlier_treatment2;
    %let lower=;
    %let upper=;

/* get the upper and lower values */
    %if "&outlier_type." = "perc" %then %do;
       %if "&perc_upper." ^= "" %then %do;
           %let upper = %sysevalf(&perc_upper.);
       %end;
       %if "&perc_lower." ^= "" %then %do;
           %let lower =%sysevalf(&perc_lower.);
        %end;
    %end;
    %else %if "&outlier_type." = "iqr" %then %do;
       %if "&outlier_side." = "two" %then %do;
           %let lower = %sysevalf(25);
          %let upper = %sysevalf(75);
       %end;
       %else %if "&outlier_side." = "one" %then %do;
           %let upper = %sysevalf(75);
       %end;
    %end;

/* LOOP through all the variables */
    %let i = 1;
    %do %until (not %length(%scan(&var_list,&i)));
           %let var = %scan(&var_list,&i);
           
       /* get statistic values - proc univariate */
       proc univariate data = in.dataworking(keep=&var.);
           var &var.;
           output out = out_pre_univ&i.
               mean = pre_mean
               median = pre_median
               mode = pre_mode
               qrange = iqr
			   %if "&upper." ^= "" or "&lower." ^="" %then %do;
               		pctlpts =  %if "&upper." ^= "" %then %do; &upper. %end; %if "&lower." ^= "" %then %do; &lower. %end;
			   		pctlpre = p_
			   %end; 
               ;
           run;quit;

       /* calculate outlier cut-offs & treatment value */
       data _null_;
           set out_pre_univ&i.;
           /*outlier*/
           %if "&outlier_type." = "iqr" %then %do;
               %if "&outlier_side." = "two" %then %do;
                  call symputx("outlier_lb&i.", compress(p_25 - (&iqr_value. * iqr)));
               %end;
               call symputx("outlier_ub&i.", compress(p_75 + (&iqr_value. * iqr)));
           %end;
           %else %if "&outlier_type." = "perc" %then %do;
               %if "&lower." ^= "" %then %do;
                  call symputx("outlier_lb&i.", %sysfunc(compress(p_%sysfunc(tranwrd(&lower.,.,_)))));
               %end;
               %if "&upper." ^= "" %then %do;
                  call symputx("outlier_ub&i.", %sysfunc(compress(p_%sysfunc(tranwrd(&upper.,.,_)))));          
               %end;
           %end;

           /*treatment value*/
           %if "&outlier_treatment." = "mean" or "&outlier_treatment." = "median" or "&outlier_treatment." = "mode"
               or "&outlier_treatment." = "capping" %then %do;

               %if "&outlier_treatment." = "mean" %then %do;
                  call symput ("outlier_val&i.", pre_mean);
               %end;
               %else %if "&outlier_treatment." = "median" %then %do;
                  call symput ("outlier_val&i.", pre_median);
               %end;
               %else %if "&outlier_treatment." = "mode" %then %do;
                  call symput ("outlier_val&i.", pre_mode);
               %end;
              
           %end;
           run;
	    
		%if "&outlier_side."="two" and "&outlier_type."="iqr" %then %do;
			%put lower bound : &&outlier_lb&i.;
			%put upper bound : &&outlier_ub&i.;
			%let low&i.=&&outlier_lb&i.;
	       	%let high&i.=&&outlier_ub&i.;
			proc sql;
				select count(&var.) into :num_outlier
				from in.dataworking
				where (&var. lt &&outlier_lb&i.) or (&var. gt &&outlier_ub&i.);
				quit;
				%put ................ &num_outlier;
		%end;
		%if "&outlier_side."="one" and "&outlier_type."="iqr" %then %do;
			%let high&i.=&&outlier_ub&i.;
			%put upper bound : &&outlier_ub&i.;
			proc sql;
			select count(&var.) into :num_outlier
			from in.dataworking
			where &var. gt &&outlier_ub&i.;
			quit;
		%end;
		%if "&outlier_type."="perc" %then %do;
			%let low&i.=&&outlier_lb&i.;
	       	%let high&i.=&&outlier_ub&i.;
			proc sql;
			select count(&var.) into :num_outlier
			from in.dataworking
			where (&var. lt &&outlier_lb&i.) or (&var. gt &&outlier_ub&i.);
			quit;
		%end;
		
       %if "&outlier_treatment." = "custom_type" %then %do;
           %let outlier_val&i. = %sysevalf(&outlier_treat_val.);
       %end;
       %put outlier_val = &&outlier_val&i..; 

       %put &&outlier_ub&i.;
       %put &&outlier_lb&i.;
       %if "&outlier_side." = "two" %then %do; 
           %put &&outlier_lb&i.; 
       %end;
       /* put var_name into the out_pre_univ table */
       data out_pre_univ&i.;
           length variable $32.;
           length treat_value $20.;
           set out_pre_univ&i.;
           attrib _all_ label="";
           variable = "&var.";
           drop iqr;
		   %if &outlier_type.=perc or (&outlier_type.=iqr and  &outlier_side.=two ) %then %do;
			   outlier_lb=&&outlier_lb&i.;
			   outlier_ub=&&outlier_ub&i.;
			   num_outlier =&num_outlier.; 
			   percentage_outlier = num_outlier/&frequency.;
		   %end;
		   %else %if (&outlier_type.=iqr and  &outlier_side.=one) %then %do;
	              outlier_ub=&&outlier_ub&i.;
				  num_outlier =&num_outlier.; 
				  percentage_outlier = num_outlier/&frequency.;
		   %end;
		   %else %do;
		   		rename %if "&upper." ^= "" %then %do; p_%sysfunc(tranwrd(&upper.,.,_)) = outlier_ub %end;
	           %if "&lower." ^= "" %then %do; p_%sysfunc(tranwrd(&lower.,.,_)) = outlier_lb %end;;
			%end;
           %if "&outlier_treatment." ^= "delete" and "&outlier_treatment." ^= "capping" %then %do;
               treat_value = "%sysevalf(&&outlier_val&i..)";
           %end;
           %else %if "&outlier_treatment." = "delete" %then %do;
               treat_value = " - ";
           %end;
           run;

       /*append the out_pre_univ tables*/
       proc append base = out_pre_univ data = out_pre_univ&i. force;
           run;

/*       proc datasets lib = work;*/
/*           delete out_pre_univ&i.;*/
/*           run;*/

       %let i = %eval(&i.+1);
    %end;

/* OUTLIER TREATMENT */
data in.dataworking;
    set in.dataworking;

    %let i = 1;
    %do %until (not %length(%scan(&var_list,&i)));
           %let t_var = %scan(&var_list,&i);
    
       %if "&lower." ^= "" and "&upper." ^= "" %then %do;
           if &t_var. > &&outlier_ub&i. or &t_var. < &&outlier_lb&i. then do;
       %end;
       %if "&lower." = "" and "&upper." ^= "" %then %do;
           if &t_var. > &&outlier_ub&i. then do;
       %end;
       %if "&lower." ^= "" and "&upper." = "" %then %do;
           if &t_var. < &&outlier_lb&i. then do;
       %end;

           %if "&outlier_treatment." ^= "delete" %then %do;
               %if ("&treatment_newVar." = "replace" or "&treatment_newVar." = "rename") and "&outlier_treatment." ^= "custom_type"%then %do;
						%if "&outlier_side."="two" or "&perc_lower." ^= "" %then %do;
			                  if &t_var. < &&low&i. then do;
			                          &t_var. = &&low&i.;
			                  end;
						%end;
	                    if &t_var. > &&high&i. then do;
	                          &t_var. = &&high&i.;
	                  	end;
               %end;
               %else %if "&treatment_newVar." = "new" and "&outlier_treatment." = "capping" %then %do;
					  	
			   		%if "&outlier_side."="two" or "&perc_lower." ^= "" %then %do;
						  if &t_var. < &&low&i. then do;
		                          &treatment_prefix._%substr(&t_var.,1,27) = &&low&i.;
		                  end;
					%end;
		                  if &t_var. > &&high&i. then do;
		                          &treatment_prefix._%substr(&t_var.,1,27) = &&high&i.;
		                  end;
               %end;

               %else %if ("&treatment_newVar." = "replace" or "&treatment_newVar." = "rename") and "&outlier_treatment." ^= "custom_type" %then %do;
			   		%if "&outlier_side."="two" or "&perc_lower." ^= "" %then %do;
						  if &t_var. < &&low&i. then do;
		                          &t_var. = %sysevalf(&&outlier_val&i..);
		                  end;
					%end;
		                  if &t_var. > &&high&i. then do;
		                         &t_var. = %sysevalf(&&outlier_val&i..);
		                  end;
               %end;
               %else %if "&treatment_newVar." = "new" %then %do;
			   		%if "&outlier_side."="two" or "&perc_lower." ^= "" %then %do;
						  if &t_var. < &&low&i. then do;
      				            &treatment_prefix._%substr(&t_var.,1,27) = %sysevalf(&&outlier_val&i..);
		                  end;
					%end;
		                  if &t_var. > &&high&i. then do;
 			                    &treatment_prefix._%substr(&t_var.,1,27) = %sysevalf(&&outlier_val&i..);
		                  end;
               %end;

			   %if ("&treatment_newVar." = "replace" or "&treatment_newVar." = "rename") and "&outlier_treatment." = "custom_type" %then %do;
					%if "&outlier_side."="two" or "&perc_lower." ^= "" %then %do;
						  if &t_var. < &&low&i. then do;
		                          &t_var. = &outlier_treat_val.;
		                  end;
					%end;
		                  if &t_var. > &&high&i. then do;
		                         &t_var. = &outlier_treat_val.;
						  end;
			   %end;
			   %else %if "&treatment_newVar." = "new" and "&outlier_treatment." = "custom_type" %then %do;
			   		%if "&outlier_side."="two" or "&perc_lower." ^= "" %then %do;
						  if &t_var. < &&low&i. then do;
      				            &treatment_prefix._%substr(&t_var.,1,27) =&outlier_treat_val.;
		                  end;
					%end;
		                  if &t_var. > &&high&i. then do;
 			                    &treatment_prefix._%substr(&t_var.,1,27) = &outlier_treat_val.;
		                  end;
			   %end;
           %end;
           %else %if "&outlier_treatment." = "delete" %then %do;
               delete;
           %end;
       end;
       else do;
           %if "&outlier_treatment." ^= "delete" and "&treatment_newVar." = "new"  %then %do;
               &treatment_prefix._%substr(&t_var.,1,27) = &t_var.;
           %end;

       end;

       %let i = %eval(&i.+1);
    %end;
    run;
	%if "&outlier_treatment." = "delete" %then %do;
	%let dsid = %sysfunc(open(in.dataworking));
		%let nobs=%sysfunc(attrn(&dsid,nobs));	
		%let rc = %sysfunc(close(&dsid));
	%put &nobs.;

	data _null_;
      		v1= &nobs.;
      		file "&output_path./noobs_refresh.txt";
      		put v1;
		run;
		%end;

/*POST_TREATMENT univ-summary*/
%let i = 1;
%do %until (not %length(%scan(&var_list,&i)));
       %let p_var = %scan(&var_list,&i);

    proc univariate data = in.dataworking;
       %if "&treatment_newVar." = "replace" or "&treatment_newVar." = "rename" %then %do;
           var &p_var.;
       %end;
       %else %if "&treatment_newVar." = "new" %then %do;
           var &treatment_prefix._%substr(&p_var.,1,27);
       %end;
       output out = out_post_univ&i.
           mean = post_mean
           median = post_median
           mode = post_mode
           pctlpts = 0 to 0.8 by 0.2 1 to 5 by 1 25 75 95 to 98 by 1 99 to 100 by 0.1 
           pctlpre = p_
           ;
       run;

    /* put var_name into the out_post_univ table */
    data out_post_univ&i.;
       length variable $32.;
       length treat_value $20.;
       set out_post_univ&i.;
       attrib _all_ label="";
       variable = "&p_var.";
       %if "&outlier_treatment." ^= "delete" and "&outlier_treatment." ^= "capping" %then %do;
           treat_value = "%sysevalf(&&outlier_val&i..)";
       %end;
       %else %if "&outlier_treatment." = "delete" %then %do;
           treat_value = " - ";
       %end;
       run;

    /*append the out_pre_univ tables*/
    proc append base = out_post_univ data = out_post_univ&i. force;
       run;

/*    proc datasets lib = work;*/
/*       delete out_post_univ&i.;*/
/*       run;*/

    %let i = %eval(&i.+1);
%end;

/*creating the treatment history table*/
proc sort data = out_pre_univ;
    by variable;
    run;
proc sort data = out_post_univ;
    by variable;
    run;

data outlier_treatment;
    merge out_pre_univ(in=a) out_post_univ(in=b);
    by variable;
    if a or b;
    run;

data outlier_treatment;
    retain variable perc_iqr num_outlier percentage_outlier treatment treat_value replace_type pre_mean pre_median pre_mode post_mean post_median;
    set outlier_treatment;
    treatment = "&outlier_treatment.";
    perc_iqr = "&iqr_value.";
    replace_type = "&treatment_newVar.";
    run;

proc export data = outlier_treatment
    outfile = "&output_path./outlier_treatment.csv"
    dbms = csv replace;
    run;

%MEND outlier_treatment2;
%outlier_treatment2;
/* flex uses this file to test if the code has finished running */
data _null_;
    v1= "EDA - OUTLIER_TREATMENT_COMPLETED";
    file "&output_path/TREATMENT_COMPLETED.txt";
    put v1;
    run;


