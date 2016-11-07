/*Successfully converted to SAS Server Format*/
*processbody;
%let completedTXTPath =  &output_path/CATEGORICAL_VARIABLE_CREATION_COMPLETED.txt;
options mprint mlogic symbolgen mfile;

proc printto log="&output_path./Categorical_Variable_Creation_Log.log";
run;
quit;
/*	*/
/*proc printto print="&output_path./Categorical_Variable_Creation_Output.out";*/
	

dm log 'clear';
/*input & output paths*/
libname in "&input_path.";
libname out "&output_path.";
libname inxml xml "&input_xml.";

data _null_;
	call symputx("vars", cats("'", tranwrd(compbl(lowcase("&newvar_list."))," " ,"', '" ), "'"));
	run;
%put &vars;

%MACRO categoricalVarCreation;
%do j = 1 %to %sysfunc(countw(&newvar_list.));
	%let variable=%scan(&newvar_list, &j, " ");
	data levels;
		set inxml.&variable.;
		run;

	proc sql;
		select level into: specific_list separated by "!!"
		from levels;
		quit;

	%if "&bivariate."="true" %then %do;

		%do k=1 %to %sysfunc(countw("&specific_list.","!!"));

			data _null_;
                  call symput("bin", "%scan(%bquote(&specific_list.),&k., "!!")");
                  run;	

		      %let dsid = %sysfunc(open(in.dataworking));
		      %let varnum = %sysfunc(varnum(&dsid,&newvar_list.));
		      %let vartyp = %sysfunc(vartype(&dsid,&varnum.));
		      %let rc = %sysfunc(close(&dsid));

	     	 %if "&vartyp." = "N" %then %do;
/*			 	data _null_;*/
/*                  call symput("bin1",tranwrd(%quote("&bin"),"_","$"));*/
/*                  run;	*/

/*				%if %index(&bin.,$)>0 %then %do;*/
/*	                  data _null_;*/
/*	                        call symput("bin",cat(%scan(%quote(&bin.),1,'-'),' - ',%scan(%quote(&bin.),-1,'-')));*/
/*	                        run;  */
/*	                  %put &bin.;*/
/*	            %end;*/
				data _null_;
					call symputx("Between", tranwrd("&bin."," - " ," and " ));
					run;

	           proc sql;
					create table in.dataworking as
					select *,
					case
					%do m=1 %to %sysfunc(countw("&bin","#"));
						when &variable. between %scan("&between",&m,"#") then 1 
					%end;
						else 0
						end as &prefix._%sysfunc(translate(%substr(&between., 1, 11),"____",". -#"))_%substr(&variable., 1, 11)
					
					from in.dataworking;
					quit;
			 %end;
			 %else %do;
				data _null_;
                    call symput("bin2","&bin.");
                  	run;
			    data _null_;
                    call symput("bin",cat("'", tranwrd("&bin.", "#", "','"),"'"));
                  	run;



				data in.dataworking;
	                  length &newvar_list. $50.;
	                  set in.dataworking;
	                        if strip(&variable.) in (&bin.) then &prefix._%sysfunc(translate(%substr(&bin2., 1, 11),'_______________________________',"~@#$%^&*()_+{}|:<>?`-=[]/,./; '"))_%substr(&variable., 1, 11)=1 ;
							else &prefix._%sysfunc(translate(%substr(&bin2., 1, 11),'_______________________________',"~@#$%^&*()_+{}|:<>?`-=[]/,./; '"))_%substr(&variable., 1, 11)=0;
	                  run;
			 %end;
		%end;
	%end;
	%else %do;
	
		data in.dataworking;
			set in.dataworking;
			%do k=1 %to %sysfunc(countw("&specific_list.","!!"));
				if &variable. = "%scan(&specific_list, &k, "!!")" then do;
					&prefix._%sysfunc(translate(%substr(%scan(&specific_list, &k, "!!"), 1, 11),'_______________________________',"~@#$%^&*()_+{}|:<>?`-=[]/,./; '"))_%substr(&variable., 1, 11) = 1;
				end;
				else do;
					&prefix._%sysfunc(translate(%substr(%scan(&specific_list, &k, "!!"), 1, 11),'_______________________________',"~@#$%^&*()_+{}|:<>?`-=[]/,./; '"))_%substr(&variable., 1, 11) = 0;
				end;
			%end;
			run;
	%end;
%end;
%MEND categoricalVarCreation;
%categoricalVarCreation;


/*subset for viewpane*/
data out.temp;
	set in.dataworking (keep = &newvar_list. &prefix._: );
	run;

%macro rows_restriction3;
	%let dsid = %sysfunc(open(out.temp));
		%let nobs=%sysfunc(attrn(&dsid,nobs));	
		%let rc = %sysfunc(close(&dsid));
	%put &nobs.;

	%if &nobs.>6000 %then %do;
	proc surveyselect data=out.temp out=out.temp method=SRS
		  sampsize=6000 SEED=1234567;
		  run;
	%end;
%mend rows_restriction3;
%rows_restriction3;

/*CSV output for viewpane population*/
proc export data = out.temp
	outfile = "&output_path/categoricalVariableCreation_subsetViewpane.csv"
	dbms = csv replace;
	run;


/*get contents for XML creation*/
proc contents data = out.temp out = contents_temp(keep = name);
	run;

proc sql;
	create table newvar as
	select name as new_varname from contents_temp
	where lowcase(name) not in (&vars.);
	quit;

/*create XML for new varnames*/
libname newvar xml "&output_path./categoricalVariableCreation_new_varname.xml";
data newvar.new_varname;
	set newvar;
	run;
%include %unquote(%str(%'&genericCode_path./datasetprop_update.sas%'));
/* flex uses this file to test if the code has finished running */
data _null_;
	v1= "CATEGORICAL_VARIABLE_CREATION_COMPLETED";
	file "&output_path/CATEGORICAL_VARIABLE_CREATION_COMPLETED.txt";
	put v1;
	run;

/*ENDSAS;*/


