/*Successfully converted to SAS Server Format*/
*processbody;
/*Code: Scoring Logistic*/
/*Author: Subarna Rana */	


options mprint mlogic symbolgen mfile;

proc printto log="&outputPath./Scoring.log";
run;
quit;
      
/*proc printto print="&outputPath./Scoring.out";*/
      

dm log 'clear';
libname in "&inputPath.";
libname group "&groupPath.";
libname out "&outputPath.";

%let output_path = &outputPath.;
/*%let nonevent="";*/
/*%macro event_nonevent;*/
/*	proc sql;*/
/*	select distinct(&dependentvariable.) into:nonevent separated by "," from out.scored where &dependentvariable <> &event.;*/
/*	quit;*/
/*	%put &nonevent;*/
/* %mend;*/
	

%macro exportCsvscl(libname=,dataset=,filename=);
	proc export data=&libname..&dataset.
    outfile="&outputPath./&filename..csv"
    dbms=csv replace;
    run;
%mend;

%MACRO scoring_logistic;
libname model "&modelpath.";
	/*Get the inmodel*/
	data out.in_model;
		set model.out_model;
			%if "&modifiedintercept" ^= "" %then %do;
				if _name_ = "Intercept" then _misc_ = %sysevalf(&modifiedintercept);
			%end;
			run;

	/* SCORING */
	%if "&flagactualVar." = "true" %then %do;
		%let dsid = %sysfunc(open(in.dataworking));
		      %let varnumx = %sysfunc(varnum(&dsid,&dependentvariable));
		      %let typ_dep = %sysfunc(vartype(&dsid,&varnumx)); 
		      %let rc = %sysfunc(close(&dsid));
	%end;
	proc logistic inmodel= out.in_model(type=logismod);
		score data=&datasetname. %if "&validationvar" ^= "" %then %do; (where=(&validationvar = 0)) %end;
		out=out.scored outroc=ROC clm fitstat ;
		run;
%mend;
%scoring_logistic;
/*%event_nonevent;*/



%macro post_scoring;
	
	%if "&flagactualVar." = "true" %then %do;
		%if "&flagctable." = "true" %then %do;
			data ctable(rename=(_PROB_=ProbLevel _POS_=CorrectEvents _NEG_=CorrectNonevents
									_FALPOS_=IncorrectNonevents _FALNEG_=IncorrectEvents 
										_SENSIT_=Sensitivity _1MSPEC_=one_minus_specificity));
				set roc;
				run;
			%exportCsvscl(libname = work,dataset =  ctable, filename = classification_table);
		%end;
		%if "&flagroc1." = "true" %then %do;
			data ROC1;
				retain ONE_MINUS_SPECIFICITY;
				set ROC(drop=_POS_ _NEG_ _FALPOS_ _FALNEG_ _PROB_ rename=(_1MSPEC_=ONE_MINUS_SPECIFICITY _sensit_=SENSITIVITY));
				run;
			%exportCsvscl(libname = work,dataset =  roc1, filename = roc1);
		%end;
		%if "&flagrocs." = "true" %then %do; 
			data ROC_S (drop = ONE_MINUS_SPECIFICITY);
				set ROC (drop=_POS_ _NEG_ _FALPOS_ _FALNEG_ rename=(_1MSPEC_=ONE_MINUS_SPECIFICITY _sensit_=SENSITIVITY));
				SPECIFICITY = 1 - ONE_MINUS_SPECIFICITY;
				run;
			%exportCsvscl(libname = work,dataset =  roc_s, filename = roc_s);
		%end;
	%end;

/*$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$*/
/*KS TEST*/

	%if %index("&dependentvariable.",/) = 0 %then %do;
	    %if &flagLift. = true or &flagGains. = true %then %do;

			data _null_;
		call symput("x_event", tranwrd("&event.","/","_"));
		run;
		data _null_;
		call symput("x_event", tranwrd("&x_event."," ","_"));
		run;
	
	
		data ks_main;
	              set out.scored (keep=p_&x_event. &dependentVariable. XXXind_logit);
	              V_GOOD=XXXind_logit;
	              V_BAD=1-XXXind_logit;
	              run;

	        proc rank data=ks_main out=ks_rankpred groups=%eval(&numGrps.) descending;
	              var p_&x_event.;
	              ranks rank_pred;
	              run;

	        proc sort data = ks_rankpred;
	              by rank_pred;
	              run;

	        proc means data=ks_rankpred noprint;
	              var p_&x_event. V_BAD;
	              by rank_pred;
	              output out=ks_means mean=mean badrate min=minimum minbad max=maximum maxbad;
	              run;

	        proc freq data=ks_rankpred noprint;
	              table rank_pred / out=ks_freq_weighted;
	              weight V_BAD;
	              run;

	        proc freq data=ks_rankpred noprint;
	              table rank_pred / out=ks_weightedFreq_good;
	              weight V_GOOD;
	              run;

	        proc freq data=ks_rankpred noprint;
	              table rank_pred / out=ks_Freq;
	              run;

	        data ks_freqs;
	              merge ks_freq_weighted(rename=(percent=percent_bad count=count_bad))
	                    ks_weightedFreq_good(rename=(percent=percent_good count=count_good))
	                    ks_Freq(rename=(count=count_accts))
	                    ks_means(keep=rank_pred mean badrate minimum maximum);
	                    by rank_pred;
	                    run;

	        data ks_freqs;
	              set ks_freqs end = final;
	                    total_accts+count_accts;
	                    if final then call symput('sum_accts',total_accts);
	              		run;

	        data ks_cumm; 
	              set ks_freqs;
	              cumm_bad+count_bad;
	              cumm_good+count_good;
	              cumm_accts+count_accts;
	              cumm_perc_bad+percent_bad;
	              cumm_perc_good+percent_good;
	              cumm_bad_rate=cumm_bad/cumm_accts;
	              cumm_good_rate=cumm_good/cumm_accts;
	              cumm_accts_rate=cumm_accts/&sum_accts;
	              ks_mv=((count_bad-count_accts*mean) * (count_bad-count_accts*mean))/ (count_accts*mean*(1-mean));
	              cumm_gof+ks_mv;
	              ks_bdgd = ABS(cumm_perc_bad - cumm_perc_good) ;
	              group=_n_;
	              run;

	        data ks_inter; 
	              set ks_cumm (keep = group rank_pred badrate mean minimum maximum cumm_bad cumm_perc_bad cumm_accts cumm_bad_rate cumm_gof ks_bdgd);
	              run;

	        proc transpose data = ks_inter out = ks_inter_trans;
	              run;

	        data ks (rename=(ks_bdgd = ks group = max_ks_dec));
	              set ks_inter (keep = ks_bdgd group);
	              run;

	        proc sort data = ks ;
	              by descending ks;
	              run;

	        data ks; 
	              set ks (obs = 1);
	              format ks 8.2; 
	              run;

	        data ks_gof (rename=(cumm_gof = gof));
	              set ks_inter (keep = cumm_gof);
	              run;

	        proc sort data = ks_gof; 
	              by descending gof;
	              run;

	        data ks_gof;
	              set ks_gof (obs = 1);
	              format gof 8.2; 
	              run;

	        data ks_inter (keep = group rank_pred cumm_accts pred_resp act_resp minimum maximum cumm_respr cumresp pctresp ks gof);
	              set ks_inter;
	              pred_resp = mean*100; format pred_resp 8.2;
	              act_resp = badrate*100; format act_resp 8.2;
	              cumm_respr = cumm_bad_rate*100;format cumm_respr 8.2;
	              format minimum 8.3 maximum 8.3 cumm_perc_bad 8.2 ks_bdgd 8.2 cumm_gof 8.2;
	              rename cumm_bad = cumresp cumm_perc_bad = pctresp ks_bdgd = ks cumm_gof = gof;
	              run;


	        data ks_order (keep=_name_ order_flag ranking sat_rank rename=(_name_=attribute)); 
	              set ks_inter_trans; 
	              where lowcase(_NAME_) = 'badrate';
	              order_flag = 0;
	              %do i = 1 %to &numGrps. - 1;
		              %let j = %eval(&i + 1);
		                    order_flag = order_flag + (col&i lt col&j);
		          %end ;
	              if order_flag gt 0 then ranking = 'NOT SATISFACTORY'; 
	                    else ranking = 'SATISFACTORY';
	              sat_rank = 'ALL';
	              %do i = 1 %to &numGrps. - 1;
		              %let j = %eval(&i + 1);
	                    if ((col&i lt col&j) and (sat_rank = 'ALL')) then sat_rank = "&i";
	              %end;
	              run;

	        data out.ks_rep; 
	              merge ks_order ks ks_gof;
	              run;

	        data out.ks_out;
	              merge ks_inter(in=a drop=group) ks_freqs(in=b drop=mean badrate minimum maximum total_accts);
	              by rank_pred;
	              if a or b;
	              run;

	        data out.ks_out(rename=(count_bad=count_events percent_bad=percent_events count_good=count_nonevents 
	                                            percent_good=percent_nonevents));
	              retain rank_pred count_bad percent_bad count_good percent_good count_accts percent_accts cumm_accts pred_resp act_resp
	                          minimum maximum cumm_respr cumresp pctresp ks gof;
	              set out.ks_out(rename=(percent=percent_accts));
	              attrib _all_ label="";
	              run;
	        
	        data out.ks_out (drop = abcd);
	              set out.ks_out;
	              abcd = (pctresp + lag(pctresp))/100;
	              if _n_ = 1 then abcd = pctresp/100;
	              gini = (0.05*abcd);
	              run;

	        proc sql;
	              create table gini as
	              select (2*sum(gini) - 1) as gini from out.ks_out;
	              quit;

	        data out.ks_rep;
	              merge out.ks_rep(in=a) gini(in=b);
	              if a or b;
	              run;

			proc sql;
				create table out.ks_rep as
				select attribute,order_flag,ranking,sat_rank, max_ks_dec,ks,gof
				from out.ks_rep;
				quit;




			%exportCsvscl(libname=out,dataset= ks_rep,filename= ks_rep);
			%exportCsvscl(libname=out,dataset= ks_out,filename= ks_out);

	/*..............................LIFT AND GAINS CHART..............................*/

			data lift (keep = percent_customers base cumulative_lift individual_lift);
			      retain percent_customers base cumulative_lift individual_lift;
			      set out.ks_out;
			      percent_customers = (rank_pred + 1)*10;
			      base = 1;
			      cumulative_lift = pctresp/percent_customers;
			      individual_lift = percent_events/10;
			      run;

	    %exportCsvscl(libname=work,dataset= lift,filename=lift);
		
	          data gains (keep = percent_customers random percent_positive_response);
	               retain percent_customers random percent_positive_response;
	               set out.ks_out;
	               percent_customers = (rank_pred + 1)*10;
	               random = percent_customers;
	               rename pctresp = percent_positive_response;
	               run;

	    %exportCsvscl(libname=work,dataset= gains,filename=gains);
	%end;
%end;

%if %index("&dependentvariable.",/) ne 0 %then %do;
	%let dependentvariable1=TRIALSind_logit;
%end;
	
/*	/*PREDICTED V/S ACTUAL CHARTS*/
%if "&flagactpred." = "true" %then %do;
	%if %index("&dependentvariable.",/) = 0 %then %do;
	 proc rank data = out.scored out = testpred (keep =  deciles p_&event. F_&dependentvariable. rename = (p_&event. = predicted)) Groups = %sysevalf(&numGrps.) descending ;
			var p_&event.;
            ranks deciles;
            run;

        proc sort data = testpred;
            by deciles;
            run;
		
        proc sql;
            create table predicted_actual as
            select deciles, avg(predicted)*100 as predicted, (sum(CASE WHEN F_&dependentvariable= "&event."  THEN 1 ELSE 0 END)/count(*))*100 as actual
            from testpred
            group by deciles;
            quit;

        proc sql;
            create table predicted_actual as
            select deciles, predicted, actual, avg(actual) as average_rate, (predicted/actual) as pred_by_actual
            from predicted_actual
            quit;
		%end;
		%if %index("&dependentvariable.",/) ne 0 %then %do;
		proc rank data = out.scored out = testpred (keep =  deciles p_Event &dependentvariable1. rename = (p_Event = predicted)) Groups = %sysevalf(&numGrps.) descending ;
			var p_Event;
            ranks deciles;
            run;

        proc sort data = testpred;
            by deciles;
            run;
	
		proc sql;
	    	create table predicted_actual as
	    	select deciles, avg(predicted)*100 as predicted,avg(TRIALSind_logit)*100  as actual
	        from testpred
	        group by deciles;
	        quit;
	    proc sql;
	        create table predicted_actual as
	        select deciles, predicted, actual, (predicted/actual) as pred_by_actual
	        from predicted_actual
	        quit;
		%end;
	%exportCsvscl(libname=work,dataset= predicted_actual,filename= predicted_actual);



	/*AVERAGE CHURN RATE*/
	 proc sql;
          create table average_rate as
          select avg(actual) as average_rate
          from predicted_actual;
          quit;
	%exportCsvscl(libname=work,dataset=average_rate,filename= average_rate);
%end;

%MEND;
%post_scoring;

/* flex uses this file to test if the code has finished running */
data _null_;
	v1= "SCORING_LOGISTIC_COMPLETED";
	file "&outputpath/SCORING_LOGISTIC_COMPLETED.txt";
	put v1;
	run;


/*ENDSAS;*/






