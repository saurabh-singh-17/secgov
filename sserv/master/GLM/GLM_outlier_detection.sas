/*Successfully converted to SAS Server Format*/
*processbody;
%let completedTXTPath =  &inter_output_path/MODELING_OUTLIER_DETECTION_COMPLETED.txt;
options mprint mlogic symbolgen mfile ;


proc printto log="&inter_output_path./ModelingOutlierDetection_Log.log";
run;
quit;

proc printto;
run;

/*proc printto print="&inter_output_path./ModelingOutlierDetection.out";*/

FILENAME MyFile "&inter_output_path./MODELING_OUTLIER_DETECTION_COMPLETED.txt" ;

 DATA _NULL_ ;
    rc = FDELETE('MyFile') ;
  RUN ;

data _null_;
call symput("outdata_path",tranwrd("&inter_output_path.","/outlier",""));
run;

libname od "&outdata_path";
libname out "&inter_output_path";


/*find total no. of obs*/
data _null_;
	set od.outdata nobs = num_obs;
	call symputx("num_obs_chk",num_obs);
	stop;
	run;



/*replace negative values by absolute values*/
data out.outdata;
	set od.outdata;
	attrib _all_ label=" ";
	format res r_student hat_diag cooks_dis dffits mape 8.3;
	res = abs(res);
	r_student = abs(r_student);
	hat_diag = abs(hat_diag); 
	cooks_dis = abs(cooks_dis);
	dffits = abs(dffits); 
	mape = res/abs(actual); 
	run;


%MACRO outlier_procReg1;

%if &num_obs_chk. > 101 %then %do;
	%let num_obs=101;
%end; 
%else %do;
	%let num_obs=&num_obs_chk.;
%end;

	%let univ_macro = r_student hat_diag cooks_dis dffits;

	%do i=1 %to 4;

		%let cur_var=%scan(&univ_macro,&i);	
		data out.outdata;
			set out.outdata;
			temp=&cur_var.;
			run;	
	
		proc rank data=out.outdata out=rankpred(keep=primary_key_1644 &cur_var. temp mape res) groups=&num_obs.;
		var &cur_var.;
		run;

		proc sort data=rankpred;
		by &cur_var.;
		run;
		
		data rankpred&i.(drop=&cur_var. rename=(temp=&cur_var. mape=mape_&cur_var. res=res_&cur_var.));
			set rankpred;
			by &cur_var.;
			if last.&cur_var.;
			_NAME_ = cat("p_",&cur_var.);
			run;

	%end;

	/*merge univariate output for all the four variables*/
	data univ;
		merge rankpred1 rankpred2 rankpred3 rankpred4;
		run;

		
	/*reform the output dataset by putting in the no. of outliers and percent outliers*/
	data out.output (drop = primary_key_1644);
		set univ;
		format no_of_outliers 8.;
		primary_key_1644 = _n_;
		percent_outliers = &num_obs.-(primary_key_1644);
		no_of_outliers = (percent_outliers/100)*&num_obs_chk.;
		run;
%MEND outlier_procReg1;
%outlier_procReg1;


	

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

/*ENDSAS;*/


