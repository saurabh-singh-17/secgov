proc datasets lib=work kill;
run;
quit;

/*Successfully converted to SAS Server Format*/
*processbody;
%let completedTXTPath =  &outputpath./BOOTSTRAPPING_COMPLETED.txt;
options mprint mlogic symbolgen mfile;

proc printto log="&outputpath./bootstrapping_log.log";
run;
quit;

libname in "&inputpath.";
libname out "&outputpath.";
libname group "&grouppath.";

%macro bootstrapping;
	%let dsid = %sysfunc(open(group.bygroupdata));
	%let varnum_dependent = %sysfunc(varnum(&dsid., &dependentvariable.));
	%let vartype_dependent = %sysfunc(vartype(&dsid., &varnum_dependent.));
	%let rc = %sysfunc(close(&dsid.));

	%if "&vartype_dependent." = "C" %then
		%do;
			%let event = "&event.";
		%end;

	proc freq data = group.bygroupdata %if "&validationvar." ^= "" %then %do; (where = (&validationvar. = 1)) %end; noprint;
		table &dependentvariable. / out=out_proc_freq;
	run;
	quit;

	data _null_;
		set out_proc_freq;
		if &dependentvariable. = &event. then
			do;
				call symput("n_event", count);
				call symput("n_pc_event", percent);
			end;
		else
			do;
				call symput("n_nonevent", count);
				call symput("n_pc_nonevent", percent);
			end;
	run;

	%let n_nonevent_required = %sysevalf(((100 - &oversample_percent.) / &oversample_percent.) * &n_event., floor);

	data event;
		set group.bygroupdata
			%if "&validationvar." ^= "" %then %do; (where = (&validationvar. = 1 and &dependentvariable. = &event.)); %end;
			%else %do; (where = (&dependentvariable. = &event.)); %end;
	run;

	%do  i = 1 %to &numiterations.;

		/*Generating a random integer*/
		%let seed = %substr(%sysfunc(ranuni(24)), 3, 8);
		%put &seed.;

		proc surveyselect data = group.bygroupdata
						  %if "&validationvar." ^= "" %then %do; (where = (&validationvar. = 1 and &dependentvariable. ^= &event.)) %end;
						  %else %do; (where = (&dependentvariable. ^= &event.)) %end;
						  out = nonevent_random_i method = SRS sampsize = &n_nonevent_required. seed = &seed. noprint;
		run;
		quit;

		data dev;
			set event nonevent_random_i;
		run;

		ods output association = association_i;
		ods output lackfitchisq = hosmer_i;
		ods output CLparmWald = param_i;

		proc logistic data = dev outest = outest_i namelen = 50;
			%if "&classVariables." ^= "" %then
				%do tempi=1 %to %sysfunc(countw(&classVariables.));
					%let ref =  %scan(&pref., &tempi., "!!");
					%let class&tempi. = %scan(&classVariables, &tempi.," ") (ref = "&ref")/ param = %scan(&param., &tempi.) order = &classOrderType. &classOrderSeq.;
					class &&class&tempi..;
				%end;
			model &dependentVariable. %if &logitForm. = single_trial %then %do; (Event="&event.") %end;
				  = &independentVariables. &classVariables.
			      /lackfit CLPARM=WALD 
			      scale = &scaleOption. aggregate &regressionOptions.
				  %if "&maxiter." ^= "" %then %do; maxiter = %eval(&maxiter.) %end;;
			%if "&weightVar." ^= "" %then
				%do; weight &weightVar.
					%if "&weightoption." ^= "" %then %do; /&weightoption. %end;
				%end;;
		run;
		quit;

		data association_i;
			set association_i(drop = cvalue1 cvalue2);
			iteration = &i.;
		run;

		data hosmer_i;
			set hosmer_i;
			iteration = &i.;
		run;

		data param_i;
			set param_i;
			iteration = &i.;
		run;

		data outest_i;
			set outest_i;
			iteration = &i.;
		run;

		%if &i. = 1 %then
			%do;
				data association;
					set association_i;
				run;

				data hosmer;
					set hosmer_i;
				run;

				data param;
					set param_i;
				run;

				data outest;
					set outest_i;
				run;
			%end;
		%else
			%do;
				data association;
					set association association_i;
				run;

				data hosmer;
					set hosmer hosmer_i;
				run;

				data param;
					set param param_i;
				run;

				data outest;
					set outest outest_i;
				run;
			%end;
	%end;

	%let classval0 =;
	%if "&classVariables." ^= "" %then %let classval0 = classval0,;

	proc sql;
		create table avg_param as
			select &classval0.
				parameter as variable,
				count(estimate >= 0) as count_estimate_nonneg,
				count(estimate < 0) as count_estimate_neg,
				avg(estimate) as avg_estimate,
				max(estimate) as max_estimate,
				min(estimate) as min_estimate,
				std(estimate) as std_estimate,
				var(estimate) as var_estimate,
				max(estimate) - min(estimate) as range_estimate,
				avg(lowercl) as avg_lowercl,
				max(lowercl) as max_lowercl,
				min(lowercl) as min_lowercl,
				avg(uppercl) as avg_uppercl,
				max(uppercl) as max_uppercl,
				min(uppercl) as min_uppercl
			from param
				group by &classval0. variable;
	run;
	quit;

	proc sort data = param out = param;
		by parameter descending estimate;
	run;
	quit;

	data param;
		set param(rename=(parameter = variable));
		retain sno 0;
		by variable;
		if first.variable then sno = 1;
		else sno = sno + 1;
	run;

	data est2(rename = (estimate = est_second_highest) drop = sno)
		est3(rename = (estimate = est_third_highest) drop = sno)
		est4(rename = (estimate = est_fourth_highest) drop = sno)
		est5(rename = (estimate = est_fifth_highest) drop = sno)
		est%eval(&numiterations.-4)(rename = (estimate = est_fifth_last) drop = sno)
		est%eval(&numiterations.-3)(rename = (estimate = est_fourth_last) drop = sno)
		est%eval(&numiterations.-2)(rename = (estimate = est_third_last) drop = sno)
		est%eval(&numiterations.-1)(rename = (estimate = est_second_last) drop = sno);
		set param(keep = variable estimate sno);
		if sno = 2 then
			output est2;
		else if sno = 3 then
			output est3;
		else if sno = 4 then
			output est4;
		else if sno = 5 then
			output est5;
		else if sno = %eval(&numiterations.-4) then
			output est%eval(&numiterations.-4);
		else if sno = %eval(&numiterations.-3) then
			output est%eval(&numiterations.-3);
		else if sno = %eval(&numiterations.-2) then
			output est%eval(&numiterations.-2);
		else if sno = %eval(&numiterations.-1) then
			output est%eval(&numiterations.-1);
	run;

	proc sort data = avg_param out = avg_param;
		by variable;
	run;
	quit;

	data avg_param;
		merge avg_param est2 est3 est4 est5 est%eval(&numiterations.-4) est%eval(&numiterations.-3)
			  est%eval(&numiterations.-2) est%eval(&numiterations.-1);
		by variable;
	run;

	data _null_;
		call symput("classval0", tranwrd("&classval0.", ",", ""));
	run;

	data out.params;
		set avg_param(keep = &classval0. variable avg_estimate rename = (variable = Variable avg_estimate = Estimate));
	run;

	/*Output CSVs*/
	proc export data = avg_param   outfile = "&outputpath./param_report.csv"       dbms=csv replace;
	proc export data = hosmer      outfile = "&outputpath./hosmer_report.csv"      dbms=csv replace;
	proc export data = association outfile = "&outputpath./association_report.csv" dbms=csv replace;
	run;
	quit;

%mend bootstrapping;

%bootstrapping;

/* Flex uses this file to test if the code has finished running */
data _null_;
	v1= "Logistic Regression - BOOTSTRAPPING_COMPLETED";
	file "&outputpath./BOOTSTRAPPING_COMPLETED.txt";
	put v1;
run;