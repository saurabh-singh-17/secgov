/*Successfully converted to SAS Server Format*/
*processbody;
%let completedTXTPath =  &outputPath/bygroupupdate_COMPLETED.txt;
%let textToReport=;

%macro bygroupupdate;
	  /*bygroupdata updation*/
	proc sort data = in.dataworking out = in.dataworking;
	      by primary_key_1644;
	      run;

	proc sort data = &datasetName. out = &datasetName.;
	      by primary_key_1644;
	      run;

	data &datasetName.;
	      merge &datasetName.(in=m_u_s_i_g_m_a) in.dataworking(in=m_u_s_i_g_m_b);
	      by primary_key_1644;
	      if m_u_s_i_g_m_a;
	      run;
	%let textToReport=&textToReport. By group data updated;
%mend;

%bygroupupdate;

data _null_;
      v1= "&textToReport.";
      file "&outputPath/bygroupupdate_COMPLETED.txt";
      put v1;
      run;