options mlogic symbolgen mfile mprint;

proc printto log="&output_path./Univariate_Log.log";
run;
quit;

proc printto;
run;
quit;

dm log 'clear';
libname in "&input_path";
libname out "&output_path";

FILENAME MyFile "&output_path./VARIABLE_CHARACTERISTICS_COMPLETED.txt";

DATA _NULL_;
	rc = FDELETE('MyFile');
RUN;

FILENAME MyFile "&output_path./verify_error.txt";

DATA _NULL_;
	rc = FDELETE('MyFile');
RUN;

FILENAME MyFile "&output_path./ GENERATE_FILTER_FAILED.txt";

DATA _NULL_;
	rc = FDELETE('MyFile');
RUN;

%macro csds;
	%let lognormal_chk                     	=%index(&histogram_options.,LogNormal);
	%let weibull_chk						=%index(&histogram_options.,Weibull);
	%let gamma_chk							=%index(&histogram_options., Gamma);
	%global var_failed;
	%let var_failed_min=;
	%let var_failed_std=;
	%let text=;

	%do i= 1 %to %sysfunc(countw(&var_list.," "));
		%let var_now=%scan(&var_list.,&i.," ");

		%if  ("&flag_fitdistr."="true") %then
			%do;

				proc sql;
					select min(&var_now.) into:ch  from in.dataworking;
				run;

				quit;

				%if %sysevalf(&ch. <= 0) %then
					%do;
						%let var_failed_min = &var_now.  &var_failed_min.;
					%end;
			%end;

		/*		%if ("&flag_whiteNoise_test."="true" or "&flag_unit_test."="true" or "&flag_acf_plot."="true" or "&flag_pacf_plot."="true") %then*/
		/*			%do;*/
		/**/
		/*				proc sql;*/
		/*					select std(&var_now.) into:std_var  from in.dataworking;*/
		/*				run;*/
		/**/
		/*				quit;*/
		/**/
		/*				%if &std_var. < 0.5 %then*/
		/*					%do;*/
		/*						%let var_failed_std=&var_now. &var_failed_std.;*/
		/*					%end;*/
		/*			%end;*/
	%end;

	%if "&var_failed_min." ^= "" %then
		%do;
			%let text = "Following variables have either zero or negative values due to which fit distribution cannot be applied: &var_failed_min.. Kindly deselect the mentioned variables and then apply fit distribution";

			data _null_;
				file "&output_path./verify_error.txt";
				put &text.;
			run;

			%abort;
		%end;

	/*	%if "&var_failed_std." ^= "" %then*/
	/*		%do;*/
	/*			%let text = &text. "Standard deviation of the following variables is close to zero due to which";*/
	/**/
	/*			data _null_;*/
	/*				file "&output_path./verify_error.txt";*/
	/*				put &text.;*/
	/*			run;*/
	/**/
	/*			%abort;*/
	/*		%end;*/
%mend csds;

%csds;
%put &var_failed.;

%macro MISSING(dataset,variables);
	%global missingVariables;
	%global minNonMissingCount;

	proc means data=&dataset. NMISS N;
		var &variables.;
		output out = nonmissing;
	run;

	quit;

	data nonmissing(drop = _TYPE_ _FREQ_ _STAT_);
		set nonmissing;

		if _STAT_ ^= 'N' then
			delete;
	run;

	proc transpose data = nonmissing out = nonmissingt;
	run;

	quit;

	proc sql;
		select min(COL1) into: minNonMissingCount from nonmissingt;
	run;

	quit;

	%put &minNonMissingCount.;

	%if &minNonMissingCount. = 0 %then
		%do;

			data nonmissingt;
				set nonmissingt;

				if COl1 ^= 0 then
					delete;
			run;

			proc sql;
				select _NAME_ into: missingVariables separated by " " from nonmissingt;
			run;

			quit;

		%end;
%mend;

%macro kruskalwallis;
	%let class=grp&grp_no._flag;
	ods output WilcoxonScores = WilcoxonScores;
	ods output KruskalWallisTest = KruskalWallisTest;

	proc npar1way wilcoxon data=&dataset_name.;
		class &class.;
		var &var_name.;
	run;

	quit;

	/*Box-plot pngs*/
	data tmp;
		set &dataset_name.;
		Panel_levels = catx("_" , of &grp_vars.);
	run;

	ods graphics on/width=3.25in height=3.25in  reset=all;
	goptions reset=all device=png100 gsfmode=replace;
	filename odsout "&output_path./&v_id.";
	goptions reset=all device=png100;
	ods listing gpath=odsout;
	footnote1 h = .5 '  ';

	/*		ods output WilcoxonScores = WilcoxonScores;*/
	/*		ods output KruskalWallisTest = KruskalWallisTest;*/
	proc npar1way wilcoxon plots=wilcoxonboxplot  data=tmp;
		class Panel_levels;
		var &var_name.;
	run;

	quit;

	ods graphics off;

	data WilcoxonScores;
		set WilcoxonScores(rename=(class=flag N=NumberOfObservations SumOfScores=SumOfScores expectedsum=ExpectedSumUnderH0 StdDevOfSum=StdDevOfSumUnderH0 MeanScore=MeanScore) drop=variable);
	run;

	libname filter "&input_path./&grp_no./";

	data byvar;
		set filter.byvar(keep=key_name flag);
	run;

	proc sort data = byvar out = byvar;
		by flag;
	run;

	quit;

	proc sort data = WilcoxonScores out = WilcoxonScores;
		by flag;
	run;

	quit;

	data WilcoxonScores(rename=(key_name=Levels));
		merge WilcoxonScores byvar;
		by flag;
	run;

	data WilcoxonScores;
		retain Levels;
		set WilcoxonScores(drop=flag);
	run;

	proc export data=WilcoxonScores outfile="&output_path./&v_id./WilcoxonScores.csv" dbms=csv replace;
	run;

	quit;

	data temp(drop=nvalue1 rename=(label1=Statistic cvalue1=Estimate));
		length label1 $25 cvalue1 $25;
		set KruskalWallisTest(keep=label1 nvalue1 cvalue1);
		Estimate=put(nvalue1,best12.);

		if label1 = "Pr > Chi-Square" then
			do;
				label1 = "p value";
				call symput("pv",putn(nvalue1,6.4));
			end;
	run;

	%if &pv. > &kruskal_wallis_cutoff. %then
		%do;

			data temp2;
				length Statistic $25 Estimate $25;
				Statistic="Result";
				Estimate="Insignificant";
			run;

		%end;
	%else
		%do;

			data temp2;
				length Statistic $25 Estimate $25;
				Statistic="Result";
				Estimate="Significant";
			run;

		%end;

	data temp;
		set temp temp2;
	run;

	proc export data=temp outfile="&output_path./&v_id./KruskalWallisTest.csv" dbms=csv replace;
	run;

	quit;

	proc transpose data=temp out=temp;
		var Estimate;
	run;

	quit;

	data temp;
		retain Selected_variable Across_variable Statistic DF Chi_Square p_value Result;
		set temp(drop= _NAME_ rename=(col1=Chi_Square col2=DF col3=p_value col4=Result));
		Selected_variable="&var_name.";
		Across_variable="&grp_vars.";
		Statistic = "Kruskal_Wallis";
	run;

	proc export data=temp outfile="&output_path./&v_id./KruskalWallisTestTransposed.csv" dbms=csv replace;
	run;

	quit;

%mend;

%macro var_char;
	%if %SYMEXIST(kruskal_wallis_test_flag)^=1 %then
		%do;
			%let kruskal_wallis_test_flag=;
		%end;

	%let flag_gamma_distribution=false;
	%let flag_normal_distribution=false;
	%let flag_lognormal_distribution =false;
	%let flag_exponential_distribution =false;
	%let flag_weibull_distribution=false;

	%if "&flag_fitdistr."="true" %then
		%do u = 1 %to %sysfunc(countw(&histogram_options.," "));
			%let histvar=%scan("&histogram_options.",&u.," ");
			%let flag_&histvar._distribution=true;
		%end;

	%let p=0;
	%let gftest=/ normal lognormal exponential gamma weibull;

	%if &flag_normal_distribution.=false %then
		%do;
			%let gftest='/ normal lognormal exponential gamma weibull';
			%let type = 'normal';

			data _null_;
				call symput("gftest", prxchange('s/'||&type.||'//',1, &gftest.));
			run;

		%end;

	%if &flag_lognormal_distribution.=false %then
		%do;
			%let gftest =%sysfunc(transtrn(&gftest.,lognormal,%str()));
		%end;

	%if &flag_gamma_distribution.=false %then
		%do;
			%let gftest =%sysfunc(transtrn(&gftest.,gamma,%str()));
		%end;

	%if &flag_exponential_distribution.=false %then
		%do;
			%let gftest =%sysfunc(transtrn(&gftest.,exponential,%str()));
		%end;

	%if &flag_weibull_distribution.=false %then
		%do;
			%let gftest =%sysfunc(transtrn(&gftest.,weibull,%str()));
		%end;

	%let gftesting=%sysfunc(tranwrd(&gftest.,/,%str()));

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

	data subdata(rename=(grp0=grp0_flag) );
		set &dataset_name.;
		grp0="1_1_1";

		/*		if cmiss(of _all_) then*/
		/*			delete;*/
	run;

	%if "&grp_no."^=0 %then
		%do;
			%let distinct_temp=%sysfunc(tranwrd(%str("&grp_flag."), %str( ), %str(",")));
		%end;
	%else
		%do;
			/*		%let distinct_grp_variable=1_1_1;*/
			%let distinct_temp="1_1_1";
		%end;

	data subdata_temper;
		set subdata;
		where grp&grp_no._flag in (&distinct_temp.);
	run;

	%if &grp_vars.^= %then
		%do;

			data subdata(drop=grp&grp_no._flag rename=(col=grp&grp_no._flag));
				set subdata_temper;

				%if %sysfunc(countw(&grp_vars.," "))=1 %then
					%do;
						col=catx("_",%scan(&grp_vars.,1));
					%end;

				%if %sysfunc(countw(&grp_vars.," "))=2 %then
					%do;
						col=catx("_",%scan(&grp_vars.,1),%scan(&grp_vars.,2));
					%end;

				%if %sysfunc(countw(&grp_vars.," "))=3 %then
					%do;
						col=catx("_",%scan(&grp_vars.,1),%scan(&grp_vars.,2),%scan(&grp_vars.,3));
					%end;
			run;

		%end;
	%else
		%do;
			%let grp_vars=grp0_flag;
		%end;

	%if &grp_no.^=0 %then
		%do;

			proc sql;
				select distinct(grp&grp_no._flag)  into: distinct_grp_variable separated by "!!" from subdata;
			run;

			quit;

			%put &distinct_grp_variable.;
		%end;
	%else
		%do;
			%let distinct_grp_variable=1_1_1;
		%end;

	/* Checking number of observations in dataset	*/
	%let dset=subdata;
	%let dsid = %sysfunc(open(&dset));
	%let nobss =%sysfunc(attrn(&dsid,NOBS));
	%let rc = %sysfunc(close(&dsid));

	%if &NOBSS. =0 %then
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

			quit;

		%end;
	%else
		%do;

			proc sort data = subdata(keep =&var_list. primary_key_1644) out = subData1;
				by primary_key_1644;
			run;

			quit;

			proc sort data = subdata(keep = &grp_vars. primary_key_1644) out = subData2;
				by &grp_vars.;
			run;

			quit;

			%if "&grp_vars." ^= "" %then
				%do;

					proc contents data = subData2 (keep = &grp_vars.) out = contents(keep = name type);
					run;

					quit;

					proc sql noprint;
						select count(*) into :num_varcnt from contents where type = 1;
					run;
					quit;

				%end;

			%let allMissingVariables =;
			%let indicator = 0;
			%let count_miss = 0;

			%do i = 1 %to %sysfunc(countw(&distinct_grp_variable.,"!!"));
				%let comma=,;

				data temp_dataset;
					set subdata;
					where grp&grp_no._flag="%scan("&distinct_grp_variable.",&i.,"!!")";
				run;

				%MISSING(dataset = temp_dataset,variables = &var_list.);

				%if &minNonMissingCount. = 0 %then
					%do;
						%let indicator = 1;
						%let count_miss = %eval(&count_miss.+1);
						%let panel_level = %scan("&distinct_grp_variable.",&i.,"!!");

						%if &count_miss. = 1 %then
							%do;
								%let comma =;
							%end;

						%let allMissingVariables = &allMissingVariables.&comma. <&missingVariables.> for the panel level <&panel_level.>;
					%end;
			%end;

			%if &indicator. = 1 %then
				%do;
					%let text = All values are missing in the variable(s) &allMissingVariables.. Kindly deselect the variable(s).;

					data _null_;
						file "&output_path./verify_error.txt";
						put "&text.";
					run;

					endsas;
				%end;

			%do var_no=1 %to %sysfunc(countw(&var_list.));

				data _null_;
					call symput ("var_name", "%scan(&var_list,&var_no)");
					call symput ("v_id", "%scan(&var_id,&var_no)");
				run;

				%put &var_name &v_id;

				/*				"&treatment."="across_groupby"*/
				%if "&kruskal_wallis_test_flag."="true" %then
					%do;
						%kruskalwallis;
					%end;

				/* BASIC CHARACTERSTICS CODE */
				proc sort data=subdata;
					by grp&grp_no._flag;
				run;

				quit;

				proc univariate data = subData;
					by grp&grp_no._flag;
					var &var_name.;
					output out = uni 
						mean = Mean 
						median = Median 
						mode = Mode 
						std = StandardDeviation 
						nobs = ObservationsUsed 
						nmiss = NumberOfMissing 
						max = Maximum 
						min = Minimum
						qrange =InterQuartileRange 
						range = Range 
						pctlpts = 25 75 pctlpre = p_;
				run;

				quit;

				data uni;
					set uni;
					format variable $32.;
					variable = "&var_name.";
				run;

				proc sql;
					create table unique as
						select grp&grp_no._flag as grp_variable from uni;
				run;

				quit;

				proc export data =unique
					outfile = "&output_path./uni_new_vars.csv"
					dbms = csv replace;
				run;

				proc export data =unique
					outfile = "&output_path./&v_id./uni_new_vars.csv"
					dbms = csv replace;
				run;

				quit;

				%if "&flag_box_plot." = "true" or "&flag_outliers." = "true" %then
					%do;

						data uni (drop = p_25 p_75);
							set uni;
							LowerBound= p_25 - (1.5*interquartilerange);
							UpperBound = p_75 + (1.5*interquartilerange);
						run;

						data subData;
							merge subData(in = a) uni(in = b);
							by grp&grp_no._flag;

							if a;
						run;

						proc sql;
							create table outliers as
								select grp&grp_no._flag,
									count(case when &var_name. = 0 then &var_name. end) as NumberOfZeros,
									count(case when (&var_name. < LowerBound) or  (&var_name. > UpperBound) then &var_name. end) as NumberOfOutliers
								from subData
									group by grp&grp_no._flag
							;
						run;

						quit;

						data uni;
							merge uni(in = a) outliers(in = b);
							by  grp&grp_no._flag;

							if a;
						run;

					%end;

				proc transpose data = uni out = uniout(drop = _label_ rename = (_name_ = statistic col1 = estimate) );
					by  grp&grp_no._flag;
				run;

				quit;

				data _null_;
					set uni end = eof;
					suffix = put(_n_,8.);
					call symputx(cats("cond",suffix),grp&grp_no._flag);

					if eof then
						call symput("grp_vcnt", compress(_n_));
				run;

				%put cond1 &cond2 &cond3 &cond4 &cond5 &cond6 &grp_vcnt.;

				/*		libname outuniv xml "&output_path./&v_id./uni.xml";*/
				data univariate;
					set uniout;

					if strip(statistic) = "Mean" then
						statistic = "Mean";

					if strip(statistic) = "StandardDeviation" then
						statistic = "StandardDeviation";

					if strip(statistic) = "Kurtosis" then
						statistic = "Kurtosis";

					if strip(statistic) = "NumberOfMissing" then
						statistic = "NumberOfMissing";

					if strip(statistic) = "ObservationsUsed" then
						statistic = "ObservationsUsed";

					if strip(statistic) = "Maximum" then
						statistic = "Maximum";

					if strip(statistic) = "Minimum" then
						statistic = "Minimum";

					if strip(statistic) = "Range" then
						statistic = "Range";

					if strip(statistic) = "InterQuartileRange" then
						statistic = "InterQuartileRange";

					if strip(statistic) = "Mode" then
						statistic = "Mode";
				run;

				proc sql;
					create table uniout1 as 
						select statistic, estimate,  grp&grp_no._flag
							from uniout;
				run;

				quit;

				data uniout1(rename=(grp&grp_no._flag=grp_variable estimate=value));
					set uniout1;
				run;

				quit;


				proc export data =univariate
					outfile = "&output_path./&v_id./univariate.csv"
					dbms = csv replace;
				run;

				quit;

				proc export data =uniout1
					outfile = "&output_path./&v_id./uni.csv"
					dbms = csv replace;
				run;

				quit;

				proc sort data = uniout;
					by statistic;
				run;

				quit;

				%let univariate=InterQuartileRange Mode Range Minimum Maximum ObservationsUsed NumberOfMissing Kurtosis StandardDeviation Mean;

				%do i = 1 %to %sysfunc(countw(&univariate. , " "));
/*		%let i=8;*/
					data uniout_%scan(&univariate. , &i. , " ");
						set uniout;
						where statistic = "%scan(&univariate. , &i. , " ")";
					run;

					data uniout_%scan(&univariate. , &i. , " ");
						set uniout_%scan(&univariate. , &i. , " ");
						length grp $250.;
						grp = cat(substr( grp&grp_no._flag,1 ,27) , mod(_n_ , 1000));
					run;

					data uniout_%scan(&univariate. , &i. , " ")(rename = (grp =  grp&grp_no._flag));
						set uniout_%scan(&univariate. , &i. , " ")(drop =  grp&grp_no._flag);
					run;

				%end;

				proc sort data=uniout out=uniout;
					by statistic;
				run;

				quit;

				options validvarname=any;

				proc transpose data = uniout(where = (statistic not in("LowerBound","UpperBound"))) out = uniout_new(drop = _name_);
					by statistic;
					id  grp&grp_no._flag;
					var estimate;
				run;

				quit;

				/*		libname outuniv1 xml "&output_path/&v_id./uni_new.xml";*/
				data uni_new;
					set uniout_new;
				run;

				proc export data =uni_new
					outfile = "&output_path./&v_id./uni_new.csv"
					dbms = csv replace;
				run;

				quit;

				proc contents data = uniout_new out = uni_new_vars(keep = name);
				run;

				quit;

				data uni_new_vars;
					set uni_new_vars;
				run;

				/*	proc export data =uni_new_vars*/
				/*		outfile = "&output_path./&v_id./uni_new_vars.csv"*/
				/*		dbms = csv replace;*/
				/*	run;*/
				proc sort data = uniout;
					by  grp&grp_no._flag;
				run;

				quit;

				/*		libname outuniv1 xml "&output_path/unique_grp_var.xml";*/
				data univariate(rename=(grp&grp_no._flag=grp_variable));
					set uniout(keep =  grp&grp_no._flag);
					by  grp&grp_no._flag;

					if first. grp&grp_no._flag;
				run;

				proc export data =univariate
					outfile = "&output_path/unique_grp_var.csv"
					dbms = csv replace;
				run;

				quit;

				data uniqueout(rename=(grp&grp_no._flag=grp_variable));
					set uniout;
				run;

				proc export data =uniqueout
					outfile = "&output_path./univariate.csv"
					dbms = csv replace;
				run;

				quit;

				/*BOX-PLOT*/
				%if "&flag_box_plot." = "true" %then
					%do;
						%do x = 1 %to &grp_vcnt.;

							data outliers&x. (rename = (&var_name. = outlier));
								set subData;
								where  strip(grp&grp_no._flag) = "&&cond&x." and ((&var_name. < LowerBound) or  (&var_name. > UpperBound));
							run;

							proc univariate data = subData;
								var &var_name.;
								output out = box&x mean = box_mean pctlpts = 0 25 50 75 100 pctlpre=p_;
								where  strip(grp&grp_no._flag) = "&&cond&x.";
							run;

							quit;

							data fivepoint&x.;
								length variable $32.;
								length grp&grp_no._flag $100.;
								set box&x.;
								variable = "&var_name.";
								grp&grp_no._flag = "&&cond&x.";
							run;

							%if %eval(&x) = 1 %then
								%do;

									data fivepoint;
										set fivepoint&x.;
									run;

									data outliers;
										set outliers&x.;
									run;

								%end;
							%else
								%do;

									data fivepoint;
										set fivepoint fivepoint&x.;
									run;

									data outliers;
										set outliers outliers&x.;
									run;

								%end;
						%end;

						/*			libname outbox xml "&output_path./&v_id./boxplot.xml";*/
						data boxplot;
							set fivepoint;
						run;

						proc sql;
							create table five1 as 
								select box_mean,p_100, p_75, p_50, p_25, p_0, grp&grp_no._flag as grp_variable
									from fivepoint;
						run;

						quit;

						proc export data =five1
							outfile = "&output_path./&v_id./boxplot.csv"
							dbms = csv replace;
						run;

						quit;

					%end;

				/*&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&*/
				/* AUTO CORR */
				%if "&flag_auto_corr." = "true" %then
					%do;
						%let nlag = 50;
						ods output CorrGraph = Corr (drop = model autocov graph);

						proc autoreg data = subData;
							by grp&grp_no._flag;
							model &var_name. = primary_key_1644 /backstep nlag = &nlag.;
						run;

						quit;

						/*			libname autocorr xml "&output_path./&v_id./autocorrplot.xml";*/
						data autocorr;
							set corr;
						run;

						proc export data =autocorr
							outfile = "&output_path./&v_id./autocorrplot.csv"
							dbms = csv replace;
						run;

						quit;

						proc sql;
							create table corr1 as 
								select Autocorr,grp&grp_no._flag from corr;
						run;

						quit;

						proc export data =corr1
							outfile = "&output_path./&v_id./autocorrplot1.csv"
							dbms = csv replace;
						run;

						quit;

					%end;

				/*	PROB PLOT CODE	*/
				%if "&flag_prob_plot." = "true" %then
					%do;

						proc univariate data = subData;
							by grp&grp_no._flag;
							var &var_name.;
							output out = prob mean = mu std = sigma;
						run;

						quit;

						data prob;
							set prob;

							%do x = 1 %to 99;
								percentile&x. = &x./100;
								Estimate&x. = mu + (sigma*probit(percentile&x.));
							%end;
						run;

						proc transpose data = prob(keep = grp&grp_no._flag percentile:) out = prob_per(drop = _name_ rename = (col1 = percentile));
							by grp&grp_no._flag;
						run;

						quit;

						proc transpose data = prob(keep = grp&grp_no._flag estimate:) out = prob_est(drop = _name_ rename = (col1 = estimate));
							by grp&grp_no._flag;
						run;

						quit;

						data probplot;
							merge prob_per(in = a)  prob_est(in = b);
						run;

						data probplot(rename=(grp&grp_no._flag=grp_variable));
							set probplot;
						run;

						proc export data =probplot
							outfile = "&output_path./&v_id./probplot.csv"
							dbms = csv replace;
						run;

						quit;

						/*						proc sql;*/
						/*							create table probplot1 as*/
						/*								select percentile, estimate, grp&grp_no._flag */
						/*									from probplot;*/
						/*						run;*/
						/**/
						/*						quit;*/
						/*						proc export data =probplot1*/
						/*							outfile = "&output_path./&v_id./probplot1.csv"*/
						/*							dbms = csv replace;*/
						/*						run;*/
						/*						quit;*/
					%end;

				/*&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&*/
				/*	RUN SEQUENCE PLOT	*/
				%if "&flag_runseq_plot." = "true" %then
					%do;
						%if "&run_against." ^="Sorted" %then
							%do;

								proc sort data=subdata out=runseq;
									by &date_var.;
								run;

								quit;

								data runseq1(rename=(&var_name.=actual grp&grp_no._flag=grp_variable &date_var=primary_key));
									set runseq(keep= grp&grp_no._flag &var_name. &date_var);
								run;

							%end;
						%else
							%do;

								proc sort data=subdata out=runseq;
									by &var_name.;
								run;

								quit;

								data runseq1(rename=(&var_name.=actual grp&grp_no._flag=grp_variable primary_key_1644=primary_key ));
									set runseq(keep= grp&grp_no._flag &var_name. primary_key_1644 );
								run;

							%end;

						PROC EXPORT DATA =  runseq1
							OUTFILE="&output_path./&v_id./runsequence.csv" 
							DBMS=CSV REPLACE;
						run;

						quit;

					%end;

				/*	HISTOGRAM CODE	*/
				%if "&flag_histogram." = "true" %then
					%do;
						%if "&flag_percentile."="false" %then
							%do;
								%do z = 1 %to &grp_vcnt.;

									proc univariate data = subData;
										var &var_name.;

										/*histogram/normal;*/
										output out = hist&z mean = mu std = sigma min = min range = range;
										where  strip(grp&grp_no._flag) = "&&cond&z.";
									run;

									quit;

									data _NULL_;
										set hist&z.;
										call symputx("min",min);
										call symputx("range",range);
									run;

									%put The min value of &var_name. is &min.;
									%put The range value of &var_name. is &range.;

									data something&z(keep = increment);
										retain increment &min.;

										do k = 1 to 10;
											increment=round((increment + %sysevalf(&range./10)),.01);
											output;
										end;
									run;

									data _null_;
										set something&z. nobs = no_obs;
										call symput("range"||left(input(put(_n_,3.),$3.)), increment);
										call symput ("no_obs",compress(no_obs));
									run;

									%let range0 = &min.;
									%put &range0 &range10 &no_obs;

									data histo&z.;
										set subData;

										%do i = 0 %to %eval(&no_obs. - 1);
											%let j = %eval(&i. +1);

											%if "&j." = "1" %then
												%do;
													if &&range&i <= &var_name. <= &&range&j then
														increment = &&range&j;
												%end;
											%else
												%do;
													if &&range&i < &var_name. <= &&range&j then
														increment = &&range&j;
												%end;
										%end;

										where  strip(grp&grp_no._flag) = "&&cond&z.";
									run;

									ods output onewayfreqs = freq&z.(keep = frequency increment rename = (Frequency = frequency));

									proc freq data = histo&z.;
										tables increment;
									run;

									quit;

									/*adding code because in sas server the csv is showing Frequency instead of frequency*/
									data freq&z.;
										set freq&z.(rename=(frequency=frequency1));
									run;

									data freq&z.;
										set freq&z.(rename=(frequency1=frequency));
									run;

									proc sql;
										create table histogram&z as
											select a.increment,b.frequency
												from something&z as a left join freq&z as b
													on compress(put(a.increment,best.)) = compress(put(b.increment,best.));
									run;

									quit;

									data histogram&z;
										set histogram&z;
										format grp&grp_no._flag $100.;
										grp&grp_no._flag = "&&cond&z.";

										if frequency = . then
											frequency = 0;
									run;

									%let dsid = %sysfunc(open(histogram&z));
									%let nobs =%sysfunc(attrn(&dsid,NOBS));
									%let rc = %sysfunc(close(&dsid));

									proc sort nodup data = histogram&z;
										by increment;
									run;

									quit;

									%if %eval(&z) = 1 %then
										%do;

											data histogram;
												set histogram&z(rename=(grp&grp_no._flag=grp_variable));
											run;

										%end;
									%else
										%do;

											data histogram;
												set histogram histogram&z(rename=(grp&grp_no._flag=grp_variable));
											run;

										%end;

									%if "&flag_fitdistr."="true" %then
										%do;
											ods graphics on;
											ods output parameterestimates=param1;

											proc univariate data=histo&z.;
												histogram &var_name./normal
													lognormal
													exponential
													weibull
													gamma noplot nochart;
											run;

											quit;

											ods graphics off;

											data param2(keep= parameter estimate);
												set param1;
											run;

											proc transpose data=param2
												out= param3;
											run;

											quit;

											data param_final(keep=col1 col2 col4 col5 col9 col13 col14 col19 col18   
												rename= (col1=normal_mean col2=normal_std
												col4=ln_scale
												col5=ln_shape
												col9=exp_mean
												col13=weibull_scale
												col14=weibull_shape
												col19=gamma_shape
												col18=gamma_scale));
												set param3;
											run;

											proc sql;
												select normal_mean, normal_std,ln_scale,ln_shape,exp_mean,weibull_scale,weibull_shape,gamma_shape,gamma_scale into :normal_mean, :normal_std,
													:ln_scale,:ln_shape,:exp_mean,:weibull_scale,:weibull_shape,:gamma_shape,:gamma_scale
												from param_final;
											run;

											quit;

											proc sql;
												create table sub_fitting_&z. as select a.*,b.frequency
													from histo&z. as a join histogram&z. as b on
														a.increment=b.increment;
											run;

											quit;

											data fd_&v_id.(keep=col_pdf grp_variable  &gftesting. increment frequency );
												%if &z.=1 %then
													%do;
														set sub_fitting_&z.(rename=(&var_name.=col_pdf grp&grp_no._flag=grp_variable));
													%end;
												%else
													%do;
														set fd_&v_id. 
															sub_fitting_&z.(rename=( &var_name.=col_pdf grp&grp_no._flag=grp_variable));
													%end;

												%IF "&flag_normal_distribution."="true" %then
													%do;
														normal = pdf('NORMAL',col_pdf,&normal_mean.,&normal_std.);
													%end;

												%if "&flag_lognormal_distribution."="true" %then
													%do;
														lognormal=pdf('lognormal',col_pdf,&ln_scale.,&ln_shape.);
													%end;

												%if "&flag_weibull_distribution."="true" %then
													%do;
														weibull=pdf('weibull',col_pdf,&weibull_shape.,&weibull_scale.);
													%end;

												%if "&flag_gamma_distribution."="true" %then
													%do;
														gamma=pdf('gamma',col_pdf,&gamma_shape.,&gamma_scale.);
													%end;

												%if "&flag_exponential_distribution."="true" %then
													%do;
														exponential=pdf('exponential',col_pdf,&exp_mean.);
													%end;
											RUN;

											ods graphics on;
											ods output GoodnessOfFit=output_temp;

											proc univariate data=histo&z.;
												histogram &var_name. &gftest. noplot nochart;
											run;

											quit;

											ods graphics off;

											data fit(keep=distribution test stat);
												set output_temp;
												test=compress(test);

												if test="Kolmogorov-Smirnov" then
													do;
														test="KStest";
														output;
													end;

												if test="Anderson-Darling" then
													do;
														test="ADtest";
														output;
													end;

												if test="Cramer-vonMises" then
													delete;
											run;

											proc sort data=fit;
												by distribution test;
											run;

											quit;

											proc transpose data=fit out=goodness_fit(drop= _name_ _label_ );
												by distribution;
												id test;
											run;

											quit;

											data goodness_fit(rename=(distribution=distributions));
												informat grp_variable $30.;
												format grp_variable $30.;
												set goodness_fit;
												grp_variable="&&cond&z..";
											run;

											data goodness_fit_&v_id.;
												%if &z.=1 %then
													%do;
														set goodness_fit;
													%end;
												%else
													%do;
														set goodness_fit_&v_id. 
															goodness_fit;
													%end;

												if KStest="." then
													KStest='0';
											run;

											proc export data =goodness_fit_&v_id.
												outfile = "&output_path./&v_id./goodfit.csv"
												dbms = csv replace;
											run;

											quit;

											proc  sort data=fd_&v_id. out= fd_&v_id. nodupkey;
											by col_pdf grp_variable  &gftesting. increment frequency;
											quit;
											run;

										

											proc export data =fd_&v_id.
												outfile = "&output_path./&v_id./pdf.csv"
												dbms = csv replace;
											run;

											quit;

										%end;
								%end;

								/*			libname outhist xml "&output_path./&v_id./histogram.xml";*/
								proc export data =histogram
									outfile = "&output_path./&v_id./histogram.csv"
									dbms = csv replace;
								run;

								quit;

							%end;
					%end;

				/*&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&*/
				/* get the unique levels */
				proc sql noprint;
					select unique(grp&grp_no._flag) into :grplist separated by "|" from subdata;
				run;

				quit;

				%put here is the list of all unique &grplist;
				%let grp_temp= %sysfunc(countw(&grplist.,'|'));
				%let grp_temp=%eval(&grp_temp.-1);

				%do grp =1 %to %sysfunc(countw(&grplist.,'|'));

					data temp&grp.;
						set &dataset_name.;
/* This data step is to change the format of the selected variables from character to numeric
/*						%do j = 1 %to &num_varcnt.;*/
/*							%let num_var&j. =%scan(&var_list.,&j.);*/
/*							new&num_var&j.. = put(&num_var&j..,best.);*/
/*							drop  &num_var&j.;*/
/*							rename &&num_var&j..1 =&num_var&j..;*/
/*						%end;*/
					run;

					/**/
					/*		data temp&grp.;*/
					/*			set temp&grp.;*/
					/*			array aa(*) &grp_vars;*/
					/*			grp&grp_no._flag = catx("_" , of aa[*]);*/
					/**/
					/*			%if "&grp_no." ^= "0" %then*/
					/*				%do;*/
					/*					where grp&grp_no._flag = "%scan(&grp_flag.,&grp.,' ')";*/
					/*				%end;*/
					/*		run;*/
				%end;

				/*******************************************************************************/
				/*Time series */
				%if "&flag_timeSeries_plot."="true" %then
					%do;
						%if "&date_var." ~= "" %then
							%do;

								proc sort data=subdata out=sub_timeseries;
									by &date_var.;
								run;

								quit;

								data sub_timeseries;
									set sub_timeseries;
									lag=lag(&date_var.);
									diff=&date_var.-lag;
								run;

								proc sql;
									select count(distinct diff),count(distinct &var_name.) into :count_lag,:count_chk from sub_timeseries;
								run;

								quit;

								%if &count_lag.=1 & &count_chk.>1 %then
									%do;

										data timeseries(keep=&date_var. &var_name. grp_variable);
											set sub_timeseries(rename=(grp&grp_no._flag=grp_variable));
										run;

										PROC EXPORT DATA =  timeseries
											OUTFILE="&output_path./&v_id./timeseries.csv" 
											DBMS=CSV REPLACE;
										run;

										quit;

									%end;
								%else
									%do;

										data _null_;
											v1="Selected date variable might have unequal interval and repeating values";
											file "&output_path./&v_id./timeserieserror.txt";
											put v1;
										run;

										data timeseries(keep=&date_var. &var_name. grp_variable);
											set sub_timeseries(rename=(grp&grp_no._flag=grp_variable));
										run;

										PROC EXPORT DATA =  timeseries
											OUTFILE="&output_path./&v_id./timeseries.csv" 
											DBMS=CSV REPLACE;
										run;

										quit;

									%end;
							%end;
					%end;
			%end;

			/*********************************************************************/
			/*		UNIT TEST AND WHITE NOISE*/
			/*********************************************************************/
			%do i = 1 %to %sysfunc(countw(&distinct_grp_variable.,"!!"));

				data subdata_GRP;
					set subdata;
					where grp&grp_no._flag="%scan("&distinct_grp_variable.",&i.,"!!")";
				run;

				data _null_;
					call symput ("name","%scan("&distinct_grp_variable.",&i.,"!!")" );
				run;

				%do var_no=1 %to %sysfunc(countw(&var_list.));

					data _null_;
						call symput ("var_name", "%scan(&var_list,&var_no)");
						call symput ("v_id", "%scan(&var_id,&var_no)");
					run;

					%let dsid=%sysfunc(open(subdata_grp));
					%let num=%sysfunc(attrn(&dsid,nlobs));
					%let rc=%sysfunc(close(&dsid));
					%let sq=%sysfunc(sqrt(&num.));
					%let diff=%sysfunc(round(1/&sq.,0.001));
					%put &diff.;

					%if "&flag_unit_test." = "true" %then
						%do;
							%if &num. le 6 %then
								%do;

									data uuu;
										/*								%let y=%scan("&distinct_grp_variable.",&i.,"!!");*/
										file "&&output_path./&v_id./unit_test_&name..txt";
									run;

								%end;
							%else
								%do;
									ods output StationarityTests = UnitRootTests&v_id.;

									proc arima data =subdata_grp;
										identify var = &var_name. stationarity = (DICKEY = (0,1,2) );
									run;

									quit;

									/*									%if "&SYSERRORTEXT." ne "" %then*/
									/*										%do;*/
									/**/
									/*											data _null_;*/
									/*												v1="&SYSERRORTEXT.";*/
									/*												file "&output_path./error.txt";*/
									/*												put v1;*/
									/*											run;*/
									/**/
									/*										%end;*/
									data UnitRootTests&v_id.;
										set UnitRootTests&v_id.;
										grp_variable= "%scan("&distinct_grp_variable.",&i.,"!!")";
									run;

									proc append base=unitroot&v_id. data=UnitRootTests&v_id. force;
									run;

									quit;

								%end;

							%if &i.=%sysfunc(countw(&distinct_grp_variable.,"!!")) %then
								%do;

									proc export data =  unitroot&v_id
										outfile = "&output_path./&v_id./UnitRootTests.csv"
										dbms = CSV replace;
									run;

									quit;

								%end;
						%end;

					%if "&flag_whitenoise_test." = "true" %then
						%do;
							%if &num. le 6 %then
								%do;

									data uuu;
										file "&&output_path./&v_id./whitenoise_&name..txt";
									run;

								%end;
							%else
								%do;
									ods output ChiSqAuto = WhiteNoiseTest&v_id.;

									proc arima data =subdata_grp;
										identify var = &var_name. stationarity = (DICKEY = (0,1,2) );
									run;

									quit;

									/*									%if "&SYSERRORTEXT." ne "" %then*/
									/*										%do;*/
									/**/
									/*											data _null_;*/
									/*												v1="&SYSERRORTEXT.";*/
									/*												file "&output_path./error.txt";*/
									/*												put v1;*/
									/*											run;*/
									/**/
									/*										%end;*/
									data whitenoisetest&v_id.;
										set whitenoisetest&v_id.;
										grp_variable= "%scan("&distinct_grp_variable.",&i.,"!!")";
									run;

									proc append base=whitenoise&v_id data=whitenoisetest&v_id. force;
									run;

									quit;

								%end;

							%if &i.=%sysfunc(countw(&distinct_grp_variable.,"!!")) %then
								%do;

									proc export data =  whitenoise&v_id
										outfile = "&output_path./&v_id./WhiteNoiseTest.csv"
										dbms = CSV replace;
									run;

									quit;

								%end;
						%end;

					%if "&flag_acf_plot." = "true" %then
						%do;
							%if &num. le 6 %then
								%do;

									data uuu;
										file "&&output_path./&v_id./acf_&name..txt";
									run;

								%end;
							%else
								%do;
									ods output AutoCorrGraph = acf&v_id.;

									proc arima data = subdata_grp;
										identify var = &var_name.;
									run;

									quit;

									/*									%if "&SYSERRORTEXT." ne "" %then*/
									/*										%do;*/
									/**/
									/*											data _null_;*/
									/*												v1="&SYSERRORTEXT.";*/
									/*												file "&output_path./error.txt";*/
									/*												put v1;*/
									/*											run;*/
									/**/
									/*										%end;*/
									data acf&v_id.;
										set acf&v_id.;
										StdErrX2 = StdErr * 1.96;
										Neg_StdErrX2 = StdErr * -1.96;
										grp_variable= "%scan("&distinct_grp_variable.",&i.,"!!")";
									run;

									proc append base=autocorr&v_id. data=acf&v_id. force;
									run;

									quit;

									data autocorr&v_id.;
										length variable_name $30.;
										set autocorr&v_id.;
										variable_name = "&var_name.";
									run;

									proc sql;
										create table autocorr&v_id. as 
											select lag,correlation,variable_name,grp_variable,StdErr,StdErrX2,Neg_StdErrX2
												from autocorr&v_id.;
									run;

									quit;

									proc sort data= autocorr&v_id. out =autocorr&v_id. nodupkey;
										by grp_variable lag;
									run;

									quit;

								%end;

							%if &i.=%sysfunc(countw(&distinct_grp_variable.,"!!")) %then
								%do;

									proc export data =  autocorr&v_id.
										outfile = "&output_path./&v_id./AutoCorrelation_Plot_Sample.csv"
										dbms = CSV replace;
									run;

									quit;

								%end;
						%end;

					%if "&flag_pacf_plot." = "true" %then
						%do;
							%if &num. le 6 %then
								%do;

									data uuu;
										file "&&output_path./&v_id./pacf_&name..txt";
									run;

								%end;
							%else
								%do;
									ods output PACFGraph = pacf&v_id.(keep = lag PACF);

									proc arima data = subdata_grp;
										identify var = &var_name.;
									run;

									quit;

									/*									%if "&SYSERRORTEXT." ne "" %then*/
									/*										%do;*/
									/**/
									/*											data _null_;*/
									/*												v1="&SYSERRORTEXT.";*/
									/*												file "&output_path./error.txt";*/
									/*												put v1;*/
									/*											run;*/
									/**/
									/*										%end;*/
									data pacf&v_id.(rename = (PACF = Correlation ));
										set pacf&v_id.;
										StdErr = &diff.;
										StdErrX2 = StdErr * 1.96;
										Neg_StdErrX2 = StdErr * -1.96;
										grp_variable= "%scan("&distinct_grp_variable.",&i.,"!!")";

										if lag = 0 then
											delete;
									run;

									proc append base=partialACF&v_id. data=pacf&v_id. force;
									run;

									quit;

								%end;

							%if &i.=%sysfunc(countw(&distinct_grp_variable.,"!!")) %then
								%do;

									proc export data =  partialACF&v_id.
										outfile = "&output_path./&v_id./_Partial_ACF_Sample.csv"
										dbms = CSV replace;
									run;

									quit;

								%end;
						%end;
				%END;
			%END;

			/*********************************************************/
			/*		WHITE NOISE TEST*/
			/*********************************************************/
			%if "&flag_whiteNoise_test." = "tr" %then
				%do;
					%do i = 1 %to %sysfunc(countw(&var_list.," "));
						%let var_num = %scan(&var_list,&i," ");
						%let var_num_id = %scan(&var_id,&i," ");
						%let dsid=%sysfunc(open(temp&grp.));
						%let num=%sysfunc(attrn(&dsid,nlobs));
						%let rc=%sysfunc(close(&dsid));

						%if &num. le 20 %then
							%do;

								data xxx;
									%let x = %scan(&grplist.,&grp.,'|');
									file "&output_path./&var_num_id./whitenoise_&grp..txt";
								run;

							%end;
						%else
							%do;
								ods output ChiSqAuto = WhiteNoiseTest&grp.;

								proc arima data =  temp&grp.;
									identify var = &var_num. stationarity = (DICKEY = (0,1,2) );
								run;

								quit;

								/*								%if "&SYSERRORTEXT." ne "" %then*/
								/*									%do;*/
								/**/
								/*										data _null_;*/
								/*											v1="&SYSERRORTEXT.";*/
								/*											file "&output_path./error.txt";*/
								/*											put v1;*/
								/*										run;*/
								/**/
								/*									%end;*/
								data WhiteNoiseTest&grp.;
									set WhiteNoiseTest&grp.;
									grp&grp_no._flag= "%scan(&grplist.,&grp.,'|')";
								run;

								proc append base=whitenoise data=WhiteNoiseTest&grp. force;
								run;

								quit;

								proc export data =  whitenoise
									outfile = "&output_path./&var_num_id./WhiteNoiseTest.csv"
									dbms = CSV replace;
								run;

								quit;

							%end;
					%end;
				%end;
		%end;

	/*%end;*/
	%do i = 1 %to %sysfunc(countw(&distinct_grp_variable.,"!!"));

		data subdata_new;
			set subdata;
			where grp&grp_no._flag="%scan("&distinct_grp_variable.",&i.,"!!")";
		run;

		%do var_no=1 %to %sysfunc(countw(&var_list.));

			data _null_;
				call symput ("var_name", "%scan(&var_list,&var_no)");
				call symput ("v_id", "%scan(&var_id,&var_no)");
			run;

			proc sql;
				select count(distinct &var_name.) into: nob from subdata_new;
			run;

			quit;

			%if "&flag_histogram."="true" %then
				%do;
					%if "&flag_percentile"="true" %then
						%do;
							%if &nob.>&no_bins. %then
								%do;
									%let bin_perc=%sysfunc(catx(%str( ),0,&breakpoints.,100));

									proc univariate data=subdata_new;
										var &var_name.;
										output out=pctl pctlpts=&bin_perc. pctlpre=p;
									run;

									quit;

									proc transpose data=pctl out=pctls;
									run;

									quit;

									proc sql;
										select col1 into: bin_temp separated by "_" from pctls;
									run;

									quit;

									%let c=;
									%let d=;

									%do h=1 %to &no_bins.;
										%let c=%sysevalf((%scan(&bin_temp.,&h.,"_")+%scan(&bin_temp.,&h.+1,"_"))/2);

										%if &h.=1 %then
											%do;
												%let d=&c.;
											%end;

										%if &h.^=1 %then
											%do;
												%let d=%sysfunc(catx(%str(_),&d.,&c.));
											%end;
									%end;

									data sub_histogram;
										set subdata_new;

										do m= 1 to &no_bins.;
											n=scan("&bin_temp.",m,"_");

											if &var_name.>n then
												y=n;
										end;

										if y="" then
											y=scan("&bin_temp.",1,"_");
									run;

									proc sql;
										Create table histo_binning as select y as bins,count(y) as frequency from sub_histogram
											group by y;
									run;

									quit;

									data temperory;
										do i=1 by 1 while(scan("&d.",i,'_ ') ^=' ');
											new=scan("&d.",i,'_');
											output;
										end;
									run;

									data histo_binning;
										set histo_binning;
										row_num=_n_;
									run;

									proc sql;
										create table histo_bin_1 as select b.new as increment,a.frequency as frequency, a.bins as ends
											from histo_binning as a join temperory as b
												on a.row_num =b.i;
									run;

									quit;

									data histo_bin(drop=ends);
										informat grp_variable $30.;
										format grp_variable $30.;
										set histo_bin_1;
										grp_variable="%scan("&distinct_grp_variable.",&i.,"!!")";
									run;

									data histo_bin_&v_id.;
										%if &p.=0 %then
											%do;
												set histo_bin;
											%end;
										%else
											%do;
												set histo_bin_&v_id.
													histo_bin;
											%end;
									run;

									%if &var_no.=%sysfunc(countw(&var_list.)) %then
										%do;
											%let p=%eval(&p.+1);
										%end;

									%if &i.=%sysfunc(countw(&distinct_grp_variable.,"!!")) %then
										%do;

											PROC EXPORT DATA = histo_bin_&v_id.
												OUTFILE="&output_path./&v_id./histogram.csv" 
												DBMS=CSV REPLACE;
											run;

											quit;

										%end;
								%end;

							%if "&flag_fitdistr." = "true" %then
								%do;
									ods graphics on;
									ods output parameterestimates=param;

									proc univariate data=sub_histogram;
										histogram &var_name./normal
											lognormal
											exponential
											weibull
											gamma noplot nochart;
									run;

									quit;

									ods graphics off;

									data param2(keep= parameter estimate);
										set param;
									run;

									proc transpose data=param2
										out= param3;
									run;

									quit;

									data param_final(keep=col1 col2 col4 col5 col9 col13 col14 col19 col18   
										rename= (col1=normal_mean col2=normal_std
										col4=ln_scale
										col5=ln_shape
										col9=exp_mean
										col13=weibull_scale
										col14=weibull_shape
										col19=gamma_shape
										col18=gamma_scale));
										set param3;
									run;

									proc sql;
										select normal_mean, normal_std,ln_scale,ln_shape,exp_mean,weibull_scale,weibull_shape,gamma_shape,gamma_scale into :normal_mean, :normal_std,
											:ln_scale,:ln_shape,:exp_mean,:weibull_scale,:weibull_shape,:gamma_shape,:gamma_scale
										from param_final;
									run;

									quit;

									proc sql;
										create table sub_fitting as select a.*,b.increment,b.frequency
											from sub_histogram as a join histo_bin_1 as b on
												a.y=b.ends;
									run;

									quit;

									data fd_&v_id.(keep=col_pdf grp_variable  &gftesting. increment frequency );
										%if &i.=1 %then
											%do;
												set sub_fitting(rename=(grp&grp_no._flag=grp_variable &var_name.=col_pdf));
											%end;
										%else
											%do;
												set fd_&v_id. 
													sub_fitting(rename=(grp&grp_no._flag=grp_variable &var_name.=col_pdf));
											%end;

										%IF "&flag_normal_distribution."="true" %then
											%do;
												normal = pdf('NORMAL',col_pdf,&normal_mean.,&normal_std.);
											%end;

										%if "&flag_lognormal_distribution."="true" %then
											%do;
												lognormal=pdf('lognormal',col_pdf,&ln_scale.,&ln_shape.);
											%end;

										%if "&flag_weibull_distribution."="true" %then
											%do;
												weibull=pdf('weibull',col_pdf,&weibull_shape.,&weibull_scale.);
											%end;

										%if "&flag_gamma_distribution."="true" %then
											%do;
												gamma=pdf('gamma',col_pdf,&gamma_shape.,&gamma_scale.);
											%end;

										%if "&flag_exponential_distribution."="true" %then
											%do;
												exponential=pdf('exponential',col_pdf,&exp_mean.);
											%end;
									RUN;

									%if &i.=%sysfunc(countw(&distinct_grp_variable.,"!!")) %then
										%do;

											PROC EXPORT DATA = fd_&v_id.
												OUTFILE="&output_path./&v_id./pdf.csv" 
												DBMS=CSV REPLACE;
											run;

											quit;

										%end;

									ods graphics on;
									ods output GoodnessOfFit=output_temp;

									proc univariate data=subdata_new;
										histogram &var_name. &gftest. noplot nochart;
									run;

									quit;

									ods graphics off;

									data fit(keep=distribution test stat);
										set output_temp;
										test=compress(test);

										if test="Kolmogorov-Smirnov" then
											do;
												test="KStest";
												output;
											end;

										if test="Anderson-Darling" then
											do;
												test="ADtest";
												output;
											end;

										if test="Cramer-vonMises" then
											delete;
									run;

									proc sort data=fit;
										by distribution test;
									run;

									quit;

									proc transpose data=fit out=goodness_fit(drop= _name_ _label_ );
										by distribution;
										id test;
									run;

									quit;

									data goodness_fit(rename=(distribution=distributions));
										informat grp_variable $30.;
										format grp_variable $30.;
										set goodness_fit;
										grp_variable="%scan("&distinct_grp_variable.",&i.,"!!")";
									run;

									data goodness_fit_&v_id.;
										%if &i.=1 %then
											%do;
												set goodness_fit;
											%end;
										%else
											%do;
												set goodness_fit_&v_id. 
													goodness_fit;
											%end;

										if KStest=. then
											KStest='0';
									run;

									%if &i.=%sysfunc(countw(&distinct_grp_variable.,"!!")) %then
										%do;

											PROC EXPORT DATA = goodness_fit_&v_id.
												OUTFILE="&output_path./&v_id./goodfit.csv" 
												DBMS=CSV REPLACE;
											run;

											quit;

										%end;
								%end;
						%end;
				%end;
		%end;
	%end;

	%if %sysfunc(countw(&distinct_grp_variable.,"!!"))>1 %then
		%do;
			%do var_no=1 %to %sysfunc(countw(&var_list.));

				data _null_;
					call symput ("var_name", "%scan(&var_list,&var_no)");
					call symput ("v_id", "%scan(&var_id,&var_no)");
				run;

				%do z=5 %to 100 %by 5;

					proc univariate data = subData;
						var &var_name.;
						by grp&grp_no._flag;
						output out = uni_per&z. pctlpts= &z. pctlpre=p_;
					run;

					quit;

					data meansData;
						merge subData(in=a keep=&var_name. grp&grp_no._flag) uni_per&z.(in=b);
						by grp&grp_no._flag;

						if a or b;
					run;

					proc means data = meansData;
						var &var_name.;
						by grp&grp_no._flag;
						where &var_name. < p_&z.;
						output out = means_uni&z.(drop = _type_ _freq_) mean = mean stddev = stddev;
					run;

					quit;

					data means_uni&z.(rename=(grp&grp_no._flag=grp_variable));
						set means_uni&z.;
						length variable $32;
						length percentile $8;
						percentile="&z.";
						variable="&var_name.";
					run;

					%if "&z." = "5" %then
						%do;

							data percentiles;
								set means_uni&z.;
							run;

						%end;
					%else
						%do;

							data percentiles;
								set percentiles 
									means_uni&z.;
							run;

							quit;

						%end;

					%if "&z." = "100" %then
						%do;

							proc export data =percentiles
								outfile = "&output_path./&v_id./percentile.csv"
								dbms = csv replace;
							run;

							quit;

						%end;
				%end;
			%end;
		%end;
%mend var_char;

%var_char;

data _NULL_;
	v1= "EDA - UNIVARIATE_ANALYSIS_COMPLETED";
	file "&output_path./VARIABLE_CHARACTERISTICS_COMPLETED.txt";
	PUT v1;
run;

quit;

/*proc datasets kill lib=work;*/
/*run;*/
/*quit;*/