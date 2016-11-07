/*Successfully converted to SAS Server Format*/
*processbody;
options mprint mlogic symbolgen mfile ;

%let correlationfilename = &output_path./correlation.xml;
%let factorfilename = &output_path./factor.xml;
%let completedTXTPath = &output_path./CORRELATION_AND_FACTOR_ANALYSIS.txt;

libname in "&input_path.";
libname group "&group_path." ;
libname out "&output_path.";

proc means data = group.bygroupdata;
	var &independent_variables. ;
	output out = means;
run; quit;

proc transpose data = means out = variablelist(keep = _name_);
	var &independent_variables. ;
run; quit;

data variablelist;
	set variablelist;
	rename _name_ = name;
run;

data correlation ;
	length variable $31. ;
	variable = "abc";
	corr_with_dep = 0.7;
	prob = 0.7;
run;


%macro factor();
	ods	output RSquare = R_Sq;
		proc varclus data= group.bygroupdata  maxclusters= 30;
			var &independent_variables. ;
		run; quit;

	data ClusterResultspre ; 
		set R_Sq; 
		where NumberOfClusters = &numberofclusters.;
	run;

	data ClusterResults;
		set ClusterResultspre;
		format cluster1 $30.;
		retain cluster1;
		if cluster ^= '' then cluster1 = cluster;
	run;

	proc sort data = ClusterResults; by cluster1 RSquareRatio;
	run; quit;

	data cluster_count;
		length variable $31. ;
		set ClusterResults(keep = cluster1 variable owncluster RSquareRatio);
		by cluster1;
		retain count;
		if first.cluster1 then count = 1;
		else count = count + 1;
	run;

	proc sql;
		create table cluster_prefinal as
		select * , max(count) as cnt from cluster_count 
		group by cluster1;
	quit;

	proc sort data = cluster_prefinal; by descending cluster1 owncluster; 
	run; quit;

		data cluster_final(keep = variable flag cluster1 RSquareRatio);
		length flag $10.;
		set cluster_prefinal;
		if (count <= int(cnt*&toppercenttoretain.)) then do;
			flag = "true";
		end;
		else do;
			flag = "false";
		end;
	run; 
	data getcorrelation_dataset;
		set group.bygroupdata;
	run;

	data _NULL_;
		set variablelist;
		call execute ('%getcorrelation(variable='||name||');');
	run; 
	
	data correlation;
		set correlation;
		keep variable corr_with_dep;
	run;

	data cluster_final;
		set cluster_final;
		rename cluster1 = group;
		rename rsquareratio = rsqratio;
	run;

	proc sort data = cluster_final; by variable; run; quit;
	proc sort data = correlation; by variable; run; quit;
	data cluster_final;
		merge cluster_final(in=a) correlation(in=b);
		by variable;
		if a or b;
	run;

	proc append base = out.cluster_finalwithbyvar data = cluster_final force;
	run; quit;

	data _NULL_;
		call execute ('%factor_xml;');
	run;
%mend factor;

%macro correlation();
	data correlation ;
		length variable $31. ;
		variable = "abc";
		corr_with_dep = 0.7;
		prob = 0.7;
	run;
	data getcorrelation_dataset;
		set group.bygroupdata;
	run;

	data _NULL_;
		set variablelist;
		call execute ('%getcorrelation(variable='||name||');');
	run; 

	data correlationfinal;
		set correlation(drop = prob);
		length flag $10. ;
		cutoff = "&correlationcutoff." ;
		if (abs(corr_with_dep) < &correlationcutoff.) then do;
			flag = "false";
		end;
		else do;
			flag = "true";
		end;
		rename corr_with_dep = coefficient; 
	run;
	proc append base = out.correlationfinalwithbyvar data = correlationfinal force;
	run; quit;

	data _NULL_;
		call execute ('%correl_xml;');
	run;
%mend correlation;

%macro getcorrelation(variable=);
	ods output pearsoncorr = correl;
	    proc corr data = getcorrelation_dataset;
	          var &variable. ;
	          with &dependent_variable.;
		run; quit;
		data correl;
			set correl;
			rename &variable. = corr_with_dep;
			rename P&variable. = prob;
		run;
		data correl;
			length variable $31. ;
			set correl;
			variable = "&variable." ;
		run;
	proc append base = correlation data = correl force;
	run; quit;
%mend getcorrelation;
 

%macro runfactorcorr;
	
/*Check by_flag which is passed is numeric variable so the value passed should be numeric*/ 
	%if ("&factor." = "true") %then %do;
		 %factor();
	
	%end;
/*Check by_flag which is passed is numeric variable so the value passed should be numeric*/
	%if ("&correlation." = "true") %then %do;
	%correlation();
	%end;
%mend runfactorcorr;

/*Initializing datasets*/
	data out.correlationfinalwithbyvar;
		length variable $31.;
		length flag $10. ;
		variable = "abc";
		coefficient = 25;
		cutoff = "&correlationcutoff." ;
		by_flag = 25;
		flag = "false";
	run;
	data out.cluster_finalwithbyvar;
		length variable $31.;
		length group $30.;
		length flag $10.;
		by_flag = 25;
		variable = "abc";
		group = "abc";
		flag = "true";
		rsqratio = 25;
		corr_with_dep = 25;
	run;
/*Putting the output datasets in xmls for flex to use*/
%macro factor_xml;
		libname outfac xml "&factorfilename.";
		data outfac.factor;
	        set out.cluster_finalwithbyvar;
			if Variable = "abc" then delete;
		run;
%mend factor_xml;
%macro correl_xml;
		libname outcorr xml "&correlationfilename.";
		data outcorr.correlation;
	        set out.correlationfinalwithbyvar;
			if Variable = "abc" then delete;
		run;
%mend correl_xml;	
data _NULL_;
	call execute('%runfactorcorr;');
run;
/* Flex uses this file to test if the code has finished running */
data _null_;
	v1= "Linear Regression - CORRELATION AND FACTOR ANALYSIS process completed";
	file "&output_path./CORRELATION_AND_FACTOR_ANALYSIS.txt";
	PUT v1;
run;

endsas;
