/*%let input_path = /data22/IDev/Mrx/projects/PGD_anvita_ZipCheck-18-Feb-2014-11-12-26/2/0/1_1_1/logistic/1/4;*/

/*	Description		: Zipping of the complete folder structure */
/*	Created Date	: 20FEB2014*/
/*	Author(s)		: Anvita Srivastava*/

options mprint mfile symbolgen mlogic;
proc printto log="&input_path./folderZipping.log";
run;
quit;

FILENAME MyFile "&input_path./zipped.zip";

DATA _NULL_;
	rc = FDELETE('MyFile');
RUN;

data dirs_found (compress=no);
	length Root $120.;
	root = "&input_path.";
	output;
	run;


data
	dirs_found /* Updated list of directories searched */
	files_found (compress=no); /* Names of files found. */
	keep Path FileName FileType;
	length fref $8 Filename $120 FileType $16;
	/* Read the name of a directory to search. */
	modify dirs_found;
	/* Make a copy of the name, because we might reset root. */
	Path = root;
	/* For the use and meaning of the FILENAME, DOPEN, DREAD, MOPEN, and */
	/* DCLOSE functions, see the SAS OnlineDocs. */
	rc = filename(fref, path);
	if rc = 0 then do;
		did = dopen(fref);
		rc = filename(fref);
	end;
	else do;
		length msg $200.;
		msg = sysmsg();
		putlog msg=;
		did = .;
	end;
	if did <= 0 then do;
		putlog 'ERR' 'OR: Unable to open ' Path=;
		return;
		end;
		dnum = dnum(did);
	do i = 1 to dnum;	
	filename = dread(did, i);
	fid = mopen(did, filename);
/* It's not explicitly documented, but the SAS online */
/* examples show that a return value of 0 from mopen */
/* means a directory name, and anything else means */
/* a file name. */
	if fid > 0 then do;
/* FileType is everything after the last dot. If */
/* no dot, then no extension. */
		FileType = prxchange('s/.*\.{1,1}(.*)/$1/', 1, filename);
		if filename = filetype then filetype = ' ';
		output files_found;
	end;
	else do;
/* A directory name was found; calculate the complete */
/* path, and add it to the dirs_found data set, */
/* where it will be read in the next iteration of this */
/* data step. */
	root = catt(path, "/", filename);
	output dirs_found;
	end;
	end;
	rc = dclose(did);
	run;

data files_found;
		set files_found;
		if index(filetype,"sas7bdat") > 0 or index(filetype,"sas") > 0 or index(filetype,"log") > 0  then delete;
		run;


%macro Zipping;

	data files_found;
		set files_found;
		folder_path = tranwrd(path,"&input_path.","");
		run;

	data files_found;
		set files_found;
		if folder_path= "" then folder_path="&input_path.";
		run;

	proc sql;
		select folder_path into:folder_path_name separated by " " from files_found;
		run;

	proc sql;
		select filename into:file_name separated by " " from files_found;
		run;

	proc sql;
		select path into:file_path_name separated by " " from files_found;
		run;

	ods package(zipped) open nopf;
		%do i = 1 %to %sysfunc(countw("&folder_path_name."," "));
		%let path_name = %qscan("&folder_path_name.",&i.," ");
		%let csv_name = %qscan("&file_name.",&i.," ");
		%let csvFilePath_name = %qscan("&file_path_name.",&i.," ");
			ods package(zipped) 
			%if "&path_name." ^= "&input_path." %then %do;
			    add file="&csvFilePath_name./&csv_name."
				path = "&path_name.";
				%end;
			%else %do;
				add file="&csvFilePath_name./&csv_name.";
				%end;
		%end;
		ods package(zipped) 
		    publish archive        
		       properties
		      (archive_name=  
		                  "zipped.zip"                  
		       archive_path="&input_path.");
		ods package(zipped) close;

			/* flex uses this file to test if the code has finished running */
		data _null_;
			v1 = "ZIPPING COMPLETED";
			file "&input_path./ZIPPING_COMPLETED.TXT";
			put v1;
		run;
%mend;
%Zipping;