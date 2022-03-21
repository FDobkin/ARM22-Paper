*Clear
clear

*Import demographic data
import delimited "https://raw.githubusercontent.com/FDobkin/ARM22-Paper/main/cal_enviro_dem.csv"

*Create Census Tract ID
tostring ïcensustract, gen(tract_id)

*Keep relevant variables
drop ïcensustract ces40score ces40percentile ces40percentilerange

*Convert variables to numeric
foreach var in children10years pop1064years elderly64years hispanic white africanamerican nativeamerican asianamerican othermultiple {
  gen `var'_n = real(`var')
  drop `var'
}

*Save
tempfile demographic
save `demographic'

*Clear
clear

*Import enviromental quality data
import delimited "https://raw.githubusercontent.com/FDobkin/ARM22-Paper/main/cal_enviro_results.csv"

*Create Census Tract ID
tostring ïcensustract, gen(tract_id)

*Keep variables
drop ïcensustract totalpopulation californiacounty approximatelocation longitude latitude ces40score ces40percentile ces40percentilerange popchar popcharscore popcharpctl
drop *pctl

*Convert variables to numeric 
foreach var in drinkingwater traffic lead asthma lowbirthweight cardiovasculardisease education linguisticisolation poverty unemployment housingburden {
	gen `var'n = real(`var')
	drop `var'
}

*Merge
merge 1:1 tract_id using `demographic'
drop _merge 

*Create county FIPS
gen countyfips = substr(tract_id, 1,4)

*Save
tempfile ces
save `ces'

*Clear
clear

*Import Primary Care HPSA data (County)
import delimited "https://raw.githubusercontent.com/FDobkin/ARM22-Paper/main/hpsa.csv"

*Remove first two rows
gen row_n = _n
drop if row_n == 1 | row_n == 2

*Keep counties 
keep if v5 == "Single County"

*Keep valuable variables
keep v3 v6

*Create count fips
gen countyfips = substr(v6, 2,5)
drop v6

*Gen HPSA indicator
gen hpsacounty = 1 

*Merge
merge 1:m countyfips using `ces'
drop _merge v3 

*Insert 0 in HPSA county
replace hpsacounty = 0 if hpsacounty == .

*Save
tempfile hpsaces
save `hpsaces'

*Clear
clear

*Import Primary Care HPSA data (Tract)
import delimited "https://raw.githubusercontent.com/FDobkin/ARM22-Paper/main/hpsa.csv"

*Keep counties 
keep if v5 == "Census Tract"

*Create census tract id
gen tract_id = substr(v6, 2, 11)

*Keep tract_id
keep tract_id

*Gen HPSA indicator
gen hpsatract = 1

*Merge
merge 1:m tract_id using `hpsaces'
drop _merge

*Insert 0 in HPSA tract
replace hpsatract = 0 if hpsatract == .

*Save
tempfile hpsacesfin
save `hpsacesfin'

*Clear
clear

*Import 
import delimited "https://raw.githubusercontent.com/FDobkin/ARM22-Paper/main/ACSDT5Y2020.B28003_data_with_overlays_2022-03-19T142244.csv"

*Create numeric values
foreach var in v1 v7 {
	gen `var'n = real(`var')
}

*Create broadband variable
gen broadband_perc = (v7n/v1n)*100

*Create census tract id
gen tract_id = substr(v13, 11, 20)

*Drop blank rows
drop if tract_id == ""

*Keep valuable variables
keep tract_id broadband_perc

*Merge
merge m:1 tract_id using `hpsacesfin'
drop _merge

*Save
tempfile hpsaacsfinint
save `hpsaacsfinint'

*Clear
clear

*Import insurance file
import delimited "https://raw.githubusercontent.com/FDobkin/ARM22-Paper/main/acs_insurance.csv"

*Keep three variables
keep v1 v3 v4

*Rename variables
rename v1 GEOID
rename v3 total_population
rename v4 insured_population

*Drop first two rows
gen row_n = _n
drop if row_n == 1 | row_n == 2
drop row_n

*Create tract_id
gen tract_id = substr(GEOID, 11, 20)
drop GEOID

*Create numeric values
gen totpop = real(total_population)
gen inspop = real(insured_population)
gen insur_rate = (inspop/totpop)*100
drop totpop inspop total_population insured_population

*merge
merge m:1 tract_id using `hpsaacsfinint'
keep if _merge == 3
drop _merge

*Save
tempfile file
save `file'

*Clear
clear

*Import Place data
import delimited "https://raw.githubusercontent.com/FDobkin/ARM22-Paper/main/places.csv"

*Keep cholestorol screening
keep if measure == "Cholesterol screening among adults aged >=18 years"

*Rename
rename data_value chol_screen

*Save
tempfile chol
save `chol'

*Clear
clear 

*Import Place data
import delimited "https://raw.githubusercontent.com/FDobkin/ARM22-Paper/main/places.csv"

*Keep Sleeping less than 7 hours among adults aged >=18 years
keep if measure == "Sleeping less than 7 hours among adults aged >=18 years"

*Rename
rename data_value sleep

*Merge
merge 1:1 locationname using `chol'
keep if _merge == 3
drop _merge 

*Save
tempfile cholsleep
save `cholsleep'

*Clear
clear

*Import Place data
import delimited "https://raw.githubusercontent.com/FDobkin/ARM22-Paper/main/places.csv"

*Keep No leisure-time physical activity among adults aged >=18 years
keep if measure == "No leisure-time physical activity among adults aged >=18 years"

*Rename measure
rename data_value phy_act

*merge 
merge 1:1 locationname using `cholsleep'
drop _merge

*Save
tempfile cholsleepph
save `cholsleepph'

*Clear
clear

*Import Place data
import delimited "https://raw.githubusercontent.com/FDobkin/ARM22-Paper/main/places.csv"

*Keep Binge drinking among adults aged >=18 years
keep if measure == "Binge drinking among adults aged >=18 years"

*Rename
rename data_value binge_drink

*merge
merge 1:1 locationname using `cholsleepph'
drop _merge

*Save
tempfile cholsleepphdrink
save `cholsleepphdrink'

*clear
clear

*Import Place data
import delimited "https://raw.githubusercontent.com/FDobkin/ARM22-Paper/main/places.csv"

*Keep Fair or poor self-rated health status among adults aged >=18 years
keep if measure == "Fair or poor self-rated health status among adults aged >=18 years"

*Rename 
rename data_value self_health

*Merge
merge 1:1 locationname using `cholsleepphdrink'
drop _merge

*Save
tempfile cholsleepphdrinkhlth
save `cholsleepphdrinkhlth'

*Clear
clear

*Import Place data
import delimited "https://raw.githubusercontent.com/FDobkin/ARM22-Paper/main/places.csv"

*Keep
keep if measure == "Current smoking among adults aged >=18 years"

*Rename
rename data_value smoke

*merge
merge 1:1 locationname using `cholsleepphdrinkhlth'
drop _merge

*Save
tempfile smoke
save `smoke'

*Clear
clear

*Import Place data
import delimited "https://raw.githubusercontent.com/FDobkin/ARM22-Paper/main/places.csv"

*Keep COPD
keep if measure == "Chronic obstructive pulmonary disease among adults aged >=18 years"

*Rename data_value
rename data_value copd

*Merge
merge 1:1 locationname using `smoke'
drop _merge

*Clear
clear

*Import Place data
import delimited "https://raw.githubusercontent.com/FDobkin/ARM22-Paper/main/places.csv"

*Keep cancer
keep if measure == "Cancer (excluding skin cancer) among adults aged >=18 years"

*rename data_value
rename data_value cancer

*merge
merge 1:1 locationname using `smoke'
drop _merge 

*Save
tempfile cancer
save `cancer'

*clear
clear

*Import 
import delimited "https://raw.githubusercontent.com/FDobkin/ARM22-Paper/main/places.csv"

*Keep 
keep if measure == "Diagnosed diabetes among adults aged >=18 years"

*Rename
rename data_value diabetes

*merge
merge 1:1 locationname using `cancer'
drop _merge

*Save
tempfile diabetes
save `diabetes'

*Clear
clear

*Import 
import delimited "https://raw.githubusercontent.com/FDobkin/ARM22-Paper/main/places.csv"

*Keep
keep if measure == "Coronary heart disease among adults aged >=18 years"

*Rename
rename data_value heart_disease

*Merge
merge 1:1 locationname using `diabetes'
drop _merge
tostring locationname, gen(tract_id)
merge 1:m tract_id using `file'
