*processbody;
/*--------------------------------------------------------------------------------------------------------*/
/*--                                                                                                  	--*/   
/*-- Functionality Name :  factor_analysis        	--*/
/*-- Description  		:  performs factor analysis which is a kind of grouping of similar variables
/*-- Return type  		:  Creates CSV's at a location according to given inputs                        --*/
/*-- Author       		:  Saurabh vikash singh                         --*/                 
/*--------------------------------------------------------------------------------------------------------*/

options mprint mlogic symbolgen mfile;
dm log 'clear';
proc printto log="&outputPath./factor_analysis.log" new;
run;
quit;

%let datasetname=dataworking;
%macro factor;
/*library definition*/
libname in "&inputPath.";
libname out "&outputPath.";


/*parameter play*/
data _null_;
	call symput("minEigenValue",tranwrd("&minEigenValue.","NaN","0"));
	run;
data _null_;
	call symput("method",tranwrd("&method.","Principal Component","PRINCIPAL"));
	run;
data _null_;
	call symput("method",tranwrd("&method.","Iterative Principal Factor","PRINIT"));
	run;
data _null_;
	call symput("method",tranwrd("&method.","Principal Factor","PRINCIPAL"));
	run;
data _null_;
	call symput("method",tranwrd("&method.","Unweighted Least-Squares Factor","ULS"));
	run;
data _null_;
	call symput("method",tranwrd("&method.","Maximum-Likelihood Factor","ML"));
	run;
data _null_;
	call symput("method",tranwrd("&method.","Alpha Factor","ALPHA"));
	run;
data _null_;
	call symput("method",tranwrd("&method.","Harris Component Analysis","HARRIS"));
	run;

/*filtering of data based on given panel and filtering based on validation scenario*/
	data dataworking;
		set in.&datasetname;
		%if "&panelNo." ne "0" %then %do;
		where GRP&panelNo._flag = "&panelFlag.";	
		%end;
		%if "&validationVar." ne "" %then %do;
			%if "&validationType." = "build" %then %do;
			where &validationVar. = 1;
			%end;
			%if "&validationType." = "validation" %then %do;
			where &validationVar. = 0;
			%end;
		%end;		
		run;

/*starting with proc factor statement*/

ods output FactorPattern = factor_pattern;
ods output Eigenvalues = eigen_values;	
%if "&rotationMethod." ne "PROMAX" and "&rotationMethod." ne "PROCRUSTES" %then %do;
ods output OrthRotFactPat = post_rot_factor_pattern;		
%end;
%else %do;
ods output ObliqueRotFactPat= post_rot_factor_pattern;
%end;
%if "&flagResidMatrix." = "true" %then %do;
ods output ResCorrUniqueDiag = resid_corr_matrix; 	
%end;

%if "&flagFactorCorr." = "true" %then %do;
ods output InterFactorCorr = factor_correlation;		
%end;

%if "&flagVariance." ="true" %then %do;
ods output VarExplain = var_exp_by_each_factor;
%end;

%if "&flagFactorScores." = "true" %then %do;	
ods output StdScoreCoef = factor_scores;
%end;
ods output Corr=corr_matrix;
ods output NObs=nobs;

/*ods for MSA and communality estimates*/
%if "&flagmsa." = "true" %then %do;
ods output SamplingAdequacy=SamplingAdequacy;
%end;
ods output PriorCommunalEst= PriorCommunalEst;

%if "&method." = "ML" or "&method." = "ALPHA" %then %do;
ods output FinalCommunWgt=FinalCommun; /*works for ML and alpha*/
%end; 
%else %do;
ods output FinalCommun=FinalCommun;   /*other method of estimation*/
%end;

proc factor data=dataworking
			%if "&numFactors." ne "0" %then %do; 		 
			out=out.outputdata 
			%end;
			%if "&method." ne "" %then %do;
			method= &method.
			%end;
			%if "&priors." ne "" %then %do;
			priors= &priors. 
			%end;
			%if "&minEigenValue." ne "0" %then %do; 
			mineigen=&minEigenValue. 
			%end;
			%if "&numFactors." ne "0" %then %do;
			nfactors=&numFactors.
			%end;
			%if "&rotationMethod." ne "none" %then %do;
			rotate=&rotationMethod.
			%end;
			%if "&rotationIteration." ne "0" %then %do;
			riter=&rotationIteration.
			%end;
			%if "&maxIterations." ne "0" %then %do;
			maxiter=&maxIterations.
			%end;
			%if "&flagUH." = "true" %then %do;
			ULTRAHEYWOOD
			%end;
			%if "&flagMSA." = "true" %then %do;
			MSA
			%end;
			residuals SCORE CORR;
			var &independentVariables.;
run;

/*making of model stats csv*/

data nobs(keep=label N);
	set nobs;
	if _n_=2 or _n_=3;
	run;

proc sql;
	insert into nobs
	set label="Number of factors",
	%if "&minEigenValue." = "0" %then %do; 
	N = &numFactors.;
	%end;
	%else %do;
	N=0;
	%end;


data nobs;
	length label $ 50;
	set nobs;
	format label $50.;
	run;

proc sql;
select sum(eigenvalue) into:sum_ev from eigen_values;
quit;

proc sql;
	insert into nobs
	set label="Total Eigen value for the matrix",
	N = &sum_ev.;


proc sql;
select	avg(eigenvalue) into:avg_ev from eigen_values;
quit;

proc sql;
	insert into nobs
	set label="Average Eigen value for the matrix",
	N = &avg_ev.;

/*cleaning and exporting of the csvs starts here*/

/*Getting the MSA and communality estimates data in shape*/
	%if "&flagMSA." = "true" %then %do;
	proc transpose data=SamplingAdequacy out=SamplingAdequacy;
	run;

	data SamplingAdequacy;
		set SamplingAdequacy;
		rename _NAME_=Variable;
		rename COL1=MSA;
		run;
	%end;
	
	%if %sysfunc(exist(PriorCommunalEst)) %then %do;
	proc transpose data=PriorCommunalEst out=PriorCommunalEst;
	run;
	
	data PriorCommunalEst;
		set PriorCommunalEst;
		rename _NAME_=Variable;
		rename COL1=Communality;
		run;
	
	proc sort data=factor_pattern out=factor_pattern nodupkey;
	by Variable;
	run;

	proc sort data=PriorCommunalEst out=PriorCommunalEst nodupkey;
	by Variable;
	run;

	data factor_pattern;
		merge factor_pattern(in=a) PriorCommunalEst(in=b);
		by Variable;
		if a;
		run;
	%end;
	%if "&method." ne "ML" and "&method." ne "ALPHA" %then %do;
	proc transpose data=FinalCommun out=FinalCommun;
	run;

	data FinalCommun;
		set FinalCommun;
		rename _NAME_=Variable;
		rename COL1=Communality;
		run;
	%end;

	%if %sysfunc(exist(FinalCommun)) & %sysfunc(exist(post_rot_factor_pattern)) %then %do;
	data FinalCommun(keep=Variable Communality);
		set FinalCommun;
		run;
	

	proc sort data=post_rot_factor_pattern out=post_rot_factor_pattern nodupkey;
	by Variable;
	run;

	proc sort data=FinalCommun out=FinalCommun nodupkey;
	by Variable;
	run;

	data post_rot_factor_pattern;
		merge post_rot_factor_pattern(in=a) FinalCommun(in=b);
		by Variable;
		if a;
		run;
	%end;	
	%if "&flagMSA." = "true" %then %do;
		%if %sysfunc(exist(SamplingAdequacy)) %then %do;

		proc sort data=factor_pattern out=factor_pattern nodupkey;
		by Variable;
		run;

		proc sort data=SamplingAdequacy out=SamplingAdequacy nodupkey;
		by Variable;
		run;

		data factor_pattern;
			merge factor_pattern(in=a) SamplingAdequacy(in=b);
			by Variable;
			if a;
			run;

		%if %sysfunc(exist(post_rot_factor_pattern)) %then %do;

		proc sort data=post_rot_factor_pattern out=post_rot_factor_pattern nodupkey;
		by Variable;
		run;

		data post_rot_factor_pattern;
			merge post_rot_factor_pattern(in=a) SamplingAdequacy(in=b);
			by Variable;
			if a;
			run;	
		%end;	

		%end;
		%else %do;
		data factor_pattern;
			set factor_pattern;
			MSA=0;
			run;
		%end;
	%end;
		
	%if "&flagMSA." = "true" %then %do;

	proc sql;
	select sum(MSA) into:sum_msa from factor_pattern;
	quit;


	proc sql;
		insert into nobs
		set label="Total MSA",
		N = &sum_msa.;
	
	%if &sum_msa. = 0 %then %do;
		data factor_pattern(drop=MSA);
			set factor_pattern;
			run;
	%end;	
	%end;
	%else %do;
	proc sql;
		insert into nobs
	set label="Total MSA",
	N = 0;
	%end;



data model_stats;
	set nobs;
	rename label=Statistic;
	rename N=Value;
	run;

/*macro to export the csv*/

%macro export(dataname);
proc export data=&dataname outfile="&outputPath./&dataname..csv" dbms=csv replace;
run;
%mend;


/*model_stats*/
%export(model_stats);

/*factor_pattern*/
%export(factor_pattern);


/*post_rot_factor_pattern*/
%if %sysfunc(exist(post_rot_factor_pattern)) %then %do;
%export(post_rot_factor_pattern);
%end;

/*eigen_values*/

proc sort data=eigen_values out=eigen_values nodupkey;
by Number;
run;

%export(eigen_values);

/*corr_matrix*/
%export(corr_matrix);

/*resid_corr_matrix*/
%if "&flagResidMatrix." = "true" %then %do;
%export(resid_corr_matrix);
%end;
/*factor_correlation*/
%if "&flagFactorCorr." = "true" %then %do;
%if %sysfunc(exist(factor_correlation)) %then %do;
%export(factor_correlation);
%end;
%end;
/*var_exp_by_each_factor*/
%if "&flagVariance." ="true" %then %do;
%if %sysfunc(exist(var_exp_by_each_factor)) %then %do;
proc transpose data=var_exp_by_each_factor out=var_exp_by_each_factor; 
%if "&rotationMethod." = "PROMAX" and "&rotationMethod." = "PROCRUSTES" %then %do;
data var_exp_by_each_factor(rename=(_NAME_=Factors COL1=Prior_rotation COL2=Varimax COL3=Promax_elim_oth_factors COL4=Promax_ignore_oth_factors));
	set var_exp_by_each_factor;
	run;
%end;
%else %do;
data var_exp_by_each_factor(rename=(_NAME_=Factors COL1=Prior_rotation COL2=Post_rotation));
	set var_exp_by_each_factor;
	run;
%end;
%export(var_exp_by_each_factor);
%end;
%end;
/*factor_scores*/
%if "&flagFactorScores." = "true" %then %do;	
%export(factor_scores);
%end;
	ods graphics on/ width=20in height=20in;
	ods listing;
	filename image "&outputPath./scree.png";
	goptions reset=all border cback=white htitle=12pt htext=10pt device = pngt gsfname=image gsfmode=replace;
	symbol1 interpol=join font="Monotype Sorts" value="s" color=orange height=1;                                                                         
	legend1 label=none frame;                                                                                                               
	axis1 label=(angle=90 'Eigenvalue');
	axis2 label=('Number');

	proc gplot data= eigen_values;
		plot eigenvalue*number/vaxis=axis1 haxis=axis2;
		run;

	ods listing close;
	ods graphics off;
                                                                                                                                                                                                                                                                        
%mend;
%factor;

data _NULL_;
		v1= "Factor analysis completed";
		file "&outputPath./FACTOR_ANALYSIS_COMPLETED.txt";
		PUT v1;
	run;	