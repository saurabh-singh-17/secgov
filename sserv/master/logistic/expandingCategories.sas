/*Successfully converted to SAS Server Format*/
*processbody;
%let completedTXTPath =  &output_path/EXPANDING_CATEGORIES_COMPLETED.txt;
options mprint mlogic symbolgen mfile ;


proc printto log="&output_path/ExpandingCategories_Log.log";
run;
quit;

/*proc printto print="&output_path/ExpandingCategories_Output.out";*/

libname in "&input_path.";
libname out "&output_path.";

FILENAME MyFile "&output_path/EXPANDING_CATEGORIES_COMPLETED.txt" ;

  DATA _NULL_ ;
    rc = FDELETE('MyFile') ;
  RUN ;
%MACRO expandingCategories;
	/*subset the predicted dataset*/
/*Modifies By : Anvita.srivastava*/
/*Bug # 7755*/
	%if "&grp_vars." ^= "" %then %do;		
		data _null_;
			call symput("grp_vars", compbl("&grp_vars."));
			run;
		%end;

		data pred;
			%if "&grp_vars." ^= "" %then %do;
				set in.pred (keep = _from_ phat &grp_vars.);
			%end;
			%if "&grp_vars." = "" %then %do;
				set in.pred (keep = _from_ phat);
			%end;
			run;

	/*create a macro-variable for sql step*/
	%if "&grp_vars." ^= "" %then %do;
		data _null_;
			call symput("cat_grp", tranwrd("&grp_vars.", " ", ",'_',"));
			run;
	
	/*cascading all the by-group variables into one variable*/
		data pred (drop=&grp_vars.);
			set pred;
			grp_var = cats(&cat_grp.);
			run;
	
	/*rank the dataset on predicted variable*/
		proc sort data = pred out = pred;
			by grp_var;
			run;
	%end;

	proc rank data = pred out = rank_pred Groups = %sysevalf(&num_grps.) descending ;
		var phat;
		ranks deciles;
		%if "&grp_vars." ^= "" %then %do;
			by grp_var;
		%end;
		run;


/*get average of predicted and total count for each level*/
	proc sql;
		create table count_total as
		select distinct 
		%if "&grp_vars." ^= "" %then %do;
			grp_var,
		%end;
		deciles, avg(phat)*100 as avg, count(_from_) as count from rank_pred
		group by 
		%if "&grp_vars." ^= "" %then %do;
			grp_var,
		%end;
			deciles;
		quit;

/*get the number of 1s in each level*/
	proc sql;
		create table count_1 as
		select distinct 
		%if "&grp_vars." ^= "" %then %do;
			grp_var, 
		%end;
		deciles, count(_from_) as count_1 from rank_pred where _from_ = "1"
		group by 
		%if "&grp_vars." ^= "" %then %do;
			grp_var,
		%end;
			deciles;
		quit;


/*merge the two intermediate datasets*/
	data out;
		merge count_total(in=a) count_1(in=b);
		by 
		%if "&grp_vars." ^= "" %then %do;
			grp_var 
		%end;
			deciles;
		if a or b;
		run;


/*calculate actual probability*/
	data out.output(drop=count count_1 rename=(avg=predicted));
		set out;
		if count_1 = . then count_1 = 0;
		actual = (count_1/count)*100;
		run;


/*sort the output by descending grp_vars*/
	%if "&grp_vars." ^= "" %then %do;
		proc sort data = out.output;
			by descending grp_var;
			run;
	%end;


/*CSV output*/
	proc export data = out.output
		outfile = "&output_path/predactual_Categories.csv"
		dbms = csv replace;
		run;

/*grp-vars XML*/
	%if "&grp_vars." ^= "" %then %do;
		libname xml xml "&output_path./grp_vars.xml";
		proc sql;
			create table xml.grp_vars as
			select distinct grp_var from out.output;
			run;
	%end;

%MEND expandingCategories;
%expandingCategories;



/* flex uses this file to test if the code has finished running */
data _null_;
	v1= "EDA - EXPANDING_CATEGORIES_COMPLETED";
	file "&output_path/EXPANDING_CATEGORIES_COMPLETED.txt";
	put v1;
run;

ENDSAS;




