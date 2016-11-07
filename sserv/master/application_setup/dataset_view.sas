/*Successfully converted to SAS Server Format*/
*processbody;
%let completedTXTPath =  &output_path./DATASET_VIEW_COMPLETED.txt;

/*-------------------------------------PROJECT SETUP_ DATASET VIEW----------------------------------------*/
/***********************************PARAMETERS REQUIRED************************************/
/*%let codePath=/product-development/murx///SasCodes//8.7.2;*/
/*%let input_path=/product-development/murx///projects/new1234-5-Sep-2014-16-15-07/1;*/
/*%let output_path=/product-development/murx///projects/new1234-5-Sep-2014-16-15-07/1;*/
/*%let dataset_name=dataworking;*/
/*%let type=all;*/
/*%let random=0;*/
/*%let start=1;*/
/*%let count=10;*/
/*%let varlist=ACV black_hispanic;*/
/*%let filter_flg=true;*/
/*%let c_path_filter_param=/product-development/murx///projects/new1234-5-Sep-2014-16-15-07/1/ProjectSetup/sortFilter/3/param_sortAndFilter.sas;*/
/*%let c_path_filter_code=/product-development/murx///SasCodes//8.7.2/application_setup/sortAndFilter.sas;*/


/******************************************************************************************/
/*Author : Aparna Joseph*/
/*Last Edited: March 11 2013*/
/*Version 1.0.0*/
/*----------------------------------------------------------------------------------------------------------*/
dm log 'clear';
options mprint mlogic symbolgen mfile;

proc printto log="&output_path/datasetview.log";
run;
quit;

/*proc printto;*/
/*run;*/
/*quit;*/
/*proc printto print="&output_path./datasetview_Output.out";*/
libname in "&input_path.";
libname out "&output_path.";
%let out_data_name= datasetView;

%macro dataset_View;
	/*Filter Scenario*/
	%if "&filter_flg." ^= "false" %then
		%do;
			%let c_path_in = &input_path.;/*Input Path*/
			%let c_path_out = &output_path.; /*Output PAth*/
			%let c_data_final_sf = dataworking_fs; /*Name of the final dataset to work on*/
			%let c_data_filter_and_sort = final_filter_sort;
			%let c_var_required=&varlist.;
			%let c_path_filter_param =  %str(%')&c_path_filter_param.%str(%');
			%let c_path_filter_code =  %str(%')&c_path_filter_code.%str(%');

			%include %unquote(&c_path_filter_param.);
			%include %unquote(&c_path_filter_code.);

			/*Input Library*/
			data in.&c_data_final_sf.;
				set &c_data_filter_and_sort.;
				primary_key_1644=_n_;
				
			run;

			/*Any other dataset name declaration specifc to code*/
			%let dataset_name = &c_data_final_sf.;
		%end;

	%let dsid = %sysfunc(open(in.&dataset_name.));
	%let nobs=%sysfunc(attrn(&dsid,nobs));
	%let rc = %sysfunc(close(&dsid));
	%put &nobs.;

	data _null_;
		v1= &nobs.;
		file "&output_path./noobs_refresh.txt";
		put v1;
	run;

	%if &type.=all %then
		%do;

			data subset;
				set in.&dataset_name.(keep=&varlist. primary_key_1644);

				if primary_key_1644>=&start.;

				if primary_key_1644<&start.+&count.;

				drop primary_key_1644;
			run;

		%end;

	%if &type.=random %then
		%do;

			proc surveyselect data=in.&dataset_name.(keep=&varlist.) out=subset method=SRS
				sampsize=&random.;
			run;

			data subset;
				set subset;
				primary_key_1644=_n_;
		%end;
%mend dataset_View;

%dataset_View;

proc export data=subset outfile="&output_path./&out_data_name..csv" dbms=csv replace;
run;

quit;

/* Flex uses this file to test if the code has finished running */
data _NULL_;
	v1= "DATASET_VIEW COMPLETED";
	file "&output_path./DATASET_VIEW_COMPLETED.txt";
	PUT v1;
run;

/*proc datasets lib=work kill nolist;*/
/*quit;*/
;