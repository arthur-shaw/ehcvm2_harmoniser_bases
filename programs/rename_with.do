capture program drop rename_with
program define rename_with
syntax , substring(string) replacement(string)

* capture variables with substring
capture qui: d *`substring'*, varlist
local old_names = r(varlist)

di "`old_names'"

* check whether any matching variables found
if inlist("`old_names'", "", ".") {
    di as error "No variables found that contain the substring `substring'"
    error 1
}

* construct new variables names by replacing substring
local new_names = subinstr("`old_names'", "`substring'", "`replacement'", .)

* rename variables and value labels (if any)
local n_vars : word count `old_names'
forvalues i = 1/`n_vars' {

    local old_name : word `i' of `old_names'
    local new_name : word `i' of `new_names'

    * capture the name of the value label associated with the old variable, if any
    qui: ds `old_name', has(vallabel)
    local val_lbl = r(varlist)

    rename `old_name' `new_name'

    * "rename" value labels by
    * - cloning old labels
    * - labelling new variable with same-named clone
    * - dropping old labels
    if (!inlist("`val_lbl'", "", ".")) {
        label copy `old_name' `new_name'
        label values `new_name' `new_name'
        label drop `old_name'
    }

}

end
