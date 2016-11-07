/*Successfully converted to SAS Server Format*/
*processbody;
%let completedTXTPath =  &outputPath/TWEEDIE_COMPLETED.txt;
%let textToReport=;

ods output ParameterEstimates=Est_save_;

/*****************************
Arguments:
	N = claim counts
	W = weight
	Y = response (actual)
	Mu = predicted
	P = custom p value
	Phi = custom Phi value

Function: 
	Tweedie distribution in genmod takes a parameter "p" (1<p<2). 
	The optimal value of p is determined by iterating this process:
	1) Start with a random p
	2) Input genmod output to nlmixed below - it outputs optimised p and phi
	3) Run genmod with optimised p and phi
*****************************/

%let output_path = &outputPath.;

%macro optimizeTweedie;

	/* The following code was obtained from Plymouth Rock and adapted to our functionality */
	ods output ParameterEstimates=tweedie_optimized;
	proc nlmixed data=genmodout;* technique=NEWRAP;
		format p_ 15.6 phi_ 15.6;
		parms p_=&tweedieP. phi_=&tweediePhi.;
		bounds 1<p_<2, phi_>0;
		n_ = &tweedieN.;
		w_ = &weightVariable.;
		y_ = &actual.;
		mu_ = pred;
		t_ = y_*mu_**(1-p_)/(1-p_)-mu_**(2-p_)/(2-p_);
		a_ = (2-p_)/(p_-1);
		if (n_ eq 0) then
		rll_ = (w_/phi_)*t_;
		else
		rll_ = n_*((a_+1)*log(w_/phi_)+a_*log(y_)-a_*log(p_-1)-log(2-p_))
		-lgamma(n_+1)-lgamma(n_*a_)-log(y_)+(w_/phi_)*t_;
		/* log likelihood of (p_,phi_) with mu_ known */
		model y_ ~ general(rll_);
	quit;

	/* Prepare p and phi to be outputted in the completed.txt file */	
	proc sql noprint;
		select estimate into: textToReport separated by " " from tweedie_optimized;
	quit;
	%put p and phi = &textToReport.;

	%exportCsv(libname=work,dataset=tweedie_optimized,filename=TweedieOptimized);
%mend;

%optimizeTweedie;

data _null_;
      v1= "&textToReport.";
      file "&outputPath/TWEEDIE_COMPLETED.txt";
      put v1;
      run;
 
