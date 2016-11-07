/*Successfully converted to SAS Server Format*/
*processbody;
%let completedTXTPath =  &output_path/MOVING_AVERAGE_COMPLETED.txt;
/* VERSION 2.2 */

options mprint mlogic symbolgen mfile ;

proc printto log="&output_path./Moving_Average_Log.log";
run;
quit;
/*proc printto print="&output_path./Moving_Average_Output.out";*/

libname in "&input_path.";
libname out "&output_path.";


%MACRO movingAvg;

	%let i=1;
	%do %until (not %length(%scan(&var_list,&i)));

		data _null_;
			set in.dataworking;
			%if "&i." = "1" %then %do;
				%if %length(%scan(&var_list,&i)) < 27 %then %do;
					call symputx("new_list", "&prefix.%scan(&var_list,&i)");
				%end;
				%if %length(%scan(&var_list,&i)) >= 27 %then %do;
					call symputx("new_list", &prefix.substr("%scan(&var_list,&i)",1,27));
				%end;
			%end;
			%else %do;
				%if %length(%scan(&var_list,&i)) < 27 %then %do;
					call symput("new_list", catx(" ", "&new_list.", "&prefix.%scan(&var_list,&i)"));
				%end;
				%if %length(%scan(&var_list,&i)) >= 27 %then %do;
					call symput("new_list", catx(" ", "&new_list.", &prefix.substr("%scan(&var_list,&i)",1,27)));
				%end;
			%end;
			run;
		%let i=%eval(&i+1);	
	%end;

	%let l =1;
	%do %until (not %length(%scan(&var_list, &l)));
		data _null_;
			set in.dataworking;
			call symput("var_name", "%scan(&var_list, &l)");
			run;
			
		%if "&avg_type." = "backward" or "&avg_type." = "mid" %then %do;
			%if "&avg_type." = "backward" %then %do;
				%let z=%eval(&num.);
			%end;
			%if "&avg_type." = "mid" %then %do;
				%let z=%eval((&num.+1)/2);
			%end;

			%let j =1;
			%do %until (%eval(&j.) = %eval(&z.));
				%if "&j." = "1" %then %do;
					data temp;
						set in.dataworking (keep = primary_key_1644 &var_name.);
						L_&var_name&j. = lag&j.(&var_name.);
						call symput("L_vars", "L_&var_name&j.");
						run;
				%end;
				%else %do;
					data temp;
						set temp;
						L_&var_name&j. = lag&j.(&var_name.);
						call symputx("L_vars", cats("&L_vars.", ", ", "L_&var_name&j."));
						run;
				%end;
				run;
				%let j=%eval(&j.+1);
			%end;
		%end;

		
		%if "&avg_type." = "forward" or "&avg_type." = "mid" %then %do;
			%if "&avg_type." = "forward" %then %do;
				%let j =1;
			%end;
			%if "&avg_type." = "mid" %then %do;
				%let j =%eval((&num.+1)/2);
			%end;
			%let obs=1;
			%do %until (%eval(&j.) = %eval(&num.));
				%if "&j." = "1" %then %do;
					data temp;
						merge in.dataworking(keep=primary_key_1644 &var_name.) in.dataworking(keep=&var_name. rename=(&var_name=L_&var_name&j.) firstobs=%eval(&obs.+1));
						run;
					data _null_;
						call symput("L_vars", "L_&var_name&j.");
						run;
				%end;
				%else %do;
					data temp;
						merge temp in.dataworking(keep=&var_name. rename=(&var_name=L_&var_name&j.) firstobs=%eval(&obs.+1)); 
						run;
					data _null_;
						call symput("L_vars", cats("&L_vars.", ", ", "L_&var_name&j."));
						run;
				%end;
				%let obs = %eval(&obs.+1);
				%let j=%eval(&j.+1);
			%end;
		%end;


		proc sql;
			create table temp&l. as 
			select primary_key_1644, &var_name., &L_vars.,
			%if "&avg_type." = "forward" or "&avg_type." = "backward" %then %do;
				case when L_&var_name%eval(&j.-1) ^= . then sum(&var_name, &L_vars.)/&num. end as &prefix.&var_name.
			%end;
			%if "&avg_type." = "mid" %then %do;
				case when L_&var_name%eval(&j.-1) ^= . and L_&var_name%eval(&z.-1) ^= . then sum(&var_name, &L_vars.)/&num. end as &prefix.&var_name.
			%end;
			from temp;
			quit;

		%if "&l." = "1" %then %do;
			data temp_final;
				set temp&l.(keep=primary_key_1644 &var_name. &prefix.&var_name.);
				run;
		%end;
		%else %do;
			proc sort data = temp_final;
				by primary_key_1644;
				run;

			data temp_final;
				merge temp_final(in=a) temp&l.(in=b keep=primary_key_1644 &var_name. &prefix.&var_name.);
				by primary_key_1644;
				if a or b;
				run;
		%end; 


		%let l=%eval(&l.+1);
	%end;

	proc sort data = temp_final;
		by primary_key_1644;
		run;

	data in.dataworking;
		merge temp_final(in=a) in.dataworking(in=b drop=&var_list.);
		by primary_key_1644;
		if a or b;
		run;

	/*create dataset containing all new varnames*/
	%let k = 1;
	%do %until (not %length(%scan(&new_list, &k)));
		data newvar_temp;
			length new_varname $32;
			new_varname = "%scan(&new_list, &k)";
			run;

		%if "&k." = "1" %then %do;
			data newvar;
				set newvar_temp;
				run;
		%end;
		%else %do;
			data newvar;
				set newvar newvar_temp;
				run;
		%end;
		%let k = %eval(&k.+1);
	%end;


%MEND movingAvg;
%movingAvg;

data temp_final;
	set temp_final (drop = primary_key_1644);
	run;

/*CSV output for view-pane*/
proc export data = temp_final
	outfile = "&output_path./movingAvg_subsetViewpane.csv"
	dbms = CSV replace;
	run;


/*create XML for new varnames*/
libname newvar xml "&output_path./movingAvg_new_varname.xml";
data newvar.new_varname;
	set newvar;
	run;


/*delete the unrequired datasets*/
proc datasets library = out;
	delete temp;
	run;

%include %unquote(%str(%'&genericCode_path./datasetprop_update.sas%'));
/* flex uses this file to test if the code has finished running */
data _null_;
	v1= "MOVING_AVERAGE_COMPLETED";
	file "&output_path/MOVING_AVERAGE_COMPLETED.txt";
	put v1;
	run;

ENDSAS;







