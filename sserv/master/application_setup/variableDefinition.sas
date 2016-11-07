/*Successfully converted to SAS Server Format*/
*processbody;
%let completedTXTPath =  &input_path./VARIABLE_DEFINITION_COMPLETED.txt;
options mprint mlogic symbolgen mfile ;

proc printto log="&output_path./variableDefinition_Log.log";
run;
quit;
/*proc printto print="&output_path./variableDefinition_Output.out";*/

libname in "&input_path.";

%macro dictionary;
	
	libname input xml "&inputXML_path./var_labels.xml";
	data labels;
		set input.var_labels;
		 if DEFINITION ^ = "";
		run;
	
	proc sql;
		select definition into :labels separated by "!!" from labels;
		select variable into :var_list separated by " " from labels;
		quit;
	%put &labels;
	%put &var_list;
	
	data in.&dataset_name.;
		set in.&dataset_name.;
		%let i = 1;
		%do %until (not %length(%scan(&var_list, &i)));
		label %scan(&var_list, &i) = "%scan(&labels, &i, "!!")";
		%let i = %eval(&i.+1);
		%end;
		run;
	

%mend dictionary;
%dictionary;


/* Flex uses this file to test if the code has finished running */
data _NULL_;
      v1= "Variable Definition - variableDefinition_COMPLETED";
      file "&input_path./VARIABLE_DEFINITION_COMPLETED.txt";
      PUT v1;
      run;







proc datasets lib=work kill nolist;
quit;

