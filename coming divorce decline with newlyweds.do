/* data is from IPUMS.org. It's free and open so you can go get info on the data and variables there */

* NOTE: You need to set the Stata working directory to the path
* where the data file is located.

set more off

clear
quietly infix              ///
  int     year      1-4    ///
  byte    statefip  5-6    ///
  double  perwt     7-16   ///
  byte    sex       17-17  ///
  int     age       18-20  ///
  byte    marst     21-21  ///
  byte    marrno    22-22  ///
  int     yrmarr    23-26  ///
  byte    divinyr   27-27  ///
  byte    hispan    28-28  ///
  byte    citizen   32-32  ///
  byte    racamind  33-33  ///
  byte    racasian  34-34  ///
  byte    racblk    35-35  ///
  byte    racpacis  36-36  ///
  byte    racwht    37-37  ///
  int     educd     40-42  ///
  using "C:\Users\pnc\Downloads\usa_00388.dat"
    
/* sample is 2008-2017 American Community Surveys, women age 15+ who have ever
   been married and lived in the US one year before the survey */

keep if marst<4 | divinyr==2 /* currently married or divorced in previous year */
gen divorced = divinyr==2
drop divinyr

replace perwt   = perwt   / 10000

format perwt   %10.2f

label var perwt   "Person weight"
label var sex     "Sex"
label var age     "Age"
label var marst   "Marital status"
label var yrmarr  "Year married"

label define sex_lbl 1 "Male"
label define sex_lbl 2 "Female", add
label values sex sex_lbl

label define marst_lbl 1 "Married, spouse present"
label define marst_lbl 2 "Married, spouse absent", add
label define marst_lbl 3 "Separated", add
label define marst_lbl 4 "Divorced", add
label define marst_lbl 5 "Widowed", add
label define marst_lbl 6 "Never married/single", add
label values marst marst_lbl

gen yrsmar = year-yrmarr
keep if yrsmar>0  /* <-- I didnt do this in past blog post rates, so they arent comparable. its to get rid of marriages that might be after the divorce */

gen ageatmar = age-yrsmar

gen female = sex==2
drop sex
gen age2 = age*age
gen yrsmar2 = yrsmar*yrsmar

gen hispanic=hispan>0
gen foreign = citizen>0
drop citizen

gen wnhisp = (hispan==0 & racwht==2 & racamind==1 & racasian==1 & racpacis==1 & racblk==1)

gen rac3 = 4
replace rac3 = 1 if wnhisp==1
replace rac3 = 2 if racblk==2
replace rac3 = 3 if hispanic==1

label define rac3_lbl 1 "White NH"
label define rac3_lbl 2 "Black", add
label define rac3_lbl 3 "Hispanic", add
label define rac3_lbl 4 "Other", add
label values rac3 rac3_lbl

recode age (16/34=1) (35/44=2) (45/54=3) (55/100=4), gen(agecat)

label define agecat_lbl 1 "<35"
label define agecat_lbl 2 "35-44", add
label define agecat_lbl 3 "45-54", add
label define agecat_lbl 4 "55+", add
label values agecat agecat_lbl

recode educd (0/61=1)(62/65=2) (70/100=3) (101/116=4), gen(edcat)

label define edcat_lbl 1 "<HS"
label define edcat_lbl 2 "HS", add
label define edcat_lbl 3 "Some col", add
label define edcat_lbl 4 "BA+", add
label values edcat edcat_lbl

*sum

/* make 1% test sample
gen temp = runiform()
gen test = temp<.001
drop temp
*/


/* Table 1 */
/* couple things just for the descriptive tab... don't mind me while I multiply and divide weights by constants */
gen intwt=int(100*perwt)
recode yrsmar (1/9=1) (10/19=10) (20/29=20) (30/90=30), gen(yrmrcat) /* <-- just for the table */
tab1 divorced year agecat yrmrcat marrno foreign edcat rac3 [weight=intwt]

/* Table 2 */
logit divorced i.year age age2 yrsmar i.marrno foreign i.edcat i.rac3 [pweight=perwt]
margins year

/* these are referenced in the paper but only age is presented */

* by age
logit divorced i.year##i.agecat yrsmar i.marrno foreign i.edcat i.rac3 [pweight=perwt]
margins i.year##i.agecat

* by race
logit divorced i.year##i.rac3 age age2 yrsmar i.marrno foreign i.edcat [pweight=perwt]
margins i.year##i.rac3

* by parity
logit divorced i.year##i.marrno age age2 yrsmar foreign i.edcat i.rac3 [pweight=perwt]
margins i.year##i.marrno

* by education
logit divorced i.year##i.edcat age age2 yrsmar i.marrno foreign i.rac3 [pweight=perwt]
margins i.year##i.edcat

/* for newlywed prediction formula */

/* Table 3
   Generate coefficients to apply to the newlywed sample, to predict their divorce risk. 
   This replaces yrsmar with ageatmar to produce an age coefficient for newlyweds.
   It runs on marriages in their first 10 years (<10yrsmar), for 2017 only
*/

logit divorced ageatmar i.marrno i.foreign i.edcat i.rac3 if yrsmar<10 & year==2017 [pweight=perwt]
/* this is the result:
(	ageatmar    *	-0.0288146	) +	 ///
(	(marrno==2) *	0.7183058	) +	 ///
(	(marrno==3) *	1.200373	) +	 ///
(	foreign     *	-0.3029773	) +	 ///
(	(edcat==2)  *	0.1340403	) +	 ///
(	(edcat==3)  *	0.1314363	) +	 ///
(	(edcat==4)  *	-0.2955606	) +	 ///
(	(rac3==2)   *	0.375711	) +	 ///
(	(rac3==3)   *	-0.0977494	) +	 ///
(	(rac3==4)   *	-0.098973	) 	 ///
	-2.979024		
*/

   
/* Analysis of selection into marriage and associated marriage risk, 2008-2017 */

* NOTE: You need to set the Stata working directory to the path
* where the data file is located.

set more off

clear
quietly infix              ///
  int     year       1-4    ///
  double  perwt      5-14   ///
  byte    sex        15-15  ///
  int     age        16-18  ///
  byte    marrno     19-19  ///
  byte    marrinyr   20-20  ///
  byte    race       21-21  ///
  int     raced      22-24  ///
  byte    hispan     25-25  ///
  int     hispand    26-28  ///
  byte    citizen    29-29  ///
  byte    educ       30-31  ///
  int     educd      32-34  ///
  int     age_sp     35-37  ///
  byte    marrno_sp  38-38  ///
  byte    race_sp    39-39  ///
  byte    hispan_sp  40-40  ///
  int     educd_sp   41-43  ///  
  using "C:\Users\pnc\Downloads\usa_00400.dat"

/*  2008-2017 ACS, sample is women who married in the year before the survey. */

/*  The _sp variables are her spouse's characteristics (regardless of spouse gender)
    I don't use the in the paper anymore but they were used in the earlier versions so I'm leaving them in */

replace perwt    = perwt    / 100
format perwt    %10.2f

gen foreign = citizen>0

label var year     "Survey year"
label var perwt    "Person weight"
label var age      "Age"
label var marrno   "Times married"
label var race     "Race [general version]"
label var hispan   "Hispanic origin [general version]"
label var educd    "Educational attainment [detailed version]"

recode educd (0/61=1)(62/65=2) (70/100=3) (101/116=4), gen(edcat)

label define edcat_lbl 1 "<HS"
label define edcat_lbl 2 "HS", add
label define edcat_lbl 3 "Some col", add
label define edcat_lbl 4 "BA+", add
label values edcat edcat_lbl

gen rac3=4
replace rac3=1 if race==1 & hispan==0
replace rac3=2 if race==2 
replace rac3=3 if hispan>0

label define rac3_lbl 1 "White NH"
label define rac3_lbl 2 "Black", add
label define rac3_lbl 3 "Hispanic", add
label define rac3_lbl 4 "Other", add
label values rac3 rac3_lbl

/* in the previous draft I made an arbitrary divorce risk scale. This is a little more scientific, based on the regression above. */

	gen divcoef = 			         ///
(	age         *	-0.0288146	) +	 ///
(	(marrno==2) *	0.7183058	) +	 ///
(	(marrno==3) *	1.200373	) +	 ///
(	foreign     *	-0.3029773	) +	 ///
(	(edcat==2)  *	0.1340403	) +	 ///
(	(edcat==3)  *	0.1314363	) +	 ///
(	(edcat==4)  *	-0.2955606	) +	 ///
(	(rac3==2)   *	0.375711	) +	 ///
(	(rac3==3)   *	-0.0977494	) +	 ///
(	(rac3==4)   *	-0.098973	) 	 ///
            		-2.979024		

gen divprob  = exp(divcoef)/(1+exp(divcoef)) /* convert coefs into probabilities */

/* to test linear trend */
reg divprob year [weight=perwt]


/* to plot means with error bars (this is the same as doing: mean divprob, over(year))*/
reg divprob i.year [weight=perwt]
margins year
marginsplot, title("Estimated annual divorce probability: newly-married women, 2008-2017", size(medium)) ///
ytitle(Probability) ylab(.02(.002).028)


