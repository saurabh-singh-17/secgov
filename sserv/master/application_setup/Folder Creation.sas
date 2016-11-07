*processbody;
options mprint mlogic symbolgen mfile;

%let completedTXTPath = &output_path/FolderCreation_Log.log;

proc printto log="&output_path/FolderCreation_Log.log";


libname in "&input_path.";
libname out "&output_path.";


%MACRO folderCreation;
	%if "&END_GRP." = "0" %then %do;
		data out.byvarworking0;
			flag = "1_1_1";
			run; 

		libname obyvar0 xml "&output_path./0/byvar.xml";
		data obyvar0.byvar;
			set out.byvarworking0;
			run;

		data in.dataworking;
			set in.&dataset_name;
			group0_flag = "1_1_1";
			run;
	%end;

	%if "&END_GRP." ^= "0" %then %do;
		%do i = &START_GRP. %to &END_GRP.;
			proc sort data = in.&dataset_name.(keep=&&GRP&i.) out = uniq_key&i. nodupkey;
				by &&GRP&i.;
				run;

			%let j = 1;
			%do %until (not %length(%scan(&&GRP&i.,&j)));

				%let j = %eval(&j.+1);
			%end;

			proc sql;
				create table uniq_keys&i. as
				select * from uniq_key&i.
				where %scan(&&GRP&i.,1) is not missing
				%if "&j." >= "3" %then %do;
					and %scan(&&GRP&i.,2) is not missing
				%end;
				%if "&j." >= "4" %then %do;
					and %scan(&&GRP&i.,3) is not missing
				%end;
				;
				quit;

				
			data uniq_keys&i.;
				retain &&GRP&i.;
				length grp&i._flag $20.;
				set uniq_keys&i.;
				by &&GRP&i.;
				%if "&j." = "4" %then %do; 
					retain ind1 ind2 ind3 0;
					ind1 = ind1;
					ind2 = ind2;
					ind3 = ind3;
					if first.%scan(&&GRP&i.,3) then do;
						ind3=ind3+1;
					end;
					if first.%scan(&&GRP&i.,2) then do;
						ind2 = ind2+1;
						ind3=1;
					end;
					if first.%scan(&&GRP&i.,1) then do;
						ind1 = ind1+1;
						ind2 = 1;
						ind3=1;
					end;
					grp&i._flag = cats(ind1, "_", ind2, "_", ind3);
					drop ind1 ind2 ind3;
				%end;
				%if "&j." = "3" %then %do; 
					retain ind1 ind2 0;
					ind1 = ind1;
					ind2 = ind2;
					if first.%scan(&&GRP&i.,2) then do;
						ind2=ind2+1;
					end;
					if first.%scan(&&GRP&i.,1) then do;
						ind1 = ind1+1;
						ind2=1;
					end;
					grp&i._flag = cats(ind1, "_", ind2, "_1");
					drop ind1 ind2;
				%end;
				%if "&j." = "2" %then %do; 
					retain ind1 0;
					ind1 = ind1;
					if first.%scan(&&GRP&i.,1) then do;
						ind1=ind1+1;
					end;
					grp&i._flag = cats(ind1, "_1_1");
					drop ind1;
				%end;
				run;

			proc sort data = in.dataworking;
				by &&GRP&i.;
				run;

			data in.dataworking;
				merge in.dataworking(in=a) uniq_keys&i.(in=b);
				by &&GRP&i.;
				if a or b;
				run;

			/*		proc sql;*/
			/*			create table in.dataworking as*/
			/*			select **/
			/*			from in.dataworking as A, uniq_keys&i. as B*/
			/*			where*/
			/*			%if "&j." = "4" %then %do; */
			/*				(A.%scan(&&GRP&i.,1) = B.%scan(&&GRP&i.,1) and A.%scan(&&GRP&i.,2) = B.%scan(&&GRP&i.,2) and A.%scan(&&GRP&i.,3) = B.%scan(&&GRP&i.,3));*/
			/*			%end;*/
			/*			%if "&j." = "3" %then %do; */
			/*				(A.%scan(&&GRP&i.,1) = B.%scan(&&GRP&i.,1) and A.%scan(&&GRP&i.,2) = B.%scan(&&GRP&i.,2));*/
			/*			%end;*/
			/*			%if "&j." = "2" %then %do; */
			/*				(A.%scan(&&GRP&i.,1) = B.%scan(&&GRP&i.,1));*/
			/*			%end;*/
			/*			quit;*/


			libname keys&i. xml "&output_path./&i/byvar_keys.xml";
			data keys&i..key_names;
				length key_name $100;
				set uniq_keys&i.;
				rename grp&i._flag = flag;
				key_name = %scan(&&GRP&i.,1);
				%if "&j." >= "3" %then %do;
				key_name = cats(key_name, "|",%scan(&&GRP&i.,2));
				%end;
				%if "&j." >= "4" %then %do;
				key_name = cats(key_name, "|",%scan(&&GRP&i.,3));
				%end;
				run;
				
			libname obyvar&i. xml "&output_path./&i/byvar.xml";
			data obyvar&i..byvar;
				set uniq_keys&i.;
				rename grp&i._flag = flag;
				%do m = 1 %to %eval(&j.-1);
					rename %scan(&&GRP&i.,&m) = var&m;
				%end;
				run;
			libname outin "&output_path./&i/";
			data outin.byvar;
					set keys&i..key_names;
					run;		
			proc export data = keys&i..key_names
				outfile = "&output_path./&i/byvar.csv"
				dbms = csv replace;
				run;
				
		/*			 addition of 1 column named grp needed for muMix */
			data keys&i..key_names_mumix;
				set keys&i..key_names;
				grp&i._flag = flag;
				run; 

			/* export of the new dataset with addition of 1 column for muMIx */
			proc export data = keys&i..key_names_mumix
				outfile = "&output_path./&i/byvar1.csv"
				dbms = csv replace;
				run;

		%end;
	%end;

%MEND folderCreation;
%folderCreation;

ENDSAS;
