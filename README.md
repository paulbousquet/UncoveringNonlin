## Example Implementation 

```
* let mp1 be the shock and standardize it (custom program in repo)
replace mp1 = 0 if abs(mp1) < .005
standshock ff1 

* define indicators, where negative regions get negative indicators

gen ii2 = -(ff1_std < -1.25)
gen ii1 = - (ff1_std < 0) * (1+i2)
gen ii4 = (ff1_std > 1.25)
gen ii3 = (ff1_std > 0) * (1-i4)

* rescale them so weights integrate to 1

reg ff1_std ii*

forvalues i = 1/4 {
gen gii`i' = ii`i' * _b[ii`i']
}

```

## Delta Method Correction

Because we are using a generated regressor, standard errors should in principle get an adjustment, which in this case will usually turn out to be negligible 

