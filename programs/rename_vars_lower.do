/*========================================================================= 
Description

Rename all variables to lower case. 

- Ingest input dta file
- Rename variables
- Save output dta file

Arguments: 

- input. Full file path to input dta file.
- output. Full file path to output dta file
=========================================================================*/

capture program drop rename_vars_lower
program define rename_vars_lower
syntax, ///
    [input(string)] ///
    [output(string)] ///

    /*========================================================================= 
    CHECK INPUTS:
    - input file exists
    - output directory exists
    =========================================================================*/

	* check that main file exists
	if "`input'" != "" {
        capture confirm file "`input'"
        if _rc != 0 {
            di as error "Input file not found at indicated location. Please confirm the file location"
            error 1
        }
    }

    * check that output directory exists
    * TODO: strip out path
    * idea 1: find position of / or \ when looking from right and take substring from there to end
    * idea 2: extract using regex pattern: /[A-Za-z0-9]+.dta

    /*========================================================================= 
    RENAME TO LOWER CASE
    =========================================================================*/

    * use input data set
    if "`input'" != "" {
        use "`input'", clear
    }

    * capture variables
    qui: d, varlist

    * rename variables to lower case
    rename `r(varlist)', lower

    * save output data set
    if "`output'" != "" {
        save "`output'", replace
    }

end
