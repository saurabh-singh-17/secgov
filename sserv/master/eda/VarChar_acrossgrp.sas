
*processbody;
%let completedTXTPath =  &output_path./UNIVARIATE_ACROSSGRPBY_COMPLETED.txt;

options mprint mlogic symbolgen mfile ;

proc printto log="&output_path./VariableCharacteristics_Log.log"; 
run;
quit;
/**/
/*proc printto;*/
/*run;*/
%global sasworklocation;
%let sasworklocation = %sysfunc(getoption(work));

libname in "&input_path";
libname out "&output_path";

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

		ods graphics on/ width=20in height=20in reset=all ;
		ods graphics on/ width=20in height=20in reset=all ;	
		ods listing gpath="&output_path./&v_id.";
		goptions reset=all device =  png300 Transparency gsfname=image gsfmode=replace;
		footnote1 h = .5 '  ';
		proc npar1way wilcoxon plots=wilcoxonboxplot  data=tmp;
			class Panel_levels;
			var &var_name.;
			run;
		ods listing close;
		ods graphics off;
	
		data WilcoxonScores;
			set WilcoxonScores(rename=(class=flag N=No_of_Observations SumOfScores=Sum_Of_Scores expectedsum=Expected_Sum_Under_H0 StdDevOfSum=Std_Dev_Of_SumUnderH0 MeanScore=Mean_Score) drop=variable);
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

%macro varchar_grp;
	data _null_;
		call symputx("grp_varlist" , catx("," , scan("&grp_vars",1) , scan("&grp_vars",2) , scan("&grp_vars",3)
			, scan("&grp_vars",4), scan("&grp_vars",5)) );
		run;
	%put &grp_varlist.;

	/*DYNAMIC FILTER*/
	%if "&flag_filter." = "true" %then %do;
		%let dataset_name=out.temporary;
		%let whr=;
	 	/*call SAS code for dynamic filtering*/
		%include %unquote(%str(%'&filterCode_path./dynamicFiltering.sas%')); 
	%end;
		%else %do;
		%let dataset_name=in.dataworking;
		%end;

	data temp;
	set &dataset_name.;
	run;
	/* Checking number of observations in dataset	*/
	%let dset=temp;
		%let dsid = %sysfunc(open(&dset));
		%let nobs =%sysfunc(attrn(&dsid,NOBS));
		%let rc = %sysfunc(close(&dsid));
	%if &NOBS. =0
		%then %do;

		data _null_;
      		v1= "There are zero observations in the filtered dataset";
      		file "&output_path./GENERATE_FILTER_FAILED.txt";
      		put v1;
			run;
		
			/*delete unrequired datasets*/
		proc datasets library = out;
			delete temporary ;
			run;
	%end;
	%else %do;
	proc sort data = &dataset_name.(keep =&var_list. primary_key_1644) out = subData1 ;
		by primary_key_1644;
		run;

	proc sort data = &dataset_name.(keep = &grp_vars. primary_key_1644) out = subData ;
		by &grp_vars.;
		run;

	%if "&grp_vars." ^= "" %then %do;
		proc contents data = subData (keep = &grp_vars.) out = contents(keep = name type);
			run;

		proc sql noprint;
			select count(*) into :num_varcnt from contents where type = 1;
			quit;

		%put &num_varcnt.;

		%if %eval(&num_varcnt.) ^= 0 %then %do;
			data _null_;
				set contents;
				suffix = put(_n_,8.);
				call symput (cats("num_var",suffix),compress(name));
				where type = 1;
				run;

			data subData;
				set subData;
				%do j = 1 %to &num_varcnt.;
					&&num_var&j..1 = put(&&num_var&j.,best.);
					drop  &&num_var&j.;
					rename &&num_var&j..1 = &&num_var&j.;
				%end;
				run;
		%end;
		data subData (drop = &grp_vars.);
			set subData;
			array aa(*) &grp_vars ;
			grp_variable = catx("_" , of aa[*]);
			run;

		proc sort data=subdata;
			by primary_key_1644;
			run;
		data subdata;
			merge subdata(in=a) subdata1(in=b);
			by primary_key_1644;
			if a or b;
			run;
		proc sort data=subdata;
			by grp_variable;
			run;
	%end;

/*&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&*/

/*===============================================================================================================================================*/

/* Check if every value is missing */

/* Macro to get the names of the variables which have all values missing*/
%macro checkIfTheWholeColumnIsMissing(dataset,variables);
	%global missingVariables;
	%global minNonMissingCount;

	proc means data=&dataset. NMISS N;
		var &variables.;
		output out = nonmissing;
		run;

	data nonmissing(drop = _TYPE_ _FREQ_ _STAT_);
		set nonmissing;
		if _STAT_ ^= 'N' then delete;
		run;

	proc transpose data = nonmissing out = nonmissingt;
		run;

	proc sql;
		select min(COL1) into: minNonMissingCount from nonmissingt;
		run;
		quit;

	%put &minNonMissingCount.;

	%if &minNonMissingCount. = 0 %then %do;
		data nonmissingt;
			set nonmissingt;
			if COl1 ^= 0 then delete;
			run;

		proc sql;
			select _NAME_ into: missingVariables separated by " " from nonmissingt;
			quit;
	%end;
%mend;

proc sql;
	select distinct(grp_variable) into: distinct_grp_variable separated by "!!" from subdata;
	quit;

%let allMissingVariables = ;
%let indicator = 0;
%let count_miss = 0;
%do i = 1 %to %sysfunc(countw(&distinct_grp_variable.,"!!"));
	%let comma=,;
	data temp_dataset;
		set subdata;
		where grp_variable="%scan("&distinct_grp_variable.",&i.,"!!")";
		run;
		
	%checkIfTheWholeColumnIsMissing(dataset = temp_dataset,variables = &var_list.);
	
	%if &minNonMissingCount. = 0 %then %do;
		%let indicator = 1;
		%let count_miss = %eval(&count_miss.+1);
		%let panel_level = %scan("&distinct_grp_variable.",&i.,"!!");
		%if &count_miss. = 1 %then %do;
			%let comma =;
		%end;
		%let allMissingVariables = &allMissingVariables.&comma. <&missingVariables.> for the panel level <&panel_level.>;
	%end;
%end;

%if &indicator. = 1 %then %do;
	%let text = All values are missing in the variable(s) &allMissingVariables.. Kindly deselect the variable(s).;

	data _null_;
      	file "&output_path./error.txt";
      	put "&text.";
		run;

	endsas;
%end;

/*===============================================================================================================================================*/

	%do var_no=1 %to %sysfunc(countw(&var_list.));

		data _null_;
			call symput ("var_name", "%scan(&var_list,&var_no)");
			call symput ("v_id", "%scan(&var_id,&var_no)");
			run;
		%put &var_name &v_id;
		
		
		%if &kruskal_wallis_test_flag. = true %then %do;
			%kruskalwallis;
		%end;

	/* BASIC CHARACTERSTICS CODE */
		proc univariate data = subData;
			by grp_variable;
			var &var_name.;
			output out = uni 
				mean = mean 
				median = median 
				mode = mode 
				std = stddev 
				nobs = observations_used 
				nmiss = number_of_missing 
				max = max 
				min = min
				qrange = iqr 
				range = range 
				pctlpts = 25 75 pctlpre = p_ ;
		run; quit;

		data uni;
			set uni;
			format variable $32.;
			variable = "&var_name.";
		run;

		proc sql;
			create table unique as
			select grp_variable  from uni;
			quit;

		proc export data =unique
			outfile = "&output_path./unique_grp_var.csv"
			dbms = csv replace;
			run;

		%if "&flag_box_plot." = "true" or "&flag_outliers." = "true" %then %do;
			data uni (drop = p_25 p_75);
				set uni;
				lb = p_25 - (3*iqr);
				ub = p_75 + (3*iqr);
				run;

			data subData;
				merge subData(in = a) uni(in = b);
				by grp_variable;
				if a;
				run;

			proc sql;
				create table outliers as
				select grp_variable,
				count(case when &var_name. = 0 then &var_name. else 0 end) as no_of_zeros,
				count(case when (&var_name. < lb) or  (&var_name. > ub) then &var_name. else 0 end) as noofoutliers
				from subData
				group by grp_variable
				;
				quit;

			data uni;
				merge uni(in = a) outliers(in = b);
				by grp_variable;
				if a;
				run;
		%end;

		proc transpose data = uni out = uniout(drop = _label_ rename = (_name_ = statistic col1 = estimate) );
			by grp_variable;
			run;

		data _null_;
				set uni end = eof;
				suffix = put(_n_,8.);
				call symputx(cats("cond",suffix),grp_variable);
				if eof then call symput("grp_vcnt", compress(_n_));
				run;

			%put cond1 &cond2 &cond3 &cond4 &cond5 &cond6 &grp_vcnt.;

/*		libname outuniv xml "&output_path./&v_id./uni.xml";*/
		data univariate;
			set uniout;
			if strip(statistic) = "mean" then statistic = "mean";
			if strip(statistic) = "stddev" then statistic = "stddev";
			if strip(statistic) = "kurtosis" then statistic = "Kurtosis";
			if strip(statistic) = "number_of_missing" then statistic = "Number of Missing";
			if strip(statistic) = "observations_used" then statistic = "Observations Used";
			if strip(statistic) = "max" then statistic = "Maximum";
			if strip(statistic) = "min" then statistic = "Minimum";
			if strip(statistic) = "range" then statistic = "Range";
			if strip(statistic) = "iqr" then statistic = "Inter-Quartile Range";
			if strip(statistic) = "mode" then statistic = "Mode";
			run;

		proc sql;
			create table uniout1 as 
			select statistic, estimate, grp_variable
			from uniout;
			quit;

		proc export data =univariate
			outfile = "&output_path./&v_id./uni.csv"
			dbms = csv replace;
			run;

		proc export data =uniout1
			outfile = "&output_path./&v_id./univarite.csv"
			dbms = csv replace;
			run;
		
		proc sort data = uniout;
			by statistic ;
			run;
		%let univariate=iqr mode rage min max observations_used number_of_missing kurtosis stddev mean;

		%do i = 1 %to %sysfunc(countw(&univariate. , " ")) ;

		data uniout_%scan(&univariate. , &i. , " ");
			set uniout;
			where statistic = "%scan(&univariate. , &i. , " ")";
			run;
		data uniout_%scan(&univariate. , &i. , " ");
			set uniout_%scan(&univariate. , &i. , " ");
			length grp $250.;
			grp = cat(substr(grp_variable,1 ,27) , mod(_n_ , 1000));
			run; 
		data uniout_%scan(&univariate. , &i. , " ")(rename = (grp = grp_variable));
			set uniout_%scan(&univariate. , &i. , " ")(drop = grp_variable);
			run;
/*		%let i=1;*/
/*		data uniout3 (keep=grp_variable);*/
/*		set uniout_iqr;*/
/*		run;*/
/**/
/*		data uniout;*/
/*			merge uniout3 uniout_%scan(&univariate. , &i. , " ")(in=b);*/
/*			by grp_variable;*/
/*			run;*/
		%end;
		proc sort data=uniout out=uniout;
		by statistic;
		run;
		proc transpose data = uniout(where = (statistic not in("lb","ub"))) out = uniout_new(drop = _name_);
			by statistic;
			id grp_variable;
			var estimate;
			run;

/*		libname outuniv1 xml "&output_path/&v_id./uni_new.xml";*/
		data uni_new;
			set uniout_new;
			run;
		proc export data =uni_new
			outfile = "&output_path./&v_id./uni_new.csv"
			dbms = csv replace;
			run;

		proc contents data = uniout_new out = uni_new_vars(keep = name);
			run;

/*		libname outuniv9 xml "&output_path/&v_id./uni_new_vars.xml";*/
		data uni_new_vars;
			set uni_new_vars;
			run;
		proc export data =uni_new_vars
		outfile = "&output_path./&v_id./uni_new_vars.csv"
		dbms = csv replace;
		run;

		proc sort data = uniout;
			by grp_variable;
			run;

/*		libname outuniv1 xml "&output_path/unique_grp_var.xml";*/
		
		data univariate;
			set uniout(keep = grp_variable);
			by grp_variable;
			if first.grp_variable;
			run;
		proc export data =univariate
			outfile = "&output_path/unique_grp_var.csv"
			dbms = csv replace;
			run;
		proc export data =uniout
			outfile = "&output_path./univarite.csv"
			dbms = csv replace;
			run;
/*&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&*/

	/*BOX-PLOT*/
		%if "&flag_box_plot." = "true" %then %do;
			%do x = 1 %to &grp_vcnt.;
			 	data outliers&x. (rename = (&var_name. = outlier));
					set subData ;
					where  strip(grp_variable) = "&&cond&x." and ((&var_name. < lb) or  (&var_name. > ub));
					run;

				proc univariate data = subData; 
					var &var_name.;
					output out = box&x mean = box_mean pctlpts = 0 25 50 75 100 pctlpre=p_ ;
					where  strip(grp_variable) = "&&cond&x.";
					run;

				data fivepoint&x.;
					length variable $32.;
					length grp_variable $100.;
					set box&x.;
					variable = "&var_name.";
					grp_variable = "&&cond&x.";
					run;

				%if %eval(&x) = 1 %then %do;
					data fivepoint;
						set fivepoint&x.;
						run;

					data outliers;
						set outliers&x.;
						run;
				%end;
				%else %do;
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
				select box_mean,p_100, p_75, p_50, p_25, p_0, grp_variable
				from fivepoint;
				quit;

			proc export data =five1
				outfile = "&output_path./&v_id./boxplot.csv"
				dbms = csv replace;
				run;	
					/*libname outbox1 xml "&output_path/boxplot1.xml";*/
					/*data outbox1.boxplot1;*/
					/*set outliers(keep = grp_variable outlier);*/
					/*run;*/
		%end;

/*&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&*/
	/*	MEAN STD DEV CODE	*/
		%if "&flag_mean." = "true" or "&flag_std_dev." = "true" %then %do;
			%do z = 5 %to 100 %by 5;

			proc univariate data = subData noprint;
				var &var_name.;
				by grp_variable;
				output out = uni_per&z. pctlpts= &z. pctlpre=p_ ;
				quit; 

			data meansData;
				merge subData(in=a keep=&var_name. grp_variable) uni_per&z.(in=b);
				by grp_variable;
				if a or b;
				run;

			proc means data = meansData noprint ;
				var &var_name.;
				by grp_variable;
				where &var_name. < p_&z.;
				output out = means_uni&z.(drop = _type_ _freq_) mean = mean stddev = stddev;
				run; quit;

			data means_uni&z.;
				set means_uni&z.;
				length variable $32 ;
				length percentile 8. ;
				percentile = "&z." ;
				variable = "&var_name." ;
				run;

				%if "&z" = "5" %then %do;
					data percentiles;
						set means_uni&z.;
						run;
				%end;

				%else %do;
					data percentiles;
						set percentiles means_uni&z.;
						run;
				%end;

			proc delete data = meansData means_uni&z. uni_per&z.;
				run; quit;

			%end;

/*			libname perctl xml "&output_path./&v_id./percentile.xml";*/
				data percentile;
					set percentiles;
					run;

			proc export data =percentiles
				outfile = "&output_path./&v_id./percentile.csv"
				dbms = csv replace;
				run;
		%end;	
/*&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&*/

	/* AUTO CORR */
		%if "&flag_auto_corr." = "true" %then %do;
			%let nlag = 50;

			ods output CorrGraph = Corr (drop = model autocov graph);
			proc autoreg data = subData;
				by grp_variable;
				model &var_name. = primary_key_1644 /backstep nlag = &nlag. ;
				run; quit;
			ods trace off;

/*			libname autocorr xml "&output_path./&v_id./autocorrplot.xml";*/
			data autocorr;
				set corr;
				run;

				proc export data =autocorr
				outfile = "&output_path./&v_id./autocorrplot.csv"
				dbms = csv replace;
				run;

			proc sql;
				create table corr1 as 
				select Autocorr,grp_variable from corr;
				quit;

			proc export data =corr1
				outfile = "&output_path./&v_id./autocorrplot1.csv"
				dbms = csv replace;
				run;
		%end;
/*&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&*/

/*	/*	LAG CODE  */*/
/*		%if "&flag_lag." = "true" %then %do;*/
/*			data lag (keep = grp_variable actual lag);*/
/*				set subData;*/
/*				by grp_variable;*/
/*				actual = &var_name.;*/
/*				lag = lag(&var_name.);*/
/*				if first.grp_variable then lag = .;*/
/*				run;*/
/**/
/*			PROC EXPORT DATA = lag*/
/*				OUTFILE="&output_path./&v_id./lag.csv" */
/*				DBMS=CSV REPLACE; */
/*				RUN;				*/
/*					/*libname outlag xml "&output_path/lag.xml";*/*/
/*					/*data outlag.lagplot;*/*/
/*					/*set lag;*/*/
/*					/*run;*/*/
/*		%end;*/;
/*&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&*/

/*	/*	NORMALITY CODE	*/*/
/*		%if "&flag_normality." = "true" or "&flag_runs_test." = "true" %then %do;*/
/*			ods output Moments = moments (where = (Label1 = "Skewness") rename = (nvalue1 = skewness nvalue2 = kurtosis)) ;*/
/*			ods output TestsForNormality = normal (keep = test pvalue grp_variable rename =(test = normalitytest pvalue = value));*/
/*			proc univariate data = subData normal ;*/
/*				by grp_variable;*/
/*				var &var_name. ;*/
/*				run; quit;*/
/**/
/*			proc transpose data = moments(keep = grp_variable skewness kurtosis) out = skewness(rename = (_NAME_ = normalitytest COL1 = value));*/
/*				by grp_variable;*/
/*				run; quit;*/
/**/
/*			data normal_out;*/
/*				length normalitytest $32.;*/
/*				set normal skewness;*/
/*				run;*/
/**/
/*			proc sort data = normal_out;*/
/*				by normalitytest;*/
/*				run;*/
/**/
/*			proc transpose data = normal_out out = normal_out_new(drop = _name_);*/
/*				by normalitytest;*/
/*				id grp_variable;*/
/*				var value;*/
/*				run;*/
/**/
/*			%if "&flag_normality" = "true" %then %do;*/
/*				libname outnorm xml "&output_path./&v_id./normalitytests.xml";*/
/*				data outnorm.normalitytests;*/
/*					set normal_out;*/
/*					run;*/
/**/
/**/
/*				libname outnorm1 xml "&output_path./&v_id./normalitytests_new.xml";*/
/*				data outnorm1.normalitytests(rename = (normalitytest = test));*/
/*					set normal_out_new;*/
/*					run;*/
/**/
/*				proc contents data = outnorm1.normalitytests out = normal_vars(keep = name);*/
/*					run;*/
/**/
/*				libname outnorm2 xml "&output_path./&v_id./normalitytests_new_vars.xml";*/
/*				data outnorm2.normal_varlist;*/
/*					set normal_vars;*/
/*					run;*/
/*			%end;*/
/*						/*	proc transpose data = runout out = runout_new(rename = (_name_ = normalitytest) drop = _label_);*/*/
/*						/*		id variable;*/*/
/*						/*		var pvalue;*/*/
/*						/*		run;*/*/
/*						/**/*/
/*						/*	libname outnorm1 xml "&output_path/normalitytests_new.xml";*/*/
/*						/*	data outnorm1.normalitytests(rename = (normalitytest = test));*/*/
/*						/*		set normal_out_new runout_new;*/*/
/*						/*		run;*/*/
/**/
/*		%end;*/;
/*&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&*/

	/*	PROB PLOT CODE	*/
		%if "&flag_prob_plot." = "true" %then %do;
			proc univariate data = subData;
				by grp_variable;
				var &var_name. ;
				output out = prob mean = mu std = sigma;
				run; quit;

			data prob;
				set prob;
				%do x = 1 %to 99;
					percentile&x. = &x./100;
					Estimate&x. = mu + (sigma*probit(percentile&x.));
				%end;
				run;

			proc transpose data = prob(keep = grp_variable percentile:) out = prob_per(drop = _name_ rename = (col1 = percentile));
				by grp_variable;
				run;

			proc transpose data = prob(keep = grp_variable estimate:) out = prob_est(drop = _name_ rename = (col1 = estimate));
				by grp_variable;
				run;

			data probplot;
				merge prob_per(in = a)  prob_est(in = b);
				run;

/*			libname outprob xml "&output_path./&v_id./probplot.xml";*/
			data probplot;
				set probplot;
				run;

			proc export data =probplot
				outfile = "&output_path./&v_id./probplot.csv"
				dbms = csv replace;
				run;

			proc sql;
				create table probplot1 as
				select percentile, estimate, grp_variable 
				from probplot;
				quit;

			proc export data =probplot1
				outfile = "&output_path./&v_id./probplot1.csv"
				dbms = csv replace;
				run;
		%end;
/*&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&*/

	/*	RUN SEQUENCE PLOT	*/
		%if "&flag_runseq_plot." = "true" %then %do;
			data runseq;
			set subData(keep = grp_variable  &var_name primary_key_1644 rename = (&var_name. = actual));
			run;

			proc sql;
				create table runseq1 as 
				select primary_key_1644, actual,grp_variable
				from runseq;
				quit;
			data runseq1(rename = primary_key_1644 = primary_key);
				set runseq1;
				run;
			proc sql;
				select distinct grp_variable into:groups separated by "$" from runseq1;
				quit;
				%put &groups;
							
			%do i=1 %to %sysfunc(countw(&groups,"$"));
			ods graphics on/ width=12in height=12in;
				filename image "&output_path./&v_id./runsequence&i..png" ;
				goptions reset=all device = png gsfname=image  gsfmode=replace ;
				footnote1 h = .5 '  ';
				symbol1 i=needle v=none c=orange w=10;
				ods listing ;
				proc gplot data=runseq1;
					plot actual*primary_key/ frame legend;
					where grp_variable="%scan(&groups,&i,"$")";
					run;
					quit;
				ods listing close;
				ods graphics off;
			%end;
			
			PROC EXPORT DATA =  runseq1
				OUTFILE="&output_path./&v_id./runsequence.csv" 
				DBMS=CSV REPLACE; 
				RUN;
					/*libname runseq xml "&output_path/runsequence.xml";*/
					/*data runseq.runsequence;*/
					/*set runseq;*/
					/*run;*/
		%end;
/*&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&*/

/*	/*	RUNS TEST CODE	*/*/
/*		%if "&flag_runs_test." = "true" %then %do;*/
/*			%do y = 1 %to &grp_vcnt.;*/
/**/
/*				proc standard data = subData out = dataset_std&y. mean = 0;*/
/*			        var &var_name.;*/
/*					where  strip(grp_variable) = "&&cond&y." ;*/
/*				run;*/
/**/
/*				data run&y.;*/
/*			        keep variable runs numpos numneg N;*/
/*			        set dataset_std&y. nobs = nobs end=last;*/
/*			        retain runs 1 numpos 0;*/
/*					variable = "&&cond&y.";*/
/*			        PREVPOS = (lag(&var_name.) GE 0 );*/
/*			        CURRPOS = (&var_name. GE 0 );*/
/*			      */
/*			        if _N_=1 and &var_name. GE 0 then numpos+1;*/
/*			        else do;*/
/*			        	if CURRPOS and PREVPOS then numpos+1;*/
/*			        	else if CURRPOS and ^PREVPOS then do;*/
/*			            	runs+1;*/
/*			            	numpos+1;*/
/*			            	end;*/
/*			        	else if ^CURRPOS and PREVPOS then runs+1;*/
/*			        	end;*/
/*			        if last then do;*/
/*			        	numneg=NOBS-numpos;*/
/*			        	N=NOBS;*/
/*			        	output;*/
/*			        	end;*/
/*				run;*/
/**/
/*				data waldwolf&y. (keep = variable z pvalue);*/
/*					length variable $100.;*/
/*					label z='WALD-WOLFOWITZ Z'*/
/*					pvalue='PR > |Z|';*/
/*			   		set run&y.;*/
/*			        mu = ( (2*numpos*numneg) / (numpos+numneg) ) + 1;*/
/*			        sigmasq = ( (2*numpos*numneg) * (2*numpos*numneg-numneg-numpos) ) /*/
/*			                  ( ( (numpos+numneg)**2 ) * (numpos+numneg-1) );*/
/*			        sigma=SQRT(sigmasq);*/
/*			        drop sigmasq;*/
/*			      */
/*			        if N GE 50 then z = (runs - mu) / sigma;*/
/*			        else if runs-mu LT 0 then z = (runs-mu+0.5)/sigma;*/
/*			        else z = (runs-mu-0.5)/sigma;*/
/*			      */
/*			        pvalue=2*(1-PROBNORM(ABS(z)));*/
/*					run;*/
/**/
/*				%if %eval(&y) = 1 %then %do;*/
/*					data runout;*/
/*						set waldwolf&y.;*/
/*						run;*/
/*				%end;*/
/*				%else %do;*/
/*					data runout;*/
/*						set runout waldwolf&y.;*/
/*						run;*/
/*				%end;*/
/*			%end;*/
/**/
/*			proc transpose data = runout out = runout_new(rename = (_name_ = normalitytest) drop = _label_);*/
/*				id variable;*/
/*				var pvalue;*/
/*				run;*/
/**/
/*			libname outrun xml "&output_path./&v_id./runs.xml";*/
/*			data outrun.runs(rename = (normalitytest = test));*/
/*				set normal_out_new runout_new;*/
/*				run;*/
/*					/*libname outrun xml "&output_path/runs.xml";*/*/
/*					/*data outrun.runs;*/*/
/*					/*set runout;*/*/
/*					/*run;*/*/
/*		%end;*/;
/*&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&*/

	/*	HISTOGRAM CODE	*/
		%if "&flag_histogram." = "true" %then %do;
		  
			%do z = 1 %to &grp_vcnt.;
			ods listing;
				proc univariate data = subData;
					var &var_name. ;
					/*histogram/normal;*/
					output out = hist&z mean = mu std = sigma min = min range = range;
					where  strip(grp_variable) = "&&cond&z." ;
					run; quit;
			ods listing close;
				data _NULL_;
					set hist&z.;
					call symputx("min",min);
					call symputx("range",range);
					run;

				%put The min value of &var_name. is &min. ;
				%put The range value of &var_name. is &range. ;
				
				data something&z(keep = increment);
					retain increment &min.;
					do k = 1 to 18;
					increment + %sysevalf(&range./18);
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
						%if "&j." = "1" %then %do;
							if &&range&i <= &var_name. <= &&range&j then increment = &&range&j;
						%end;
						%else %do;
							if &&range&i < &var_name. <= &&range&j then increment = &&range&j;
						%end;
					%end;
					where  strip(grp_variable) = "&&cond&z." ;
					run;

				ods output onewayfreqs = freq&z.(keep = frequency increment rename = (Frequency = frequency));
				proc freq data = histo&z.;
					tables increment;
					run;

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
					quit;

				data histogram&z;
					set histogram&z;
					format grp_variable $100.;
					grp_variable = "&&cond&z.";
					if frequency = . then frequency = 0;
					run;
				%let dsid = %sysfunc(open(histogram&z));
				%let nobs =%sysfunc(attrn(&dsid,NOBS));
				%let rc = %sysfunc(close(&dsid));
				%if &nobs. > 5 %then %do;
					ods graphics on/ width=12in height=12in;
					ods listing;
					filename image "&output_path./&v_id./histogram&z..png";
					goptions device = png gsfname=image gsfmode=replace;
					footnote1 h = .5 '  ';
					symbol1 i=needle v=none c=orange w=10;
					proc gplot data=histogram&z;
									plot frequency*increment;
					run;
					quit;
					ods listing close;
					ods graphics off;
				%end;
				proc sort nodup data = histogram&z; by increment; run;

				%if %eval(&z) = 1 %then %do;
					data histogram;
						set histogram&z;
						run;
				%end;
				%else %do;
					data histogram;
						set histogram histogram&z;
						run;
				%end;
			%end;

/*			libname outhist xml "&output_path./&v_id./histogram.xml";*/
/*			data outhist.histogram;*/
/*				set histogram;*/
/*				run;*/

			proc export data =histogram
				outfile = "&output_path./&v_id./histogram.csv"
				dbms = csv replace;
				run;
		%end;
/*&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&*/

	/* get the unique levels */
	proc sql noprint;
		select unique(grp_variable) into :grplist separated by "|" from subdata  ;
		quit;
	%put here is the list of all unique &grplist;

	%do grp =1 %to %sysfunc(countw(&grplist.,'|'));

	data temp&grp.;
		set &dataset_name.;
				%do j = 1 %to &num_varcnt.;
					&&num_var&j..1 = put(&&num_var&j.,best.);
					drop  &&num_var&j.;
					rename &&num_var&j..1 = &&num_var&j.;
				%end;
			run;

	data temp&grp.;
		set temp&grp.;
		array aa(*) &grp_vars ;
		grp_variable = catx("_" , of aa[*]);
		%if "&grp_no." ^= "0" %then %do;
			where grp&grp_no._flag = "%scan(&grp_flag.,&grp.,' ')";
		%end;
		run;


	/*	TIME SERIES CODE	*/
		%macro try;

		%if "&date_var." ~= "" %then %do;
		%if "&flag_timeSeries_plot." = "true" %then %do;
			%do j = 1 %to %sysfunc(countw(&date_var.," "));
				%do i = 1 %to %sysfunc(countw(&var_list.," "));
					%let var_num = %scan(&var_list,&i," ");
					%let var_num_id = %scan(&var_id,&i," ");
					%let var_date = %scan(&date_var,&j," ");
					data time&grp(keep=&var_date. &var_num. grp_variable);
						set temp&grp.;
						run;
						
					 proc sort data = time&grp.;
						by &var_date.;
						run;

						%let dsid = %sysfunc(open(time&grp.));
						%let nobs =%sysfunc(attrn(&dsid,NOBS));
						%let rc = %sysfunc(close(&dsid));

						%if &nobs. > 5 %then %do;
							ods graphics on/ width=12in height=12in;
							ods listing;
							filename image "&output_path./&var_num_id./timeseries&grp..png";
							goptions device = png gsfname=image gsfmode=replace;
							footnote1 h = .5 '  ';
							symbol1 interpol = join v=none c=orange w=2;
							proc gplot data=time&grp.;
								plot &var_num.* &var_date.;
							run;
							quit;
							ods listing close;
							ods graphics off;
						%end;
					
					proc append base=time&i.&i. data=time&grp. force;
						run;
					PROC EXPORT DATA =  time&i.&i.
							OUTFILE="&output_path./&var_num_id./timeseries.csv" 
							DBMS=CSV REPLACE; 
							RUN;

				%end;
			%end;
		%end;
		%end;

		%mend try;
		%try;

		/*&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&*/

	/*	ACF CODE	*/
%macro acf;
	%if "&flag_acf_plot." = "true" %then %do;
		%do i = 1 %to %sysfunc(countw(&var_list.," "));
			%let var_num = %scan(&var_list,&i," ");
			%let var_num_id = %scan(&var_id,&i," ");
			%let dsid=%sysfunc(open(temp&grp.));
            %let num=%sysfunc(attrn(&dsid,nlobs));
            %let rc=%sysfunc(close(&dsid));
		     %if &num. le 6 %then %do;
			   data www;
		          %let x = %scan(&grplist.,&grp.,'|');
		            file "&output_path./&var_num_id./acf_&grp..txt";
		                run;
			%end;
            %else %do;
			ods output AutoCorrGraph = acf(keep= lag Correlation StdErr);
		   	proc arima data = temp&grp.;
			   	identify var = &var_num. ;
				run;
			%if "&SYSERRORTEXT." ne "" %then %do;
				data _null_;
					v1="&SYSERRORTEXT.";
					file "&output_path./error.txt";
					put v1;
					run;
				%end;
			data acf&grp.;
				set acf;
				StdErrX2 = StdErr * 1.96;
				Neg_StdErrX2 = StdErr * -1.96;
				grp_variable= "%scan(&grplist.,&grp.,'|')";
				run;

				proc append base=autocorr&i. data=acf&grp. force;
				run;
					
				data autocorr&i.;
				length variable_name $30.;
				set autocorr&i.;
				variable_name = "&var_num.";
				run;
				proc sql;
				create table autocorr&i. as 
				select lag,correlation,variable_name,grp_variable,StdErr,StdErrX2,Neg_StdErrX2
				from autocorr&i.;
				run;
				quit;
				proc sort data= autocorr&i. out =autocorr&i. nodupkey;
				by grp_variable lag;
				run;
				quit;
		        PROC EXPORT DATA =  autocorr&i.
				OUTFILE="&output_path./&var_num_id./AutoCorrelation_Plot_Sample.csv" 
				DBMS=CSV REPLACE; 
				RUN;
		%end;
		%end;
	%end;
 %mend acf;
 %acf;

		/*&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&*/
 	/*	PACF CODE	*/
	%macro pacf;
	%if "&flag_pacf_plot." = "true" %then %do;
		%let dsid=%sysfunc(open(temp&grp.));
 		%let nobs=%sysfunc(attrn(&dsid,nobs));
 		%let dsid=%sysfunc(close(&dsid));
		%let sq=%sysfunc(sqrt(&nobs.));
		%put &sq.;

		%let diff=%sysfunc(round(1/&sq.,0.001));
		%put &diff.;
		%do i = 1 %to %sysfunc(countw(&var_list.," "));
			%let var_num = %scan(&var_list,&i," ");
			%let var_num_id = %scan(&var_id,&i," ");
			%if &nobs. le 6 %then %do;
					  data yyy;
					  		%let x = %scan(&grplist.,&grp.,'|');
                              file "&&output_path./&var_num_id./pacf_&grp..txt";
		                  	run;
		    %end;
			%else %do;
            ods output PACFGraph = pacf(keep = lag PACF);
			proc arima data = temp&grp.;
			   	identify var = &var_num. ;
				run;
			%if "&SYSERRORTEXT." ne "" %then %do;
				data _null_;
					v1="&SYSERRORTEXT.";
					file "&output_path./error.txt";
					put v1;
					run;
				%end;
			data pacf&grp.(rename = (PACF = Correlation));
				set pacf;
				StdErr = &diff.;
				StdErrX2 = StdErr * 1.96;
				Neg_StdErrX2 = StdErr * -1.96;
				grp_variable= "%scan(&grplist.,&grp.,'|')";
				if lag = 0 then delete;
				run;
			proc append base=partialACF data=pacf&grp. force;
				run;		
			PROC EXPORT DATA =  partialACF
					OUTFILE="&output_path./&var_num_id./_Partial_ACF_Sample.csv" 
					DBMS=CSV REPLACE; 
					RUN;
			%end;
		
	%end;	
	%end;
	 %mend pacf;
	 %pacf;


		/*	UNIT TEST	*/
		%if "&flag_unit_test." = "true" %then %do;
		     %do i = 1 %to %sysfunc(countw(&var_list.," "));
                  %let var_num = %scan(&var_list,&i," ");
                  %let var_num_id = %scan(&var_id,&i," ");
                  %let dsid=%sysfunc(open(temp&grp.));
                  %let num=%sysfunc(attrn(&dsid,nlobs));
                  %let rc=%sysfunc(close(&dsid));
				  %if &num. le 6 %then %do;
					  data uuu;
					  %let x = %scan(&grplist.,&grp.,'|');
                         file "&output_path./&var_num_id./unit_test_&grp..txt";
		                  	run;
				 %end;
                 %else %do;
				 ods trace on;
				 ods output StationarityTests = UnitRootTests&grp.;
				   proc arima data =  temp&grp.;
					   identify var = &var_num. stationarity = (DICKEY = (0,1,2) );
					   run;
					   quit;
			     ods trace off;
				 %if "&SYSERRORTEXT." ne "" %then %do;
					data _null_;
						v1="&SYSERRORTEXT.";
						file "&output_path./error.txt";
						put v1;
						run;
				%end;
				 data UnitRootTests&grp.;
					 set UnitRootTests&grp.;
					grp_variable= "%scan(&grplist.,&grp.,'|')";
					run;
				proc append base=unitroot data=UnitRootTests&grp. force;
				run;
				proc export data =  unitroot
					outfile = "&output_path./&var_num_id./UnitRootTests.csv"
					dbms = CSV replace;
					run;
				%end;
			%end;

			
		%end;




   	/*	SEASONALITY TEST	*/
		%if "&flag_seasonality_test." = "true" %then %do;
			  %do i = 1 %to %sysfunc(countw(&var_list.," "));
                  %let var_num = %scan(&var_list,&i," ");
                  %let var_num_id = %scan(&var_id,&i," ");
                  %let dsid=%sysfunc(open(temp&grp.));
                  %let num=%sysfunc(attrn(&dsid,nlobs));
                  %let rc=%sysfunc(close(&dsid));
				  %if &num. le 6 %then %do;
					  data zzz;
		               		%let x = %scan(&grplist.,&grp.,'|');
                              file "&output_path./&var_num_id./seasonality_&grp..txt";
		                  	run;
				 %end;
                 %else %do;
				ods trace on;
				   proc arima data = temp&grp.;
				   ods output StationarityTests = SeasonalityTests&grp.;
				   identify var = &var_num. stationarity = (DICKEY = (0,1,2) DLAG = 12 );
				   run;
				   quit;
				 ods trace off;
				 %if "&SYSERRORTEXT." ne "" %then %do;
				data _null_;
					v1="&SYSERRORTEXT.";
					file "&output_path./error.txt";
					put v1;
					run;
				%end;
				 data SeasonalityTests&grp.;
					 set SeasonalityTests&grp.;
					 grp_variable= "%scan(&grplist.,&grp.,'|')";
					 run;

				proc append base=seasonality data=SeasonalityTests&grp. force;
					run;
				proc export data =  seasonality
					outfile = "&output_path./&var_num_id./SeasonalityTests.csv"
					dbms = CSV replace;
					run;
				%end;
			%end;

			
		%end;




    /*	WHITE NOISE TEST	*/
		%if "&flag_whiteNoise_test." = "true" %then %do;
			 %do i = 1 %to %sysfunc(countw(&var_list.," "));
                  %let var_num = %scan(&var_list,&i," ");
                  %let var_num_id = %scan(&var_id,&i," ");
				  %let dsid=%sysfunc(open(temp&grp.));
                  %let num=%sysfunc(attrn(&dsid,nlobs));
                  %let rc=%sysfunc(close(&dsid));
				  %if &num. le 20 %then %do;
					  data xxx;
		               		%let x = %scan(&grplist.,&grp.,'|');
                              file "&output_path./&var_num_id./whitenoise_&grp..txt";
		                  	run;
				 %end;
                 %else %do;
				 	data temp&grp._new;
						set temp&grp.;

						if &var_num. ^= . then
							output;
					run;
					
					%let dsid=%sysfunc(open(temp&grp._new));
					%let nums=%sysfunc(attrn(&dsid,nlobs));

%let rc=%sysfunc(close(&dsid));

					%if &nums. le 24 %then
						%do;

							data _null_;
								v1="Insufficient data to perform whitenoise test";
								file "&output_path./&var_id./error.txt";
								put v1;
							run;

						%end;
					%else
						%do;

				 	   ods trace on;
					   ods output ChiSqAuto = WhiteNoiseTest&grp.;
					   proc arima data =  temp&grp._new;
						   identify var = &var_num. stationarity = (DICKEY = (0,1,2) );
						   run;
						   quit;
			     		ods trace off;
						%if "&SYSERRORTEXT." ne "" %then %do;
						data _null_;
							v1="&SYSERRORTEXT.";
							file "&output_path./error.txt";
							put v1;
							run;
						%end;
					 data WhiteNoiseTest&grp.;
						set WhiteNoiseTest&grp.;
						grp_variable= "%scan(&grplist.,&grp.,'|')";
						run;
					 proc append base=whitenoise data=WhiteNoiseTest&grp. force;
						run;
				proc export data =  whitenoise
						outfile = "&output_path./&var_num_id./WhiteNoiseTest.csv"
						dbms = CSV replace;
						run;
				%end;
				%end;
			%end;

		%end;
				
	%end;
	%end;

	/* Flex uses this file to test if the code has finished running */
data _null_;
	v1= "EDA - UNIVARIATE_ACROSSGRPBY_COMPLETED";
	file "&output_path./UNIVARIATE_ACROSSGRPBY_COMPLETED.txt";
	PUT v1;
	run;


%end;

%mend varchar_grp;
%varchar_grp;

proc datasets lib=work kill nolist;
quit;
