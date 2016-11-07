/*------------------------------------------------------------------------------
parameters required
------------------------------------------------------------------------------*/
/*%let inputpath                        = /product-development/vasanth.mm/;*/
/*%let outputpath                       = /product-development/vasanth.mm/temp/;*/
/*%let grpno                            = 0;*/
/*%let grpflag                          = 1_1_1;*/
/*%let testsubsetvar                    = channel_1;*/
/*%let testsubsetlevel                  = 0||1;*/
/*%let testindicatorvar                 = geography;*/
/*%let testvalue                        = north;*/
/*%let controlvalue                     = south;*/
/*%let nostd                            = nostd;*/
/*%let vars                             = ACV black_hispanic geography||sales acv;*/
/*%let categoricalvars                  = store_format;*/
/*%let idvar                            = Date;*/
/*%let testcontrolindicatorvar          = dfsfsfae;*/
/*%let matchpreferencevar               = sales;*/
/*%let matchpreferenceorder             = descending;*/
/*%let matchtype1                       = Many to One;*/
/*%let matchtype2                       = simpleeuclidean;*/
/*%let distance_cutoff                  = 150;*/
/*%let mapcontroltotestvar              = wwwwwww;*/
/*%let distancevarflag                  = true;*/
/*%let createdatasetflag                = true;*/
/*%let newdatasetname                   = dfsaddfsaddf;*/
/*----------------------------------------------------------------------------*/

*processbody;
options mlogic mprint spool symbolgen;

proc printto log = "&outputpath./edm_distance_matrix.log" new;
/*proc printto;*/
run;
quit;
proc printto;
run;
quit;

%macro edm_error_check;
	libname in "&inputpath.";

	%let c_data_temp                      = murx_temp;
	%let n_dsid                           = %sysfunc(open(in.dataworking));
	%let n_varnum_temp                    = %sysfunc(varnum(&n_dsid., &testindicatorvar.));
	%let c_vartyp_tiv                     = %sysfunc(vartype(&n_dsid., &n_varnum_temp.));
	%let n_varnum_temp                    = %sysfunc(varnum(&n_dsid., &testsubsetvar.));
	%let c_vartyp_tsv                     = %sysfunc(vartype(&n_dsid., &n_varnum_temp.));
	%let n_rc                             = %sysfunc(close(&n_dsid.));
	
	%if %str(&testsubsetvar.) ^= %str() %then
		%do;
			%let testsubsetlevel_2                = ;
			%let vars_2                           = ;
			%let c_sep                            = ;

			%do n_temp_i = 1 %to %sysfunc(countw(%str(&testsubsetlevel.), %str(||)));
				%let testsubsetlevel_now              = %scan(%str(&testsubsetlevel.), &n_temp_i., %str(||));
				%let vars_now                         = %scan(%str(&vars.), &n_temp_i., %str(||));

				%if %str(&vars_now.) ^= %str() %then
					%do;
						%let testsubsetlevel_2                = &testsubsetlevel_2. &c_sep. &testsubsetlevel_now.;
						%let vars_2                           = &vars_2. &c_sep. &vars_now.;

						%let c_sep                            = ||;
					%end;
			%end;

			%let testsubsetlevel                  = &testsubsetlevel_2.;
			%let vars                             = &vars_2.;
			
			%if %str(&vars.) = %str() %then 
				%do;
					data _null_;
						v1= "Select at least 1 variable for distance calculation.";
						file "&outputpath./error.txt";
						put v1;
					run;
					
					%goto the_end;
				%end;
		%end;

	%let c_temp = categoricalvars idvar testindicatorvar testsubsetvar vars;

	%do n_create_dataset_i = 1 %to %sysfunc(countw(&c_temp.));
		%let c_create_dataset_i = %scan(&c_temp., &n_create_dataset_i.);
		%if %str(&&&c_create_dataset_i..) = %str() %then %goto n_create_dataset_i_end;

		data &c_create_dataset_i.;
			length &c_create_dataset_i. $32;
			%do n_temp_i = 1 %to %sysfunc(countw(&&&c_create_dataset_i..));
				&c_create_dataset_i. = "%scan(%str(&&&c_create_dataset_i..), &n_temp_i.)";
				output;
			%end;
		run;

		%n_create_dataset_i_end:
	%end;

	%do n_var_error_check_i = 1 %to %sysfunc(countw(&c_temp.));
		%let c_1 = %scan(&c_temp., &n_var_error_check_i.);
		%if %str(&&&c_1..) = %str() %then %goto n_var_error_check_i_end;

		%do n_var_error_check_j = 1 %to %sysfunc(countw(&c_temp.));
			%let c_2 = %scan(&c_temp., &n_var_error_check_j.);
			%if %str(&&&c_2..) = %str() %then %goto n_var_error_check_j_end;
			%if %str(&c_1.) = %str(&c_2.) %then %goto n_var_error_check_j_end;

			proc sql;
				create table &c_data_temp. as
					select *
						from &c_1. murx_ds1, &c_2. murx_ds2
							where murx_ds1.&c_1.=murx_ds2.&c_2.;
			run;
			quit;

			%let dsid                             = %sysfunc(open(&c_data_temp.));
			%let n_obs_temp                       = %sysfunc(attrn(&dsid., NOBS));
			%let rc                               = %sysfunc(close(&dsid.));

			%if &n_obs_temp. ^= 0 %then
				%do;
					%let c_error_msg = Same variables cannot be selected &c_1. and &c_2..;
					%goto write_error_msg;
				%end;
			
			%n_var_error_check_j_end:
		%end;
		%n_var_error_check_i_end:
	%end;

	/*-----------------------------------------------------------------------------------------
	If the &testindicatorvar. is character then put double quotes around &testvalue. and &controlvalue.
	-----------------------------------------------------------------------------------------*/
	%if &c_vartyp_tiv. = C %then
		%do;
			%let testvalue="&testvalue.";
			%let controlvalue="&controlvalue.";
		%end;
	/*-----------------------------------------------------------------------------------------*/
	
	%let c_st_tables = &categoricalvars. &testindicatorvar. &testsubsetvar.;
	%let c_st_tables = %sysfunc(tranwrd(%str(&c_st_tables.), %str( ), %str(*)));
	%let c_st_tables = %str(tables &c_st_tables. / out=murx_count;);

	%let c_st_where   = (&testindicatorvar.=&testvalue. or &testindicatorvar.=&controlvalue.);
	%let c_st_where_1 = ;
	%let c_st_where_2 = ;
	%let c_sep        = ;
	%let c_sep_b4_1      = ;
	%let c_sep_b4_2      = ;

	%if &grpno. ^= 0 %then
		%do;
			%let c_st_where_1 = grp&grpno._flag="&grpflag.";
			%let c_sep_b4_1   = and;
		%end;
		
	%if %str(&testsubsetvar.) ^= %str() %then
		%do n_temp_i = 1 %to %sysfunc(countw(%str(&testsubsetlevel.), %str(||)));
			%let testsubsetlevel_now = %scan(%str(&testsubsetlevel.), &n_temp_i., %str(||));
			%if &c_vartyp_tsv. = C %then %let testsubsetlevel_now = "&testsubsetlevel_now.";
			
			%let c_st_where_2 = &c_st_where_2. &c_sep. &testsubsetvar.=&testsubsetlevel_now.;
			%let c_sep        = or;
			%let c_sep_b4_2   = and;
		%end;

	%if %str(&c_st_where_2.) ^= %str() %then
		%let c_st_where_2 = (&c_st_where_2.);
	
	%let c_st_where = (where=(&c_st_where. &c_sep_b4_1. &c_st_where_1. &c_sep_b4_2. &c_st_where_2.));
	
	proc freq data=in.dataworking&c_st_where. noprint;
		&c_st_tables.
	run;
	quit;

	data murx_count(keep = murx_level murx_id count);
		set murx_count;
		murx_level = catx("_", of &categoricalvars. &testsubsetvar.);

		if &testindicatorvar. = &testvalue. then
			murx_id = "nooftest";

		if &testindicatorvar. = &controlvalue. then
			murx_id = "noofctrl";
	run;

	proc sort data=murx_count out=murx_count;
		by murx_level;
	run;
	quit;

	proc transpose data=murx_count out=murx_t_count(keep=murx_level nooftest noofctrl);
		var count;
		id murx_id;
		by murx_level;
	run;
	quit;

	data murx_t_count;
		retain murx_level nooftest noofctrl;
		set murx_t_count;

		if missing(nooftest) then
			nooftest = 0;

		if missing(noofctrl) then
			noofctrl = 0;
	run;

	proc sql;
		select sum(nooftest * noofctrl), sum(nooftest), sum(noofctrl) into :n_sum_testxctrl, :n_sum_nooftest, :n_sum_noofctrl  from murx_t_count;
	run;
	quit;

	%if &n_sum_testxctrl. = 0 %then
		%do;

			data _null_;
				v1= compbl("Matching cannot be performed as there are &n_sum_nooftest. tests and &n_sum_noofctrl. controls available.");
				file "&outputpath./error.txt";
				put v1;
			run;

/*			%goto the_end;*/
		%end;

	data murx_t_count;
		set murx_t_count(rename=(murx_level = level));
		matchtype="&matchtype1.";

		%if %str(&categoricalvars.) = %str() and %str(&testsubsetvar.) = %str() %then
			%do;
				level = "Across Dataset";
			%end;

		%if &matchtype1. = One to One %then
			%do;
				if noofctrl < nooftest or noofctrl = 0 or nooftest = 0;
			%end;

		%if &matchtype1. = Many to One %then
			%do;
				if noofctrl = 0 or nooftest = 0;
			%end;
	run;

	%let dsid              = %sysfunc(open(murx_t_count));
	%let n_obs_error       = %sysfunc(attrn(&dsid., NOBS));
	%let rc                = %sysfunc(close(&dsid.));

	%if &n_obs_error. = 0 or &n_obs_error. = . %then
		%do;

			data _null_;
				v1= "Distance matrix completed";
				file "&outputpath./edm_distance_matrix_completed.txt";
				put v1;
			run;

			%goto the_end;
		%end;

	proc export data=murx_t_count outfile="&outputpath./error.csv" dbms=csv replace;
	run;

	quit;

	%goto the_end;

	%write_error_msg:

	%let c_error_msg = %sysfunc(tranwrd(%str(&c_error_msg.), %str(categoricalvars), %str(in variables for exact match)));
	%let c_error_msg = %sysfunc(tranwrd(%str(&c_error_msg.), %str(vars), %str(in variables for distance calculation)));
	%let c_error_msg = %sysfunc(tranwrd(%str(&c_error_msg.), %str(testsubsetvar), %str(as test subset variable)));
	%let c_error_msg = %sysfunc(tranwrd(%str(&c_error_msg.), %str(testindicatorvar), %str(as subject variable)));
	%let c_error_msg = %sysfunc(tranwrd(%str(&c_error_msg.), %str(idvar), %str(as dependent variable)));

	data _null_;
		v1= "&c_error_msg.";
		file "&outputpath./error.txt";
		put v1;
	run;

	%goto the_end;

	%the_end:
%mend edm_error_check;

%edm_error_check;