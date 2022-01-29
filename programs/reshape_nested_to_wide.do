capture program drop reshape_nested_to_wide
program define reshape_nested_to_wide
syntax ,                        ///
    input_dir(string)           ///
    data_file(string)           ///
    [filter_condition(string)]  ///
    id_vars(string)             ///
    current_item_id(string)     ///
    [new_wide_id(string)]       ///
    vars_to_keep(string)        ///
    output_dir(string)          ///
    [output_file(string)]         ///


    * check inputs

    * read in long-format nested meeting
    use "`input_dir'/`data_file/'", clear

	* if there is a filter question:
    * - keep obs that fill condition
    * - create re-serialized item ID
	if "`filter_condition'" != "" {

		* keep cases that meet condition
		keep if (`filter_condition')

		* create a new serial number from 1 to N for all remaining obs
		sort `id_vars'
		local id_vars_minus_curr : list id_vars - current_item_id
		bysort `id_vars_minus_curr' : gen new_item_id = _n

	}
	if "`filter_condition'" == "" {
		local id_vars_minus_curr : list id_vars - current_item_id
        clonevar new_item_id = `current_item_id'
	}

    * keep IDs and variables to reshape
    if "`new_wide_id'" == "" {
        keep `id_vars_minus_curr' new_item_id `vars_to_keep'
    }
    else if  "`new_wide_id'" != "" {
        clonevar `new_wide_id'_ = `current_item_id'
        keep `id_vars_minus_curr' `new_wide_id'_ new_item_id `vars_to_keep'
    }

    * TODO: think about getting this list without
    qui: d `vars_to_keep', varlist
    local vars_to_keep = r(varlist)

    local new_vars_to_keep ""

	foreach var of local vars_to_keep {
		rename `var' `var'_
		local new_vars_to_keep "`new_vars_to_keep' `var'_"
	}

	* reshape from long to wide
    if "`new_wide_id'" == "" {
	    reshape wide `new_vars_to_keep' , i(`id_vars_minus_curr') j(new_item_id)
    }
    else if "`new_wide_id'" != "" {
	    reshape wide `new_wide_id'_ `new_vars_to_keep' , i(`id_vars_minus_curr') j(new_item_id)
    }

	/* if "`filter_condition'" != "" {
	}
	else if "`filter_condition'" == "" {
		reshape wide `new_vars_to_keep' , i(`id_vars_minus_curr') j(new_item_id)
	} */

    * change variable order to matche expectations: 
    * - first, ID varibles
    * - then, each group of variables for each j in reshape
    /* qui: d, varlist
    local all_vars = r(varlist)
    local non_id_vars: list all_vars - id_vars_minus_curr
    order `non_id_vars', sequential
    order `id_vars_minus_curr' */

    * save result to disk
    if "`output_file'" == "" {
        save "`output_dir'/`data_file'", replace
    }
    else if "`output_file'" != "" {
        save "`output_dir'/`output_file'", replace
    }

end
