/*Successfully converted to SAS Server Format*/
*processbody;
%let completedTXTPath =  &output_path/MULTIVAR_TREATMENT_COMPLETED.txt;
/* VERSION # 1.1.0 */

options mprint mlogic symbolgen mfile ;

proc printto log="&output_path/MultiVar_Treatment_Log.log";
run;
quit;
  
/*proc printto print="&output_path/MultiVar_Treatment_Output.out";*/
  

libname in "&input_path.";
libname out "&output_path.";


%MACRO outlier_treatment;
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
       
       %if "&flag_missing." = "true" and "&pref." = "missing" and "&treatment_newVar." = "new" %then %do;
           %let var = &treatment_prefix._%scan(&var_list,&i);
       %end;
       %else %do;
           %let var = %scan(&var_list,&i);
       %end;
           
       /* get statistic values - proc univariate */
       proc univariate data = in.dataworking(keep=&var.);
           var &var.;
           output out = out_pre_univ&i.
               mean = pre_mean
               median = pre_median
               mode = pre_mode
               qrange = iqr
               pctlpts =  %if "&upper." ^= "" %then %do; &upper. %end; %if "&lower." ^= "" %then %do; &lower. %end;
               pctlpre = p_ 
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
		%end;
		%if "&outlier_side."="one" and "&outlier_type."="iqr" %then %do;
			%let high&i.=&&outlier_ub&i.;
			%put upper bound : &&outlier_ub&i.;
		%end;
		%if "&outlier_type."="perc" %then %do;
			%let low&i.=&&outlier_lb&i.;
	       	%let high&i.=&&outlier_ub&i.;
		%end;

/*		%if "&outlier_treatment." = "capping" %then %do;*/
/*	               */
/*	       %let low&i.=&&outlier_lb&i.;*/
/*	       %let high&i.=&&outlier_ub&i.;*/
/*	       %put &&low&i. &&high&i.;*/
/*		%end;*/
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
           rename %if "&upper." ^= "" %then %do; p_%sysfunc(tranwrd(&upper.,.,_)) = outlier_ub %end;
           %if "&lower." ^= "" %then %do; p_%sysfunc(tranwrd(&lower.,.,_)) = outlier_lb %end;;
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

       proc datasets lib = work;
           delete out_pre_univ&i.;
           run;

       %let i = %eval(&i.+1);
    %end;

/* OUTLIER TREATMENT */
data in.dataworking;
    set in.dataworking;

    %let i = 1;
    %do %until (not %length(%scan(&var_list,&i)));

       %if "&flag_missing." = "true" and "&pref." = "missing" and "&treatment_newVar." = "new" %then %do;
           %let t_var = &treatment_prefix._%scan(&var_list,&i);
           %let treatment_newVar = replace;
       %end;
       %else %do;
           %let t_var = %scan(&var_list,&i);
       %end;
    
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
               %if "&treatment_newVar." = "replace" or "&treatment_newVar." = "rename" %then %do;
			   		%if "&outlier_treatment." = "capping" %then %do;
						%if "&outlier_side."="two" %then %do;
			                  if &t_var. < &&low&i. then do;
			                          &t_var. = &&low&i.;
			                  end;
						%end;
	                    if &t_var. > &&high&i. then do;
	                          &t_var. = &&high&i.;
	                  	end;
					%end;
               %end;
               %else %if "&treatment_newVar." = "new" and "&outlier_treatment." = "capping" %then %do;
					  	
			   		%if "&outlier_side."="two" %then %do;
						  if &t_var. < &&low&i. then do;
		                          &treatment_prefix._%substr(&t_var.,1,27) = &&low&i.;
		                  end;
					%end;
		                  if &t_var. > &&high&i. then do;
		                          &treatment_prefix._%substr(&t_var.,1,27) = &&high&i.;
		                  end;
               %end;

               %else %if "&treatment_newVar." = "replace" or "&treatment_newVar." = "rename" %then %do;
                  &t_var. = %sysevalf(&&outlier_val&i..);
               %end;
               %else %if "&treatment_newVar." = "new" %then %do;
                  &treatment_prefix._%substr(&t_var.,1,27) = %sysevalf(&&outlier_val&i..);
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

/*POST_TREATMENT univ-summary*/
%let i = 1;
%do %until (not %length(%scan(&var_list,&i)));

    %if "&flag_missing." = "true" and "&pref." = "missing" and "&treatment_newVar." = "new" %then %do;
       %let p_var = &treatment_prefix._%scan(&var_list,&i);
    %end;
    %else %do;
       %let p_var = %scan(&var_list,&i);
    %end;

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

    proc datasets lib = work;
       delete out_post_univ&i.;
       run;

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
    retain variable   perc_iqr treatment treat_value replace_type pre_mean pre_median pre_mode post_mean post_median;
    set outlier_treatment;
    treatment = "&outlier_treatment.";
    perc_iqr = "&iqr_value.";
    replace_type = "&treatment_newVar.";
    run;

proc export data = outlier_treatment
    outfile = "&output_path./outlier_treatment.csv"
    dbms = csv replace;
    run;

%MEND outlier_treatment;



%MACRO missing_treatment3;

/*LOOP through all the variables*/
%let i = 1;
%do %until (not %length(%scan(&var_list,&i)));

    %if "&flag_outlier." = "true" and "&pref." = "outlier" and "&treatment_newVar." = "new" %then %do;
       %let var = &treatment_prefix._%scan(&var_list,&i);
    %end;
    %else %do;
       %let var = %scan(&var_list,&i);
    %end;

    /*univariate summary*/
    proc univariate data = in.dataworking(keep=&var.);
       var &var.;
       output out = mis_pre_univ&i.
           mean = pre_mean
           median = pre_median
           mode = pre_mode
           %if "&missing_treatment." = "capping" %then %do;
               pctlpts = &missing_treat_val.
               pctlpre = p_
           %end;
           ;
           run;

    /*get the treatment value*/
    %if "&missing_treatment." = "mean" or "&missing_treatment." = "median" or "&missing_treatment." = "mode"
       or "&missing_treatment." = "capping" %then %do;
       data _null_;
           set mis_pre_univ&i.;
           %if "&missing_treatment." = "mean" %then %do;
               call symput ("missing_val&i.", pre_mean);
           %end;
           %else %if "&missing_treatment." = "median" %then %do;
               call symput ("missing_val&i.", pre_median);
           %end;
           %else %if "&missing_treatment." = "mode" %then %do;
               call symput ("missing_val&i.", pre_mode);
           %end;
           %else %if "&missing_treatment." = "capping" %then %do;
               call symput ("missing_val&i.", %sysfunc(tranwrd(&missing_treat_val.,.,_)));
           %end;
           run;
    %end;
    %else %if "&missing_treatment." = "custom_type" %then %do;
       %let missing_val&i. = %sysevalf(&missing_treat_val.);
    %end;
    %put missing_val = &&missing_val&i..; 

    /* put var_name into the mis_pre_univ table */
    data mis_pre_univ&i.;
       length variable $32.;
       set mis_pre_univ&i.;
       attrib _all_ label="";
       variable = "&var.";
       %if "&missing_treatment." = "capping" %then %do;
           drop %sysfunc(tranwrd(&missing_treat_val.,.,_));
       %end;
       run;

    /*append the mis_pre_univ tables*/
    proc append base = mis_pre_univ data = mis_pre_univ&i. force;
       run;

    proc datasets lib = work;
       delete mis_pre_univ&i.;
       run;

    %let i = %eval(&i.+1);
%end;

/* MISSING TREATMENT */
data in.dataworking;
    set in.dataworking;
    
    %let i = 1;
    %do %until (not %length(%scan(&var_list,&i)));

       %if "&flag_outlier." = "true" and "&pref." = "outlier" and "&treatment_newVar." = "new" %then %do;
           %let t_var = &treatment_prefix._%scan(&var_list,&i);
           %let treatment_newVar = replace;
       %end;
       %else %do;
           %let t_var = %scan(&var_list,&i);
       %end;
       
       if &t_var. = . %if "&missing_spl." ^= "" %then %do; or &t_var. in (&missing_spl.) %end; then do;
           %if "&missing_treatment." ^= "delete" %then %do;
               %if "&treatment_newVar." = "replace" or "&treatment_newVar." = "rename" %then %do;
                  &t_var. = %sysevalf(&&missing_val&i..);
               %end;
               %else %if "&treatment_newVar." = "new" %then %do;
                  &treatment_prefix._%substr(&t_var.,1,25) = %sysevalf(&&missing_val&i..);
               %end;
           %end;
           %else %if "&missing_treatment." = "delete" %then %do;
               delete;
           %end;
       end;
       else do;
           %if "&missing_treatment." ^= "delete" and "&treatment_newVar." = "new" %then %do;
               &treatment_prefix._%substr(&t_var.,1,25) = &t_var.;
           %end;
       end;
       %let i = %eval(&i.+1);
    %end;
    run;

/*POST_TREATMENT univ-summary*/
%let i = 1;
%do %until (not %length(%scan(&var_list,&i)));

    %if "&flag_outlier." = "true" and "&pref." = "outlier" and "&treatment_newVar." = "new" %then %do;
       %let p_var = &treatment_prefix._%scan(&var_list,&i);
    %end;
    %else %do;
       %let p_var = %scan(&var_list,&i);
    %end;

    proc univariate data = in.dataworking;
       %if "&treatment_newVar." = "replace" or "&treatment_newVar." = "rename" %then %do;
           var &p_var.;
       %end;
       %else %if "&treatment_newVar." = "new" %then %do;
           var &treatment_prefix._%substr(&p_var.,1,27);
       %end;
       output out = mis_post_univ&i.
           mean = post_mean
           median = post_median
           mode = post_mode
           pctlpts = 0 to 0.8 by 0.2 1 to 5 by 1 25 75 95 to 98 by 1 99 to 100 by 0.1 
           pctlpre = p_
           ;
       run;

    /* put var_name into the mis_post_univ table */
    data mis_post_univ&i.;
       length variable $32.;
       length treat_value $20.;
       set mis_post_univ&i.;
       attrib _all_ label="";
       variable = "&p_var.";
       %if "&missing_treatment." ^= "delete" %then %do;
           treat_value = "%sysevalf(&&missing_val&i..)";
       %end;
       %else %if "&missing_treatment." = "delete" %then %do;
           treat_value = " - ";
       %end;
       run;

    /*append the mis_pre_univ tables*/
    proc append base = mis_post_univ data = mis_post_univ&i. force;
       run;

    proc datasets lib = work;
       delete mis_post_univ&i.;
       run;

    %let i = %eval(&i.+1);
%end;

/*creating the treatment history table*/
proc sort data = mis_pre_univ;
    by variable;
    run;
proc sort data = mis_post_univ;
    by variable;
    run;

data missing_treatment;
    merge mis_pre_univ(in=a) mis_post_univ(in=b);
    by variable;
    if a or b;
    run;

data missing_treatment;
    retain variable spl_chars treatment treat_value replace_type pre_mean pre_median pre_mode post_mean post_median;
    set missing_treatment;
    treatment = "&missing_treatment.";
    %if "&missing_spl." ^= "" %then %do;
       spl_chars = "&missing_spl.";
    %end;
    %else %if "&missing_spl." = "" %then %do;
       spl_chars = "N.A.";
    %end;
    replace_type = "&treatment_newVar.";
    run;

proc export data = missing_treatment
    outfile = "&output_path./missing_treatment.csv"
    dbms = csv replace;
    run;

%MEND missing_treatment3;


%MACRO variable_treatment;

%if "&flag_outlier." = "true" and "&flag_missing." = "false" %then %do;
    %outlier_treatment;
%end;
%else %if "&flag_outlier." = "false" and "&flag_missing." = "true" %then %do;
    %missing_treatment3;
%end;
%else %if "&flag_outlier." = "true" and "&flag_missing." = "true" %then %do;
    %if "&pref." = "missing" %then %do;
       %missing_treatment3;
       %outlier_treatment;
    %end;
    %if "&pref." = "outlier" %then %do;
       %outlier_treatment;
       %missing_treatment3;
    %end;
%end;

%MEND variable_treatment;
%variable_treatment;

/* flex uses this file to test if the code has finished running */
data _null_;
    v1= "EDA - MULTIVAR_TREATMENT_COMPLETED";
    file "&output_path/MULTIVAR_TREATMENT_COMPLETED.txt";
    put v1;
    run;

/*ENDSAS;*/



