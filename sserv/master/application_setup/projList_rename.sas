/*-----------------------------------------------------------------------------------------
Parameters Required
-----------------------------------------------------------------------------------------*/
/*%let input_path=/data22/IDev/Mrx;*/
/*%let project_path=/data22/IDev/Mrx/projects;*/
/*%let projectid=1234;*/
/*%let projectname=onesdf-26-jul-2-13-2-2-3;*/
/*%let newprojectname=adadsasddafads-26-jul-2-13-2-2-3;*/
/*-----------------------------------------------------------------------------------------*/


*processbody;

options mprint mlogic symbolgen;

/*-----------------------------------------------------------------------------------------
Macro to rename a project in SAS Server
Needs:
	projectID
	newprojectname
Assumptions:
	&input_path. exists and project.csv already exists in &input_path.
-----------------------------------------------------------------------------------------*/
%macro renameproject;
/*-----------------------------------------------------------------------------------------
Rename the project folder
-----------------------------------------------------------------------------------------*/
data _null_;
	renamerc=rename("&project_path./&projectname.","&project_path./&newprojectname.","file");
	call symput("renamerc",renamerc);
run;
/*-----------------------------------------------------------------------------------------*/



/*-----------------------------------------------------------------------------------------
If the folder name already exists write error txt and abort
-----------------------------------------------------------------------------------------*/
%if &renamerc. = 1 %then
	%do;
		data _null_;
			v1= "Folder name already exists.";
			file "&project_path./projList_rename_error.txt";
			put v1;
		run;
		
		proc datasets lib=work kill nolist;
		quit;

		%abort;
	%end;
%else
	%do;
		/*-----------------------------------------------------------------------------------------
		Read project.csv from &input_path.
		-----------------------------------------------------------------------------------------*/
		data project;
			infile "&input_path./project.csv" delimiter = ',' MISSOVER DSD lrecl=32767 firstobs=2;
			informat projectId best32. projectName $50.userName $30. userAccount $30. workspace $2000.;
			format projectId best12. projectName $50. userName $30. userAccount $30. workspace $2000.;
			input projectId projectName $ userName $ userAccount $ workspace $;
		run;
		/*-----------------------------------------------------------------------------------------*/



		/*-----------------------------------------------------------------------------------------
		Rename the project
		-----------------------------------------------------------------------------------------*/
		data project;
			set project;
			if projectid = &projectid. then projectname="&newprojectname.";
		run;
		/*-----------------------------------------------------------------------------------------*/



		/*-----------------------------------------------------------------------------------------
		Export project.csv to &input_path.
		-----------------------------------------------------------------------------------------*/
		proc export data = project outfile = "&input_path./project.csv" dbms = csv replace;
		run;
		quit;
		/*-----------------------------------------------------------------------------------------*/

		data _null_;
			v1= "Project successfully renames.";
			file "&input_path./projList_rename_completed.txt";
			put v1;
		run;
		
		proc datasets lib=work kill nolist;
		quit;
	%end;
/*-----------------------------------------------------------------------------------------*/
%mend renameproject;
/*-----------------------------------------------------------------------------------------*/
%renameproject;