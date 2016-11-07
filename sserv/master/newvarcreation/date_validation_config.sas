/*----------------------------------------------------------------------------*/
/* sample parameters */
/*----------------------------------------------------------------------------*/
/*%let codePath=/temp2/produser///SasCodes//8.7.1;*/
/*%let input_Path=/temp2/produser///projects/vasanth_segmentation-23-Sep-2014-17-09-23/1;*/
/*%let output_Path=/temp2/produser///projects/vasanth_segmentation-23-Sep-2014-17-09-23/1/NewVariable/Transformation/0;*/
/*%let dataset_name=dataworking;*/
/*%let dateVarName=ACV;*/
/*%let grp_no=2!!2!!2!!2!!*/
/*2!!2!!2!!2!!*/
/*2;*/
/*%let levels=Food/Drug Combo north!!Food/Drug Combo south!!Super Combo north!!Super Combo south!!*/
/*Supercenter north!!Supercenter south!!Supermarket north!!Superstore north!!*/
/*Superstore south;*/
/*%let grp_flag=1_1_1!!1_2_1!!2_1_1!!2_2_1!!*/
/*3_1_1!!3_2_1!!4_1_1!!5_1_1!!*/
/*5_2_1;*/
/*%let panel_name=Store_Format geography!!Store_Format geography!!Store_Format geography!!Store_Format geography!!*/
/*Store_Format geography!!Store_Format geography!!Store_Format geography!!Store_Format geography!!*/
/*Store_Format geography;*/
/*----------------------------------------------------------------------------*/



/*------------------------------------------------------------------------------
Description		: Date validation for correlation and transformation 
Created Date	: 13FEB2014
Author(s)		: Anvita Srivastava
------------------------------------------------------------------------------*/



*processbody;
options mprint mlogic symbolgen;

proc printto log="&output_path./date_validation_config.log" new;
/*proc printto;*/
run;
quit;

%macro date_validation_config;

	libname in "&input_path.";
	libname out "&output_path.";
	
	filename myfile "&output_path./DATE_VAL_TRA_WARNING.txt";

	data _null_;
		rc = fdelete('myfile');
	run;

	filename myfile "&output_path./DATE_VAL_WARNING.txt";

	data _null_;
		rc = fdelete('myfile');
	run;

	filename myfile "&output_path./DATE_VAL_COMPLETED.txt";

	data _null_;
		rc = fdelete('myfile');
	run;	

	%let c_not_regular                = ;
	%let c_not_unique                 = ;
	%let c_sep_not_regular            = ;
	%let c_sep_not_unique             = ;
	%let c_sep_warning                = ;
	%let c_warning                    = ;

	%do i = 1 %to %sysfunc(countw("&grp_no.","!!"));
		%let grp_no_now               = %scan("&grp_no.",&i.,"!!");
		%let grp_flag_now             = %scan("&grp_flag.",&i.,"!!");
		%let levels_now               = %scan("&levels.",&i.,"!!");
		%let panel_name_now           = %scan("&panel_name.",&i.,"!!");
		%let c_st_keep                = keep=&dateVarName.;
		%let c_st_where               = ;
		%if &grp_no_now. ^= 0 %then
			%do;
				%let c_st_keep        = &c_st_keep. grp&grp_no_now._flag;
				%let c_st_where       = where=(grp&grp_no_now._flag = "&grp_flag_now.");
			%end;

		proc sort data=in.&dataset_name.(&c_st_keep. &c_st_where.) out=murx_temp;
			by &dateVarName.;
		run;
		quit;

		data murx_temp;
			set murx_temp end=end;
			n_interval = &dateVarName. - lag1(&dateVarName.);
		run;

		proc sql noprint;
			select count(distinct &dateVarName.), count(&dateVarName.), count(distinct n_interval)  into :n_unique_date , :n_total_date , :n_unique_lag1
				from murx_temp;
		run;
		quit;

		%if &n_unique_date. ^= &n_total_date. %then
			%do;
				%let c_not_unique     = %str(&c_not_unique. &c_sep_not_unique. <&panel_name_now. : &levels_now.>);
				%let c_sep_not_unique = and;
			%end;

		%if &n_unique_date. = &n_total_date. and &n_unique_lag1. ^= 1 %then
			%do;
				%let c_not_regular    = %str(&c_not_regular. &c_sep_not_regular. <&panel_name_now. : &levels_now.>);
				%let c_sep_not_regular= and;
			%end;
	%end;

	%if %bquote(&c_not_unique.) ^= %str() %then
		%let c_not_unique             = %str(not unique for &c_not_unique.);

	%if %bquote(&c_not_regular.) ^= %str() %then
		%let c_not_regular            = %str(not regularly spaced for &c_not_regular.);

	%if %bquote(&c_not_unique.) ^= %str() and %bquote(&c_not_regular.) ^= %str() %then
		%let c_sep_warning            = and;

	%if %bquote(&c_not_unique.) ^= %str() or %bquote(&c_not_regular.) ^= %str() %then
		%let c_warning                = %str(%sysfunc(compbl(The variable &dateVarName. is &c_not_unique. &c_sep_warning. &c_not_regular.)));
		
	%if &grp_no_now. = 0 %then
		%let c_warning                = %sysfunc(tranwrd(%str(&c_warning.), %str(for <acrossdataset : acrossDataset>), %str()));

	%if %bquote(&c_warning.) = %str() %then
		%do;
			data _null_;
				file "&output_path./DATE_VAL_COMPLETED.txt";
				put "Date validation completed";
			run;
		%end;
	%else
		%do;
			data _null_;
				file "&output_path./DATE_VAL_TRA_WARNING.txt";
				put "&c_warning.";
			run;
			
			data _null_;
				file "&output_path./DATE_VAL_WARNING.txt";
				put "&c_warning.";
			run;
		%end;
%mend date_validation_config;

%date_validation_config;