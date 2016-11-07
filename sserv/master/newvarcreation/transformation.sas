*processbody;
options mlogic mprint symbolgen;

%macro dp_nvc_trn;

	/* workflow */
	%goto parameter_play;
	%wf_a_parameter_play:

	%goto delete_files;
	%wf_a_delete_files:

	%goto create_c_data_new;
	%wf_a_create_c_data_new:

	%goto error_check;
	%wf_a_error_check:

	%goto nvc;
	%wf_a_nvc:

	%goto cbind_c_data_new_c_data_in;
	%wf_a_cbind_c_data_new_c_data_in:
	
	%include "&genericCode_path./datasetprop_update.sas";

	%goto output;
	%wf_a_output:

	%goto completed;
	%wf_a_completed:

	%goto the_end;
	/* workflow ends */

	%parameter_play:
	/* sample parameters */
	/*%let codePath=/product-development/murx///SasCodes//8.7.1;*/
	/*%let inputPath=/product-development/murx///projects/vasanth_871_ah-17-Nov-2014-13-17-48/1;*/
	/*%let output_path=/product-development/murx///projects/vasanth_871_ah-17-Nov-2014-13-17-48/1/NewVariable/Transformation/11;*/
	/*%let datasetName=dataworking;*/
	/*%let prefix=trn1;*/
	/*%let varList=black_hispanic sales;*/
	/*%let tranz=Sine!!Cosine!!Reciprocal!!RecSquare!!RecCube!!roundUp!!roundDown!!Log!!exponential!!movingavg!!CumSum!!Lag!!lead!!meanCenter!!Normalize;*/
	/*%let meanVars=Across Dataset;*/
	/*%let normVars=Across Dataset;*/
	/*%let lag=1;*/
	/*%let lead=1;*/
	/*%let moveavg=1;*/
	/*%let avgType=fw;*/
	/*%let CumSumType=absolute;*/
	/*%let dateVarName=ACV;*/
	/*%let datasetinfo_path=/product-development/murx///projects/vasanth_871_ah-17-Nov-2014-13-17-48/1/NewVariable/Transformation/11;*/
	/*%let genericCode_path=/product-development/murx///SasCodes//8.7.1/common;*/
	/*%let grp_no =1;*/

	/* initialising */
	%let b_cos                            = %index(&tranz., Cosine);
	%let b_cs                             = %index(&tranz., CumSum);
	%let b_exponent                       = %index(&tranz., exponential);
	%let b_lag                            = %index(&tranz., Lag);
	%let b_lead                           = %index(&tranz., lead);
	%let b_log                            = %index(&tranz., Log);
	%let b_ma                             = %index(&tranz., movingavg);
	%let b_meancenter                     = %index(&tranz., meanCenter);
	%let b_normalize                      = %index(&tranz., Normalize);
	%let b_onebyx                         = %index(&tranz., Reciprocal);
	%let b_onebyxcube                     = %index(&tranz., RecCube);
	%let b_onebyxsquare                   = %index(&tranz., RecSquare);
	%let b_rounddown                      = %index(&tranz., roundDown);
	%let b_roundup                        = %index(&tranz., roundUp);
	%let b_sine                           = %index(&tranz., Sine);
	%let c_path_in                        = &inputPath.;
	%let c_path_out                       = &output_path.;
	%let c_prefix                         = &prefix.;
	%let c_type_cs                        = &CumSumType.;
	%let c_type_ma                        = &avgType.;
	%let c_var_in_date                    = &dateVarName.;
	%let c_var_in_transformation          = &varList.;
	%let n_lag                            = &lag.;
	%let n_lead                           = &lead.;
	%let n_ma                             = &moveavg.;
	%let n_panel                          = &grp_no.;

	proc printto log="&c_path_in./transformations.log" new;
	run;
	quit;

	/* hardcoding */
	%let c_csv_newvar                     = transformations_output;
	%let c_data_in                        = dataworking;
	%let c_data_newvar                    = murx_newvar;
	%let c_prefix_cos                     = cos_;
	%let c_prefix_cs                      = ;
	%let c_prefix_exponent                = exp_;
	%let c_prefix_lag                     = ;
	%let c_prefix_lead                    = ;
	%let c_prefix_log                     = log_;
	%let c_prefix_ma                      = ;
	%let c_prefix_meancenter              = mean_;
	%let c_prefix_normalize               = normal_;
	%let c_prefix_onebyx                  = rec_;
	%let c_prefix_onebyxcube              = reccub_;
	%let c_prefix_onebyxsquare            = recsqr_;
	%let c_prefix_rounddown               = rnddn_;
	%let c_prefix_roundup                 = rndup_;
	%let c_prefix_sin                     = sin_;
	%let c_txt_completed                  = NEWVAR_TRANSFORMATION_COMPLETED;
	%let c_txt_error                      = error;
	%let c_txt_warning                    = warning;
	%let c_var_cs                         = ;
	%let c_var_key                        = primary_key_1644;
	%let c_var_meancenter                 = ;
	%let c_var_normalize                  = ;
	%let c_var_panel                      = ;
	
	%if "&c_type_ma." = "fw" %then %let c_type_ma = forward;
	%if "&c_type_ma." = "bw" %then %let c_type_ma = backward;
	%if &b_cs. %then
		%do;
			%if &c_type_cs. = absolute   %then %let c_prefix_cs = csa_;
			%if &c_type_cs. = percentage %then %let c_prefix_cs = csp_;
		%end;
	%if &b_lag. %then
		%let c_prefix_lag          = lag&n_lag._;
	%if &b_lead. %then
		%let c_prefix_lead         = ld&n_lead._;
	%if &b_ma. %then
		%do;
			%if &c_type_ma. = forward  %then %let c_prefix_ma = ma&n_ma.fw_;
			%if &c_type_ma. = backward %then %let c_prefix_ma = ma&n_ma.bw_;
			%if &c_type_ma. = mid      %then %let c_prefix_ma = ma&n_ma.mid_;
		%end;
	%if &n_panel. %then %let c_var_panel = grp&n_panel._flag;

	%let c_file_delete		   =	&c_path_out./&c_txt_completed..txt#
									&c_path_out./&c_txt_error..txt#
									&c_path_out./&c_txt_warning..txt#
									&c_path_out./&c_csv_newvar..csv;
	%let c_var_keep            =	&c_var_in_transformation. &c_var_in_date. &c_var_key.
									&c_var_panel.;
	%let c_prefix              = &c_prefix._;

	/* libraries */
	libname in  "&c_path_in.";
	libname out "&c_path_out.";

	%goto wf_a_parameter_play;

	%delete_files:

	%do tempi = 1 %to %sysfunc(countw(%str(&c_file_delete.), %str(#)));
		%let c_file_delete_now = %sysfunc(compress(%scan(%str(&c_file_delete.), &tempi., %str(#))));

		filename myfile "&c_file_delete_now.";

		data _null_;
			rc = fdelete('myfile');
		run;
	%end;

	%goto wf_a_delete_files;

	%create_c_data_new:

	data &c_data_newvar.;
		set in.&c_data_in.(keep = &c_var_keep.);
	run;

	%goto wf_a_create_c_data_new;

	%error_check:
	%goto wf_a_error_check;

	%nvc:

	%let c_var_new = ;

	%if "&c_var_panel." ^= "" or "&c_var_in_date" ^= "" %then
		%do;
			proc sort data=&c_data_newvar. out=&c_data_newvar.;
				by &c_var_panel. &c_var_in_date.;
			run;
			quit;
		%end;
		
	%if &b_meancenter. or &b_normalize. or &b_cs. %then
		%do;
			data &c_data_newvar.;
				set &c_data_newvar.;
				%do tempi = 1 %to %sysfunc(countw(&c_var_in_transformation., %str( )));
					%let c_var_in_transformation_now = %scan(&c_var_in_transformation., &tempi., %str( ));
					%if &b_cs. %then
						%do;
							%let c_var_new_now   = &c_prefix.
												   &c_prefix_cs.
												   %substr(&c_var_in_transformation_now., 1, 17);
							%let c_var_new_now   = %sysfunc(compress(&c_var_new_now.));
							%let c_var_new       = &c_var_new. &c_var_new_now.;
							%let c_var_cs        = &c_var_cs. &c_var_new_now.;

							&c_var_new_now.      = &c_var_in_transformation_now.;
						%end;
					%if &b_meancenter. %then
						%do;
							%let c_var_new_now   = &c_prefix.
												   &c_prefix_meancenter.
												   %substr(&c_var_in_transformation_now., 1, 17);
							%let c_var_new_now   = %sysfunc(compress(&c_var_new_now.));
							%let c_var_new       = &c_var_new. &c_var_new_now.;
							%let c_var_meancenter= &c_var_meancenter. &c_var_new_now.;

							&c_var_new_now.      = &c_var_in_transformation_now.;
						%end;
					%if &b_normalize. %then
						%do;
							%let c_var_new_now   = &c_prefix.
												   &c_prefix_normalize.
												   %substr(&c_var_in_transformation_now., 1, 17);
							%let c_var_new_now   = %sysfunc(compress(&c_var_new_now.));
							%let c_var_new       = &c_var_new. &c_var_new_now.;
							%let c_var_normalize = &c_var_normalize. &c_var_new_now.;

							&c_var_new_now.      = &c_var_in_transformation_now.;
						%end;
				%end;
			run;
		%end;
	
	%if &b_meancenter. %then
		%do;
			proc stdize data=&c_data_newvar. out=&c_data_newvar. method=mean;
				var &c_var_meancenter.;
				%if %str(&c_var_panel.) ^= %str( ) %then by &c_var_panel.;;
			run;
			quit;
		%end;

	%if &b_normalize. %then
		%do;
			proc stdize data=&c_data_newvar. out=&c_data_newvar. method=std;
				var &c_var_normalize.;
				%if %str(&c_var_panel.) ^= %str( ) %then by &c_var_panel.;;
			run;
			quit;
		%end;

	%if &b_lag. or &b_lead. or &b_ma. or &b_cs. %then
		%do;			
			%if "&c_type_cs." = "percentage" %then
				%do;
					proc stdize data=&c_data_newvar. out=&c_data_newvar. method=sum mult=100;
						var &c_var_cs.;
						%if %str(&c_var_panel.) ^= %str( ) %then by &c_var_panel.;;
					run;
					quit;
				%end;
			
			proc expand	data = &c_data_newvar. out = &c_data_newvar.;
				%do tempi = 1 %to %sysfunc(countw(&c_var_in_transformation., %str( )));
					%let c_var_in_transformation_now = %scan(&c_var_in_transformation., &tempi., %str( ));

					%if &b_cs. %then
						%do;
							%let c_var_new_now = &c_prefix.
												 &c_prefix_cs.
												 %substr(&c_var_in_transformation_now., 1, 17);
							%let c_var_new_now = %sysfunc(compress(&c_var_new_now.));
							
							convert &c_var_new_now. = &c_var_new_now. / transformout=(cusum);
						%end;
					%if &b_lag. %then
						%do;
							%let c_var_new_now = &c_prefix.
												 &c_prefix_lag.
												 %substr(&c_var_in_transformation_now., 1, 17);
							%let c_var_new_now = %sysfunc(compress(&c_var_new_now.));
							%let c_var_new     = &c_var_new. &c_var_new_now.;

							convert &c_var_in_transformation_now. = &c_var_new_now. / transformout=(lag &n_lag.);
						%end;
					%if &b_lead. %then
						%do;
							%let c_var_new_now = &c_prefix.
												 &c_prefix_lead.
												 %substr(&c_var_in_transformation_now., 1, 17);
							%let c_var_new_now = %sysfunc(compress(&c_var_new_now.));
							%let c_var_new     = &c_var_new. &c_var_new_now.;

							convert &c_var_in_transformation_now. = &c_var_new_now. / transformout=(lead &n_lead.);
						%end;
					%if &b_ma. %then
						%do;							
							%let c_var_new_now = &c_prefix.
												 &c_prefix_ma.
												 %substr(&c_var_in_transformation_now., 1, 17);
							%let c_var_new_now = %sysfunc(compress(&c_var_new_now.));
							%let c_var_new     = &c_var_new. &c_var_new_now.;

							%if &c_type_ma. = forward %then
								%do;
									convert &c_var_in_transformation_now. =  &c_var_new_now. / transformout=(reverse movave &n_ma. reverse);
								%end;
							%if &c_type_ma. = backward %then
								%do;
									convert &c_var_in_transformation_now.  = &c_var_new_now.  / transformout=(movave &n_ma.);
								%end;
							%if &c_type_ma. = mid %then
								%do;
									convert &c_var_in_transformation_now.  =  &c_var_new_now./ transformout=(cmovave &n_ma.);
								%end;
						%end;
				%end;
				%if %str(&c_var_panel.) ^= %str( ) %then by &c_var_panel.;;
			run;
			quit;
		%end;

	data &c_data_newvar.;
		set &c_data_newvar.;
		%do tempi = 1 %to %sysfunc(countw(&c_var_in_transformation., %str( )));
			%let c_var_in_transformation_now = %scan(&c_var_in_transformation., &tempi., %str( ));

			%if &b_sine. %then
				%do;
					%let c_var_new_now = &c_prefix.
										 &c_prefix_sin.
										 %substr(&c_var_in_transformation_now., 1, 17);
					%let c_var_new_now = %sysfunc(compress(&c_var_new_now.));
					%let c_var_new     = &c_var_new. &c_var_new_now.;
					&c_var_new_now.    = sin(&c_var_in_transformation_now.);
				%end;
			%if &b_cos. %then
				%do;
					%let c_var_new_now = &c_prefix.
										 &c_prefix_cos.
										 %substr(&c_var_in_transformation_now., 1, 17);
					%let c_var_new_now = %sysfunc(compress(&c_var_new_now.));
					%let c_var_new     = &c_var_new. &c_var_new_now.;
					&c_var_new_now.    = cos(&c_var_in_transformation_now.);
				%end;
			%if &b_onebyx. %then
				%do;
					%let c_var_new_now = &c_prefix.
										 &c_prefix_onebyx.
										 %substr(&c_var_in_transformation_now., 1, 17);
					%let c_var_new_now = %sysfunc(compress(&c_var_new_now.));
					%let c_var_new     = &c_var_new. &c_var_new_now.;
					&c_var_new_now.    = 1 / &c_var_in_transformation_now.;
				%end;
			%if &b_onebyxsquare. %then
				%do;
					%let c_var_new_now = &c_prefix.
										 &c_prefix_onebyxsquare.
										 %substr(&c_var_in_transformation_now., 1, 17);
					%let c_var_new_now = %sysfunc(compress(&c_var_new_now.));
					%let c_var_new     = &c_var_new. &c_var_new_now.;
					&c_var_new_now.    = 1 / &c_var_in_transformation_now.**2;
				%end;
			%if &b_onebyxcube. %then
				%do; 	
					%let c_var_new_now = &c_prefix.
										 &c_prefix_onebyxcube.
										 %substr(&c_var_in_transformation_now., 1, 17);
					%let c_var_new_now = %sysfunc(compress(&c_var_new_now.));
					%let c_var_new     = &c_var_new. &c_var_new_now.;
					&c_var_new_now.    = 1 / &c_var_in_transformation_now.**3;
				%end;
			%if &b_roundup. %then
				%do;
					%let c_var_new_now = &c_prefix.
										 &c_prefix_roundup.
										 %substr(&c_var_in_transformation_now., 1, 17);
					%let c_var_new_now = %sysfunc(compress(&c_var_new_now.));
					%let c_var_new     = &c_var_new. &c_var_new_now.;
					&c_var_new_now.    = ceil(&c_var_in_transformation_now.);
				%end;
			%if &b_rounddown. %then
				%do;
					%let c_var_new_now = &c_prefix.
										 &c_prefix_rounddown.
										 %substr(&c_var_in_transformation_now., 1, 17);
					%let c_var_new_now = %sysfunc(compress(&c_var_new_now.));
					%let c_var_new     = &c_var_new. &c_var_new_now.;
					&c_var_new_now.    = floor(&c_var_in_transformation_now.);
				%end;
			%if &b_log. %then
				%do;
					%let c_var_new_now = &c_prefix.
										 &c_prefix_log.
										 %substr(&c_var_in_transformation_now., 1, 17);
					%let c_var_new_now = %sysfunc(compress(&c_var_new_now.));
					%let c_var_new     = &c_var_new. &c_var_new_now.;
					&c_var_new_now.    = log(&c_var_in_transformation_now.);
				%end;
			%if &b_exponent. %then
				%do;
					%let c_var_new_now = &c_prefix.
										 &c_prefix_exponent.
										 %substr(&c_var_in_transformation_now., 1, 17);
					%let c_var_new_now = %sysfunc(compress(&c_var_new_now.));
					%let c_var_new     = &c_var_new. &c_var_new_now.;
					&c_var_new_now.    = exp(&c_var_in_transformation_now.);
				%end;
		%end;
	run;

	%goto wf_a_nvc;

	%cbind_c_data_new_c_data_in:

	proc sql noprint;
		create table in.&c_data_in.
			as select d1.*, d2.*
				from in.&c_data_in. d1
					left join &c_data_newvar.(keep = &c_var_new. &c_var_key.) d2
						on d1.&c_var_key. = d2.&c_var_key.;
	run;
	quit;

	%goto wf_a_cbind_c_data_new_c_data_in;
	
	%output:

	/*restriction on the no of rows in the output csv*/
	%let dsid = %sysfunc(open(&c_data_newvar.));
	%let nobs = %sysfunc(attrn(&dsid,nobs));
	%let rc   = %sysfunc(close(&dsid));

	%if &nobs. > 6000 %then
		%do;
			proc surveyselect data=&c_data_newvar. out=&c_data_newvar. method=SRS sampsize=5000 SEED=1234567;
			run;
			quit;
		%end;

	proc export data=&c_data_newvar. outfile="&c_path_out./&c_csv_newvar..csv" dbms=csv replace;
	run;
	quit;

	data muRx_temp;
		length new_variable $32.;
		%do i=1 %to %sysfunc(countw(&c_var_new.," "));
			new_variable = "%scan(&c_var_new.,&i.," ")";
			output;
		%end; 
	run;

	proc export data=muRx_temp outfile= "&c_path_out./newVar_transformation.csv" dbms=csv replace;
	run;
	quit;

	%goto wf_a_output;

	%completed:

	data _null_;
		v1= "&c_txt_completed.";
		file "&c_path_out./&c_txt_completed..txt";
		put v1;
	run;

	%goto wf_a_completed;

	%the_end:

%mend dp_nvc_trn;
%dp_nvc_trn;
