capture program drop reshape_multi_select_yn
program define reshape_multi_select_yn
syntax ,                        ///
    input_dir(string)           ///
    main_file(string)           ///
    roster_file(string)         ///
    trigger_var(string)         ///
    item_code_var(string)       ///
    new_roster_id_var(string)   ///
    output_dir(string)

    /*========================================================================= 
    CHECK INPUTS:
    - input file exists
    - roster file exists
    - output directory exists
    =========================================================================*/

	* check that main file exists
	capture confirm file "`input_dir'/`main_file'"
	if _rc != 0 {
		di as error "Main file not found at indicated location. Please confirm the file location"
		error 1
	}

	* check that roster file exists
	capture confirm file "`input_dir'/`roster_file'"
	if _rc != 0 {
		di as error "Roster file not found at indicated location. Please confirm the file location"
		error 1
	}

    * check output directory exists
    di "`output_dir'"
    capture cd "`output_dir'"
    if _rc != 0 {
        di as error "Output directory not found. Please confirm the directory path"
        error 1
    }

	* check that variables with this stub exist
	use "`input_dir'/`main_file'", clear
    qui: d `trigger_var'*, varlist
	local varsFound = r(varlist)
	local numVarsFound : list sizeof varsFound
	if `numVarsFound' == 0 {
		di as error "No variables found with stub `trigger_var'"
		error 1
	}

    /*========================================================================= 
    Capture value label for item code variable
    -  saving them externally for later use in program
    -  -clear- destroys the label
    =========================================================================*/

    use "`input_dir'/`roster_file'", clear
    local `new_roster_id_var': value label `item_code_var'
    label copy `item_code_var' `new_roster_id_var'
    label save `new_roster_id_var' using "`output_dir'/`new_roster_id_var'.do", replace

    /*========================================================================= 
    Reshape multi-select question
    -  pivoting from wide to long
    -  creating an ID variable for merging with roster file
    - recoding yes/no
    =========================================================================*/

    use "`input_dir'/`main_file'", clear
    keep interview__id interview__key `trigger_var'__*
    reshape long `trigger_var'__, i(interview__id interview__key) j(`new_roster_id_var')
    rename `trigger_var'__ `trigger_var'
    clonevar `item_code_var' = `new_roster_id_var'
    recode `trigger_var' (0=2)

    /*========================================================================= 
    Merge reshaped yes/no with roster file
    =========================================================================*/

    merge 1:1 interview__id interview__key `item_code_var' using "`input_dir'/`roster_file'", nogen    

    /*========================================================================= 
    Apply value labels
    - to yes/no question, since it never had a label for current values
    - to new roster ID variable, since its label was destroyed by -clear-
    =========================================================================*/

    label define `trigger_var' 1 "Oui" 2 "Non", replace
    do "`output_dir'/`new_roster_id_var'.do"
    label values `new_roster_id_var' `new_roster_id_var'
    label values `trigger_var' `trigger_var'

    /*========================================================================= 
    Finalize and save data
    - reorder variables to be expected order for first variables
    - save to disk
    =========================================================================*/

    order interview__id interview__key `new_roster_id_var' `trigger_var'
    drop `item_code_var'
    save "`output_dir'/`roster_file'", replace

    /*========================================================================= 
    Clean up environment
    =========================================================================*/

    * delete external file created to store labels
    rm "`output_dir'/`new_roster_id_var'.do"

end


* "C:\Users\wb393438\UEMOA\ehcvm2_rejet\data\02_combined"

* use "`test_dir'/Ehcvm.dta", clear
/* 
local test_dir "C:\Users\wb393438\Downloads\sn_ehcvm\Ehcvm_23_STATA_All"
local output_dir "C:\Users\wb393438\Downloads"

reshape_multi_select_yn,                ///
    input_dir("`test_dir'")             ///
    main_file("Ehcvm.dta")              ///
    roster_file("depense_7j.dta")       ///
    trigger_var("s09Bq02")              ///
    item_code_var("depense_7j__id")     ///
    new_roster_id_var("s09Bq01")        ///
    output_dir("`output_dir'")
 */


* merge 1:1 interview__id interview__key depense_7j__id using "`test_dir'/depense_7j.dta", nogen
