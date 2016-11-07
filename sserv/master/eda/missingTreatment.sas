/*Successfully converted to SAS Server Format*/
*processbody;
%let completedTXTPath =  &output_path/TREATMENT_COMPLETED.txt;
options mprint mlogic symbolgen mfile ;

proc printto log="&output_path/MissingTreatment_Log.log";
run;
quit;
 
dm log 'clear';
libname in "&input_path.";
libname out "&output_path.";

%let dsid=%sysfunc(open(in.dataworking));
%let frequency=%sysfunc(attrn(&dsid.,nobs));
%let rc=%sysfunc(close(&dsid.));

%MACRO missing_treatment4;

/*LOOP through all the variables*/
%let i = 1;
%do %until (not %length(%scan(&var_list,&i)));

/*    %if "&flag_outlier." = "true" and "&pref." = "outlier" and "&treatment_newVar." = "new" %then %do;*/
/*       %let var = &treatment_prefix._%scan(&var_list,&i);*/
/*    %end;*/
/*    %else %do;*/
      %let var = %scan(&var_list,&i);
/*    %end;*/

    /*univariate summary*/
    proc univariate data = in.dataworking(keep=&var.);
       var &var.;
       output out = mis_pre_univ&i.
           mean = pre_mean
           median = pre_median
           mode = pre_mode
          %if &flag_missing. = true %then %do ;
        nmiss=nmiss
      %end;
      %if &treatment_newVar=custom_type %then %do;
      pctlpre=p_ pctlpts=&missing_treat_val.
      %end;
           ;
           run;

 
  %if "&missing_spl." ^= "" %then %do;
    proc sql;
      select count(&var.) into:mis
      from in.dataworking 
      where &var. in (&missing_spl.);
      quit;
  %end;

  %put extra missing values is ................... :  &mis.;
    data mis_pre_univ&i.;
      length variable $32.;
      set mis_pre_univ&i.;
      variable = "&var.";
      attrib _all_ label=' ';
      %if &flag_missing. = true %then %do;
        %if "&missing_spl." ^= "" %then %do;
          nmiss=nmiss+&mis;
        %end;
        missing_percetange=nmiss/&frequency.;
      %end;
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

/*    proc datasets lib = work;*/
/*       delete mis_pre_univ&i.;*/
/*       run;*/

    %let i = %eval(&i.+1);
%end;

/* MISSING TREATMENT */
data in.dataworking;
    set in.dataworking;
    
    %let i = 1;
    %do %until (not %length(%scan(&var_list,&i)));

/*       %if "&flag_outlier." = "true" and "&pref." = "outlier" and "&treatment_newVar." = "new" %then %do;*/
/*           %let t_var = &treatment_prefix._%scan(&var_list,&i);*/
/*           %let treatment_newVar = replace;*/
/*       %end;*/
/*       %else %do;*/
           %let t_var = %scan(&var_list,&i);
/*       %end;*/

 /*------ENHANCEMENT-to create missing value indicator------*/
  %if &Create_ind_flag.= true %then %do ;
    
      %if "&treatment_newVar." = "new" %then %do;
	        %if "&missing_spl." ^= "" %then %do;

			if &t_var. in (&missing_spl.) or &t_var.=. then do;
			&treatment_prefix._MissingInd_%substr(&t_var.,1,15)=1;
			end;
			else do;
			&treatment_prefix._MissingInd_%substr(&t_var.,1,15)=0;
			end;
			%end;
	        %else %do;
	        &treatment_prefix._MissingInd_%substr(&t_var.,1,15) ='.'=&t_var.;
	        %end;
      %end;
      %else %if "&treatment_newVar." = "replace" %then %do;
        %if "&missing_spl." ^= "" %then %do;
		
			if &t_var. in (&missing_spl.) or &t_var.=. then do;
			Missing_Ind_%substr(&t_var.,1,15)=1;
			end;
			else do;
			Missing_Ind_%substr(&t_var.,1,15)=0;
			end;
		%end;
        %else %do;
      		  Missing_Ind_%substr(&t_var.,1,15) ='.' =&t_var.;
        %end;
      %end;
  %end;

/*--------------------------------------------------------------------------------------------  */

 
  /* Adoption Request For THD */
   %if &missing_treatment. = replace_with_existing %then %do;
     	%let misTreatVar= %scan(&var_list., &i.);
     	%let misReplaceVar= %scan(&missing_replacement_var., &i.);
    
	     %if "&treatment_newVar." = "replace" or "&treatment_newVar." = "rename" %then %do;
	  				if &misTreatVar.=. then do;
						&misTreatVar.=&misReplaceVar.;
					end;
			%if "&missing_spl." ^= "" %then %do;
					if &misTreatVar. in (&missing_spl.) then &misTreatVar.= &misReplaceVar.;
			%end;
		%end;
	    %else %if "&treatment_newVar." = "new" %then %do;
			    if &misTreatVar.= .  then  &treatment_prefix._%substr(&misTreatVar.,1,25)= &misReplaceVar.;
				else &treatment_prefix._%substr(&misTreatVar.,1,25)=&misTreatVar.;
				%if "&missing_spl." ^= "" %then %do;
					if &misTreatVar. in (&missing_spl.) then &treatment_prefix._%substr(&misTreatVar.,1,25)= &misReplaceVar.;
/*					else if &misTreatVar.= .  then &treatment_prefix._%substr(&misTreatVar.,1,25)= &misReplaceVar. */
/*					else &treatment_prefix._%substr(&misTreatVar.,1,25)=&misTreatVar.;*/
				%end;
	    %end;
    
    %end;
  /* Adoption Request For THD Ends here */

	%if &missing_treatment. ^= replace_with_existing %then %do;
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
    %end;     
       %let i = %eval(&i.+1);
    %end;
    run;

/*POST_TREATMENT univ-summary*/
%let i = 1;
%do %until (not %length(%scan(&var_list,&i)));
/**/
/*    %if "&flag_outlier." = "true" and "&pref." = "outlier" and "&treatment_newVar." = "new" %then %do;*/
/*       %let p_var = &treatment_prefix._%scan(&var_list,&i);*/
/*    %end;*/
/*    %else %do;*/
       %let p_var = %scan(&var_list,&i);
/*    %end;*/

    proc univariate data = in.dataworking;
       %if "&treatment_newVar." = "replace" or "&treatment_newVar." = "rename" %then %do;
           var &p_var.;
       %end;
       %else %if "&treatment_newVar." = "new" %then %do;
           var &treatment_prefix._%substr(&p_var.,1,25);
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
       %if "&missing_treatment." ^= "delete" and "&missing_treatment." ^= "replace_with_existing"  %then %do;
           treat_value = "%sysevalf(&&missing_val&i..)";
       %end;
       %else %if "&missing_treatment." = "delete"  %then %do;
           treat_value = " - ";
       %end;
	   %else %if "&missing_treatment." ^= "replace_with_existing" %then %do;
           treat_value = " NA ";
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

  

%MEND missing_treatment4;
%missing_treatment4;

/* flex uses this file to test if the code has finished running */
data _null_;
    v1= "EDA - MISSING_TREATMENT_COMPLETED";
    file "&output_path/TREATMENT_COMPLETED.txt";
    put v1;
    run;