/*-- Parameters Required -------------------------------------------------------------------------------------------------------------------*/
/*%let input_path=/home/mrx1/vasanth||/home/mrx1/vasanth||/home/mrx1/vasanth;*/
/*%let dataset_name=dataworking dataworking dataworking;*/
/*%let output_path=/home/mrx1/vasanth;*/
/*%let type_join=a1 and a2 and a3;*/
/*%let new_dataset=nyu;*/
/*%let key_variables=Date channel_1|channel_2|channel_3;*/
/*%let new_key_variables=dayte channels_combined;*/
/*%let selected_vars1=ACV;*/
/*%let selected_vars2=black_hispanic;*/
/*%let selected_vars3=sales;*/
/*%let new_selected_vars1=ACV;*/
/*%let new_selected_vars2=bh;*/
/*%let new_selected_vars3=sa;*/
/*------------------------------------------------------------------------------------------------------------------------------------------*/

*processbody;
%let completedTXTPath =  &output_path./MERGE_COMPLETED.txt;
/*-- Description ---------------------------------------------------------------------------------------------------------------------------*/
/*-- Process Name       : Merge                                                                                                                                                                             */
/*-- Description        : Merges datasets and writes the resulting dataset                                                                                                          */
/*-- Return type        : None                                                                                                                                                                        */
/*-- Author             : Vasanth M M 4261                                                                                                                                                            */
/*-- Last Edit          :                                                                                                                                                                                   */
/*-- Last Edited on     :                                                                                                                                                                                   */
/*-- Last Edited By     :                                                                                                                                                                                   */
/*Known Issues          : If variables with the same name exist in multiple datasets we get only the values from the base dataset                       */
/*------------------------------------------------------------------------------------------------------------------------------------------*/

/*-- Parameters Required -------------------------------------------------------------------------------------------------------------------*/
/*%let input_path=C:/Documents and Settings/Aparna.Joseph/Desktop/Datasets||C:/Documents and Settings/Aparna.Joseph/Desktop/Datasets;*/
/*%let output_path=C:/Documents and Settings/Aparna.Joseph/Desktop/codes;*/
/*%let dataset_name=dataworking dataworking_linear;*/
/*%let key_variables=ACV;                                                                                                                                                                         */
/*%let type_join=a1 and a2;                                                                                                                                                                */
/*%let new_dataset=nyu;                                                                                                                                                                                 */
/*%let final_variables=Date channel_3;                                                                                                                                            */
/*------------------------------------------------------------------------------------------------------------------------------------------*/

/*-- Code Fragments ------------------------------------------------------------------------------------------------------------------------*/
/*Frag 1 : Macro : Options and clear the log                                                                                                                                              */
/*Frag 2 : Macro : Library definitions                                                                                                                                                          */
/*Frag 3 : Macro : Log and print                                                                                                                                                                */
/*Frag 4 : Macro : Sorting the input datasets by key variables and taking the name of the input datasets,                                                   */
/*                concatenating them together, so that they can be used in merge data step                                                                                    */
/*Frag 4.2 : Macro : Replace a1 by a2                                                                                                                                                           */
/*Frag 5 : Macro : Merge datasets using SAS                                                                                                                                                     */
/*Frag 6 : Macro : Many-many outer join using SQL                                                                                                                                         */
/*Frag 7 : Macro : Many-many inner join using SQL                                                                                                                                         */
/*Frag 8 : Macro : Get the common values from the input datasets                                                                                                              */
/*Frag 9 : Macro : Check if the merge is many-many or not                                                                                                                           */
/*Frag 10 : Macro : Write the merged dataset in the output path and the CSV and completed.txt                                                                        */
/*Frag 11 : Macro : Rearrange the input datasets for SQL                                                                                                                            */
/*Frag 12 : Macro : Rename the necessary variables and change the parameters*/
/*Frag 13 : Calling all the macro(s)                                                                                                                                                            */
/*------------------------------------------------------------------------------------------------------------------------------------------*/

/*Frag 1 : Macro : Options and clear the log*/
%macro options;

options mprint mlogic symbolgen mfile;
dm log 'clear';

%mend;


/*Frag 2 : Macro : Library definitions*/
%macro lib_in_i_out;

%do i=1 %to %sysfunc(countw(&input_path.,"||"));
      libname in&i. "%scan(&input_path.,&i.,"||")";
%end;
libname out "&output_path.";

%mend;


/*Frag 3 : Macro : Log and print*/
%macro print_log;

proc printto log="&output_path/merge_complete_Log.log";
  run;
  quit;
proc printto print="&output_path/merge_complete_Output.out";
  run;
  quit;

%mend;

/*Frag 4 : Macro : Sorting the input datasets by key variables and taking the name of the input datasets,
concatenating them together, so that they can be used in merge data step*/
%macro create_the_name_and_sort_for_sas;

/*Initialising a global macro variable <these_datasets>*/
%global these_datasets;

/*Creating the name and sorting*/
%do i=1 %to %sysfunc(countw(&input_path.,"||")); %let data= %scan(&dataset_name.,&i.);
      /*Concatenating the names of the input datasets together to use in SAS merge data step*/
      %let this_dataset = in&i..&data. (in = a&i.);
      %let these_datasets = &these_datasets. &this_dataset.;
      %put &these_datasets.;
      /*Sorting the dataset by the key_variables selected*/
      proc sort data=in&i..&data.;
            by &key_variables.;
            run;
%end;

%mend;


/*Frag 4a : Macro : Replace a1 by a2*/
%macro a1_by_a2;

/*Replace a1 by temp*/
data _null_;
      call symput("type_join",tranwrd("&type_join.","a1","temp"));
      run

/*Replace a2 by a1*/
data _null_;
      call symput("type_join",tranwrd("&type_join.","a2","a1"));
      run;

/*Replace temp by a2*/
data _null_;
      call symput("type_join",tranwrd("&type_join.","temp","a2"));
      run;

%put &type_join.;

%mend;


/*Frag 5 : Macro : Merge datasets using SAS*/
%macro merge_sas;

data &new_dataset. (keep = &final_variables. &key_variables.);
    merge &these_datasets.;
    by &key_variables.;
    if &type_join.;
    run;

%mend;


/*Frag 6 : Macro : Many-many outer join using SQL*/
%macro merge_sql_outer_join;

/*Determine if the merge is full outer join (or) left outer join (or) right outer join*/
%if %index(&type_join.,a1 or a2) > 0 %then %do;
      %let type=full;
%end;
%else %if %index(&type_join.,a2) > 0 %then %do;
      %let type=right;
%end;
%else %if %index(&type_join.,a1) > 0 %then %do;
      %let type=left;
%end;

/*Create the necessary statements for merging and merge the datasets two at a time*/

/*Initialising a variable <firstDatasetName> to be used in the do loop below*/ %let data= %scan(&dataset_name.,1);
%let firstDatasetName=in1.&data.;

%do i=1 %to (%sysfunc(countw(&input_path.,"||"))-1);
%let data= %scan(&dataset_name.,%eval(&i.+1));
      /*Creating the dataset names*/
      %let createDatasetName=temp&i.;
      %if (&i.+1) = %sysfunc(countw(&input_path.,"||")) %then %do;
            %let createDatasetName=&new_dataset.;
      %end;
      %let secondDatasetName=in%eval(&i.+1).&data.;
      /*Creating selectStatement & onStatement*/
      %let comma=,;
      %let and=and;
      %let selectStatement=;
      %let onStatement=;
      %do k=1 %to %sysfunc(countw(&key_variables.," "));
            %if (&k.+1) > %sysfunc(countw(&key_variables.," ")) %then %do;
                  %let comma=;
                  %let and=;
            %end;
            %let tempVar = %scan(&key_variables.,&k.," ");
            %let selectStatement = &selectStatement. coalesce(a1.&tempVar.,a2.&tempVar.) as &tempVar.&comma.;
            %let onStatement = &onStatement. (a1.&tempVar. = a2.&tempVar.) &and.;
      %end;
      %put &selectStatement.;
      %put &onStatement.;
      /*Merging the datasets now*/
      proc sql;
            create table &createDatasetName. as
            select &selectStatement., *
            from &firstDatasetName. a1
            &type. join &secondDatasetName. a2
            on &onStatement.;
            quit;
      /*The variable below will be used in the next iteration of the loop*/
      %let firstDatasetName=&createDatasetName.;
%end;

%mend;


/*Frag 7 : Macro : Many-many inner join using SQL*/
%macro merge_sql_inner_join;

/*Initialising two variables <fromDatasetName> and <whereStatement> to be used in the do loops below*/
%let fromDatasetName=;
%let whereStatement=;

/*Creating fromDatasetName*/
%let comma=,;
%do i=1 %to %sysfunc(countw(&input_path.,"||"));
	%let data= %scan(&dataset_name.,&i.);
	%if (&i.+1) > %sysfunc(countw(&input_path.,"||")) %then %do;
	    %let comma=;
	%end;
	%let fromDatasetName = &fromDatasetName. in&i..&data. a&i. &comma.;
%end;

/*Creating whereStatement*/
%let and=and;
%do k=1 %to %sysfunc(countw(&key_variables.," "));
      %if (&k.+1) > %sysfunc(countw(&key_variables.," ")) %then %do;
            %let and=;
      %end;

      %let equalTo==;
      %do i=1 %to %sysfunc(countw(&input_path.,"||"));
            %if (&i.+1) > %sysfunc(countw(&input_path.,"||")) %then %do;
                  %let equalTo=;
            %end;
            %let whereStatement = &whereStatement. a&i..%scan(&key_variables.,&k.," ") &equalTo.;
      %end;

      %let whereStatement = &whereStatement. &and.;
%end;

/*Merging the datasets now*/
proc sql;
      create table &new_dataset. as
      select *
      from &fromDatasetName.
      where (&whereStatement.);
      quit;

%mend;


/*Frag 8 : Macro : Get the common values from the input datasets*/
%macro get_the_common_values;

/*First inner join the datasets*/
%merge_sql_inner_join;

/*Creating temporary datasets with only the key variables*/
%do d=1 %to %sysfunc(countw(&input_path.,"||"));      %let data= %scan(&dataset_name.,&d.);
      data in&d._dataworking_key;
            set in&d..&data.(keep = &key_variables.);
            run;
%end;

/*Converting the key variables into character format*/
%do i=1 %to %sysfunc(countw(&key_variables.," "));
      %let vName=%scan(&key_variables.,&i.," ");
      data &new_dataset.;
            set &new_dataset.;
            char_%substr(&vName.,1,25) = put(&vName., 32.) ; 
            drop &vName.; 
            rename char_%substr(&vName.,1,25)=&vName.;
            run;

      %do d=1 %to %sysfunc(countw(&input_path.,"||"));
            data in&d._dataworking_key;
                  set in&d._dataworking_key;
                  char_%substr(&vName.,1,25) = put(&vName., 32.) ; 
                  drop &vName.; 
                  rename char_%substr(&vName.,1,25)=&vName.;
                  run;
      %end;
%end;

/*Creating a macro variable that can be used to concatenate all the key variables*/
%let tempKeyVariables = &key_variables.;
%if %sysfunc(countw(&key_variables.," ")) > 1 %then %do;
      data _null_;
            call symput("tempKeyVariables",tranwrd("&key_variables."," ","' || '"));
            run;
      %let tempKeyVariables="&tempKeyVariables.";
%end;

/*Get the unique value(s) of the key variables and their count from the inner joined dataset*/
proc sql;
      create table &new_dataset.count as
      select &tempKeyVariables.,count(&tempKeyVariables.)
      from &new_dataset.
      group by &tempKeyVariables.;
      quit;

/*Get the common unique values(and their count) between the input datasets and the inner joined dataset*/
%do d=1 %to %sysfunc(countw(&input_path.,"||"));
      %let DS=in&d._dataworking_key;
      proc sql;
            create table count&d. as
            select &tempKeyVariables.,count(&tempKeyVariables.) as count
            from &DS.
            where &tempKeyVariables. in 
                  (     select &tempKeyVariables.
                        from &new_dataset.count )
            group by &tempKeyVariables.;
            quit;
%end;

%mend;


/*Frag 9 : Macro : Check if the merge is many-many or not*/
%macro check_for_many_many;

/*Get the number of unique values common to all the input datasets(from the inner joined dataset)*/
proc sql;
      select count(*) into : nounique
      from &new_dataset.count;
      quit;

/*Initialising this variable for using inside the loop*/
%let manyorone=;

/*Get the total no.of times the above unique values appear in each input dataset*/
%do d=1 %to %sysfunc(countw(&input_path.,"||"));
      /*Get the total no.of times the above unique values appear in the d'th input dataset*/
      proc sql;
            select sum(count) into : totalnounique&d.
            from count&d.;
            quit;
      
      /*If there are 10 unique values and if they appear more than 10 times, then concatenate 'many' to the variable <manyorone>*/
      %if &&totalnounique&d.. > &nounique. %then %do;
            %let manyorone = &manyorone. many;
      %end;
      /*Else concatenate 'one' to the variable <manyorone>*/
      %else %do;
            %let manyorone = &manyorone. one;
      %end;
%end;

/*Initialising a global macro variable <manymany>*/
%global manymany;
/*If the word 'many' appears more than one time in the variable <manyorone> then <manymany> will be 'yes'*/
%if %sysfunc(count(&manyorone.,many))>1 %then %do;
      %let manymany=yes;
%end;
/*Else <manymany> will be 'no'*/
%else %do;
      %let manymany=no;
%end;

%mend;


/*Frag 10 : Macro : Write the merged dataset in the output path and the CSV and completed.txt*/
%macro write_dataset;

/* Checking number of observations in dataset   */
%let dset=&new_dataset.;
%let dsid = %sysfunc(open(&dset));
%let nobs =%sysfunc(attrn(&dsid,NOBS));
%let global_nobs = &nobs.;
%let rc = %sysfunc(close(&dsid));

%if &NOBS. =0 %then %do;
      data _null_;
            v1= " Merge not possible. Merge operation will result in a dataset with 0 observations.";
            file "&output_path./NO_OF_ROWS_IS_ZERO.txt";
            put v1;
            run;
%end;
%else %do;
      data out.&new_dataset. (keep = &final_variables. &key_variables.);
            set &new_dataset.;
            run;

      proc export data = out.&new_dataset.
            outfile = "&output_path./&new_dataset..csv"
            dbms = csv replace;
            run;

	  
		ods output members = properties(where=(lowcase(name)=lowcase("&new_dataset.")) keep=name obs vars FileSize);
		proc datasets details library = out;
			run; 
			quit ;

		/*libname prop xml "&output_path./dataset_properties.xml";*/
		data properties;
			set properties(rename =(name=file_name obs=no_of_obs vars=no_of_vars fileSize = file_size));
			format file_size 12.4;
			file_size = file_size/(1024*1024);
			run;

		/*CSV export*/
		 proc export data = properties
			outfile="&output_path/dataset_properties.csv"
			dbms=CSV replace;
			run;

     	 data _null_;
            v1= "MERGE_COMPLETED";
            file "&output_path./MERGE_COMPLETED.txt";
            put v1;
            run;
%end;

%mend;


/*Frag 11 : Macro : Rearrange the input datasets for SQL*/
%macro rearrange_input_path;

%let temp_input_path=;
%do tempi = 1 %to %sysfunc(countw(&input_path.,"||"));
	%if &tempi. = %sysfunc(countw(&input_path.,"||")) %then
		%do;
			%let temp_input_path=%scan(&input_path.,&tempi,"||")&temp_input_path.;
		%end;
	%else
		%do;
			%let temp_input_path=&temp_input_path.||%scan(&input_path.,&tempi,"||");
		%end;
%end;

%let input_path=&temp_input_path.;

%put Succesfully rearranged inputpath.;
%put &input_path.;

%mend;


/*Frag 12 : Macro : Rename the necessary variables and change the parameters*/
%macro rename_variables;
	%global input_path dataset_name final_variables key_variables;
	%let new_input_path=;
	%let new_input_path_separator=;
	%let new_dataset_name=;
	%let new_final_variables=;
	data _null_;
		call symput("sas_work_wo_quotes",tranwrd(&sasworklocation.,'"',''));
	run;

	%do tempi = 1 %to %sysfunc(countw(&input_path.,"||"));
		%let dsname = %scan(&dataset_name.,&tempi.," ");

		%let key_variable_i=;
		%do temp2i = 1 %to %sysfunc(countw(&key_variables.," "));
			%let current_key_variable=%scan(&key_variables.,&temp2i.," ");
			%if %sysfunc(countw(&current_key_variable.,"|")) > 1 %then
				%do;
					%let current_key_variable=%scan(&current_key_variable.,&tempi.,"|");
				%end;
			%let key_variable_i=&key_variable_i. &current_key_variable.;
		%end;

		%let current_all_variables = &&selected_vars&tempi.. &key_variable_i.;
		%let current_all_new_variables = &&new_selected_vars&tempi.. &new_key_variables.;
		
		%let forrename=;
		%do temp2i = 1 %to %sysfunc(countw(&current_all_variables.," "));
			%let forrename=&forrename. %scan(&current_all_variables.,&temp2i.," ") =  %scan(&current_all_new_variables.,&temp2i.," ");
		%end;

		%if &tempi. > 1 %then %let new_input_path_separator=||;
		%let new_input_path=&new_input_path.&new_input_path_separator.&sas_work_wo_quotes.;
		%let new_dataset_name=&new_dataset_name. muRx_merge_temp_&tempi.;
		%let new_final_variables=&new_final_variables. &&new_selected_vars&tempi..;

		data muRx_merge_temp_&tempi.(rename=(&forrename.));
			set in&tempi..&dsname.(keep = &current_all_variables.);
		run;

	%end;
	
	%let input_path=&new_input_path.;
	%let dataset_name=&new_dataset_name.;
	%let final_variables=&new_final_variables.;
	%let key_variables=&new_key_variables.;
%mend rename_variables;


/*Frag 13 : Calling all the macro(s)*/
%macro callit;
FILENAME MyFile "&output_path./NO_OF_ROWS_IS_ZERO.txt";
DATA _NULL_ ;
rc = FDELETE('MyFile') ;
RUN ;

%options;
%lib_in_i_out;
%rename_variables;
%lib_in_i_out;
/*%print_log;*/
%if %index(&type_join., not) > 0 %then %do;
      %a1_by_a2;
      %create_the_name_and_sort_for_sas;
      %merge_sas;
%end;
%else %do;
      %get_the_common_values;
      %check_for_many_many;
      %if &manymany. = no %then %do;
            %a1_by_a2;
            %create_the_name_and_sort_for_sas;
            %merge_sas;
      %end;
      %if &manymany. = yes %then %do;
            %rearrange_input_path;
            %lib_in_i_out;
            %if %index(&type_join., and) > 0 %then %do;
                  %merge_sql_inner_join;
            %end;
            %else %do;
                  %merge_sql_outer_join;
            %end;
      %end;
%end;

%if %sysfunc(exist(&new_dataset.)) %then %do;
      %write_dataset;
%end;
%mend;

%callit;