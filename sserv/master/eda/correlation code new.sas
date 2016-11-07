/*Successfully converted to SAS Server Format*/
*processbody;
%let completedTXTPath =  &output_path./CORRELATION_COMPLETED.TXT;

/* Version : 2.6.2 */
options mprint;
FILENAME MyFile "&output_path./GENERATE_FILTER_FAILED.txt";

DATA _NULL_;
	rc = FDELETE('MyFile');
RUN;

dm log 'clear';
libname in "&input_path.";
libname out "&output_path.";

proc printto;
run;

/* log="&output_path/corr_log.log"*/
/*proc printto print="&output_path/corr_output.out";*/
%macro boxcoxcorr;
	%global BOXCOXNEWVARS;

	data boxcoxvars(keep=&yvars. primary_key_1644);
		set in.dataworking;

		%if &grp_no.^= 0 %then
			%do;
				where grp&grp_no._flag = "&grp_flag.";
			%end;
	run;

	%let boxcoxvalues=;
	%let lastboxcoxvalue=&box_start.;
	%let boxcoxvalues=&box_start.;

	%do tempi = 1 %to %sysevalf((&box_stop.-&box_start.)/&box_step.);
		%let boxcoxvalues=&boxcoxvalues. %sysevalf(&lastboxcoxvalue.+&box_step.);
		%let lastboxcoxvalue=%sysevalf(&lastboxcoxvalue.+&box_step.);
	%end;

	%let boxcoxvaluesfornaming=%sysfunc(translate(&boxcoxvalues.,__,.-));
	%let boxcoxnewvars=;

	%do i = 1 %to %sysfunc(countw(&xvars.));
		%let currentxvars=%scan(&xvars.,&i.);

		%do j = 1 %to %sysfunc(countw(&boxcoxvaluesfornaming.));
			%let currentboxcoxvaluesfornaming=%scan(&boxcoxvaluesfornaming.,&j.," ");
			%if (%sysfunc(countw(&currentboxcoxvaluesfornaming.,"_"))<2 ) %then %do;
			%let currentnewvar=bc_&currentboxcoxvaluesfornaming._%substr(&currentxvars.,1,26);
			%put &currentnewvar.;
			%end;
			%else %do;
			%let currentnewvar=bc_&currentboxcoxvaluesfornaming._%substr(&currentxvars.,1,24);
			%put &currentnewvar.;
            %end;
            %let boxcoxnewvars=&boxcoxnewvars. &currentnewvar.;
			%let currentboxcoxvalues=%scan(&boxcoxvalues.,&j.," ");

			data tempp(keep=&currentnewvar.);
				set in.dataworking(keep= &currentxvars.);

				%if "&currentboxcoxvalues." ^= "0" %then %do;
					&currentnewvar.=(((&currentxvars.**&currentboxcoxvalues.)-1)/(&currentboxcoxvalues.));
				%end;
				%else %do; 
				&currentnewvar.=log(&currentxvars.);
				%end;
			run;

			data boxcoxvars;
				merge boxcoxvars tempp;
			run;

		%end;
	%end;

	ods output PearsonCorr = corr;

	proc corr data = boxcoxvars;
		var &boxcoxnewvars.;
		with &yvars.;
	run;

	quit;

	data boxcoxvars;
		set boxcoxvars(drop=&yvars.);
	run;

	%do i = 1 %to %sysfunc(countw(&yvars.));
		%let currentyvars=%scan(&yvars.,&i.);

		%do  j= 1 %to %sysfunc(countw(&xvars.));
			%let currentxvars=%scan(&xvars.,&j.);

			%do k = 1 %to %sysfunc(countw(&boxcoxvaluesfornaming.));
				%let currentboxcoxvaluesfornaming=%scan(&boxcoxvaluesfornaming.,&k.);
				%if (%sysfunc(countw(&currentboxcoxvaluesfornaming.,"_"))<2 ) %then %do;
				%let currentnewvar=bc_&currentboxcoxvaluesfornaming._%substr(&currentxvars.,1,26);
				%let currentnewpvar=Pbc_&currentboxcoxvaluesfornaming._%substr(&currentxvars.,1,26);
				%end;
				%else %do;
     			%let currentnewvar=bc_&currentboxcoxvaluesfornaming._%substr(&currentxvars.,1,24);
				%let currentnewpvar=Pbc_&currentboxcoxvaluesfornaming._%substr(&currentxvars.,1,24);
                %end;
				proc sql;
					select &currentnewvar. into:corr_values from corr where variable = "&currentyvars.";
					select &currentnewpvar. into: p_value from corr where variable = "&currentyvars.";
				run;

				quit;

				%put &corr_values. &p_value.;

				data temp_box_chart_final;
					length type $32 y_vars $32 x_vars $32 classes $15 corr_value $10 p_value $10 case $13 category $6;
					y_vars 		=	"&currentyvars.";
					x_vars		=	"&currentxvars.";
					/* classes		=	"lambda &currentboxcoxvaluesfornaming."; */
					classes		=	"&currentboxcoxvaluesfornaming.";
					if index(classes,"_") = 1 then substr(classes,1,1) = "-";
					classes		=	translate(classes,".","_");
					corr_value	=	"%sysfunc(compress(&corr_values.))";
					p_value		=	"%sysfunc(compress(&p_value.))";

					%if %sysfunc(abs(&corr_values.)) >= &corr_cutoff. %then
						%do;
							case = "Significant";
						%end;
					%else
						%do;
							case = "Insignificant";
						%end;

					category	=	"boxcox";
					type		=	"boxcox";
				run;

				proc append base=box_chart_final data=temp_box_chart_final force;
				run;

				quit;

			%end;
		%end;
	%end;

	%do u = 1 %to %sysfunc(countw(&yvars.));
		%let currentyvars=%scan(&yvars.,&u.);

		%do  l= 1 %to %sysfunc(countw(&xvars.));
			%let currentxvars=%scan(&xvars.,&l.);
			ods output BOXCOX = brsq&u.&l.;

			proc transreg details data=in.dataworking;
				model BoxCox(&currentyvars./ lambda = &box_start. to &box_stop. by &box_step.) =
					identity(&currentxvars.);
			run;


			data brsq&u.&l.;
				set brsq&u.&l.;
				y_vars = "&currentyvars.";
				x_vars = "&currentxvars.";
			run;

			data brsq&u.&l.;
				set brsq&u.&l.(drop=Convenient RMSE CI Dependent);
			run;

			proc append base=brsq data=brsq&u.&l. FORCE nowarn;
			run;

		%end;
	%end;

	data brsq(drop=lambda);
	set brsq;
	classes=compress(lambda);
	run;

	proc sort data=box_chart_final;
		by classes;
	run;

	proc sort data=brsq;
		by classes;
	run;

	data box_chart_final2;
		MERGE box_chart_final(IN=In1) brsq(IN=In2);
		BY classes;
		IF (In1=1 and In2=1) then
			output box_chart_final2;
	RUN;

	data box_chart_final;
		set box_chart_final2 /*(drop = classes rename=(lambda = lambda))*/;
	run;

%mend boxcoxcorr;

%macro corr;

	data _null_;
		call symput("yvars", compbl("&yvars."));
		call symput("xvars", compbl("&xvars."));
		call symput("c_yvars", cats("'", tranwrd(compbl(lowcase("&yvars.")), " ", "', '"), "'"));
		call symput("c_xvars", cats("'", tranwrd(compbl(lowcase("&xvars.")), " ", "', '"), "'"));
	run;

	%put &yvars &xvars;
	%put &c_yvars &c_xvars;

	/*DYNAMIC FILTER*/
	%if "&flag_filter." = "true" %then
		%do;
			%let dataset_name=out.temporary;
			%let whr=;

			/*call SAS code for dynamic filtering*/
			%include %unquote(%str(%'&filterCode_path./dynamicFiltering.sas%'));
		%end;
	%else
		%do;
			%let dataset_name=in.dataworking;
		%end;

	data temp;
		set &dataset_name.;

		%if &grp_no.^= 0 %then
			%do;
				where grp&grp_no._flag = "&grp_flag.";
			%end;
	run;

	%let dataset_name=temp;

	/* Checking number of observations in dataset	*/
	%let dset=&dataset_name.;
	%let dsid = %sysfunc(open(&dset));
	%let nobs =%sysfunc(attrn(&dsid,NOBS));
	%let rc = %sysfunc(close(&dsid));

	%if &NOBS. =0 %then
		%do;

			data _null_;
				v1= "There are zero observations in the filtered dataset";
				file "&output_path./GENERATE_FILTER_FAILED.txt";
				put v1;
			run;

			/*delete unrequired datasets*/
			proc datasets library = out;
				delete temporary;
			run;

%macro delvars;

	data vars;
		set sashelp.vmacro;
	run;

	data _null_;
		set vars;

		if scope='GLOBAL' and substr(name,1,3) ne "SYS" and name ne "SASWORKLOCATION" and substr(name,1,1) ne "_" then
			call execute('%symdel '||trim(left(name))||';');
	run;

%mend;

%delvars;
%abort;
%end;
%else
	%do;
		%if "&box_cox." = "true" or "&lag." ^= "0" or "&lead." ^= "0" or "&trans_type." ^= "" or "&adstock_type." ^= "" %then
			%do;

				proc contents data = &dataset_name.(keep = &xvars.) out = contents(keep = name);
				run;

				data _temp_;
					set contents nobs = no_of_obs;
					suffix = put(_n_,8.);
					call symput (cats("x_var",suffix),compress(name));
					call symputx("no_of_obs",no_of_obs);
				run;

				%put &no_of_obs;

				%if "&adstock_type" ^= "" %then
					%do;
						%let decay_rates =;
						%let decay_names =;
						%let decay_count=0;
						%let decay = %sysevalf(&ad_start.);

						%do %until (%sysevalf(&decay.) >  %sysevalf(&ad_end.));

							data _null_;
								call symput("decay_rates", cat("&decay_rates.","!!","&decay."));
								call symput("decay_names", cat("&decay_names.","!!",tranwrd("&decay.",".","_")));
							run;

							%let decay_count = %sysevalf(&decay_count.+1);
							%let decay = %sysevalf(%sysevalf(&decay.) + %sysevalf(&ad_step.));
						%end;

						%put &decay_rates;
						%put &decay_names;
					%end;

					%if "&lag." ^= "0" or "&adstock_type." ^= "" or "&lead." ^= "0" %then %do;
						
					proc sort data=&dataset_name.(keep = primary_key_1644 &xvars. &yvars. &dateVarName.

								%if &grp_no.^= 0 %then grp&grp_no._flag;) out=final_temp;
								by &dateVarName.;
								run;
								quit;

					%end;

				%if "&lag." ^= "0" or "&trans_type." ^= "" or "&adstock_type." ^= "" %then
					%do;

						data final_temp(%if &grp_no.^= 0 %then drop=grp&grp_no._flag;);
							retain primary_key_1644;
						%if "&lag." ^= "0" or "&adstock_type." ^= "" or "&lead." ^= "0" %then %do;
							set final_temp;
							%end;
						%else %do;

							set &dataset_name.(keep = primary_key_1644 &xvars. &yvars. &dateVarName.

								%if &grp_no.^= 0 %then grp&grp_no._flag;);
							%end;

								%if &grp_no.^= 0 %then
									%do;
										where grp&grp_no._flag = "&grp_flag.";
									%end;

								%do a = 1 %to  &no_of_obs;
									%let samp = &&x_var&a;
									%let sample = %substr(&&x_var&a, 1, 28);

									%do i = 1 %to &lag.;
										lg_&sample.&i = lag&i(&samp);
									%end;

									%if %index(&trans_type.,rec) > 0 %then
										%do;
											rec_%substr(&&x_var&a, 1, 28) = (1/&&x_var&a..);
										%end;

									%if %index(&trans_type.,sqr) > 0 %then
										%do;
											sqr_%substr(&&x_var&a, 1, 28) = (&&x_var&a..)*(&&x_var&a..);
										%end;

									%if %index(&trans_type.,cub) > 0 %then
										%do;
											cub_%substr(&&x_var&a, 1, 28) = (&&x_var&a..)*(&&x_var&a..)*(&&x_var&a..);
										%end;

									%if %index(&trans_type.,log) > 0 %then
										%do;
											log_%substr(&&x_var&a, 1, 28) = log(&&x_var&a..);
										%end;

									%if %index(&trans_type.,sin) > 0 %then
										%do;
											sin_%substr(&&x_var&a, 1, 28) = sin(&&x_var&a..);
										%end;

									%if %index(&trans_type.,cos) > 0 %then
										%do;
											cos_%substr(&&x_var&a, 1, 28) = cos(&&x_var&a..);
										%end;

									%if "&adstock_type" ^= "" %then
										%do;
											%do decay_var = 1 %to %eval(&decay_count.);
												retain ad_%substr(&&x_var&a, 1, 24)_%scan(&decay_names,&decay_var,"!!");

												%if "&adstock_type." = "simple" %then
													%do;
														if _n_ = 1 then
															do;
																if &&x_var&a.. ^= . then
																	do;
																		ad_%substr(&&x_var&a, 1, 24)_%scan(&decay_names,&decay_var,"!!") = &&x_var&a..;
																	end;
																else if &&x_var&a.. = . then
																	do;
																		ad_%substr(&&x_var&a, 1, 24)_%scan(&decay_names,&decay_var,"!!") = 0;
																	end;
															end;
														else
															do;
																if &&x_var&a.. ^= . then
																	do;
																		ad_%substr(&&x_var&a, 1, 24)_%scan(&decay_names,&decay_var,"!!") = &&x_var&a.. + ((1 - %scan(&decay_rates,&decay_var,"!!"))*(ad_%substr(&&x_var&a, 1, 24)_%scan(&decay_names,&decay_var,"!!")));
																	end;
																else if &&x_var&a.. = . then
																	do;
																		ad_%substr(&&x_var&a, 1, 24)_%scan(&decay_names,&decay_var,"!!") = 0 + ((1 - %scan(&decay_rates,&decay_var,"!!"))*(ad_%substr(&&x_var&a, 1, 24)_%scan(&decay_names,&decay_var,"!!")));
																	end;
															end;
													%end;

												%if "&adstock_type." = "log" %then
													%do;
														if _n_ = 1 then
															do;
																ad_%substr(&&x_var&a, 1, 24)_%scan(&decay_names,&decay_var,"!!") = &&x_var&a..;
															end;
														else
															do;
																ad_%substr(&&x_var&a, 1, 24)_%scan(&decay_names,&decay_var,"!!") = log(&&x_var&a..) + ((1 - %scan(&decay_rates,&decay_var,"!!"))*(ad_%substr(&&x_var&a, 1, 24)_%scan(&decay_names,&decay_var,"!!")));
															end;
													%end;
											%end;
										%end;
								%end;
						run;

					%end;

				%if "&lead." ^= "0" %then
					%do;

						data _null_;
							%if "&lag." ^= "0" or "&trans_type." ^= "" or "&adstock_type." ^= "" %then
								%do;
									call symput("lag_base", "final_temp");
								%end;

							%if "&lag." = "0" and "&trans_type." = "" and "&adstock_type." = "" %then
								%do;
									call symput("lag_base", "temp");
								%end;
						run;

						proc sort data = &lag_base.;
							by descending &dateVarName.;
						run;

						data final_temp;
							retain primary_key_1644;
							set &lag_base.;

							%if "&lag_base." = "temp" and &grp_no.^= 0 %then
								%do;
									where grp&grp_no._flag = "&grp_flag.";
								%end;

							%do a = 1 %to &no_of_obs.;
								%let samp = &&x_var&a;
								%let sample = %substr(&&x_var&a, 1, 28);

								%do i = 1 %to &lead;
									ld_&sample.&i = lag&i(&samp);
								%end;
							%end;
						run;

						proc sort data = final_temp;
							by primary_key_1644;
						run;

					%end;

				%if &box_cox. = true %then
					%do;
						%boxcoxcorr;

						proc sort data=boxcoxvars out=boxcoxvars;
							by primary_key_1644;
						run;

						quit;

						%if %sysfunc(exist(final_temp)) %then
							%do;

								proc sort data=final_temp out=final_temp;
									by primary_key_1644;
								run;

								quit;

								data final_temp;
									merge final_temp boxcoxvars;
									by primary_key_1644;
								run;

							%end;
						%else
							%do;

								data final_temp(keep=primary_key_1644 &xvars. &yvars.);
									set in.dataworking;

									%if &grp_no.^= 0 %then
										%do;
											where grp&grp_no._flag = "&grp_flag.";
										%end;
								run;

								proc sort data=final_temp out=final_temp;
									by primary_key_1644;
								run;

								quit;

								data final_temp;
									merge final_temp boxcoxvars;
									by primary_key_1644;
								run;

							%end;
					%end;
			%end;
		%else
			%do;

				data final_temp;
					retain primary_key_1644;
					set &dataset_name.(keep = primary_key_1644  &xvars. &yvars.
                        %if &trend_var. ^=   %then &trend_var.
						%if &grp_no.    ^= 0 %then grp&grp_no._flag;);

						%if &grp_no.^= 0 %then
							%do;
								where grp&grp_no._flag = "&grp_flag.";
							%end;
				run;

			%end;

		/*&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&*/
		/* CORRELATION - proc corr */
		ods output PearsonCorr = corr_table(rename=(variable=xvar ));

		proc corr data = final_temp out=out.cormat(where = (_type_ not in ("MEAN","STD","N")));
			var &yvars;
			with &xvars.

			%if "&lag." ^= "0" %then
				%do;
					lg_:
				%end;

			%if "&lead." ^= "0" %then
				%do;
					ld_:
				%end;

			%if %index(&trans_type.,log) > 0 %then
				%do;
					log_:
				%end;

			%if %index(&trans_type.,rec) > 0 %then
				%do;
					rec_:
				%end;

			%if %index(&trans_type.,sqr) > 0 %then
				%do;
					sqr_:
				%end;

			%if %index(&trans_type.,cub) > 0 %then
				%do;
					cub_:
				%end;

			%if %index(&trans_type.,sin) > 0 %then
				%do;
					sin_:
				%end;

			%if %index(&trans_type.,cos) > 0 %then
				%do;
					cos_:
				%end;

			%if "&adstock_type." ^= "" %then
				%do;
					ad_:
				%end;

			%if &box_cox. = true %then
				%do;
					&boxcoxnewvars.
				%end;;
		run;

		data out.cormat;
			set out.cormat ( drop = _type_ rename  = (_name_ = xvar));
		run;

		/* CORRELATION MATRIX */
		%if "&flag_cormat." = "true" %then
			%do;
				%if "&cormat_selectVars." = "true" %then
					%do;
						%let all = &xvars. &yvars.;
						ods output PearsonCorr = selectvars (keep = &all. variable);

						proc corr data = &dataset_name.(keep = &all.
							%if &grp_no.^= 0 %then
								%do;
									grp&grp_no._flag
								%end;
							);
							var &all.;

							%if &grp_no.^= 0 %then
								%do;
									where grp&grp_no._flag = "&grp_flag.";
								%end;
						run;

						proc export data = selectvars
							outfile = "&output_path./corr_matrix/selectVars_cormat.csv"
							dbms = CSV replace;
						run;

					%end;

				%if "&cormat_allVars." = "true" %then
					%do;

						proc contents data = &dataset_name.(drop=primary_key_1644) out = contents_allvars;
						run;

						proc sql;
							select distinct (name) into: vars separated by " " from contents_allvars;
						quit;

						%put &vars.;
						ods output summary=summary;

						proc means data=&dataset_name.
							NMISS N;
						run;

						proc transpose data=summary out=t1;
						run;

						%let dset=&dataset_name.;
						%let dsid = %sysfunc(open(&dset));
						%let nobs =%sysfunc(attrn(&dsid,NOBS));
						%let rc = %sysfunc(close(&dsid));
						%put &nobs.;

						data t1;
							set t1;
							vname  = substr(_name_,1,find(_name_,'_',-vlength(_name_))-1);
							_name_ = scan(_name_,-1,'_');
						run;

						Proc transpose data=t1 out=t2;
							by vname notsorted;
							var col1;
						run;

						data t2;
							set t2;

							if nmiss=. then
								nmiss=&nobs.-n;
						run;

						data t3;
							set t2;

							if nmiss>n then
								delete;
						run;

						proc sql;
							select vname into :var1 separated by " " from T3;
						quit;

						%put &var1.;

						data &dataset_name.;
							set &dataset_name.(keep = &vars.);
						run;

						ods output PearsonCorr = allvars;

						proc corr data = &dataset_name.(keep= &vars.
							%if &grp_no.^= 0 %then
								%do;
									grp&grp_no._flag
								%end;
							);
							%if &grp_no.^= 0 %then
								%do;
									where grp&grp_no._flag = "&grp_flag.";
								%end;
						run;

						data allvars (keep= &vars. variable);
							set allvars;
						run;

						proc export data = allvars
							outfile = "&output_path./corr_matrix/allVars_cormat.csv"
							dbms = CSV replace;
						run;

					%end;
			%end;

		/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/
		/*CSV OUTPUT*/
		/*modifying the corr output*/
		%let i = 1;

		%do %until (not %length(%scan(&yvars, &i)));

			data _null_;
				call symput("y_var", "%scan(&yvars, &i)");
			run;

			data corr(rename=(&y_var.=corr_value P&y_var.=p_value));
				retain y_vars;
				length y_vars $32.;
				set corr_table (keep = xvar &y_var. P&y_var.);
				y_vars = "&y_var.";
				xvar = lowcase(strip(xvar));
			run;

			proc append base = correlation data = corr force;
			run;

			%let i = %eval(&i.+1);
		%end;

		/*modifying corr table*/
		data correlation(drop=xvar);
			retain y_vars x_vars classes corr_value p_value case;
			length category $15.;
			length classes $17.;
			length x_vars $32.;
			length case $13.;
			set correlation;

			/*	x_vars = xvar;*/
			if abs(corr_value) >= %sysevalf(&corr_cutoff.) then
				case = "Significant";

			if abs(corr_value) < %sysevalf(&corr_cutoff.) then
				case = "Insignificant";
			%let yvar_no = 1;

			%do %until (not %length(%scan(&xvars., &yvar_no)));
				if lowcase(xvar) = lowcase("%scan(&xvars., &yvar_no)") then
					do;
						%if "&lag." ^= "0" or "&lead." ^= "0" %then
							%do;
								category = "lag-lead";
								classes = "Original_Variable";
								x_vars = "%scan(&xvars., &yvar_no)";
								output;
							%end;

						%if "&trans_type." ^= "" %then
							%do;
								category = "transformations";
								classes = "Original_Variable";
								x_vars = "%scan(&xvars., &yvar_no)";
								output;
							%end;

						%if "&adstock_type." ^= "" %then
							%do;
								category = "adstock";
								classes = "Original_Variable";
								x_vars = "%scan(&xvars., &yvar_no)";
								output;
							%end;

						%if "&lag." = "0" and "&lead." = "0" and "&adstock_type." = "" and "&trans_type." = "" %then
							%do;
								classes = "Original_Variable";
								x_vars = "%scan(&xvars., &yvar_no)";
								output;
							%end;
					end;

				%let lag_no = 1;

				%do %until (%eval(&lag_no.)>%eval(&lag.));
					if lowcase(xvar) = lowcase("lg_%substr(%scan(&xvars., &yvar_no),1,28)&lag_no.") then
						do;
							category = "lag-lead";
							classes = "lag - &lag_no.";
							x_vars = "%scan(&xvars., &yvar_no)";
							output;
						end;

					%let lag_no = %eval(&lag_no.+1);
				%end;

				%let lead_no = 1;

				%do %until (%eval(&lead_no.)>%eval(&lead.));
					if lowcase(xvar) = lowcase("ld_%substr(%scan(&xvars., &yvar_no),1,28)&lead_no.") then
						do;
							category = "lag-lead";
							classes = "lead - &lead_no.";
							x_vars = "%scan(&xvars., &yvar_no)";
							output;
						end;

					%let lead_no = %eval(&lead_no.+1);
				%end;

				%if "&adstock_type" ^= "" %then
					%do;
						%do ad_name = 1 %to %eval(&decay_count.);
							if lowcase(xvar) = lowcase("ad_%substr(%scan(&xvars., &yvar_no),1,24)_%scan(&decay_names, &ad_name, "!!")") then
								do;
									category = "adstock";
									classes = "decay - %scan(&decay_rates, &ad_name, "!!")";
									x_vars = "%scan(&xvars., &yvar_no)";
									output;
								end;
						%end;
					%end;

				%if %index(&trans_type.,log) > 0 %then
					%do;
						if lowcase(xvar) = lowcase("log_%substr(%scan(&xvars., &yvar_no),1,28)") then
							do;
								category = "transformations";
								classes = "Log";
								x_vars = "%scan(&xvars., &yvar_no)";
								output;
							end;
					%end;

				%if %index(&trans_type.,rec) > 0 %then
					%do;
						if lowcase(xvar) = lowcase("rec_%substr(%scan(&xvars., &yvar_no),1,28)") then
							do;
								category = "transformations";
								classes = "Reciprocal";
								x_vars = "%scan(&xvars., &yvar_no)";
								output;
							end;
					%end;

				%if %index(&trans_type.,sqr) > 0 %then
					%do;
						if lowcase(xvar) = lowcase("sqr_%substr(%scan(&xvars., &yvar_no),1,28)") then
							do;
								category = "transformations";
								classes = "Square";
								x_vars = "%scan(&xvars., &yvar_no)";
								output;
							end;
					%end;

				%if %index(&trans_type.,cub) > 0 %then
					%do;
						if lowcase(xvar) = lowcase("cub_%substr(%scan(&xvars., &yvar_no),1,28)") then
							do;
								category = "transformations";
								classes = "Cube";
								x_vars = "%scan(&xvars., &yvar_no)";
								output;
							end;
					%end;

				%if %index(&trans_type.,sin) > 0 %then
					%do;
						if lowcase(xvar) = lowcase("sin_%substr(%scan(&xvars., &yvar_no),1,28)") then
							do;
								category = "transformations";
								classes = "Sine";
								x_vars = "%scan(&xvars., &yvar_no)";
								output;
							end;
					%end;

				%if %index(&trans_type.,cos) > 0 %then
					%do;
						if lowcase(xvar) = lowcase("cos_%substr(%scan(&xvars., &yvar_no),1,28)") then
							do;
								category = "transformations";
								classes = "Cosine";
								x_vars = "%scan(&xvars., &yvar_no)";
								output;
							end;
					%end;

				%let yvar_no = %eval(&yvar_no.+1);
			%end;
		run;

		data lag;
			set correlation;

			if classes="Original_Variable" and category="lag-lead";

			if classes="Original_Variable" and category="lag-lead" then
				type="lead";
		run;

		data correlation;
			set correlation lag;
		run;

		data correlation;
			set correlation;

			if classes="Original_Variable" and category="lag-lead" and type ^="lead" then
				type="lag";
		run;

		data correlation;
			length type $32.;
			set correlation;

			if scan(classes,1,"-")="lag" then
				type="lag";
			else if scan(classes,1,"-")="lead" then
				type="lead";
			else if type="" then
				type=category;
		run;

		/*	proc sql;*/
		/*		create table correlation  as select *, max(corr_value) as High, min(corr_value) as Low, max(corr_value)- min(corr_value) as Difference*/
		/*		from correlation*/
		/*		group by type,y_vars,x_vars;*/
		/*		quit;*/
		proc sql;
			create table correlation  as select * from correlation
				group by type,y_vars,x_vars;
		quit;

		proc sort data=correlation;
			by y_vars x_vars category;
		run;

		%if "&box_cox." = "true" and "&lag." = "0" and "&lead." = "0" and "&trans_type." = "" and "&adstock_type." = "" %then
			%do;

				proc sql;
					create table correlation1 as 
						select type , y_vars , x_vars , classes , corr_value, category, p_value, RSquare, LogLike
							from box_chart_final;
				quit;

				data correlation;
					set correlation1;
					case = "Significant";
				run;

			%end;
		%else %if "&box_cox." = "true" or "&lag." ^= "0" or "&lead." ^= "0" or "&trans_type." ^= "" or "&adstock_type." ^= ""  %then
			%do;
				%if %sysfunc(exist(box_chart_final)) %then
					%do;

						data correlation(drop=p_value corr_value rename=(tempp_value=p_value tempcorr_value=corr_value));
							set correlation;
							tempp_value=put(p_value,best12.);
							tempcorr_value=put(corr_value,best12.);
						run;

						data correlation;
							set correlation box_chart_final;
						run;

					%end;
				%else
					%do;

						data correlation;
							set correlation;
						run;

					%end;
			%end;
		%else
			%do;

				data correlation;
					set correlation;
				run;

			%end;

			
		data correlation;
		length category $20.;
		set correlation;
		if type = " " then type="Original_Variable";
		if category = " " then category="Original_Variable";
		run;

		data correlation;
			retain type y_vars x_vars classes corr_value p_value case category;
			set correlation;
		run;


		/*CSV export*/
		proc export data = correlation
			outfile = "&output_path./correlation.csv"
			dbms = CSV replace;
		run;

		/*I write dirty code thank you :D*/
		/*SAS graphs for more than 6000 data-points*/
		%let dset=temp;
		%let dsid = %sysfunc(open(&dset));
		%let nobs =%sysfunc(attrn(&dsid,NOBS));
		%let rc = %sysfunc(close(&dsid));
		%put &nobs;

		data nobs;
			nobs = "&nobs.";
		run;

		data _null_;
			set nobs;
			v1=nobs;
			file "&output_path./NOBS.TXT";
			put v1;
		run;

		%if %eval(&nobs.) > 5000 %then
			%do;

				proc sql;
					select (xvar) into :c_xvars separated by " " from out.cormat;
				quit;

				%put &c_xvars;

				/*		libname chart "&output_path./charts";*/
				/*		goptions device = jpeg;*/
				/*		ods graphics on;*/
				/*		ods html gpath = "&output_path./charts";*/
				/*		proc gplot data=final_temp gout=chart; */
				/*			%let j = 1;*/
				/*			%do %until (not %length(%scan(&yvars,&j)));*/
				/*				%let k = 1;*/
				/*				%do %until (not %length(%scan(&c_xvars,&k)));*/
				/**/
				/*					plot %scan(&yvars,&j)*%scan(&c_xvars,&k);*/
				/**/
				/*					%let k = %eval(&k.+1);*/
				/*				%end;*/
				/*				%let j = %eval(&j.+1);*/
				/*			%end;*/
				/*			run;*/
				/*			ods html close;*/
				/*		ods graphics off;*/
				libname chart "&output_path./charts";
				filename fileref "&output_path./charts";
				goptions device = gif gsfname=fileref gsfmode=replace;
				ods graphics on;

				/*		ods html gpath = "&output_path./charts";*/
				ods listing gpath="&output_path./charts";

				proc gplot data=final_temp gout=chart;
					%let j = 1;

					%do %until (not %length(%scan(&yvars,&j)));
						%let k = 1;

						%do %until (not %length(%scan(&c_xvars,&k)));
							plot %scan(&yvars,&j)*%scan(&c_xvars,&k);
							%let k = %eval(&k.+1);
						%end;

						%let j = %eval(&j.+1);
					%end;
				run;

				ods listing close;

				/*		ods html close;*/
				ods graphics off;
				%let c_count = 0;

				data chart_index;
					length yvar xvar $32.;
					length chart $10.;
					%let j = 1;

					%do %until (not %length(%scan(&yvars,&j)));
						%let k = 1;

						%do %until (not %length(%scan(&c_xvars,&k)));
							yvar = "%scan(&yvars,&j)";
							xvar = "%scan(&c_xvars,&k)";
							chart = "gplot%eval(&c_count.)";
							output;
							%let c_count = %eval(&c_count.+1);
							%let k = %eval(&k.+1);
						%end;

						%let j = %eval(&j.+1);
					%end;
				run;

				data chart_index;
					set chart_index;

					if chart = "gplot0" then
						chart = "gplot";
				run;

				proc export data = chart_index
					outfile = "&output_path./charts/chart_index.csv"
					dbms = csv replace;
				run;

			%end;

		/*CSV for charts*/
        
        %if(&trend_var. !=  ) %then %do;
        proc sort data = final_temp(drop= primary_key_1644)  out= final_temp;
		by &trend_var.;
		quit;

        data final_temp(drop=date1 date2);
		set final_temp;
        date1 = &trend_var.;
        date2 = lag(&trend_var.);
		datecheck = date1 - date2;
        run;
        
		proc sql;
		select distinct(datecheck) into:datechecker separated by " " from final_temp;
		quit; 
        %end;

/*       uniq count of datechecker should be "2" bcoz "." is also included*/
/*		 in date1-date2*/
		    

        proc export data = final_temp
			outfile = "&output_path./corr_charts.csv"
			dbms = CSV replace;
		run;

		
		%if(%sysfunc(countw(&datechecker.))>2) %then %do;
		data _null_;
         msg = "Date variable failed to satisfy the DATECHECK conditions.Please TRY AGAIN with another date variable";
		file "&output_path./trend_analysis_ERROR.TXT";
			put msg;
		run;
		%end;

		/*xml creation*/
		libname corr xml "&output_path./correlation.xml";

		data corr.cormat;
			set out.cormat;
		run;

		/*delete unrequired datasets*/
/*		proc datasets library = out;*/
/*			delete temporary;*/
/*		run;*/

		/* flex uses this file to test if the code has finished running */
		data _null_;
			%if %sysfunc(fileexist(&output_path./correlation.csv)) %then
				%do;
					v1 = "COMPLETED";
				%end;
			%else
				%do;
					v1 = "FAILED";
				%end;

			file "&output_path./CORRELATION_COMPLETED.TXT";
			put v1;
		run;

	%end;
%mend corr;

%corr;

proc datasets lib=work kill nolist;
quit;
