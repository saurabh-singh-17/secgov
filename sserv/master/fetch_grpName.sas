*processbody;


options mprint mlogic symbolgen;

proc printto log="&output_path./grpName_log.log";


data _null_;
	call symput("command", "'id -gn &user_name.'");
	run;
%put &command;
	

filename grp pipe &command.;
data grpName;
	infile grp;
	length group_name $30.;
	input group_name $;
	run;



libname inx xml "&input_path./group_info.xml";
data grpInfo;
	set inx.grpInfo;
	run;


data grpName;
	merge grpName(in=a) grpInfo(in=b drop=name);
	by group_name;
	if a;
	run;

proc export data = grpName
	outfile = "&output_path./user_group.csv"
	dbms = csv replace;
	run;


/*data _NULL_;*/
/*	v1= "FETCHED_GRPNAME";*/
/*    file "&output_path./completed.txt";*/
/*    put v1;*/
/*    run;*/
