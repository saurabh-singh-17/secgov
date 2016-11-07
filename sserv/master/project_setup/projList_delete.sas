*processbody;

options mprint mlogic symbolgen;

/*extract the project list*/
proc printto log="& ./ProjectList_delete.log";
run;
quit;
%let project_name=;
data project;
	infile "&input_path./project.csv"  MISSOVER DSD lrecl=32767 firstobs=2;

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

	data project;
		set project;
		if projectName = "&projectName." then delete;
		run;

%macro DirExist(dir) ; 

   %global rc fileref return; 
   %let rc = %sysfunc(filename(fileref,&dir)) ; 
   %if %sysfunc(fexist(&fileref)) %then %do; 
	%let return=1; 
	%end;   
   %else %do;
	%let return=0;
	%end;
	%put &return.;
%mend DirExist;
%DirExist(&project_path./univariateAnalysis);
%put &return.;





    %macro recursiveDelete(root_path=_none_,lev=0,rmFiles_lev0=Y);
 
        %local rc root_path root_ID root_FN fname_path fname_ID fname_FN ifile nfile;
 
        %if %bquote(&root_path) = _NONE_ %then
            %return;
		
 
        %put Recursion level &lev;
        %put root_path = &root_path;
 
        /* Open root directory */
        %let rc = %sysfunc(filename(root_FN,&root_path));
        %if &rc ^= 0 %then %do;
            %put %sysfunc(sysmsg());
            %return;
        %end;
        %put root_FN = &root_FN;
        %let root_ID = %sysfunc(dopen(&root_FN));
 
 
        /* Get a list of all files in root directory */
        %let nfile = %sysfunc(dnum(&root_ID));
        %do ifile = 1 %to &nfile;
 
            /* Read pathname of file */
            %local fname_path_&ifile;
            %let fname_path_&ifile = %sysfunc(dread(&root_ID,&ifile));
 
            /* Set fileref */
            %local fname_FN_&ifile;
            %let rc = %sysfunc(filename(fname_FN_&ifile,&root_path/&&fname_path_&ifile));
            %if &rc ^= 0 %then %do;
                %put %sysfunc(sysmsg());
                %return;
            %end;
 
        %end;
 
        /* Loop over all files in directory */
        %do ifile = 1 %to &nfile;
 
            /* Test to see if it is a directory */
            %let fname_ID = %sysfunc(dopen(&&fname_FN_&ifile));
            %if &fname_ID ^= 0 %then %do;
 
                %put &root_path/&&fname_path_&ifile is a directory;
 
                /* Close test */
                %let close = %sysfunc(dclose(&fname_ID));
 
                /* Close root path */
                %let close_root = %sysfunc(dclose(&root_ID));
 
                /* Remove files in this directory */
                %recursiveDelete(root_path=&root_path/&&fname_path_&ifile,lev=%eval(&lev+1));
                %put Returning to recursion level &lev;
 
                /* Remove directory */
                %put Deleting directory &root_path/&&fname_path_&ifile;
                %let rc = %sysfunc(fdelete(&&fname_FN_&ifile));
                %put %sysfunc(sysmsg());
 
                /* Reopen root path */
                %let root_ID = %sysfunc(dopen(&root_FN));
 
            %end;
            %else %if &rmFiles_lev0 = Y or &lev > 0 %then %do;
                %put Deleting file &root_path/&&fname_path_&ifile;
                %let rc = %sysfunc(fdelete(&&fname_FN_&ifile));
                %put %sysfunc(sysmsg());
            %end;
 
        %end;
 
    %mend recursiveDelete;
%macro ckeck_complete;
%let last_word = %scan(&project_path.,-1,"/");
%if "&last_word."="&projectName." %then %do;
	%If &return. = 1 %then %do;
	%recursiveDelete(root_path=&project_path.,lev=20,rmFiles_lev0=Y);
	%end;
%end;
	%mend ckeck_complete;
	%ckeck_complete;
	
	filename testdir "&project_path.";
	data _null_;
	rc=fdelete('testdir');
	put rc=;
	msg=sysmsg();
	put msg=;
	run;

	/*export the list*/
	proc export data = project
		outfile = "&input_path./project.csv"
		dbms = csv replace;
		run;