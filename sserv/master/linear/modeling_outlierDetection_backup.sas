/*Successfully converted to SAS Server Format*/
*processbody;
%let completedTXTPath =  &inter_output_path/MODELING_OUTLIER_DETECTION_COMPLETED.txt;
options mprint mlogic symbolgen mfile ;


%sysexec del "&inter_output_path./MODELING_OUTLIER_DETECTION_COMPLETED.txt";

proc printto log="&inter_output_path./ModelingOutlierDetection_Log.log";
run;
quit;
/*proc printto print="&inter_output_path./ModelingOutlierDetection.out";*/


libname in "&input_path";
libname out "&inter_output_path";
FILENAME MyFile "&inter_output_path./MODELING_OUTLIER_DETECTION_COMPLETED.txt" ;

  DATA _NULL_ ;
    rc = FDELETE('MyFile') ;
  RUN ;
/*put-in primary key*/
data in.dataworking;
	set in.dataworking;
	primary_key_1644 = _n_;
	run;

/*subset the input dataset*/
data out.temp;
	set in.dataworking (keep = &dependent_var &independent_var);
	run;


/*find total no. of obs*/
data _null_;
	set out.temp nobs = num_obs;
	call symputx("num_obs",num_obs);
	stop;
	run;


/*regression*/
proc reg data = out.temp;
	model &dependent_var. = &independent_var./influence;
	output out = out.outdata r = res rstudent = r_student h = hat_diag cookd = cooks_dis dffits = dffits;
run;
quit;	

/*replace negative values by absolute values*/
data out.outdata;
	set out.outdata;
	attrib _all_ label=" ";

	format res r_student hat_diag cooks_dis dffits mape 8.3;
	res = abs(res);
	r_student = abs(r_student);
	hat_diag = abs(hat_diag); 
	cooks_dis = abs(cooks_dis);
	dffits = abs(dffits); 
	mape = res/&dependent_var.; 
	run;


%MACRO outlier_procReg1;

	%let univ_macro = r_student hat_diag cooks_dis dffits;

	%let i =1;
	%do %until(not %length(%scan(&univ_macro,&i)));

	/*univariate treatment per variable*/
		proc univariate data = out.outdata noprint;
			var %scan(&univ_macro,&i);
			output out= univ&i.
				pctlpts= 0 to 100 by 1
				pctlpre=p_ ;
			run;

		data univ&i.;
			retain attributes;
			set univ&i.;
			attrib _all_ label=" ";

			format attributes $50.;
			attributes = "%scan(&univ_macro,&i)";
			run;

		%let i=%eval(&i+1);
	%end;

	/*merge univariate output for all the four variables*/
	data univ;
		set univ1 univ2 univ3 univ4;
		run;

	/*transpose the univariate output*/
	proc transpose data = univ out = trans_univ;
		id attributes;
		run;


	/*find values corresponding residual values per variable at each percentile point*/
	%let j =1;
	%do %until(not %length(%scan(&univ_macro,&j)));

		data out_part&j.;
			set out.outdata (keep = res mape %scan(&univ_macro,&j));
			run;

		proc sort data = out_part&j. out = out_part&j.;
			by %scan(&univ_macro,&j);
			run;

		data trans_univ&j.(rename = (res=res_%scan(&univ_macro,&j) mape=mape_%scan(&univ_macro,&j)));
			merge trans_univ(in=a) out_part&j.(in=b);
			by %scan(&univ_macro,&j);
			if a;
			run;
		data trans_univ&j.(drop=obs2);
			set trans_univ&j.;
			obs2=tranwrd(_NAME_,"p_","0");
			obs1=obs2*1;
			run;
		data trans_univ&j.(drop=obs1);
			set trans_univ&j.;
			by obs1;
			if last.obs1;
			run;
	%let j=%eval(&j+1);
	%end;
	data trans_univ;
	merge trans_univ1 trans_univ2(keep=res: mape:) trans_univ3(keep=res: mape:) trans_univ4(keep=res: mape:);
	run;

%MEND outlier_procReg1;
%outlier_procReg1;


/*reform the output dataset by putting in the no. of outliers and percent outliers*/
data out.output (drop = primary_key_1644);
	set trans_univ;
	
	format no_of_outliers 8.;
	primary_key_1644 = _n_;
	percent_outliers = 100-(primary_key_1644 - 1);
	no_of_outliers = (percent_outliers/100)*&num_obs.;
	
	run;
	

/*CSV export*/
proc export data = out.output
	outfile="&inter_output_path/modeling_outlierDetection.csv" 
	dbms=CSV replace; 
	run;

/*delete datasets from output folder*/
proc datasets library = out;
	delete output temp;
	run;


/* flex uses this file to test if the code has finished running */
data _null_;
	v1= "MODELING_OUTLIER_DETECTION_COMPLETED";
	file "&inter_output_path/MODELING_OUTLIER_DETECTION_COMPLETED.txt";
	put v1;
	run;


ENDSAS;


