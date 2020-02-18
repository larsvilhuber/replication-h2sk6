/* data is from IPUMS.org. It's free and open so you can go get info on the data and variables there */

* NOTE: You need to set the Stata working directory to the path
* where the data file is located.

global pathname "U:/Documents/Workspace/socarxiv/replication-h2sk6"
set more off

clear
do config.do
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
  using "${pathname}/usa_00388.dat"
    
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


   
/* QUICK TAKE on selection into marriage, 2008-2017 */

* NOTE: You need to set the Stata working directory to the path
* where the data file is located.

set more off

clear
quietly infix              ///
  int     year       1-4    ///
  double  perwt      5-14   ///
  byte    nchild     15-15  ///
  int     age        17-19  ///
  byte    marrno     20-20  ///
  byte    race       22-22  ///
  byte    hispan     26-26  ///
  int     educd      32-34  ///
  int     age_sp     35-37  ///
  byte    marrno_sp  38-38  ///
  byte    race_sp    39-39  ///
  byte    hispan_sp  40-40  ///
  int     educd_sp   41-43  ///
  using "$pathname/usa_00389.dat"

/*  2008-2017 ACS, sample is women who married in the year before the survey.
    The _sp variables are her spouse's characteristics (regardless of spouse gender) */


*replace perwt    = perwt    / 100

*format perwt    %10.2f

label var year     "Census year"
label var perwt    "Person weight"
label var age      "Age"
label var marrno   "Times married"
label var race     "Race [general version]"
label var hispan   "Hispanic origin [general version]"
label var educd    "Educational attainment [detailed version]"


label define race_lbl 1 "White"
label define race_lbl 2 "Black/African American/Negro", add
label define race_lbl 3 "American Indian or Alaska Native", add
label define race_lbl 4 "Chinese", add
label define race_lbl 5 "Japanese", add
label define race_lbl 6 "Other Asian or Pacific Islander", add
label define race_lbl 7 "Other race, nec", add
label define race_lbl 8 "Two major races", add
label define race_lbl 9 "Three or more major races", add
label values race race_lbl


label define hispan_lbl 0 "Not Hispanic"
label define hispan_lbl 1 "Mexican", add
label define hispan_lbl 2 "Puerto Rican", add
label define hispan_lbl 3 "Cuban", add
label define hispan_lbl 4 "Other", add
label define hispan_lbl 9 "Not Reported", add
label values hispan hispan_lbl

label define educd_lbl 000 "N/A or no schooling"
label define educd_lbl 001 "N/A", add
label define educd_lbl 002 "No schooling completed", add
label define educd_lbl 010 "Nursery school to grade 4", add
label define educd_lbl 011 "Nursery school, preschool", add
label define educd_lbl 012 "Kindergarten", add
label define educd_lbl 013 "Grade 1, 2, 3, or 4", add
label define educd_lbl 014 "Grade 1", add
label define educd_lbl 015 "Grade 2", add
label define educd_lbl 016 "Grade 3", add
label define educd_lbl 017 "Grade 4", add
label define educd_lbl 020 "Grade 5, 6, 7, or 8", add
label define educd_lbl 021 "Grade 5 or 6", add
label define educd_lbl 022 "Grade 5", add
label define educd_lbl 023 "Grade 6", add
label define educd_lbl 024 "Grade 7 or 8", add
label define educd_lbl 025 "Grade 7", add
label define educd_lbl 026 "Grade 8", add
label define educd_lbl 030 "Grade 9", add
label define educd_lbl 040 "Grade 10", add
label define educd_lbl 050 "Grade 11", add
label define educd_lbl 060 "Grade 12", add
label define educd_lbl 061 "12th grade, no diploma", add
label define educd_lbl 062 "High school graduate or GED", add
label define educd_lbl 063 "Regular high school diploma", add
label define educd_lbl 064 "GED or alternative credential", add
label define educd_lbl 065 "Some college, but less than 1 year", add
label define educd_lbl 070 "1 year of college", add
label define educd_lbl 071 "1 or more years of college credit, no degree", add
label define educd_lbl 080 "2 years of college", add
label define educd_lbl 081 "Associates degree, type not specified", add
label define educd_lbl 082 "Associates degree, occupational program", add
label define educd_lbl 083 "Associates degree, academic program", add
label define educd_lbl 090 "3 years of college", add
label define educd_lbl 100 "4 years of college", add
label define educd_lbl 101 "Bachelors degree", add
label define educd_lbl 110 "5+ years of college", add
label define educd_lbl 111 "6 years of college (6+ in 1960-1970)", add
label define educd_lbl 112 "7 years of college", add
label define educd_lbl 113 "8+ years of college", add
label define educd_lbl 114 "Masters degree", add
label define educd_lbl 115 "Professional degree beyond a bachelors degree", add
label define educd_lbl 116 "Doctoral degree", add
label define educd_lbl 999 "Missing", add
label values educd educd_lbl

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

egen agecat=cut(age), at(15,25,35,45,65,100)
*bysort agecat: sum age

replace nchild=1 if nchild>0

* make an arbitrary divorce-prevention selection scale
gen score = (age>=30) + (rac3==1 | rac3==3) + (edcat==4) + (marrno==1) + (nchild==0)
gen sscore = (age_sp>=30) + (hispan_sp==0 | race_sp==1) + (educd_sp >=101) + (marrno_sp==1)
gen marscore = score+sscore

tab2 year marrno [weight=perwt], nofreq row
tab2 year edcat [weight=perwt], nofreq row
tab2 year rac3 [weight=perwt], nofreq row
tab2 year agecat [weight=perwt], nofreq row
tab2 year nchild [weight=perwt], nofreq row
tab2 year score [weight=perwt], nofreq row
tab2 year sscore [weight=perwt], nofreq row
tab2 year marscore [weight=perwt], nofreq row

collapse (mean) score (mean) sscore (mean) marscore [weight=perwt], by(year)



/* CALCULATING AGE-SPECIFIC DIVORCE RATES TO MATCH KENNEDY & RUGGLES */

* NOTE: You need to set the Stata working directory to the path
* where the data file is located.

/* SAMPLE is ever-married women ages 15+ */

set more off

clear
quietly infix             ///
  int     year     1-4    ///
  double  perwt    5-14   ///
  byte    sex      15-15  ///
  int     age      16-18  ///
  byte    marst    19-19  ///
  byte    divinyr  20-20  ///
  using "$pathname/usa_00390.dat"

/* sample is 2008-2017 ACS, ever-married women ages 15+ */
  
replace perwt   = int(perwt   / 100) /* <-- note all weights end with 00 so this just truncates it */

label var year    "Census year"
label var perwt   "Person weight"
label var sex     "Sex"
label var age     "Age"
label var marst   "Marital status"
label var divinyr "Divorced in the past year"

label define marst_lbl 1 "Married, spouse present"
label define marst_lbl 2 "Married, spouse absent", add
label define marst_lbl 3 "Separated", add
label define marst_lbl 4 "Divorced", add
label define marst_lbl 5 "Widowed", add
label define marst_lbl 6 "Never married/single", add
label values marst marst_lbl

label define divinyr_lbl 0 "N/A"
label define divinyr_lbl 1 "Blank (No)", add
label define divinyr_lbl 2 "Yes", add
label values divinyr divinyr_lbl

gen divorced = divinyr==2
drop divinyr

egen agecat=cut(age), at(15(5)135)

replace agecat=75 if age>=75 /* now 75 = 75+ */

tab2 year agecat if marst<4 [weight=perwt] /* married people */
tab2 year agecat if divorced==1 [weight=perwt] /* divorced people */

/* then I calculate the age-specific divorce rates in Excel */
