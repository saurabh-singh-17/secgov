*processbody;
/*--------------------------------------------------------------------------------------------------------*/
/*--                                                                                                  	--*/
/*-- Functionality Name :  ResponseCurve        	--*/
/*-- Description  		:  generates the csvs required for the plottingn the response curve
/*-- Return type  		:  Creates CSV's at a location according to given inputs                        --*/
/*-- Author       		:  Saurabh vikash singh                         --*/
/*--------------------------------------------------------------------------------------------------------*/         
options mprint mlogic symbolgen mfile;

/*dm log 'clear';*/
/**/
proc printto log="&output_path./response_curve.log" new;
run;
quit;

/*proc printto;*/
/*run;*/

/*library creation*/

libname in "&input_path.";
libname out "&output_path.";

/*changing parameters*/
/* modified by proma
need {exp part to put -1 at the end of baseline equation*/
%let eqn = &Equation.;
%put &eqn.;

%macro change_parameters;
data _null_;
call symput("View",tranwrd("&View.","Weekly","week"));
run;
data _null_;
call symput("View",tranwrd("&View.","Monthly","month"));
run;
data _null_;
call symput("View",tranwrd("&View.","Quarterly","qtr"));
run;
data _null_;
call symput("View",tranwrd("&View.","Yearly","year"));
run;
data _null_;
call symput("Date_range",tranwrd("&Date_range.",",","||"));
run;
data _null_;
call symput("Equation",tranwrd("&Equation.","{",""));
run;
data _null_;
call symput("Equation",tranwrd("&Equation.","}",""));
run;
data _null_;
call symput("Equation",tranwrd("&Equation.","*","||"));
run;
%if "&Class_variable." ne "" %then %do;
%let remove_date_name = %scan("&Date_var.",1,"#");	
data _null_;
call symput("Class_variable",tranwrd("&Class_variable.",",&remove_date_name.",""));
run;
data _null_;
call symput("Class_variable",tranwrd("&Class_variable.","&remove_date_name.,",""));
run;
%end;
%mend;
%change_parameters;
%let change_var=current_model_var current_baseline_var current_market_var;
/*calculation for responsencurve starts*/
%macro response_curve;
%if "&Panel_flag" = "" %then %do;
	%let Panel_flag=Across_Dataset;
%end;
%do i=1 %to %sysfunc(countw("&Panel_flag.","#"));
/*	getting current iteration parameters from initial parameters*/
     %let current_model_var=%scan("&model.",&i.,"#");
     %let current_baseline_var=%scan("&baseline_var",&i.,"#");
     %let current_market_var=%scan("&market_var",&i.,"#");
     %let current_class_var=%scan("&class_variable.",&i.,"#");
     %let current_param_path=%scan("&param_path.",&i.,"#");
     %let temp_panel=%scan("&Panel.",&i.,"#");
     %let temp_panel_flag=%scan("&Panel_flag.",&i.,"#");
     %let temp_panel_level=%scan("&Panel_level.",&i.,"#");
     %let temp_panel_level_flag=%scan("&Panel_level_flag.",&i.,"#");
     %let current_Transformation_factor=%scan("&Transformation_factor.",&i.,"#");
     %let current_model_equation=%scan("&Equation.",&i.,"#");
     %let current_Conversion_rate=%scan("&Conversion_rate.",&i.,"#");
     %let current_response=%scan("&response.",&i.,"#");
     %let current_date_var=%scan("&Date_var.",&i.,"#");
     %let current_start_stop=%scan("&Date_range.",&i.,"#");


/*	 filtering of current class var from baseline variables*/
	%if "&current_class_var." ne "" %then %do;
	%do zz=1 %to %sysfunc(countw("&current_class_var.",","));
		%let ab_class= %scan("&current_class_var.",&zz.,",");
		data _null_;
		call symput("current_baseline_var",tranwrd("&current_baseline_var.","&ab_class.,",""));
		run;
		data _null_;
		call symput("current_baseline_var",tranwrd("&current_baseline_var.","&ab_class.",""));
		run;
	%end;	
	%end;
 
 /*	making of cost equation for the current iteration*/
     %let current_cost_equation=;
     %do cc=1 %to %sysfunc(countw("&current_market_var.",","));
         %do dd=1 %to %sysfunc(countw("&current_model_var.",","));
         	%if %scan("&current_market_var.",&cc.,",") = %scan("&current_model_var.",&dd.,",") %then %do;
         		%if "&current_cost_equation." = "" %then %do;
         		%let current_cost_equation=%scan("&current_Transformation_factor.",&dd.,",")*(%scan("&current_market_var.",&cc.,","));
        		%end;
        		%else %do;
        		%let current_cost_equation=&current_cost_equation + %scan("&current_Transformation_factor.",&dd.,",")*(%scan("&current_market_var.",&cc.,","));
        		%end;
        	%end;
        %end;	
    %end;
    %do sa =1 %to %sysfunc(countw("&current_market_var.",","));
        %let in_current_market_var = %scan("&current_market_var.",&sa.,",");


        %do sap=1 %to %sysfunc(countw("&current_model_var.",","));
        	%let match_var=%scan("&current_model_var.",&sap.,",");
        	%if %sysfunc(strip(&in_current_market_var.)) = %sysfunc(strip(&match_var.)) %then %do;
        		%let cu_conv_rate= %scan("&current_Conversion_rate.",&sap.,",");
        	%end;
        %end;
        %do seq= 1 %to %sysfunc(countw("&current_cost_equation.","+"));
        	%let in_current_cost_equation =%scan("&current_cost_equation.",&seq.,"+");
        	%if %index(&in_current_cost_equation.,&in_current_market_var.) > 0 %then %do;
        		data _null_;
        			call symput("current_cost_equation",tranwrd("&current_cost_equation.","&in_current_cost_equation.","&cu_conv_rate.*&in_current_cost_equation"));
        			run;
        	%end;
        %end;
    %end;
    data _null_;
    call symput("current_model_equation",tranwrd("&current_model_equation.","log(","log1px("));
    run;
    data _null_;
    call symput("current_cost_equation",tranwrd("&current_cost_equation.","log(","log1px("));
    run;

    %put &current_cost_equation.;
/*	sorting the variables in decreasing order of their length in order to facilitate correct substitution in the model equation*/
/*	%do ch=1 %to %sysfunc(countw("&chnage_var."," "));*/
/*		%let current_change_var =%scan("&change_var.",&ch.," ");*/
/*		data rearrange;*/
/*		 	input new $ @@;*/
/*			datalines;*/
/*			&current_change_var.*/
/*			;*/
/*			run;*/
/**/
/*		data forsort;*/
/*			set forsort;*/
/*			colnew=length(strip(new));*/
/*			run;*/
/**/
/*			proc sort data=forsort out=forsort;*/
/*			by descending colnew;*/
/*			run;*/
/**/
/*		proc sql;*/
/*		select new into: &current_change_var. separated by "," from forsort;*/
/*		quit;*/
/*	%end;*/


    %do j=1 %to %sysfunc(countw("&temp_panel_flag",","));
        %let current_panel=%scan("&temp_panel.",&j.,",");
        %let current_panel_flag=%scan("&temp_panel_flag.",&j.,",");
        %let current_panel_level=%scan("&temp_panel_level.",&j.,",");
        %let current_panel_level_flag=%scan("&temp_panel_level_flag.",&j.,",");
        %if "&Date_var." ne "" %then %do;
		data _null_;
			call symput("Date_start","%scan(&current_start_stop.,1,"||")");
        	run;
        data _null_;
        	call symput("Date_end","%scan(&current_start_stop.,2,"||")");
        	run;

/*		filtering the data *****************************************************************/
        data in.current_data;
        	set in.dataworking;
			%if "&current_panel_level." ne "Across_Dataset" %then %do;
        	if &current_panel_flag="&current_panel_level_flag.";
			%end;
        	if "&Date_start."d <= &current_date_var. <= "&Date_end."d;
        	run;	
/*		filtering data completed		*****************************************************/
        %end;
		%else %do;
		data in.current_data;
        	set in.dataworking;
			%if "&current_panel_level." ne "Across_Dataset" %then %do;
        	if &current_panel_flag="&current_panel_level_flag.";
			%end;
        	run;	
		%end;
/*		prepare the model equation for the evaluation i.e including transormation factor in the equation */
        %do m=1 %to %sysfunc(countw("&current_model_var",","));
        	%let scan_var=%scan("&current_model_var.",&m.,",");
        	%let scan_Transformation_factor=%scan("&current_Transformation_factor.",&m.,",");
        	data _null_;
        	call symput("current_model_equation",tranwrd("&current_model_equation.","&scan_var.","&scan_Transformation_factor.*&scan_var."));
        	run;
        %end;
        data _null_;
        call symput("current_model_equation","&current_response.*(&current_model_equation.)");
        run;	

        %put &current_model_equation.;
/*		filtering out class variables from independent variables if any		*/
        %if "&current_class_var." ne "" %then %do;
        	%do n=1 %to %sysfunc(countw("&current_class_var.",","));
        		%let temp_class = %scan("&current_class_var.",&n.,",");
        		data _null_;
        		call symput("current_model_var",tranwrd("&current_model_var.",",&temp_class.",""));
        		run;
        	%end;
        %end;
        
/*		getting the data ready for putting in the model equation		*********************/
/*		making the final filter for the model data creation for each combined level of class*/

        %if "&current_class_var." ne "" %then %do;
        	data in.current_data;
        		format class_filter_var $200.;
        		set in.current_data;
        		class_filter_var=catx("||",&current_class_var.);
        		run;
        %end;
        %else %do;
        	data in.current_data;
        		set in.current_data;
        		class_filter_var="dummy";
        		run;
        %end;

        proc sql;
        select distinct(class_filter_var) into: class_filter_var_unique separated by "," from in.current_data;
        quit;
        
/*		starting the process for feeding the data into the model eqautions and changing the model equation for each class level*/

/*		preparing the rolled up data to feed*/
        %do n=1 %to %sysfunc(countw("&class_filter_var_unique",","));
        	%let this_class_combined_level =%scan("&class_filter_var_unique.",&n.,",");
        	data in.this_class_combined_data;
        			set in.current_data;
        			if class_filter_var ="&this_class_combined_level.";
        			run;
         		data in.this_class_combined_data;
        			set in.this_class_combined_data;
					%if "&View" = "Daily" %then %do;
						format rollup_var1 date9.;
						format rollup_var $20.;
						rollup_var1=&current_date_var.;
						rollup_var=put(rollup_var1,date9.);
					%end;
					%else %do;
	        			%if "&View." ne "year" %then %do;
	        				rollup_var=catx("_",&View.(&current_date_var.),year(&current_date_var.));
	        			%end;
	        			%else %do;
	        				rollup_var=&View.(&Date_var.);
	        			%end;
					%end;
        			run;
        		data _null_;
        			call symput("current_model_var_1",tranwrd("&current_model_var.",","," "));
        			run;	
        		proc sort data=in.this_class_combined_data out=in.this_class_combined_data;
        			by rollup_var;
        			run;
        		proc means data=in.this_class_combined_data;
        			by rollup_var;
        			var &current_model_var_1;
        			output out=final_model_data;
        			run;
        		data final_model_data(drop=_TYPE_);
        			set final_model_data;
        			if _STAT_ = "MEAN";
        			run;
        		%if "&aggregation"  = "Sum" %then %do;
        			%let current_model_var_sum=;
        			data final_model_data;
        				set final_model_data;
						format _numeric_ BEST12.;
        			%do tem=1 %to %sysfunc(countw("&current_model_var.",","));
        				 %scan("&current_model_var.",&tem.,",")= _FREQ_ *%scan("&current_model_var.",&tem.,",");
/*						%let current_model_var_sum=&current_model_var_sum. ,sum(%scan("&current_model_var.",&tem.,",")) as %scan("&current_model_var.",&tem.,",");*/
        			%end;
        			run;
/*					proc sql;*/
/*					create table final_model_data as select rollup_var as Variable, &current_model_var_sum. from in.this_class_combined_data group by rollup_var;*/
/*					quit;*/
        		%end;
        		data _null_;
        		call symput("current_other_var",tranwrd("&current_model_var.",",&Selected_variable",""));
        		run;
				data _null_;
        		call symput("current_other_var",tranwrd("&current_model_var.","&Selected_variable",""));
        		run;
        		data _null_;
        		call symput("current_other_var_1",tranwrd("&current_other_var.",","," "));
        		run;
/*				treating the other variables process : two macros will be created one will contain the other variable
				names and the other will contain the corresponding treatment value*/

        		proc means data=final_model_data;
        		var &current_other_var_1;;
        		output out=other_var_data;
        		run;
        		data other_var_data;	
        			set other_var_data;
        			%if "&other_variable." = "average" %then %do;		
        			if _STAT_ = "MEAN";
        			%end;
        			%else %do;
        			if _STAT_ = "MIN";
        			%end;
        			run;
        		proc transpose data=other_var_data out=other_var_data;
        			var &current_other_var_1;
        			by _STAT_;
        			run;
        		%if "&other_variable." = "zero" %then %do;		
        		data other_var_data;
        			set other_var_data;
        			COL1 = 0;
        			run;	
        		%end;
        		proc sql;
        		select _NAME_ into: model_eqn_var separated by "," from other_var_data;
        		quit;

        		proc sql;
        		select COL1 into: model_eqn_var_value separated by "," from other_var_data;
        		quit;

/*				now substituting the value into the model equation and reconstructing the model eqn for further use*/
        		data _null_;
        		call symput("this_current_model_equation","&current_model_equation.");
        		run;
        		data _null_;
        		call symput("this_current_cost_equation","&current_cost_equation.");
        		run;

        		%put &this_current_cost_equation.;
        		%put &this_current_model_equation.;

        		%do bl =1 %to %sysfunc(countw("&current_baseline_var.",","));
        			%let into_current_baseline_var = %scan("&current_baseline_var.",&bl.,",");
        			%do eq= 1 %to %sysfunc(countw("&this_current_model_equation.","+"));
        				%let in_cur_model_eqn=%scan("&this_current_model_equation.",&eq.,"+");
        				%let into_current_baseline_var_name= %scan("&in_cur_model_eqn.",2,"||");
        				%if %index("&into_current_baseline_var_name.",&into_current_baseline_var.) > 0 %then %do;
        				data _null_;
        				call symput("this_current_model_equation",tranwrd("&this_current_model_equation.","&into_current_baseline_var_name.","1"));
        				run;
        				%end;
        			%end;
        		%end;
        		data _null_;
        		call symput("this_current_model_equation_base","&this_current_model_equation.");
        		run;
        		%put &this_current_model_equation_base.;
        		%do bl =1 %to %sysfunc(countw("&current_market_var.",","));
        			%let into_current_market_var = %scan("&current_market_var.",&bl.,",");
        			%do eq= 1 %to %sysfunc(countw("&this_current_model_equation_base."," + "));
        				%let in_this_cur_model_eqn_base=%scan("&this_current_model_equation_base.",&eq.,"+");
        				%let into_current_market_var_name= %scan("&in_this_cur_model_eqn_base.",2,"||");
        				%if %index("&into_current_market_var_name.",&into_current_market_var.) > 0 %then %do;
        				data _null_;
        				call symput("this_current_model_equation_base",tranwrd("&this_current_model_equation_base.","&into_current_market_var_name.","0"));
        				run;
        				%end;
        			%end;
        		%end;

        		%put &this_current_model_equation_base.;

        		%do fin=1 %to %sysfunc(countw("&model_eqn_var.",","));
        			%let current_model_eqn_var=%scan("&model_eqn_var.",&fin.,",");
        			%let current_model_eqn_var_value=%scan("&model_eqn_var_value.",&fin.,",");
        			data _null_;
        			call symput("this_current_model_equation",tranwrd("&this_current_model_equation.","&current_model_eqn_var.","&current_model_eqn_var_value."));
        			run;
        			data _null_;
        			call symput("this_current_cost_equation",tranwrd("&this_current_cost_equation.","&current_model_eqn_var.","&current_model_eqn_var_value."));
        			run;
        		%end;
        		%do fin=1 %to %sysfunc(countw("&this_class_combined_level.","||"));
        			%let this_class_combined_level_split=%scan("&this_class_combined_level.",&fin.,"||");
        			data _null_;
        			call symput("this_current_model_equation",tranwrd("&this_current_model_equation.","_&this_class_combined_level_split.","*1"));        					
					run;
        			data _null_;
        			call symput("this_current_cost_equation",tranwrd("&this_current_cost_equation.","_&this_class_combined_level_split.","*1"));
        			run;
        			data _null_;
        			call symput("this_current_model_equation_base",tranwrd("&this_current_model_equation_base.","_&this_class_combined_level_split.","*1"));
        			run;
        		%end;
        		%do k=1 %to %sysfunc(countw("&current_class_var.",","));
        			%let into_current_class_var=%scan("&current_class_var.",&k.,",");
        			data _null_;
        					call symput("this_current_model_equation",tranwrd("&this_current_model_equation.","&into_current_class_var","1"));
        					run;
        			data _null_;
        					call symput("this_current_cost_equation",tranwrd("&this_current_cost_equation.","&into_current_class_var","1"));
        					run;
        			data _null_;
        					call symput("this_current_model_equation_base",tranwrd("&this_current_model_equation_base.","&into_current_class_var","1"));
        					run;
        			proc sql;
        			select distinct(&into_current_class_var.) into:level_class separated by "," from in.dataworking;	
        			quit;
        			%do l=1 %to %sysfunc(countw("&level_class.",","));
        				%let current_level_class=%scan("&level_class",&l.,",");
        					data _null_;
        					call symput("this_current_model_equation",tranwrd("&this_current_model_equation.","_&current_level_class.","*0"));
        					run;
        					data _null_;
        					call symput("this_current_cost_equation",tranwrd("&this_current_cost_equation.","_&current_level_class.","*0"));
        					run;
        					data _null_;
        					call symput("this_current_model_equation_base",tranwrd("&this_current_model_equation_base.","_&current_level_class.","*0"));
        					run;
        			%end;
        		%end;
/*				for this_current_model_equation*/

				data _null_;
				call symput("new1",compress(tranwrd("&this_current_model_equation.","(","")));
				run;	
				data _null_;
				call symput("new2",compress(tranwrd("&this_current_model_equation.",")","")));
				run;	
				data _null_;
				call symput("test1",%length("&new1."));
				run;
				data _null_;
				call symput("test2",%length("&new2."));
				run;
				data _null_;
				call symput("num_of_cl_brac","%sysevalf(%sysevalf(&test2.)- %sysevalf(&test1.))");
				run;
				%put &num_of_cl_brac.;
				%let brackets=;
				%do lm=1 %to &num_of_cl_brac.;
					%let brackets=&brackets.);
				%end;
				%let this_current_model_equation=&this_current_model_equation.&brackets.;
/* 				end of this_current_model_equation*/


/*				for this_current_model_equation*/

				data _null_;
				call symput("new1",compress(tranwrd("&this_current_model_equation_base.","(","")));
				run;	
				data _null_;
				call symput("new2",compress(tranwrd("&this_current_model_equation_base.",")","")));
				run;	
				data _null_;
				call symput("test1",%length("&new1."));
				run;
				data _null_;
				call symput("test2",%length("&new2."));
				run;
				data _null_;
				call symput("num_of_cl_brac","%sysevalf(%sysevalf(&test2.)- %sysevalf(&test1.))");
				run;
				%put &num_of_cl_brac.;
				%let brackets=;
				%do lm=1 %to &num_of_cl_brac.;
					%let brackets=&brackets.);
				%end;
				%let this_current_model_equation_base=&this_current_model_equation_base.&brackets.;
/* 				end of this_current_model_equation*/

        		data _null_;
        		call symput("this_class_combined_lvl_4_pan",tranwrd("&this_class_combined_level.","||","_"));
        		run;
				data _null_;
        		call symput("this_class_combined_lvl_4_pan",strip("&this_class_combined_level."));
        		run;
        		data _null_;
        		call symput("this_current_model_equation",compress(tranwrd("&this_current_model_equation.","||","*")));
        		run;
        		data _null_;
        		call symput("this_current_model_equation_base",compress(tranwrd("&this_current_model_equation_base.","||","*")));
        		run;
        		%if "&flag_selection." = "dataset" %then %do;
        			data feed_data(keep=Variable  &Selected_variable. y_var Level Profit type rename=(&Selected_variable.=x_var Variable=Date));
        				set final_model_data;
						length Level $100.;
        				y_var=(&this_current_model_equation.) - (&this_current_model_equation_base.);
						%if "&this_class_combined_lvl_4_pan" ne "dummy" %then %do;
        				Level="&current_panel_level._&this_class_combined_lvl_4_pan.";
						%end;
						%else %do;
						Level="&current_panel_level.";
						%end;
        				Profit=y_var- (&this_current_cost_equation.);
        				marginal_roi=0;
        				type=0;
        				run;
        		%end;
        		%else %do;
        		data feed_data;
        			do ex = &Start. to &Stop. by &Step.;
        			output;		
        			end;
        			run;
				data feed_data;
					set feed_data;
					rename ex=&Selected_variable.;
					run;
        		data feed_data (rename=(&Selected_variable.=x_var));
        			set feed_data;
					length Level $100.;
        			y_var=(&this_current_model_equation.) - (&this_current_model_equation_base.);
					%if "&this_class_combined_lvl_4_pan" ne "dummy" %then %do;
        			Level="&current_panel_level._&this_class_combined_lvl_4_pan.";
					%end;
					%else %do;
					Level="&current_panel_level.";
					%end;
        			Profit=y_var- (&this_current_cost_equation.);
        			marginal_roi=0;
        			type=0;
        			Date="";
        			run;
        		%end;
        		%if "&i" = "1" & "&j." = "1" & "&n." = "1" %then %do;
        			data csv_data;
        				set feed_data;
        				run;
        		%end;
        		%else %do;
        			data csv_data;
        				set csv_data feed_data;
        				run;
        		%end;
				/* modified by proma
				need {exp part to put -1 at the end of baseline equation*/
				data x;
					length a $200.;
					a="&this_current_model_equation_base.";
					a=tranwrd(a,"&current_response.*","&current_response.*{");
					b=cats(a,"}");
					%if %index("&eqn.",{exp) > 0 %then %do;
					b=compress(tranwrd(b,"}","-1}"));
					%end;
					run;

				proc sql;
					select b into:baseline_eqn from x;
					quit;

				%put &baseline_eqn.;

				%if "&this_class_combined_lvl_4_pan." ne "dummy" %then %do;
        		data _null_;
        			v1= "&this_current_model_equation.";
        			file "&output_path/response_equation_&current_panel_level._&this_class_combined_lvl_4_pan..txt";
        			put v1;
        			run;
        		data _null_;
        			v1= "&this_current_cost_equation.";
        			file "&output_path/cost_equation_&current_panel_level._&this_class_combined_lvl_4_pan..txt";
        			put v1;
        			run;

        		data _null_;
        			v1= "&baseline_eqn.";
        			file "&output_path/baseline_equation_&current_panel_level._&this_class_combined_lvl_4_pan..txt";
        			put v1;
        			run;
				%end;
				%else %do;
				data _null_;
        			v1= "&this_current_model_equation.";
        			file "&output_path/response_equation_&current_panel_level..txt";
        			put v1;
        			run;
        		data _null_;
        			v1= "&this_current_cost_equation.";
        			file "&output_path/cost_equation_&current_panel_level..txt";
        			put v1;
        			run;

        		data _null_;
        			v1= "&baseline_eqn.";
        			file "&output_path/baseline_equation_&current_panel_level..txt";
        			put v1;
        			run;
				%end;	
        %end;
    %end;
%end;		
data csv_data;
    set csv_data;
    Level=tranwrd(Level,"_dummy","");
    run;

proc sort data=csv_data out=csv_data ;
by Level  x_var ;
quit;




proc export data=csv_data dbms=csv outfile="&output_path./response_curve.csv" replace;

data _null_;
    v1= "RESPONSE_CURVE_COMPLETED";
    file "&output_path/RESPONSE_CURVE_COMPLETED.txt";
    put v1;
    run;
%mend;
%response_curve;