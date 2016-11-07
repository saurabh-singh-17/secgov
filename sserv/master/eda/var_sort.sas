/*--------------------------------------------------------------------------------------------------------*/
/*--                                                                                                  	--*/
/*-- Functionality Name :  var_sort.sas        	--*/

/*-- Description  		:  sorts the generated csv for bivariate 
/*-- Return type  		:  Creates CSV's at a location according to given inputs                        --*/

/*-- Author       		:  Saurabh vikash singh                         --*/
/*--------------------------------------------------------------------------------------------------------*/
/*parameters*/
/*%let input_path="D:/";*/
/*%let var_order=new || new2 || new3;*/
/*%let csvname=ACV*/
*processbody;
options mprint mlogic symbolgen mfile;
dm log 'clear';

proc printto log="&input_path./var_sort.log";
quit;

%macro sortdata;

	proc import datafile="&input_path./&csvname..csv" dbms=csv out=temp replace;
	run;

	%do i = 1 %to %sysfunc(countw("&var_order.","||"));
		%let level = %scan("&var_order.",&i.,"||");

		data new;
			set temp;

			if level= "&level." then
				output;
		run;

		%if &i = 1 %then
			%do;

				data final;
					set new;
				run;

			%end;
		%else
			%do;

				data final;
					set final new;
				run;

			%end;
	%end;

	proc export data=final dbms=csv outfile="&input_path./&csvname..csv" replace;
	run;
	quit;
%mend;

%sortdata;
;