*------------------------------------------------------------------------------
log and library and clean lib=work
------------------------------------------------------------------------------*/
proc printto log="&outputpath./edm_assign.log" new;
/*proc printto;*/
run;
quit;

libname in "&inputpath.";
libname out "&outputpath.";

proc datasets lib=work kill nolist;
run;
quit;
/*----------------------------------------------------------------------------*/

%put vasanth : start time : %sysfunc(datetime());

%macro eda_edm__distance_matrix(c_data_holdout/*the input dataset containing holdouts*/,
	c_data_test/*the input dataset containing tests*/,
	c_var_in_distance/*the variables to use for distance calculation*/,
	c_var_in_id/*the variable that identifies every observation*/,
	c_data_out/*the output dataset*/);

	%local c_data_holdout c_data_out c_data_test
		c_var_in_distance c_var_in_id;

	proc datasets lib=work nolist;
		delete &c_data_out.;
	run;
	quit;

	%if &b_std. = 1 %then
		%do;
			data &c_data_out.;
				set &c_data_holdout. &c_data_test.;
			run;

			proc stdize data=&c_data_out. out=&c_data_out. method=std;
				var &c_var_in_distance.;
			run;
			quit;

			data &c_data_test. &c_data_holdout.;
				set &c_data_out.;

				if &testindicatorvar. = &testvalue. then
					output &c_data_test.;

				if &testindicatorvar. = &controlvalue. then
					output &c_data_holdout.;
			run;

			proc datasets lib=work nolist;
				delete &c_data_out.;
			run;
			quit;
		%end;

	/*parameter play*/
	%local n_var_in_distance c_data_temp c_st_keep_holdout c_st_keep_test c_st_rename_holdout
		c_st_rename_test n_var_in_distance_i n_dsid n_obs_test n_rc n_test_i;

	%let n_var_in_distance                = %sysfunc(countw(%str(&c_var_in_distance.), %str( )));
	%let c_data_temp                      = eda_edm__distance_matrix_temp;
	%let c_st_keep_holdout                = keep=&c_var_in_id. &c_var_in_distance.;
	%let c_st_keep_test                   = keep=&c_var_in_id. &c_var_in_distance.;
	%let c_st_rename_holdout              = rename=(&c_var_in_id.=murx_x_id_holdout;
	%let c_st_rename_test                 = rename=(&c_var_in_id.=murx_x_id_test;
	%do n_var_in_distance_i = 1 %to &n_var_in_distance.;
		%let c_var_in_distance_now = %scan(%str(&c_var_in_distance.), &n_var_in_distance_i., %str( ));

		%let c_st_rename_holdout   = &c_st_rename_holdout. &c_var_in_distance_now.=murx_n_holdout_v&n_var_in_distance_i.;
		%let c_st_rename_test      = &c_st_rename_test. &c_var_in_distance_now.=murx_n_test_v&n_var_in_distance_i.;
	%end;

	%let c_st_rename_holdout              = &c_st_rename_holdout.);
	%let c_st_rename_test                 = &c_st_rename_test.);

	data &c_data_holdout.;
		set &c_data_holdout.(&c_st_keep_holdout. &c_st_rename_holdout.);
	run;

	data &c_data_test.;
		set &c_data_test.(&c_st_keep_test. &c_st_rename_test.);
	run;

	proc sql;
		create table &c_data_out. as
			select *
				from &c_data_holdout., &c_data_test.;
	run;
	quit;

	data &c_data_out.(keep=murx_x_id_test murx_x_id_holdout murx_n_distance);
		set &c_data_out.;
		murx_n_distance = 0;

		%do n_var_in_distance_i = 1 %to &n_var_in_distance.;
			murx_n_distance = murx_n_distance + (murx_n_test_v&n_var_in_distance_i. - murx_n_holdout_v&n_var_in_distance_i.)**2;
		%end;

		murx_n_distance = sqrt(murx_n_distance);
	run;

%mend eda_edm__distance_matrix;

%macro eda_edm__assign(c_data_in/*the input dataset*/,
	c_type_assignment/*onetoone (or) manytoone*/,
	c_var_in_id_test/*the variable that identifies the test in every observation*/,
	c_var_in_id_holdout/*the variable that identifies the holdout in every observation*/,
	c_var_in_distance/*the variable that specifies the distance between the test and holdout in every observation*/,
	c_var_in_sort_by/*the variables to sort the dataset by, before assignment*/,
	c_data_out/*the output dataset*/);
									
	%local c_data_in c_type_assignment c_var_in_id_test c_var_in_id_holdout c_var_in_distance c_var_in_sort_by c_data_out
		c_data_temp c_data_temp_in n_dsid n_obs_temp_in n_rc;
	 
	/*parameter play*/
	%let c_data_temp                      = murx_temp;
	%let c_data_temp_in                   = murx_temp_in;

	/*sorting the input dataset by test id*/
	proc sort data=&c_data_in. out=&c_data_temp_in.;
		by murx_x_id_test;
	run;
	quit;

	/*creating a flag for test id*/
	data &c_data_temp_in.;
		set &c_data_temp_in. end=end;
		by murx_x_id_test;
		retain murx_n_id_test 0;
		if first.murx_x_id_test then murx_n_id_test = murx_n_id_test + 1;
		if end then call symput("n_test", murx_n_id_test);
	run;

	/*sorting the input dataset by holdout id*/
	proc sort data=&c_data_temp_in. out=&c_data_temp_in.;
		by murx_x_id_holdout;
	run;
	quit;

	/*creating a flag for holdout id*/
	data &c_data_temp_in.;
		set &c_data_temp_in. end=end;
		by murx_x_id_holdout;
		retain murx_n_id_holdout 0;
		if first.murx_x_id_holdout then murx_n_id_holdout = murx_n_id_holdout + 1;
		if end then call symput("n_holdout", murx_n_id_holdout);
	run;

	/*sorting the input dataset*/
	proc sort data=&c_data_temp_in. out=&c_data_temp_in.;
		by &c_var_in_sort_by.;
	run;
	quit;

	%let c_array_holdout = %sysfunc(compress(array_holdout1-array_holdout&n_holdout.));
	%let c_array_test = %sysfunc(compress(array_test1-array_test&n_test.));

	data &c_data_out.(keep=murx_x_id_test murx_x_id_holdout murx_n_distance);
		set &c_data_temp_in.;
		array array_holdout[&n_holdout.] _temporary_;
		array array_test[&n_test.] _temporary_;
		retain array_holdout: array_test: 0;
		flag = 0;
		if _n_ = 1 then
			do;
				flag = 1;
				array_holdout[murx_n_id_holdout] = 1;
				array_test[murx_n_id_test] = 1;
			end;
		else if array_test[murx_n_id_test] ^= 1
			%if &c_type_assignment. = onetoone %then and array_holdout[murx_n_id_holdout] ^= 1 ;
			then
			do;
				flag = 1;
				array_holdout[murx_n_id_holdout] = 1;
				array_test[murx_n_id_test] = 1;
			end;
		if flag = 1;
	run;

%mend eda_edm__assign;

*processbody;
options mlogic mprint symbolgen;



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
/*%let nostd                            = ;*/
/*%let vars                             = ACV black_hispanic||sales acv;*/
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



%macro eda_edm__workflow_dm;
	/*------------------------------------------------------------------------------
	parameter play
	------------------------------------------------------------------------------*/
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
		%end;

	%let n_dsid                           = %sysfunc(open(in.dataworking));
	%let n_varnum_temp                    = %sysfunc(varnum(&n_dsid., &testsubsetvar.));
	%let c_vartyp_tsv                     = %sysfunc(vartype(&n_dsid., &n_varnum_temp.));
	%let n_varnum_temp                    = %sysfunc(varnum(&n_dsid., &testindicatorvar.));
	%let c_vartyp_tiv                     = %sysfunc(vartype(&n_dsid., &n_varnum_temp.));
	%let n_rc                             = %sysfunc(close(&n_dsid.));
	%let b_em                             = 0;
	%let b_ts                             = 0;
	%let b_std                            = 0;
	%let c_data_dm                        = murx_dm;
	%let c_data_em                        = murx_em;
	%let c_data_em_dm                     = murx_em_dm;
	%let c_data_in                        = dataworking;
	%let c_data_holdout                   = murx_holdout;
	%let c_data_test                      = murx_test;
	%let c_data_temp                      = murx_temp;
	%let c_data_em_holdout                = murx_em_holdout;
	%let c_data_em_test                   = murx_em_test;
	%let c_data_em_ts_test                = murx_em_ts_test;
	%let c_data_ts_test                   = murx_ts_test;
	%let c_st_where                       =;
	%let n_ts_level                       = %sysfunc(countw(&testsubsetlevel., ||));

	%if &c_vartyp_tiv. = C %then
		%do;
			%let testvalue                        = "&testvalue.";
			%let controlvalue                     = "&controlvalue.";
		%end;

	%if %str(&categoricalvars.) ^= %str() %then
		%let b_em = 1;

	%if %str(&testsubsetvar.) ^= %str() %then
		%let b_ts = 1;

	%if %str(&nostd.) = %str() %then
		%let b_std = 1;

	%if &grpno. ^= 0 %then
		%let c_st_where = %str(where=(grp&grpno._flag="&grpflag."));
	/*----------------------------------------------------------------------------*/

	/*------------------------------------------------------------------------------
	splitting tests and holdouts
	------------------------------------------------------------------------------*/
	data &c_data_test. &c_data_holdout.;
		set in.&c_data_in.(&c_st_where.);

		if &testindicatorvar. = &testvalue. then
			output &c_data_test.;

		if &testindicatorvar. = &controlvalue. then
			output &c_data_holdout.;
	run;

	%let n_dsid                           = %sysfunc(open(&c_data_test.));
	%let n_obs_test                       = %sysfunc(attrn(&n_dsid., NOBS));
	%let n_rc                             = %sysfunc(close(&n_dsid.));
	%let n_dsid                           = %sysfunc(open(&c_data_holdout.));
	%let n_obs_holdout                    = %sysfunc(attrn(&n_dsid., NOBS));
	%let n_rc                             = %sysfunc(close(&n_dsid.));

	%if &n_obs_test. = 0 or &n_obs_holdout. = 0 %then
		%goto the_end;
	/*----------------------------------------------------------------------------*/
	
	%if &b_em. = 0 and &b_ts. = 0 %then
		%do;
			%put muRx_log : n_obs_holdout = &n_obs_holdout. n_obs_test = &n_obs_test.;

			%eda_edm__distance_matrix(&c_data_holdout.,
				&c_data_test.,
				&vars.,
				&idvar.,
				&c_data_dm.);
		%end;
		
	%if &b_em. = 0 and &b_ts. = 1 %then
		%do n_ts_i = 1 %to &n_ts_level.;
			
			%let x_ts_level_now                   = %scan(&testsubsetlevel., &n_ts_i., ||);
			%let c_var_in_distance_now            = %scan(&vars., &n_ts_i., ||);

			%if &c_vartyp_tsv. = C %then
				%let x_ts_level_now = "&x_ts_level_now.";

			data &c_data_ts_test.;
				set &c_data_test.(where=(&testsubsetvar.=&x_ts_level_now.));
			run;

			%let n_dsid                           = %sysfunc(open(&c_data_ts_test.));
			%let n_obs_ts_test                    = %sysfunc(attrn(&n_dsid., NOBS));
			%let n_rc                             = %sysfunc(close(&n_dsid.));

			%if &n_obs_ts_test. = 0 %then
				%goto em0ts1_ts_end;

			%put muRx_log : n_obs_holdout = &n_obs_holdout. n_obs_ts_test = &n_obs_ts_test.;

			%eda_edm__distance_matrix(&c_data_holdout.,
				&c_data_ts_test., 
				&c_var_in_distance_now.,
				&idvar.,
				&c_data_temp.);

			proc append base=&c_data_dm. data=&c_data_temp. force;
			run;
			quit;

			proc datasets lib=work nolist;
				delete &c_data_temp.;
			run;
			quit;

			%em0ts1_ts_end:
		%end;
		
	%if &b_em. = 1 %then
		%do;
			proc sort data=in.&c_data_in.(keep=&categoricalvars.) out=&c_data_em. nodupkey;
				by &categoricalvars.;
			run;
			quit;
			
			%let dsid                             = %sysfunc(open(&c_data_em.));
			%let n_obs_em                         = %sysfunc(attrn(&dsid., NOBS));
			%let rc                               = %sysfunc(close(&dsid.));
			%let c_st_on                          = on;
			%let c_sep                            =;

			%do n_temp_i = 1 %to %sysfunc(countw(&categoricalvars.));
				%let categoricalvars_now              = %scan(&categoricalvars., &n_temp_i.);
				%let c_st_on                          = &c_st_on. &c_sep. murx_ds1.&categoricalvars_now.=murx_ds2.&categoricalvars_now.;
				%let c_sep                            = and;
			%end;
		%end;

	%if &b_em. = 1 and &b_ts. = 0 %then
		%do n_em_i = 1 %to &n_obs_em.;

			proc sql;
				create table &c_data_em_test. as
					select *
						from &c_data_test. murx_ds1 
							inner join &c_data_em.(firstobs=&n_em_i. obs=&n_em_i.) murx_ds2
								&c_st_on.;
				create table &c_data_em_holdout. as
					select *
						from &c_data_holdout. murx_ds1 
							inner join &c_data_em.(firstobs=&n_em_i. obs=&n_em_i.) murx_ds2
								&c_st_on.;
			run;
			quit;

			%let n_dsid                           = %sysfunc(open(&c_data_em_test.));
			%let n_obs_em_test                    = %sysfunc(attrn(&n_dsid., NOBS));
			%let n_rc                             = %sysfunc(close(&n_dsid.));
			%let n_dsid                           = %sysfunc(open(&c_data_em_holdout.));
			%let n_obs_em_holdout                 = %sysfunc(attrn(&n_dsid., NOBS));
			%let n_rc                             = %sysfunc(close(&n_dsid.));

			%if &n_obs_em_test. = 0 or &n_obs_em_holdout. = 0 %then
				%goto em1ts0_em_end;

			%put muRx_log : n_obs_em_holdout = &n_obs_em_holdout. n_obs_em_test = &n_obs_em_test.;

			%eda_edm__distance_matrix(&c_data_em_holdout.,
				&c_data_em_test.,
				&vars.,
				&idvar.,
				&c_data_em_dm.);

			proc append base=&c_data_dm. data=&c_data_em_dm. force;
			run;
			quit;

			proc datasets lib=work nolist;
				delete &c_data_em_dm.;
			run;
			quit;

			%em1ts0_em_end:
		%end;

	%if &b_em. = 1 and &b_ts. = 1 %then
		%do n_em_i = 1 %to &n_obs_em.;

			proc sql;
				create table &c_data_em_test. as
					select *
						from &c_data_test. murx_ds1 
							inner join &c_data_em.(firstobs=&n_em_i. obs=&n_em_i.) murx_ds2
								&c_st_on.;
				create table &c_data_em_holdout. as
					select *
						from &c_data_holdout. murx_ds1 
							inner join &c_data_em.(firstobs=&n_em_i. obs=&n_em_i.) murx_ds2
								&c_st_on.;
			run;
			quit;

			%let n_dsid                           = %sysfunc(open(&c_data_em_test.));
			%let n_obs_em_test                    = %sysfunc(attrn(&n_dsid., NOBS));
			%let n_rc                             = %sysfunc(close(&n_dsid.));
			%let n_dsid                           = %sysfunc(open(&c_data_em_holdout.));
			%let n_obs_em_holdout                 = %sysfunc(attrn(&n_dsid., NOBS));
			%let n_rc                             = %sysfunc(close(&n_dsid.));

			%if &n_obs_em_test. = 0 or &n_obs_em_holdout. = 0 %then
				%goto em1ts1_em_end;

			%do n_ts_i = 1 %to &n_ts_level.;
					
				%let x_ts_level_now                   = %scan(&testsubsetlevel., &n_ts_i., ||);
				%let c_var_in_distance_now            = %scan(&vars., &n_ts_i., ||);

				%if &c_vartyp_tsv. = C %then
					%let x_ts_level_now = "&x_ts_level_now.";

				data &c_data_ts_test.;
					set &c_data_em_test.(where=(&testsubsetvar.=&x_ts_level_now.));
				run;

				%let n_dsid                           = %sysfunc(open(&c_data_ts_test.));
				%let n_obs_ts_test                    = %sysfunc(attrn(&n_dsid., NOBS));
				%let n_rc                             = %sysfunc(close(&n_dsid.));

				%if &n_obs_ts_test. = 0 %then
					%goto em1ts1_ts_end;

				%put muRx_log : n_obs_em_holdout = &n_obs_em_holdout. n_obs_ts_test = &n_obs_ts_test.;

				%eda_edm__distance_matrix(&c_data_em_holdout.,
					&c_data_ts_test., 
					&c_var_in_distance_now.,
					&idvar.,
					&c_data_temp.);

				proc append base=&c_data_em_dm. data=&c_data_temp. force;
				run;
				quit;

				proc datasets lib=work nolist;
					delete &c_data_temp.;
				run;
				quit;

				%em1ts1_ts_end:
			%end;

			proc append base=&c_data_dm. data=&c_data_em_dm. force;
			run;
			quit;

			proc datasets lib=work nolist;
				delete &c_data_em_dm.;
			run;
			quit;

			%em1ts1_em_end:
		%end;

	%the_end:	
%mend eda_edm__workflow_dm;



%macro eda_edm__workflow_as;

	%let c_data_assign                    = murx_assign;
	%let c_data_dm                        = murx_dm;
	%let c_data_in                        = dataworking;
	%let c_type_assignment                = %sysfunc(compress(&matchtype1.));
	%let c_type_assignment                = %sysfunc(lowcase(&c_type_assignment.));

	%if %str(&matchpreferencevar.) ^= %str() %then
		%do;
			proc sql;
				create table &c_data_dm. as
					select murx_ds1.* , murx_ds2.&matchpreferencevar.
						from &c_data_dm. murx_ds1, in.&c_data_in. murx_ds2
							where murx_ds1.murx_x_id_test = murx_ds2.&idvar.;
			run;
			quit;
		%end;

	proc datasets lib=work nolist;
		delete &c_data_assign.;
	run;
	quit;

	%eda_edm__assign(&c_data_dm.,
		&c_type_assignment.,
		murx_x_id_test,
		murx_x_id_holdout,
		murx_n_distance,
		&matchpreferencevar. &matchpreferenceorder. murx_n_distance,
		&c_data_assign.);
	
	/*-----------------------------------------------------------------------------------------
	Write necessary CSVs for distance cutoff popup
	-----------------------------------------------------------------------------------------*/
	proc means data=&c_data_assign.;
		var murx_n_distance;
		output std=std mean=mean max=max min=min out=out_means;
	run;
	quit;

	proc sql;
		select count(distinct(murx_x_id_test)) into: nooftest from &c_data_assign.;
		select count(distinct(murx_x_id_holdout)) into: noofctrl from &c_data_assign.;
	run;
	quit;

	data beforecutoff(drop=_TYPE_ _FREQ_);
		set out_means;
		nooftest=&nooftest.;
		noofctrl=&noofctrl.;
		maptype="&matchtype1.";
	run;

	proc export data=beforecutoff outfile="&outputpath./beforecutoff.csv" dbms=csv replace;
	run;
	quit;
	/*-----------------------------------------------------------------------------------------*/

	/*-----------------------------------------------------------------------------------------
	Exporting assign.csv
	-----------------------------------------------------------------------------------------*/
	data out.assign(rename=(murx_x_id_test=test murx_x_id_holdout=control murx_n_distance=distance));
		set &c_data_assign.(keep=murx_x_id_test murx_x_id_holdout murx_n_distance);
	run;

	proc export data=out.assign outfile="&outputpath./assign.csv" replace;
	run;
	quit;
	/*-----------------------------------------------------------------------------------------*/

	/*-----------------------------------------------------------------------------------------
	Completed txt
	-----------------------------------------------------------------------------------------*/
	data _null_;
		v1= "Assigning control to tests completed";
		file "&outputpath./edm_assign_completed.txt";
		put v1;
	run;
	/*-----------------------------------------------------------------------------------------*/
				
%mend eda_edm__workflow_as;

%eda_edm__workflow_dm;

%put vasanth : distance matrix completed : %sysfunc(datetime());

%eda_edm__workflow_as;

%put vasanth : stop time : %sysfunc(datetime());
