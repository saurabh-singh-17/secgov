*processbody;

options mprint mlogic symbolgen;

%macro upProj;

/*extract the project list*/
	data project;
		infile "&input_path./project.csv" delimiter = ',' MISSOVER DSD lrecl=32767 firstobs=2;
		informat projectId best32.;
        informat projectName $50.;
       	informat userName $30.;
        informat userAccount $30.;

		format projectId best12.;
        format projectName $50.;
        format userName $30.;
        format userAccount $30.;

		input
			projectId
	        projectName $
	        userName $
	        userAccount $
       		;
		run;
		quit;



	proc sql;
		select max(projectId) into :nobss from project;
		quit;
	%put &nobss;

	%if &nobss. = . %then %do;
		%let nobss = 0;
	%end;

	data useless;
		set project;
		if projectName = "&projectName." and userName = "&userName." and userAccount = "&userAccount." ;
		run;

/*get the number of observations in the list*/
		%let dset=useless;
		%let dsid = %sysfunc(open(&dset));
		%let nobs =%sysfunc(attrn(&dsid,NOBS));
		%let rc = %sysfunc(close(&dsid));
	%put &nobs;

	%If &nobs.> 0 %then %do;
	data _null_;
			set useless;
			call symput("projectId",projectId);
			run;
	%end;
	%else %do;
		%let projectId = %eval(&nobss.+1);
	%end;
   

/*put the info for current project*/
	data this_proj;	
		projectName = "&projectName.";
		userName = "&userName.";
		userAccount = "&userAccount.";
		projectId = &projectId.;
		run;


/*append this proj. to the list*/
	data project;
		set project this_proj;
		run;

		
/*Removing Duplicates*/
Proc SQL ;
	create table project as 
		select  distinct *
		from project;
	quit;
run;


/*export the list*/
	proc export data = project
		outfile = "&input_path./project.csv"
		dbms = csv replace;
		run;

%mend upProj;
%upProj;

proc datasets lib=work kill nolist;
quit;

