/*Successfully converted to SAS Server Format*/
*processbody;
/* 

	Simple macro for exporting to CSV.
	Arguments required: 
		library name (pass "work" if applicable)
		dataset name
		filename to be exported (without extension)

*/

%macro exportCsv(libname=,dataset=,filename=);
	proc export data=&libname..&dataset.
    outfile="&outputPath./&filename..csv"
    dbms=csv replace;
    run;
%mend;