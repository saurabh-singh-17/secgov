*processbody;
options mlogic mfile symbolgen;

proc printto log="&outputpath./export_dataset.log";
run;
quit;

filename myfile "&outputpath./export_dataset_completed.txt";

data _null_;
	rc = fdelete("myfile");
run;

%macro exportdataset(inputpath,
					 outputpath,
					 indata,
					 outdata,
					 keep);

filename myfile "&outputpath./export_dataset_completed.txt";

data _null_;
	rc = fdelete('myfile');
run;

libname in "&inputPath.";
libname out "&outputpath.";

data out.&outdata.;
	set in.&indata.(keep = &keep.);
run;

data _null_;
	v1 = "Export dataset completed";
	file "&outputpath./export_dataset_completed.txt";
	put v1;
run;

%mend exportdataset;

%exportdataset(inputpath=&inputPath.,
					 outputpath=&outputpath.,
					 indata=dataworking,
					 outdata=&newdatasetname.,
					 keep=&variables.);