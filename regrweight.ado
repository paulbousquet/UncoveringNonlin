*! regrweight v1.0 - Compute and plot regression weights
*! Syntax: regrweight shock_var feature1 [feature2 ... featureK]

capture program drop regrweight
program define regrweight
    version 14.0
    
    * Parse arguments
    gettoken shock features : 0
    local k : word count `features'
    
    * Check number of features
    if `k' == 0 {
        di as error "Error: At least one feature variable must be specified"
        exit 198
    }
    if `k' >= 7 {
        di as error "Error: Maximum 6 feature variables allowed"
        exit 198
    }
    
    * Preserve data
    preserve
    
    * Keep only necessary variables and complete cases
    keep `shock' `features'
    quietly keep if !missing(`shock')
    foreach var of local features {
        quietly keep if !missing(`var')
    }
    
    * Get unique levels of shock variable and extend
    quietly levelsof `shock', local(levels)
    quietly summarize `shock'
    local min_level = r(min) - 0.01
    local max_level = r(max) + 0.01
    local extended_levels "`min_level' `levels' `max_level'"
    
    * Count number of levels for progress reporting
    local n_levels : word count `extended_levels'
    
    * Loop through each feature
    local feat_num = 0
    foreach target_var of local features {
        local feat_num = `feat_num' + 1
        di as text _n "Processing feature `feat_num' of `k': `target_var'"
        
        * Create list of all OTHER features (excluding current target)
        local other_features ""
        foreach var of local features {
            if "`var'" != "`target_var'" {
                local other_features "`other_features' `var'"
            }
        }
        
        * First regression: target feature on all other features (with constant)
        quietly reg `target_var' `other_features'
        quietly predict residuals_`feat_num', residuals
        
        * Create temporary file for results
        tempfile results_`feat_num'
        quietly postfile handle_`feat_num' level coef using `results_`feat_num'', replace
        
        
        * Loop through each threshold level
        foreach lev of local extended_levels {

            * Create indicator variable (shock >= threshold)
            quietly gen byte indicator = (`shock' >= `lev')
            
            * Regression of indicator on constant and residuals
            quietly reg indicator residuals_`feat_num'
            
            * Post the coefficient on residuals
            quietly post handle_`feat_num' (`lev') (_b[residuals_`feat_num'])
            
            * Drop indicator
            quietly drop indicator
        }
        
        * Close postfile
        quietly postclose handle_`feat_num'
        
        * Drop residuals
        quietly drop residuals_`feat_num'
    }
    
    * Restore original data
    restore
    
    * Create plots
    di as text _n "Creating plots..."
    
    * Determine subplot layout
    if `k' == 1 {
        local rows = 1
        local cols = 1
    }
    else if `k' == 2 {
        local rows = 1
        local cols = 2
    }
    else if `k' == 3 {
        local rows = 1
        local cols = 3
    }
    else if `k' == 4 {
        local rows = 2
        local cols = 2
    }
    else if `k' == 5 | `k' == 6 {
        local rows = 2
        local cols = 3
    }
    
    * Create individual plots and combine
    local plot_list ""
    forvalues i = 1/`k' {
        preserve
        
        * Load results
        quietly use `results_`i'', clear
        
        * Create plot
        local plot_cmd "line coef level, connect(stairstep) lwidth(thick) lcolor(black)"
        local plot_cmd "`plot_cmd' yline(0, lcolor(black) lpattern(dash) lwidth(thin)) "
        local plot_cmd "`plot_cmd' title("Weight on x{sub:t} in {&beta}{sub:`i'}", size(medium))"
        local plot_cmd "`plot_cmd' xtitle("x{sub:t}", size(small)) ytitle("", size(small)) "
        local plot_cmd "`plot_cmd' graphregion(fcolor(255 255 255)) plotregion(fcolor(255 255 255)) "
        local plot_cmd "`plot_cmd' name(plot_`i', replace) nodraw"
        
        quietly `plot_cmd'
        local plot_list "`plot_list' plot_`i'"
        
        restore
    }
    
    * Combine plots
    if `k' == 1 {
        graph display plot_1
    }
    else {
        graph combine `plot_list', rows(`rows') cols(`cols') ///
            graphregion(fcolor(255 255 255)) ///
            title("Regression Weight Functions", size(large))
    }
    
end
