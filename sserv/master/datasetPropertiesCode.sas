*processbody;
options mprint mlogic symbolgen;
proc printto log="&output_path/dataset_prop_output.log";
	run;
libname in "&input_path.";
libname out "&output_path.";
ods output Attributes=out.mmbr_details;

proc contents data= in.&dataset_name ;
	run;
	quit;
proc transpose data=in.mmbr_details out=out.details;
	id label2;
	var cvalue2;
	run;
	quit;

data out.details(keep=Name Variables Observations Observation_Length);
	set out.details;
	Name="&dataset_name.";
	run;

proc export data = out.details
	outfile = "&output_path/dataset_properties.csv"
	dbms = csv replace;
	run;
