
options mprint mlogic symbolgen;

proc printto log = "/data10/IDev/Mrx/fetch_fileList_log.log";

libname test "/data10/IDev/Mrx";

filename indata pipe 'ls -l /data10/IDev/Mrx';

data test.one;
	length ftr $88;
	infile indata truncover;
	input ftr $88.;
	run;


filename indata pipe 'ls /data10/IDev/Mrx/* > v7test.files';

data test.two;
	length ftr $88;
	infile indata truncover;
	input ftr $88.;
	run;


filename indata pipe 'ls -1 /data10/IDev/Mrx/* > v7test.files';

data test.three;
	length pftr $100;
	infile "/data10/IDev/Mrx/v7test.files" truncover;
	input ftr $88.;
	pftr = "/data10/IDev/Mrx/"||ftr;
	infile dummy filevar=pftr truncover end=done;
	do while(not done);
	output;
	end;
	run;
