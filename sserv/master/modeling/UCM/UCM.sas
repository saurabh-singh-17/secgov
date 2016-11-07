options mprint mlogic symbolgen mfile;

/*Log file for UCM*/
/*proc printto log="&outputPath./UCM_Log.log";*/
/*	run;*/
/*	quit;*/

proc printto;
run;
quit;

/*deleting the ERROR.txt*/
FILENAME MyFile "&outputPath./ERROR.txt" ;
DATA _NULL_ ;
	rc = FDELETE('MyFile') ;
RUN ;	

/*defining input and output libraries*/
libname in "&inputPath.";
libname out "&outputPath.";


/*macro for plotting the chart in case of more than 6000 points*/
%MACRO plots(dataset, flag);
	%let dsid = %sysfunc(open(&dataset.));
	%let nobs =%sysfunc(attrn(&dsid,NOBS));
	%let rc = %sysfunc(close(&dsid));

	%if &nobs. > 5500 %then
		%do;
			/*Predicted Vs Actual Plot*/
			data anno;
				function='move';
				xsys='1';
				ysys='1';
				x=0;
				y=0;
				output;
				function='draw';
				xsys='1';
				ysys='1';
				color='green';
				x=100;
				y=100;
				output;
			run;

			ods graphics on/ width=20in height=20in;
			ods listing;
			filename image %if &flag. = 0 %then
			%do;
				"&outputPath./ActualvsPredicted.png";
			%end;
			%else
			%do;
				"&outputPath./ActualvsPredicted_Transformed.png";
			%end;;
			goptions device = pngt gsfname=image gsfmode=replace;
			footnote1 h = .5 '  ';
			symbol1 font = marker value=U height=.3 color=orange width=20;
			axis1 label=('Predicted');
			axis2 label=('Actual');

			proc gplot data= &dataset.;
				plot forecast*actual/anno=anno vaxis=axis1 haxis=axis2;
			run;

			ods listing close;
			ods graphics off;
			
			/*---------------------------------------------------------*/
			/*Residual Vs Predicted Plot*/
			ods graphics on/ width=20in height=20in;
			ods listing;
			filename image %if &flag. = 0 %then

			%do;
				"&outputPath./ResidualvsPredicted.png";
			%end;
			%else
			%do;
			"&outputPath./ResidualvsPredicted_Transformed.png";
			%end;;

			goptions device = pngt transparency gsfname=image gsfmode=replace;
			footnote1 h = .5 '  ';
			symbol1 font = marker value=U height=.3 color=orange;
			axis1 label=('Predicted');
			axis2 label=('Residual');

			proc gplot data= &dataset.;
			plot Forecast*Residual/vaxis=axis1 haxis=axis2;
			run;

			ods listing close;
			ods graphics off;

			
			/*---------------------------------------------------------*/
			/*Actual Vs Predicted*/
			ods graphics on/ width=20in height=20in;
			ods listing;
			filename image %if &flag. = 0 %then
			%do;
			"&outputPath./PredictedandActual.png";
			%end;
			%else
			%do;
			"&outputPath./PredictedandActual_Transformed.png";
			%end;;

			goptions device = pngt gsfname=image gsfmode=replace;
			footnote1 h = .5 '  ';
			symbol1 interpol=join color=green font=marker value=U height=0.3 w=1;
			symbol2 interpol=join color=orange font=marker value=U height=0.3 w=1;
			axis1 label=('Actual & Predicted');
			axis2 label=('&dateVar.');

			proc gplot data= &dataset.;
			plot (Actual Forecast)*&dateVar./overlay vaxis=axis1 haxis=axis2;
			run;

			ods listing close;
			ods graphics off;

			/*---------------------------------------------------------*/
		%end;
%mend;


%macro final_UCM;
	
	%let old_outputPath = &outputPath.;
	
	/*set the validation type if validation is not applied to build*/
	%if "&validationType." = "" & "&validationVar." = "" %then %do;
		%let validationType = build;
		%end;

	/*Loop for validation type build, validation and entire*/
	%do z = 1 %to %sysfunc(countw("&validationType."," "));
		%let type = %scan("&validationType.",&z.," ");

		/*change the outputPath as per validationType*/
		%if "&type." ^= "build"  %then %do;
			data _null_;
				call symput("outputPath",catx("/","&old_outputPath.","validation","&type."));
				run;
			%end;

		/*check if Date variable has missing values*/
		proc sql;
		select count(&dateVar.) into:missDate separated by " " from in.dataworking where &dateVar. = .;
		run;
		quit;

		%if &missDate. > 0 %then %do;
			data _null_;
				file "&outputPath./ERROR.txt";
				put "Date variable has missing values. Cannot continue.";
				run;

				ENDSAS;
			%end;

		/*check for across dataset, per group by and validation applied*/
		data dataworking(keep=&dateVar. &dependentVariable. &fixedVars. &splineVars. &randomVars.);
			set in.dataworking;
			%if &grpNo.^= 0 %then %do;
				if grp&grpNo._flag = "&grpFlag.";
				%end;
			%if "&validationVar." ^= "" %then %do;
				%if "&type." = "build" %then %do;
					if &validationVar. = 1;
					%end;
				%else %do;
					%if "&type." = "validation" %then %do;
						if &validationVar. = 0;
						%end;
					%end;
				%end;
			run;
		
		/*removing the missing values*/
		data dataworking;
			set dataworking;
			if nmiss(of _numeric_) then delete;
			run;


		/*take the transformations for selected variables*/
		%if "&fixedTransform." ^= "" | "&dependentTransform." ^= "" %then %do;
			%let fixedDependentTrans = &fixedTransform. &dependentTransform.;
			%let fixedDependentVars = &fixedVars. &dependentVariable.;
			%do i = 1 %to %sysfunc(countw("&fixedDependentTrans."," "));
				%let transform = %scan("&fixedDependentTrans.",&i.," ");
				%let variable = %scan("&fixedDependentVars.",&i.," ");
				%if "&transform." = "log" %then %do;
					data dataworking;
						set dataworking;
						&variable. = log1px(&variable.);
						run;
					%end;
				%end;
			%end;


		/*create table for selected transformation for fixed vars*/
		%if "&fixedVars." ^= "" %then %do;
			data transform;
				length Transformation $50.;
				format Transformation $50.;
				length Variable $50.;
				format Variable $50.;
				%do trans = 1 %to %sysfunc(countw(&fixedVars.," "));
				   Transformation="%scan(&fixedTransform.,&trans.," ")";
				   Variable = "%scan(&fixedVars.,&trans.," ")";
				   output;
				%end;
				run;
			%end;


		/*check for less number of observation*/
		%let dsid = %sysfunc(open(dataworking));
		%let nobs = %sysfunc(attrn(&dsid.,nobs));
		%let rc = %sysfunc(close(&dsid.));

		%if &nobs. < 10 %then %do ;
			data _null_;
				file "&outputPath./ERROR.txt";
				put "Less observations after eliminating missing values from the dataset";
				run;
				
				ENDSAS;
		%end;


		/*check for Date irregularity*/
		proc sort data=dataworking;
			by &dateVar.;
			run;
			quit;
		proc contents data=dataworking(keep=&dateVar.) out=contents(keep=format formatl);
			run;
			quit;

		proc sql;
		select format, formatl into:format, :formatl separated by " " from contents;
			run;
			quit;

		data _null_;
			call symput("dateFormat",cat(strip("&format."),strip("&formatl."),"."));
			run;
		
		data temp;
			set dataworking(keep=&dateVar.);
			format lagDate &dateFormat.;
			lagDate = lag1(&dateVar.);
			run;
		
		data temp;
			set temp;
			interval = &dateVar.-lagDate;
			run;

		proc sql;
			select count(distinct interval) into: uniqueDate separated by " " from temp where interval not in (28, 29, 366, 31);
			run;
			quit;

		%if &uniqueDate. > 1 %then %do;
			data _null_;
				file "&outputPath./ERROR.txt";
				put "Date variable is irregular. Cannot continue.";
				run;

				ENDSAS;
			%end;


		/*check if the variables selected dont have one unique level*/
		%if "&fixedVars." ^= "" | "&randomVars." ^= "" | "&splineVars." ^= "" %then %do;
			%let allVars = &fixedVars.;

			%do i=1 %to %sysfunc(countw("&splineVars."," "));
				%let addSplineVar = %scan("&splineVars.",&i.," ");
				%if %index(&allVars.,&addSplineVar.)=0 %then %do;
					%let allVars = &allVars. &addSplineVar.;
					%end;

				%end;

			%do j=1 %to %sysfunc(countw("&randomVars."," "));
				%let addRandomVar = %scan("&randomVars.",&j.," ");
				%if %index(&allVars.,&addRandomVar.)=0 %then %do;
					%let allVars = &allVars. &addRandomVar.;
					%end;
				%end;
			%put &allVars.;
			
					
			ods output nlevels=levels;
			proc freq data=dataworking nlevels;
				tables &allVars. /noprint;
				quit;

			%let oneUniqueVars =;	
			proc sql;
				select TableVar into: oneUniqueVars separated by "," from levels where NLevels = 1; 
				run;
				quit;
		
			
			%if "&oneUniqueVars." ^= "" %then %do;
			%let errorStat = "The following Variables &oneUniqueVars. have only one unique level. Cannot continue.";
				data _null_;
					v1 = &errorStat.;
					file "&outputPath./ERROR.txt";
					put v1;
					run;

					ENDSAS;			
				%end;
			%end;



		/*formation of dependent lag statement if selected	*/
		%let final_dependentLag =;
		%if "&dependentLag." ^= "" %then %do;
			%if "&dependentLag." = "ordered" %then %do;
				data _null_;
					call symput("new_dependentLag",cat("deplag lags=","&lags. "));
					run;
				%end;
			%else %do;
				%if "&dependentLag." = "custom" %then %do;
					data _null_;
						call symput("new_dependentLag",cat("deplag lags=(",tranwrd("&lags."," ",") ("),") "));
						run;
					%end;	
				%end;
			%if "&phi." ^= "" %then %do;
				data _null_;
					call symput("final_dependentLag",cat("&new_dependentLag.","phi=","&phi.;"));
					run;
				%end;
			%else %do;
				data _null_;
					call symput("final_dependentLag",cat("&new_dependentLag.",";"));
					run;
				%end;
			%end;

		/*splinereg statement formation*/
		%let final_splineStat = ;
		%if "&splineVars." ^= "" %then %do;
			%do j=1 %to %sysfunc(countw("&splineVars."," "));
				%let splineVar = %scan("&splineVars.",&j.," ");
				%let splineVarMenu = %scan("&splineMenu.",&j.,"||");
				data _null_;
					call symput("final_splineStat",cat("&final_splineStat."," splinereg ","&splineVar. ","&splineVarMenu.;"));
					run;
				%end;
			%end;
		%put &final_splineStat.;

		/*randomreg statement formation*/
		%let final_randomStat = ;
		%if "&randomVars." ^= "" %then %do;
			%do k=1 %to %sysfunc(countw("&randomVars."," "));
				%let randomVar = %scan("&randomVars.",&k.," ");
				%let randomVarMenu = %scan("&randomMenu.",&k.,"||");
				data _null_;
					call symput("final_randomStat",cat("&final_randomStat."," randomreg ","&randomVar. /","&randomVarMenu.;"));
					run;
				%end;
			%end;
		%put &final_randomStat.;

		/*cycle statement formation*/
		%let final_cycleStat = ;
		%let keepCycleStat = ;
		%let renameCycleStat= ;
		%let l = 1;
		%if "&cycle." ^= "" %then %do;
			%do l=1 %to %sysfunc(countw("&cycle.","||"));
				%let cycleMenu = %scan("&cycle.",&l.,"||");
				data _null_;
					call symput("final_cycleStat",cat("&final_cycleStat.","&cycleMenu. ;"));
					run;

				%let keepCycleStat = &keepCycleStat. s_cycle&l.;
				%let renameCycleStat = &renameCycleStat. s_cycle&l. = Cycle&l.;
				%end;
			%end;

		%if &l. = 2 %then %do;
			%let keepCycleStat = s_cycle;
			%let renameCycleStat= s_cycle = Cycle;
			%end;
		%put &final_cycleStat.;


		/*proc ucm*/
		ods trace on;
		ods output FitSummary = fitSummary(keep=FitStatistic Value rename=(FitStatistic=Statistic));
		ods output FitStatistics = fitStats(keep=FitStatistic Value rename=(FitStatistic=Statistic));
/*		ods output ParameterEstimates = params(drop=_group_ rename=(Component=Variable Probt=PValue));*/
		ods output ComponentSignificance = significance(drop=_group_);
		ods output SeasonDescription=season(keep= Name Type SeasonLength ErrorVar);
		ods output TrendInformation=trend(keep = Name Estimate StdErr);
		ods output CycleDescription=cycle(keep= Name Period Frequency Rho Amplitute CycleVar LevelRatio);
		%if "&outlier." ^= "" %then %do;
			ods output OutlierSummary = outlier(drop=_group_);
			%end;
		ods output ConvergenceStatus = status;
		proc ucm data=dataworking;
			id &dateVar. interval=&dateInterval. align=&dateAlign.;
			model &dependentVariable. = &fixedVars.;
			%if "&irregular." ^= "" %then %do;
				&irregular.;
				%end;
			%if "&level." ^= "" %then %do;
				&level.;
				%end;
			&final_splineStat.
			&final_randomStat.
			%if "&slope." ^= "" %then %do;
				&slope.;
				%end;
			%if "&season." ^= "" %then %do;
				&season.;
				%end;
			&final_cycleStat.
			%if "&autoreg." ^= "" %then %do;
				&autoreg.;
				%end;
			&final_dependentLag.
			%if "&estimate." ^= "" %then %do;
				&estimate. outest=params(drop=_group_ _status_ type rename=(Component=Variable Probt=PValue));
				%end;
			%else %do;
				estimate outest=params(drop=_group_ _status_ type rename=(Component=Variable Probt=PValue));
				%end;
			%if "&forecast." ^= "" %then %do;
				&forecast. outfor=forecast(keep=&dependentVariable. &dateVar. STD forecast residual LCL UCL 
													s_irreg s_autoreg s_level s_slope s_season 
													&keepCycleStat. 
													rename=(LCL=L99 UCL=U99 &dependentVariable. = Actual 
													s_irreg= Irregular s_autoreg=Autoreg s_level=Level 
													s_slope = Slope s_season= Season 
													&renameCycleStat.));
				%end;
			%else %do;
				forecast lead=0 outfor=forecast(keep=&dependentVariable. &dateVar. STD forecast residual LCL UCL 
													s_irreg s_autoreg s_level s_slope s_season 
													&keepCycleStat. 
													rename=(LCL=L99 UCL=U99 &dependentVariable. = Actual 
													s_irreg= Irregular s_autoreg=Autoreg s_level=Level 
													s_slope = Slope s_season= Season 
													&renameCycleStat.));
				%end;
			%if "&outlier." ^= "" %then %do;
				&outlier.;
				%end;
			%if "&optimization." ^= "" %then %do;
				&optimization.;
				%end;
			run;
			quit;
		ods output close;
		ods trace off;


		/*changing the depLag row names*/
		%if "&dependentLag." = "ordered" %then %do;

			data final_estimate(drop=autonumers);
				retain autonumers 0;
				set params;
				if variable = "DepLag" then do;
					autonumers=autonumers+1;
					variable = catx("_",variable,autonumers);
					end;
				run;

			%if "&phi." ^= "" %then %do;
				data DependentLag;
					length phiCol 5.;
					format phiCol 5.;
					length PARAMETER $32.;
					format PARAMETER $32.;
					%do tempi = 1 %to %sysfunc(countw(&phi.," "));
					   phiCol=%scan(&phi.,&tempi.," ");
					   PARAMETER = "%sysfunc(catx(_,Phi,&tempi.))";
					   output;
					%end;
					run;

				proc sort data=params;
					by PARAMETER;
					run;
					quit;

				data final_estimate;
					merge final_estimate(in=a) DependentLag(in=b);
					if a;
					by PARAMETER;
					run;

				data final_estimate(drop= phiCol);
					set final_estimate;
					if substr(variable,1,6) = "DepLag" then do;
						parameter = catx("_","phi",phiCol);
						end;
					run;
				
				%end;
			%end;
		%if "&dependentLag." = "custom" %then %do;
			data DependentLag;
				length lag 5.;
				format lag 5.;
				length phiCol 5.;
				format phiCol 5.;
				length PARAMETER $32.;
				format PARAMETER $32.;
				%do tempi = 1 %to %sysfunc(countw(&lags.," "));
				   lag=%scan(&lags.,&tempi.," ");
				   %if "&phi." ^= "" %then %do;
				      phiCol=%scan(&phi.,&tempi.," ");
					  %end;
				   PARAMETER = "%sysfunc(catx(_,Phi,&tempi.))";
				   output;
				%end;
				run;

				proc sort data=params;
					by PARAMETER;
					run;
					quit;

				data final_estimate;
					merge params(in=a) DependentLag(in=b);
					if a;
					by PARAMETER;
					run;

				data final_estimate(drop= phiCol lag);
					set final_estimate;
					if variable = "DepLag" then do;
						variable = catx("_",variable,lag);
						%if "&phi." ^= "" %then %do;
							parameter = catx("_","phi",phiCol);
							%end;
						end;
					run;
				%end;
			%if "&dependentLag." = "" & %sysfunc(exist(params)) %then %do;
				data final_estimate;
					set params;
					run;
				%end;

		/*preparing component analysis table depending on the selection*/
		%if "&level." ^= "" | "&slope." ^= "" | "&season." ^= "" | "&cycle." ^= "" %then %do;
			data comp_analysis;
				set 
				%if "&level." ^= "" | "&slope." ^= "" %then %do;
				trend 
				%end;
				%if "&season." ^= "" %then %do;
				season
				%end;
				%if "&cycle." ^= "" %then %do;
				cycle 
				%end;
				;
				by name;
				run;
			%end;

		/*Preparing Model Statistics table*/
		data modelStats;
			set fitSummary fitStats;
			if value = . then delete;
			run;

		/*get the normal chart from transformed chart*/
		%if "&dependentTransform." = "log" %then %do;
			data forecast_normal;
				set forecast;
				forecast= exp(forecast);
				actual = exp(actual);
				residual = exp(residual);
				run;

			%plots(forecast_normal,0);
			%plots(forecast,1);

			proc export data = forecast_normal
				outfile = "&outputPath./Forecast_Values.csv"
				dbms = CSV replace;
				run;

			proc export data = forecast
				outfile = "&outputPath./ForecastTransformed_Values.csv"
				dbms = CSV replace;
				run;
			%end;
		%else %do;

			%plots(forecast,0);

			proc export data = forecast
			outfile = "&outputPath./Forecast_Values.csv"
			dbms = CSV replace;
			run;
		%end;


		/*Export the required CSV's	*/
		
		%if %sysfunc(exist(fitSummary)) | %sysfunc(exist(fitStats)) %then %do;
			proc export data = modelStats
				outfile = "&outputPath./Model_Statistics.csv"
				dbms = CSV replace;
				run;
			%end;

		proc export data = significance
			outfile = "&outputPath./Significance.csv"
			dbms = CSV replace;
			run;

		%if %sysfunc(exist(final_estimate)) %then %do;

			/*set flag for time series components*/
			data final_estimate;
				set final_estimate;
				if index(Variable,"Season")>0 | index(Variable,"Cycle")>0 | index(Variable,"Slope")>0 | index(Variable,"Irregular")>0 | index(Variable,"DepLag")>0 | index(Variable,"AutoReg")>0 | index(Variable,"Level")>0 then Type="Component";
				else Type = "Variable";
				run;
			/*add the transformation column for selected fixed variables*/
			%if "&fixedVars." ^= "" %then %do;
				proc sort data=transform;
					by Variable;
					run;

				proc sort data=final_estimate;
					by Variable;
					run;

				data final_estimate;
					merge final_estimate transform;
					by Variable;
					run;
				%end;

			proc export data = final_estimate
				outfile = "&outputPath./ParameterEstimates.csv"
				dbms = CSV replace;
				run;
			%end;

		%if %sysfunc(exist(comp_analysis)) %then %do;
			proc export data = comp_analysis
				outfile = "&outputPath./Component_Analysis.csv"
				dbms = CSV replace;
				run;
			%end;

		%if "&outlier." ^= "" %then %do;
			proc export data = outlier
				outfile = "&outputPath./Outlier.csv"
				dbms = CSV replace;
				run;		
			%end;

		%if %sysfunc(exist(params)) %then %do;
			data _NULL_;
				file "&outputPath./UCM_COMPLETED.txt";
				PUT "UCM - UCM_MODEL_COMPLETED";
				run;
			%end;
		%else %do;
			data _NULL_;
				file "&outputPath./ERROR.txt";
				PUT "Model did not converge for the current selection.";
				run;
			%end;
		%end;
%mend;
%final_UCM;

/*proc datasets kill lib=work;*/
/*	run;*/
/*	quit;*/