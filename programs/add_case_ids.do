/*========================================================================= 

add_case_ids

Arguments:

- source_file. Full path to file. Source contains case IDs.
- target_file. Full path to file. Target is file to which case IDs are to added.

Returns:

Target data set with case IDs added

=========================================================================*/

capture program drop add_case_ids
program define add_case_ids
syntax ,                        ///
    source_file(string)         ///
    [target_file(string)]       ///
    [suso_ids(string)]          ///
    case_ids(string)

    /*========================================================================= 
    CAPTURE INPUT DATA
    =========================================================================*/

    if "`target_file'" == "" {
        tempfile target_file
        save "`target_file'", replace
    }

    /*========================================================================= 
    SET SUSO IDs
    =========================================================================*/

    * specify SuSo IDs
    * if not specified, use SuSo defaults
    * otherwise, use user-defined IDs
    if "`suso_ids'" == "" {
        local suso_ids "interview__key interview__id"
    }

    * identify last SuSo ID
    local n_suso_ids: list sizeof suso_ids
    local last_suso_id: word `n_suso_ids' of `suso_ids'

    /*========================================================================= 
    CHECK INPUTS
    =========================================================================*/

    * source_file exists
	capture confirm file "`source_file'"
	if _rc != 0 {
		di as error "Source file not found at indicated location. Please confirm the file location"
		error 1
	}

    * target_file exists
	if "`target_file'" != "" {
        capture confirm file "`target_file'"
        if _rc != 0 {
            di as error "Target file not found at indicated location. Please confirm the file location"
            error 1
        }
    }

    * source_file contains:
    use "`source_file'", clear
    * - suso_ids
    capture confirm variable `suso_ids'
	if _rc != 0 {
		di as error "Source file does not contain SuSo IDs: `suso_ids'"
		error 1
	}
    * - case_ids
    capture confirm variable `case_ids'
	if _rc != 0 {
		di as error "Source file does not contain case IDs: `case_ids'"
		error 1
	}

    * target_file contains suso_ids
    use "`target_file'", clear
    capture confirm variable `suso_ids'
	if _rc != 0 {
		di as error "Target file not contain SuSo IDs: `suso_ids'"
		error 1
	}    

    /*========================================================================= 
    ADD CASE IDs FROM SOURCE FILE TO TARGET FILE
    =========================================================================*/

    * add case IDs
    use "`target_file'", clear
    merge m:1 `suso_ids' using "`source_file'", keepusing(`case_ids')

    * move case IDs after
    order `case_ids', after(`last_suso_id')

end
