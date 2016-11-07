/*Parameters required*/
/*%let input_path=/data22/IDev/Mrx/what;*/
/*%let output_path=/data22/IDev/Mrx;*/


*processbody;
FILENAME MyFile "&output_path.\clear_cache.txt" ;

  DATA _NULL_ ;
    rc = FDELETE('MyFile') ;
  RUN ;

options mfile mlogic mprint symbolgen;
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
	%recursiveDelete(root_path=&input_path.,lev=5,rmFiles_lev0=Y);

/* flex uses this file to test if the code has finished running */
data _null_;
	v1= "workspace is cleared";
	file "&output_path./clear_cache.txt";
	put v1;
	run;
