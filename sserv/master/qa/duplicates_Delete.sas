options mprint mlogic symbolgen;

/*%let inputPath=*/
/*	%let outputPath=*/
/*	%let datasetName=*/
/*	%let scenarioName=;*/
/*%let datasetOption=;*/
/*%let inputPath= /temp2/produser/datasets;*/
%macro create_existing;
	libname in "&inputPath.";
	libname out "&outputPath.";

	%if "&datasetOption." = "CREATE" %then
		%do;

			data out.&datasetName.(keep=&datasetVar.);
				set in.dataworking;

				if murx_&scenarioName.=1 then
					output;
			run;

			proc export data=out.&datasetName. outfile="&outputPath./&datasetName..csv" dbms=CSV replace;
			run;

			quit;

			data _null_;
				v1= "Completed";
				file "&outputPath/DUPLICATE_CREATED_COMPLETED.TXT";
				put v1;
			run;

		%end;

	%if "&datasetOption." = "EXISTING" %then
		%do;

			data in.dataworking;
				set in.dataworking;

				if murx_&scenarioName.=1 then
					output;
			run;

			data in.dataworking;
				set in.dataworking;
				primary_key_1644 = _n_;
			run;

			ods output members = properties(where=(lowcase(name)=lowcase("dataworking")) keep=name obs vars FileSize);
			ods trace on;

			proc datasets details library =in;
			run;

			quit;

			ods trace off;

			data properties;
				set properties(rename =(name=file_name obs=no_of_obs vars=no_of_vars fileSize = file_size));
				format file_size 12.4;
				file_size = file_size;
			run;

			/*CSV export*/
			proc export data = properties
				outfile="&inputPath./dataset_properties.csv"
				dbms=CSV replace;
			run;

			proc export data=in.dataworking outfile="&inputPath./dataworking.csv" dbms=CSV replace;
			run;

			quit;

			data _null_;
				v1= "Completed";
				file "&inputPath./DUPLICATE_EXISTING_COMPLETED.TXT";
				put v1;
			run;

		%end;
%mend create_existing;

%create_existing;
;
;