
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
