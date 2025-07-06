## Example Implementation 

```
* let mp1 be the shock and standardize it (custom program in repo)
replace mp1 = 0 if abs(mp1) < .005
standshock mp1 

* define indicators, where negative regions get negative indicators

gen ii2 = -(mp1_std < -1.25)
gen ii1 = - (mp1_std  < 0) * (1+ii2)
gen ii4 = (mp1_std > 1.25)
gen ii3 = (mp1_std  > 0) * (1-ii4)

* rescale them so weights integrate to 1

reg mp1_std ii*

forvalues i = 1/4 {
gen gii`i' = ii`i' * _b[ii`i']
}

```

## Delta Method Correction

Because we are using a generated regressor, standard errors should in principle get an adjustment, which in this case will usually turn out to be negligible 

Continuing from the previous code 

```
matrix b = e(b)'
matrix V = e(V)

forvalues i=1/4 {
	scalar b`i' = b[`i',1]
}

* example regression

reg dlcpi gii*, r

matrix VV = e(V)
matrix bb = e(b)'

forvalues i=1/4 {
	scalar bb`i' = bb[`i',1]
}

*now we will compute corrected standard 

* size effects: \beta_k - \beta_{k+1} = 0 for k=1 (negative) and 3 (positive)

local k = 1 //or 3 for positive shock size effects
local k1 = `k'+1

var_size_base = VV[`k',`k']+VV[`k1',`k1']-2*VV[`k',`k1']
var_size_correction = V[`k',`k']*(bb`k']/b`k')^2+V[`k1',`k1']*(bb`k1']/b`k1')^2-2*V[`k',`k1']*(bb`k' * bb`k1')/(b`k'*b`k1')
se_size = sqrt(var_size_base+var_size_correction)

* sign effects follow the same structure
* instead \beta_k + \beta_{k+2} = 0 for k=1 (small) and 2 (big)
* Also, add covariances rather than subtracting 


```

