/*Successfully converted to SAS Server Format*/
*processbody;
options mlogic mprint symbolgen;

proc printto log="&output_path./verify.log" new;
run;
quit;

filename myfile1 "&output_path./ERROR.txt";
filename myfile2 "&output_path./VERIFY_COMPLETED.txt";
filename myfile3 "&output_path./verification.csv";

data _null_;
	rc = fdelete('myfile1');
	rc = fdelete('myfile2');
	rc = fdelete('myfile3');
run;

proc datasets library = work kill nolist;
run;
quit;

/* key variable count*/
/*dataset count*/
%let key_variables = %sysfunc(compbl(&key_variables.));
%let var_count=%sysfunc(countw(&key_variables));
%let data_count=%sysfunc(countw(&datasets));

data _null_;
	call symput("key_sql",tranwrd("&key_variables.","  "," "));
run;

data _null_;
	call symput("key_sql",tranwrd("&key_variables."," ",","));
run;

%macro merge_verify;

	libname in1 "%scan(&input_path., 1, ||)";

	proc contents data=in1.dataworking(keep=&key_variables.) out=murx_contents(keep=name type rename=(type=type1));
	run;
	quit;

	%do i = 2 %to &data_count;
		libname in&i. "%scan(&input_path., &i., ||)";

		proc contents data=in&i..dataworking(keep=&key_variables.) out=murx_temp(keep=name type rename=(type=type&i.));
		run;
		quit;

		proc sql;
			create table murx_contents as
				select *
					from murx_contents a1
						inner join murx_temp a2
							on a1.name = a2.name;
		run;
		quit;
	%end;

	%let b_type_mismatch              = 0;
	data murx_contents;
		set murx_contents;
		array num[*] _numeric_;
		if(min(of num[*]) ^= max(of num[*])) then
			call symput("b_type_mismatch", 1);
	run;

	%if &b_type_mismatch. = 1 %then
		%do;
			data csv;
				Merge_Possible="No";
				type="NA";
			run;

			proc export data = CSV
				outfile = "&output_path./verification.csv"
				dbms = csv replace;
			run;

			data _null_;
				v1= "VERIFY_COMPLETED";
				file "&output_path/VERIFY_COMPLETED.txt";
				put v1;
			run;

			endsas;
		%end;

	data csv;
		Merge_Possible="Yes";
	run;

	%if &data_count. = 2 and %index(&type_join., not) = 0 %then
		%do;
			%do i= 1 %to 2;

				/*creating temp dataset with only key variables to find the relationship*/
				data temp&i.(keep= &key_variables. );
					set in&i..%scan(&datasets.,&i.,||);
				run;

				/*creating common column with concatenated key variables*/
				data temp&i.(keep=common);
					set temp&i.;
					common = catx("-",&key_sql.);
				run;

				proc sort data=temp&i. out=temp&i.;
					by common;
				run;

			%end;

			/*merging both the datasets with common columns to find unique elements in both*/
			data common;
				merge temp1(in=a) temp2(in=b);
				by common;

				if a and b;
			run;

			proc sort data=common nodupkey out=common;
				by common;
			quit;

			%do i= 1 %to 2;

				proc sql;
					create table final&i. as
						select a.common from temp&i. as a, common as b
							where a.common contains b.common;
				quit;

				proc sql;
					select count(*) into :unique&i. from (select distinct common from final&i.);
				quit;

				proc sql;
					select count(*) into :total&i. from (select common from final&i.);
				quit;

				%if ("&&unique&i."<"&&total&i.") %then
					%do;
						%let type&i.=many;
					%end;
				%else
					%do;
						%let type&i.=one;
					%end;
			%end;

			data _null_;
				call symput("temp",cat("&type2."," to ","&type1."));
			run;

			data csv;
				set csv;
				format type $15.;
				type="&temp";
			run;

		%end;
	%else
		%do;

			data csv;
				set csv;
				type="NA";
			run;

		%end;

	proc export data = CSV
		outfile = "&output_path./verification.csv"
		dbms = csv replace;
	run;

	data _null_;
		v1= "VERIFY_COMPLETED";
		file "&output_path/VERIFY_COMPLETED.txt";
		put v1;
	run;

%mend merge_verify;

%merge_verify;
;