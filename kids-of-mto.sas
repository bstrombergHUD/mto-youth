/*Indivs born after random assignment that live in households headed by MTO partcipants.*/
/* This includes both hohs are the time of RA and new_hohs that became heads of household
after the conclusion of MTO. */
/* MTO heads of household have PPID that end in 01. SSNs match through best_ssn.*/
%let year = 2017;
/*****************************************************************************************************/
/* First we create the dataset of heads of households based on the last two digits of the PPID */
data mto_not_hohs;
	set mto.best_ssn;
	where substr(ppid, 9,2) ne "01";
run;

proc sort data=mto_hohs out=mto_hohs_sort(rename=(ssn=ssn_head));
	by ssn;
run;

/* Second, we find the individuals that have a birthday that is later than 12/31/1997 from the desired longitudinal file. */
data mem_post1997;
	set long.mem_long_ssns_&year.;
	where input(substr(mbr_dob,1,4), best8.) > 1997; /* Converts the year from the string into a number and checks if it's more than 1997 (all births after 1997). */
run;

proc sort data=mem_post1997 out=mem_post1997_yearsort; /* Sorted by the date, year coming first. Easy to check if the selection was done right. */
	by mbr_dob;
run;

proc sort data=mem_post1997;
	by head_id;
run;

/* Attach the ssn_head variable using the ssn_aid crosswalk */

data mem_post1997_heads;
	merge mem_post1997(in=mem) long.ssn_aid;
	by head_id;
	if mem;
run;

proc sort data=mem_post1997_heads;
by ssn_head;
run;

/* mto_hohs_kids includes all HUD residents from the chosen longitudinal file that were born after 1997 to households where head of household were MTO participants. */
data mto.mto_hohs_kids_&year.(rename=(ppid=head_ppid) keep=ppid ssn_head ssn_mem mbr_id head_id mbr_dob mbr_age_yr_cnt birth_year kid_count);
	merge mto_hohs_sort(in=mto) mem_post1997_heads(in=post);
	by ssn_head;
	birth_year = input(substr(mbr_dob,1,4), best8.);
	kid_count = 1;
	if mto and post;
run;

/* Sum the number of kids the individuals had since 1997. */

proc means data=mto.mto_hohs_kids_&year. noprint nway;
	class head_ppid;
	var kid_count;
	output out=mto.mto_kids_tots_&year.(drop= _TYPE_ _FREQ_) sum=;
run;
