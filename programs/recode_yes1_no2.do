capture program drop recode_yes1_no2
program define recode_yes1_no2
syntax, ///
    vars(string)        ///
    [yes_txt(string)]   ///
    [no_txt(string)]    ///

    qui: d `vars', varlist
    local varlist = r(varlist)
    di as text "Variables recoded with this command: `varlist'"

    recode `varlist' (0 = 2)
    
    if ("`yes_txt'" == "" | "no_txt" == "") {
        local yes_txt = "Oui"
        local no_txt = "Non"
    }

    foreach var of local varlist {

        label define `var' 1 "`yes_txt'" 2 "`no_txt'"
        label values `var' `var'

    }

end
