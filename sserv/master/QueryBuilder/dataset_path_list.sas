/* Data set dirs_found starts out with the names of the root folders */
/* you want to analyze. After the second data step has finished, it */
/* will contain the names of all the directories that were found. */
/* The first root name must contain a slash or backslash. */
/* Make sure all directories exist and are readable. Use complete */
/* path names. */
/*%let output_path=/data22/IDev/Mrx/SasCodes/G8/eda;*/
*processbody;
options mprint mfile symbolgen mlogic;
proc printto log="&output_path./datasetlist.log";
run;
quit;

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

/*data files_found1;*/
/*	set files_found;*/
/*	lenroot=index("*/
	
data files_found(drop=filename filetype path);
	format newpath $ 300.;
	set files_found;
	newpath=cat(strip(path),"/",strip(filename));
	run;
data files_found;
	set files_found;
	newpath=tranwrd(newpath,"//","/");
	rename newpath=path;
	run;
data files_found;
		set files_found;
		if index(path,".sas7bdat") > 0  then output;
		run;
/*proc export data =  dirs_found*/
/*	outfile = "&output_path./dirs_found.csv"*/
/*	dbms = CSV replace;*/
/*	run;*/
proc export data =  files_found
	outfile = "&output_path./files_found.csv"
	dbms = CSV replace;
	run;

	data _null_;
	      v1= "DATASET_LIST_COMPLETED";
	      file "&output_path/DATASET_LIST_COMPLETED.txt";
	      put v1;
	      run;
