/*Successfully converted to SAS Server Format*/
*processbody;
    libname in "&input_path.";

ods output members = dataset_list(keep=name);
proc datasets lib = in;
      quit;
      run;

proc export data = dataset_list(keep=name)
      outfile = "&output_path./custom_dataset_list.csv"
      dbms = csv replace;
      run;


proc datasets lib=work kill nolist;
quit;

