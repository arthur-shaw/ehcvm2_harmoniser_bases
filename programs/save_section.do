capture program drop save_section
program define save_section
syntax, ///
    [input(string)]         ///
    [suso_ids(string)]      ///
    case_ids(string)        ///
    [roster_ids(string)]    ///
    vars_to_keep(string)    ///
    section_code(string)    ///
    country_code(string)    ///
    year(string)            ///
    output_dir(string)      ///

    /*========================================================================= 
    CHECK INPUTS
    =========================================================================*/

    * TODO: draft this section

    * input file exists

    * input contains
    * - suso_ids
    * - case_ids
    * - vars_to_keep

    * output_dir exists

   /*========================================================================= 
    SAVE DATA TO SECTION FILE
    =========================================================================*/

    * define all ID variables
    if "`suso_ids'" == "" {
        local suso_ids "interview__key interview__id"
    }
    if "`roster_ids'" == "" {
        local roster_ids ""
    }

    local all_ids "`suso_ids' `case_ids' `roster_ids'"

    * keep variables
    keep `all_ids' `vars_to_keep'

    * save data to file
    save "`output_dir'/s`section_code'_me_`country_code'_`year'.dta", replace

end
