/*Successfully converted to SAS Server Format*/
*processbody;
%let completedTXTPath =  &output_path/DATE_MANIPULATION_COMPLETED.txt;
options mprint mlogic symbolgen;
libname in "&input_path.";
libname out "&output_path.";

proc printto log="&output_path./date_manipulation.log" new;
/*proc printto;*/
run;
quit;

%let new_vars=;

%macro datemanipulation;
	%let delete_vars=;

	%if &univariate.=true %then
		%do;

			data temp;
				set &dataset_name.(keep = &univ_datevars.);
			run;

			proc sort data = temp out= temp;
				by &univ_datevars.;
			run;

			quit;

			proc contents data=temp out=temp_contents;
			run;

			quit;

			%let new_univ_datevars2=;

			%do l=1 %to %sysfunc(countw(&univ_datevars.," "));
				%let new_univ_datevars=%scan(&univ_datevars.,&l.," ");

				proc sql noprint;
					select FORMAT into: dateformat from temp_contents where NAME = "&new_univ_datevars.";
				quit;

				%put &dateformat.;

				%if &dateformat. = DATETIME %then
					%do;
						%let delete_vars=;
						%let var_date_name = %substr(&new_univ_datevars.,1,27)_muRx;

						data &dataset_name.;
							format &var_date_name. date9.;
							set &dataset_name.;
							&var_date_name.= datepart(&new_univ_datevars.);
						run;

						%let delete_vars= &delete_vars. &var_date_name.;
						%let new_univ_datevars2=&new_univ_datevars2. &var_date_name.;
					%end;
				%else
					%do;
						%let new_univ_datevars2=&new_univ_datevars2. &new_univ_datevars.;
					%end;
			%end;
		%end;

	%put &new_univ_datevars2.;
	%put &delete_vars;

	%if &univariate.=true %then
		%do;
			%if &univ_func.=intervalAlignment %then
				%do;
					%if &interval.=quarter %then
						%do;
							%let &interval.= "qtr";
						%end;

					data _null_;
						call symput("datevar_int","'&interval.'");
					run;

					%if &alignment.= beginning %then
						%do;

							data _null_;
								call symput("ali_int","'b'");
							run;

						%end;
					%else
						%do;

							data _null_;
								call symput("ali_int","'e'");
							run;

						%end;
				%end;

			%if &univ_func.=dateComparison %then
				%do;

					data _null_;
						call symput("showin_type","'&showIn.'");
					run;

					%if &isCurrentDate.=true %then
						%do;

							data _null_;
								call symput ("comp_date",today());
							run;

						%end;
					%else
						%do;

							data _null_;
								call symput ("comp_date","'&customDatevalue.'d");
							run;

						%end;

					%put &comp_date.;
				%end;
		%end;
		
	%let c_varfmt = ;
	%let n_dsid = %sysfunc(open(in.dataworking));
	%if &univariate.=true %then
		%let x_temp = &univ_datevars.;
	%else
		%let x_temp = &bi_x_datevars.;
		
	%do i = 1 %to %sysfunc(countw(&x_temp.));
		%let x_temp_now = %scan(&x_temp., &i.);
		%let n_varnum = %sysfunc(varnum(&n_dsid., &x_temp_now.));
		%let c_varfmt = &c_varfmt. %sysfunc(varfmt(&n_dsid., &n_varnum.));
	%end;
	%let n_rc = %sysfunc(close(&n_dsid.));

	%if &univariate.=true %then
		%do;

			data &dataset_name.;
				set &dataset_name.;
				%do i=1 %to %sysfunc(countw(&new_univ_datevars2.));
					%let c_varfmt_now = %scan(%str(&c_varfmt.), &i., %str( ));

					%if &univ_func.=increment %then
						%do;
							format &pref._%substr(%scan(&univ_datevars.,&i.),1,18)_incr_&inc_dec_value. &c_varfmt_now.;
							&pref._%substr(%scan(&univ_datevars.,&i.),1,18)_incr_&inc_dec_value.=%scan(&new_univ_datevars2.,&i.)+&inc_dec_value.;
							%let new_vars=&new_vars. &pref._%substr(%scan(&univ_datevars.,&i.),1,18)_incr_&inc_dec_value.;
						%end;

					%if &univ_func.=decrement %then
						%do;
							format &pref._%substr(%scan(&univ_datevars.,&i.),1,18)_decr_&inc_dec_value. &c_varfmt_now.;
							&pref._%substr(%scan(&univ_datevars.,&i.),1,18)_decr_&inc_dec_value.=%scan(&new_univ_datevars2.,&i.)-&inc_dec_value.;
							%let new_vars=&new_vars. &pref._%substr(%scan(&univ_datevars.,&i.),1,18)_decr_&inc_dec_value.;
						%end;

					%if &univ_func.=intervalAlignment %then
						%do;
							format &pref._%substr(%scan(&univ_datevars.,&i.),1,18)_int_ali &c_varfmt_now.;
							&pref._%substr(%scan(&univ_datevars.,&i.),1,18)_int_ali = intnx(&datevar_int.,%scan(&new_univ_datevars2.,&i.),0,&ali_int.);
							%let new_vars=&new_vars. &pref._%substr(%scan(&univ_datevars.,&i.),1,18)_int_ali;
						%end;

					%if &univ_func.=dateComparison %then
						%do;
							format &pref._%substr(%scan(&univ_datevars.,&i.),1,16)_date_comp;
							&pref._%substr(%scan(&univ_datevars.,&i.),1,16)_date_comp = intck(&showin_type.,%scan(&new_univ_datevars2.,&i.),&comp_date.);
							%let new_vars=&new_vars. &pref._%substr(%scan(&univ_datevars.,&i.),1,16)_date_comp;
						%end;
				%end;
			run;

		%end;

	%if &bivariate=true %then
		%do;

			data &dataset_name.;
				set &dataset_name.;
				%do i=1 %to %sysfunc(countw(&bi_x_datevars.));
					%let c_varfmt_now = %scan(&c_varfmt., &i., %str( ));
					
					%if &bi_func.=addition %then
						%do;
							format &pref._%substr(%scan(&bi_x_datevars.,&i.),1,10)_add_%substr(&bi_y_datevars.,1,9) &c_varfmt_now.;
							&pref._%substr(%scan(&bi_x_datevars.,&i.),1,10)_add_%substr(&bi_y_datevars.,1,9)=%scan(&bi_x_datevars.,&i.)+&bi_y_datevars.;
							%let new_vars=&new_vars. &pref._%substr(%scan(&bi_x_datevars.,&i.),1,10)_add_%substr(&bi_y_datevars.,1,9);
						%end;
					%else %if &bi_func.=subtraction %then
						%do;
							%if &bi_y_type.=date %then
								%do;
									&pref._%substr(%scan(&bi_x_datevars.,&i.),1,10)_sub_%substr(&bi_y_datevars.,1,9)=%scan(&bi_x_datevars.,&i.)-&bi_y_datevars.;
								%end;
							%else %if &bi_y_type.=numeric %then
								%do;
									format &pref._%substr(%scan(&bi_x_datevars.,&i.),1,10)_sub_%substr(&bi_y_datevars.,1,9) &c_varfmt_now.;
									&pref._%substr(%scan(&bi_x_datevars.,&i.),1,10)_sub_%substr(&bi_y_datevars.,1,9)=%scan(&bi_x_datevars.,&i.)-&bi_y_datevars.;
								%end;

							%let new_vars=&new_vars. &pref._%substr(%scan(&bi_x_datevars.,&i.),1,10)_sub_%substr(&bi_y_datevars.,1,9);
						%end;
				%end;
			run;

		%end;

	%put &new_vars.;

	data new_vars;
		set &dataset_name.(keep=&new_vars);
	run;

	data &dataset_name(drop=&delete_vars.);
		set &dataset_name;
	run;
	
	/*restriction on the no of rows in the output CSV*/
	%let dsid = %sysfunc(open(new_vars));
	%let nobs=%sysfunc(attrn(&dsid,nobs));	
	%let rc = %sysfunc(close(&dsid));
	%put &nobs.;

	%if &nobs.>6000 %then %do;
		proc surveyselect data=new_vars out=new_vars method=SRS
			sampsize=6000 SEED=1234567;
			run;
	%end;

	proc export data = new_vars
		outfile = "&output_path./new_Datevars.csv"
		dbms = CSV replace;
	run;

%mend datemanipulation;

%datemanipulation;
%include %unquote(%str(%'&genericCode_path./datasetprop_update.sas%'));

/*Flex uses this file to test if the code has finished running*/
data _null_;
	v1= "DATE_MANIPULAION_COMPLETED";
	file "&output_path/DATE_MANIPULATION_COMPLETED.txt";
	put v1;
run;
;