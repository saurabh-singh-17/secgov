/*Successfully converted to SAS Server Format*/
*processbody;
%let completedTXTPath =  &output_path./add_label_completed.txt;
*processbody;

options mprint mlogic symbolgen mfile;

proc printto log="&output_path/categorical_log.log";
run;
quit;

/*proc printto print="&output_path/categorical_output.out";*/

libname in "&input_path.";
libname out "&output_path.";
%macro rename_labels();

/* 		the variables whose labels need to be changed and its corresponding labels 
   		are passed as params and the labels are changed here					 */
%do i = 1 %to %sysfunc(countw(&var_list.));
	%let temp_var = %scan(&var_list,&i);
	%let temp_label = %scan(&label_list,&i,"|");
	data out.dataworking;
	    set out.dataworking;
		attrib &temp_var. label = "&temp_label.";
		run;
%end;

/*		the variables which need to be changed from numeric to string type are passed as parameters and changed here	*/
%do i = 1 %to %sysfunc(countw(&string_vars.," "));
	%let num_var = %scan(&string_vars,&i," ");
	data out.dataworking;
	    set out.dataworking;
		&num_var.1 = put(&num_var. , $4.);
		drop &num_var.;
		run;
	data out.dataworking;
	    set out.dataworking(rename=(&num_var.1=&num_var.));
		run;
%end;
	

%mend rename_labels();
%rename_labels();


data _null_;
	v1= "add_label_completed";
	file "&output_path./add_label_completed.txt";
	put v1;
	run;




proc datasets lib=work kill nolist;
quit;

