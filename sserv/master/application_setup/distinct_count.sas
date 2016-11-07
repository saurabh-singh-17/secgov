*processbody;
options mlogic mprint symbolgen;

proc printto log="&c_path_out./murx__distinct_count.log" new;
/*proc printto;*/
run;
quit;

/*------------------------------------------------------------------------------
sample parameters
%let c_path_in                        = /product-development/vasanth.mm/;
%let c_path_out                       = /product-development/vasanth.mm/temp/;
%let c_var_in                         = chiller_flag store_format_missing acv;
%let n_var_id_in                      = 1 4 5;
------------------------------------------------------------------------------*/

%macro murx__distinct_and_count;
	libname in "&c_path_in.";

	/*------------------------------------------------------------------------------
	parameter play
	------------------------------------------------------------------------------*/
	%let c_data                           = dataworking;
	%let c_data_temp                      = murx_temp;

	/*------------------------------------------------------------------------------
	getting the distinct count
	------------------------------------------------------------------------------*/
	%let n_count_distinct                 =;

	%do n_i_var = 1 %to %sysfunc(countw(%str(&c_var_in.), %str( )));
		%let c_var_in_now = %scan(%str(&c_var_in.), &n_i_var., %str( ));

		proc sql;
			create table &c_data_temp. as
				select distinct(&c_var_in_now.) as murx_x_temp
					from in.&c_data.;
			select count(murx_x_temp) into: n_count_distinct_now
				from &c_data_temp.;
		run;

		quit;

		%let n_count_distinct = &n_count_distinct. &n_count_distinct_now.;
	%end;

	/*------------------------------------------------------------------------------
	output
	------------------------------------------------------------------------------*/
	data &c_data_temp.;
		length variable $32 var_id 8 distinct_count 8;

		%do n_i_var = 1 %to %sysfunc(countw(%str(&c_var_in.), %str( )));
			%let c_var_in_now = %scan(%str(&c_var_in.), &n_i_var., %str( ));
			%let n_var_id_in_now = %scan(%str(&n_var_id_in.), &n_i_var., %str( ));
			%let n_count_distinct_now = %scan(%str(&n_count_distinct.), &n_i_var., %str( ));
			variable = "&c_var_in_now.";
			var_id = &n_var_id_in_now.;
			distinct_count = &n_count_distinct_now.;
			output;
		%end;
	run;

	proc export data=&c_data_temp. outfile="&c_path_out./distinct_count.csv" replace dbms=csv;
	run;

	quit;

%mend murx__distinct_and_count;

%murx__distinct_and_count;