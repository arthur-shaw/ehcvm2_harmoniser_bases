/*=============================================================================
Parmétrage
=============================================================================*/

/*-----------------------------------------------------------------------------
Paramètres du programme
-----------------------------------------------------------------------------*/

local proj_dir 	"C:\Users\wb393438\UEMOA\ehcvm2_harmoniser_bases/"
local fichier_principal "menage.dta"
local case_ids_vars "grappe id_menage vague"
local pays "TGO"
local annee "2021"

/*-----------------------------------------------------------------------------
Définir les répertoires
-----------------------------------------------------------------------------*/

* données
local data_dir_raw      "`proj_dir'/data/0_downloaded/"	// données brutes
local data_dir_combined "`proj_dir'/data/1_combined/" 	// données légèrement modifiées
local data_dir_temp     "`proj_dir'/data/2_temp/" 		// fichiers temporaires
local data_dir_output   "`proj_dir'/data/3_output/" 	// données finales

* étiquettes
local lbl_dir_temp  "`proj_dir'/labels/temp/"
local lbl_dir_out   "`proj_dir'/labels/output/"

* programmes
local prog_dir "`proj_dir'/programs/"

/*-----------------------------------------------------------------------------
Charger les programmes de service
-----------------------------------------------------------------------------*/

include "`prog_dir'/appendAll"
include "`prog_dir'/reshape_multi_select_yn.do"
include "`prog_dir'/reshape_nested_to_wide.do"
include "`prog_dir'/add_case_ids.do"
include "`prog_dir'/rename_vars_lower.do"
include "`prog_dir'/save_section.do"

/*=============================================================================
Fusionner les bases
=============================================================================*/

/*-----------------------------------------------------------------------------
Toutes les bases
-----------------------------------------------------------------------------*/

* append together same-named files from different template versions
appendAll, 							    ///
	inputDir("`data_dir_raw'") 		    ///	où chercher les données téléchargées
	outputDir("`data_dir_combined'")    /// où sauvegarder la concatination

/*-----------------------------------------------------------------------------
Créer un base de consommation
-----------------------------------------------------------------------------*/

/*- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
Harmoniser les noms de vqriable
- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -*/

#delim ;
local food_conso_files = "
boissons
cereales
epices
fruits
huiles
laitier
legtub
legumes
poissons
sucreries
viandes
";
#delim cr

foreach food_conso_file of local food_conso_files {

    use "`data_dir_combined'/`food_conso_file'.dta", clear

    * product ID
    rename `food_conso_file'__id produit__id
    label save `food_conso_file'__id using "`lbl_dir_temp'/`food_conso_file'__id.do", replace

    * all other variables
    qui: d s07Bq*, varlist
    local var_w_suffixes = r(varlist)
    foreach var_w_suffix of local var_w_suffixes {

        * save label for later manipulation, for variables that have labels
        qui : ds `var_w_suffix', has(vallabel)
        if "`r(varlist)'" != "" {
            label save `var_w_suffix' `var_w_suffix' using "`lbl_dir_temp'/`var_w_suffix'.do", replace
        }

        * rename variable
        * - extract variable name component (e.g., s07bq03b)
        * - rename from with to without suffix
        local var_no_suffix = regexm("`var_w_suffix'", "([A-Za-z0-9]+)_([A-Za-z]+)")
        local var_no_suffix = regexs(1)
        rename `var_w_suffix' `var_no_suffix'

    }

    * save data
    save "`data_dir_temp'/`food_conso_file'.dta", replace

} 

/*- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
Gérer étiquettes de valeur
- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -*/

* TODO

/*- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
Mettre dans une seule base toutes les bases de consommation alimentaire
- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -*/

local food_count = 0

foreach food_conso_file of local food_conso_files {

    local ++food_count

    if `food_count' == 1 {
        use "`data_dir_temp'/`food_conso_file'.dta", clear
    }

    else if `food_count' > 0 {
        append using "`data_dir_temp'/`food_conso_file'.dta"
    }

}

save "`data_dir_temp'/consommation_alimentaire_7j.dta", replace

/*=============================================================================
Rendre les rosters conformes à leur forme dans questionnaire papier
=============================================================================*/

/*-----------------------------------------------------------------------------
Ramener la question filtre dans le roster
-----------------------------------------------------------------------------*/
/* 
* get list of variables
qui: d s07Bq*_cereales, varlist
local var_w_suffix = r(varlist)

* construct list of variable names without product group suffix
local var_no_suffix = ""
foreach var of local var_w_suffix {
    local new_element = subinstr("`var'", "_cereales", "", .)
    local var_no_suffix "`var_no_suffix' `new_element'" 
}

local nitems: word count `var_w_suffix'

forvalues i = 1/`nitems' {

	local old_name : word `i' of `var_w_suffix'
	local new_name : word `i' of `var_no_suffix'

    rename `old_name' `new_name'

    local `old_name': value label `new_name'
    label save `old_name' using "`lbl_dir_temp'/`old_name'.do", replace

}

local vars_no_suffix = subinstr("`var_w_suffix'", "__cereales", "") 
*/

/*- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
Céréales
- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -*/
/* 
reshape_multi_select_yn,


cereales
viandes
poissons
huiles
laitier
fruits
legumes
legtub
sucreries
epices
boissons 
*/

/*-----------------------------------------------------------------------------
Ramener la question filtre oui/non dans le roster
-----------------------------------------------------------------------------*/

* 9A: depense_fete
reshape_multi_select_yn, ///
    input_dir("`data_dir_combined'") ///
    main_file("`fichier_principal'") ///
    roster_file("depense_fete.dta") ///
    trigger_var("s09Aq02") ///
    item_code_var("depense_fete__id") ///
    new_roster_id_var("s09Aq01") ///
    output_dir("`data_dir_temp'") ///

* 9B: depense_7j
reshape_multi_select_yn, ///
    input_dir("`data_dir_combined'") ///
    main_file("`fichier_principal'") ///
    roster_file("depense_7j.dta") ///
    trigger_var("s09Bq02") ///
    item_code_var("depense_7j__id") ///
    new_roster_id_var("s09Bq01") ///
    output_dir("`data_dir_temp'") ///

* 9C: depense_30j
reshape_multi_select_yn, ///
    input_dir("`data_dir_combined'") ///
    main_file("`fichier_principal'") ///
    roster_file("depense_30j.dta") ///
    trigger_var("s09Cq02") ///
    item_code_var("depense_30j__id") ///
    new_roster_id_var("s09Cq01") ///
    output_dir("`data_dir_temp'") ///

* 9D: depense_3m
reshape_multi_select_yn, ///
    input_dir("`data_dir_combined'") ///
    main_file("`fichier_principal'") ///
    roster_file("depense_3m.dta") ///
    trigger_var("s09Dq02") ///
    item_code_var("depense_3m__id") ///
    new_roster_id_var("s09Dq01") ///
    output_dir("`data_dir_temp'") ///

* 9E: depense_6m
reshape_multi_select_yn, ///
    input_dir("`data_dir_combined'") ///
    main_file("`fichier_principal'") ///
    roster_file("depense_6m.dta") ///
    trigger_var("s09Eq02") ///
    item_code_var("depense_6m__id") ///
    new_roster_id_var("s09Eq01") ///
    output_dir("`data_dir_temp'") ///

* 9F: depense_12m
reshape_multi_select_yn, ///
    input_dir("`data_dir_combined'") ///
    main_file("`fichier_principal'") ///
    roster_file("depense_12m.dta") ///
    trigger_var("s09Fq02") ///
    item_code_var("depense_12m__id") ///
    new_roster_id_var("s09Fq01") ///
    output_dir("`data_dir_temp'") ///

* 12: actifs
reshape_multi_select_yn, ///
    input_dir("`data_dir_combined'") ///
    main_file("`fichier_principal'") ///
    roster_file("actifs.dta") ///
    trigger_var("s12q02") ///
    item_code_var("actifs__id") ///
    new_roster_id_var("s12q01") ///
    output_dir("`data_dir_temp'") ///

* 14A: impactCovid19
reshape_multi_select_yn, ///
    input_dir("`data_dir_combined'") ///
    main_file("`fichier_principal'") ///
    roster_file("impactCovid19.dta") ///
    trigger_var("s14aq02") ///
    item_code_var("impactCovid19__id") ///
    new_roster_id_var("s14aq01") ///
    output_dir("`data_dir_temp'") ///

* s14B: chocs
reshape_multi_select_yn, ///
    input_dir("`data_dir_combined'") ///
    main_file("`fichier_principal'") ///
    roster_file("chocs.dta") ///
    trigger_var("s14bq02") ///
    item_code_var("chocs__id") ///
    new_roster_id_var("s14bq01") ///
    output_dir("`data_dir_temp'") ///

* 15: filets_securite
reshape_multi_select_yn, ///
    input_dir("`data_dir_combined'") ///
    main_file("`fichier_principal'") ///
    roster_file("filets_securite.dta") ///
    trigger_var("s15q02") ///
    item_code_var("filets_securite__id") ///
    new_roster_id_var("s15q01") ///
    output_dir("`data_dir_temp'") ///

* 16B: cout_intrants
reshape_multi_select_yn, ///
    input_dir("`data_dir_combined'") ///
    main_file("`fichier_principal'") ///
    roster_file("cout_intrants.dta") ///
    trigger_var("s16bq02") ///
    item_code_var("cout_intrants__id") ///
    new_roster_id_var("s16bq01") ///
    output_dir("`data_dir_temp'") ///

* 17: elevage
reshape_multi_select_yn, ///
    input_dir("`data_dir_combined'") ///
    main_file("`fichier_principal'") ///
    roster_file("elevage.dta") ///
    trigger_var("s17q03") ///
    item_code_var("elevage__id") ///
    new_roster_id_var("s17q01") ///
    output_dir("`data_dir_temp'") ///

/*-----------------------------------------------------------------------------
reshape nested roster to wide
-----------------------------------------------------------------------------*/

* entreprise_travailFamilial
reshape_nested_to_wide, ///
    input_dir("`data_dir_combined'") ///
    data_file("entreprise_travailFamilial.dta") ///
    filter_condition("s10q61a == 1") ///
    id_vars("interview__key interview__id entreprises__id entreprise_travailFamilial__id") ///
    current_item_id("entreprise_travailFamilial__id") ///
    new_wide_id("s10q61") ///
    vars_to_keep("s10q61a s10q61b s10q61c s10q61d") ///
    output_dir("`data_dir_temp'") ///

* entreprise_travailSalarie
reshape_nested_to_wide, ///
    input_dir("`data_dir_combined'") ///
    data_file("entreprise_travailSalarie.dta") ///
    id_vars("interview__key interview__id entreprises__id entreprise_travailSalarie__id") ///
    current_item_id("entreprise_travailSalarie__id") ///
    vars_to_keep("s10q62*") ///
    output_dir("`data_dir_temp'") ///

* preparation_f
reshape_nested_to_wide, ///
    input_dir("`data_dir_combined'") ///
    data_file("preparation_f.dta") ///
    filter_condition("s16Aq33a == 1") ///
    id_vars("interview__key interview__id champs__id parcelles__id preparation_f__id") ///
    current_item_id("preparation_f__id") ///
    new_wide_id("s16Aq33a") ///
    vars_to_keep("s16Aq33b") ///
    output_dir("`data_dir_temp'") ///
    output_file("preparation_f.dta") ///

* entretien_f
reshape_nested_to_wide, ///
    input_dir("`data_dir_combined'") ///
    data_file("preparation_f.dta") ///
    filter_condition("s16Aq35a == 1") ///
    id_vars("interview__key interview__id champs__id parcelles__id preparation_f__id") ///
    current_item_id("preparation_f__id") ///
    new_wide_id("s16Aq35a") ///
    vars_to_keep("s16Aq35b") ///
    output_dir("`data_dir_temp'") ///
    output_file("entretien_f.dta") ///

* recolte_f
reshape_nested_to_wide, ///
    input_dir("`data_dir_combined'") ///
    data_file("preparation_f.dta") ///
    filter_condition("s16Aq37a == 1") ///
    id_vars("interview__key interview__id champs__id parcelles__id preparation_f__id") ///
    current_item_id("preparation_f__id") ///
    new_wide_id("s16Aq37a") ///
    vars_to_keep("s16Aq37b") ///
    output_dir("`data_dir_temp'") ///
    output_file("recolte_f.dta") ///

* preparation_sol_semi_nf
reshape_nested_to_wide, ///
    input_dir("`data_dir_combined'") ///
    data_file("preparation_sol_semi_nf.dta") ///
    id_vars("interview__key interview__id champs__id parcelles__id preparation_sol_semi_nf__id") ///
    current_item_id("preparation_sol_semi_nf__id") ///
    vars_to_keep("s16Aq39*") ///
    output_dir("`data_dir_temp'") ///

* entretien_nf
reshape_nested_to_wide, ///
    input_dir("`data_dir_combined'") ///
    data_file("entretien_nf.dta") ///
    id_vars("interview__key interview__id champs__id parcelles__id entretien_nf__id") ///
    current_item_id("entretien_nf__id") ///
    vars_to_keep("s16Aq41*") ///
    output_dir("`data_dir_temp'") ///

* recolte_nf
reshape_nested_to_wide, ///
    input_dir("`data_dir_combined'") ///
    data_file("recolte_nf.dta") ///
    id_vars("interview__key interview__id champs__id parcelles__id recolte_nf__id") ///
    current_item_id("recolte_nf__id") ///
    vars_to_keep("s16Aq43*") ///
    output_dir("`data_dir_temp'") ///

/*-----------------------------------------------------------------------------
Impact du COVID-19
-----------------------------------------------------------------------------*/

* ramener les questions oui-non dans le roster
reshape_multi_select_yn, ///
    input_dir("`data_dir_combined'") ///
    main_file("`fichier_principal'") ///
    roster_file("impactCovid19.dta") ///
    trigger_var("s14aq02") ///
    item_code_var("impactCovid19__id") ///
    new_roster_id_var("s14aq01") ///
    output_dir("`data_dir_temp'")

* joindre la base des personnes qui ont subi ce problème
use "`data_dir_temp'/impactCovid19.dta", clear
clonevar impactCovid19__id = s14aq01
merge 1:m interview__key interview__id impactCovid19__id ///
    using "`data_dir_combined'/impactCovid19NoMembres.dta", nogen assert(1 3)

drop impactCovid19__id impactCovid19NoMembres__id

rename rang s14aq02b

save "`data_dir_temp'/s14.dta", replace

/*-----------------------------------------------------------------------------
champs-parcelles
-----------------------------------------------------------------------------*/

* 16A: champs-parcelles
use "`data_dir_combined'/champs.dta", clear
merge 1:m interview__id interview__key champs__id using "`data_dir_combined'/parcelles.dta", nogen assert(3)
capture drop ///
    s16Aa01b__* /// liste des parcelles sur le champs
    s16Cq03__* /// liste des cultures sur la parcelle

tempfile champs_parcelles
save "`champs_parcelles'", replace

#delim ;
local ag_labor_dsets "
preparation_f
entretien_f
recolte_f
preparation_sol_semi_nf
entretien_nf
recolte_nf
";
#delim cr

foreach ag_labor_dset of local ag_labor_dsets {

    di "Merging `ag_labor_dset'"
    merge 1:1 interview__id interview__key champs__id parcelles__id using ///
        "`data_dir_temp'/`ag_labor_dset'.dta", nogen assert(1 3)

}

save "`data_dir_temp'/s16a.dta", replace

/*-----------------------------------------------------------------------------
champs-parcelles-cultures
-----------------------------------------------------------------------------*/

* 16C: champs-parcelle-culture
use "`champs_parcelles'", clear
merge 1:m interview__id interview__key champs__id parcelles__id using ///
    "`data_dir_combined'/cultures.dta", ///
    nogen assert(1 3)

save "`data_dir_temp'/s16c.dta", replace

/*-----------------------------------------------------------------------------
cultures
-----------------------------------------------------------------------------*/

* 16D: utilisation de la production

* harmonize variable names by removing _p suffix for perennial crops data
use "`data_dir_combined'/culture_utilisation_perenne.dta", clear
rename culture_utilisation_perenne__id culture_utilisation__id
qui: d *_p*, varlist // compile list of all variables with _p suffix
local p_vars = r(varlist)
local no_p_vars = subinstr("`p_vars'", "_p", "", .) // remove _p from allnames
rename (`p_vars') (`no_p_vars') // rename names with _p to names without _p
save "`data_dir_temp'/culture_utilisation_perenne.dta", replace

* combine data
use "`data_dir_combined/'culture_utilisation_annuelle.dta", clear
rename culture_utilisation_annuelle__id culture_utilisation__id
append using "`data_dir_temp'/culture_utilisation_perenne.dta"

* save combined data as single file
save "`data_dir_temp'/s16d.dta", replace

/*-----------------------------------------------------------------------------
rename variables to make letters lower case
-----------------------------------------------------------------------------*/


/*=============================================================================
Créer des fichiers par section
=============================================================================*/

/*-----------------------------------------------------------------------------
Niveau ménage
-----------------------------------------------------------------------------*/

use "`data_dir_combined'/`fichier_principal'", clear

rename_vars_lower

tempfile menages
save "`menages'", replace

/*-----------------------------------------------------------------------------
0: Identification du ménage
-----------------------------------------------------------------------------*/

use "`menages'", clear

#delim ;
local oth_vars "
nom_prenom_cm localisation_menage gps 
anneeScolaireEnCours anneeScolairePassee campagneAgricole 
format_interview observation
";
#delim cr

save_section, ///
    case_ids(`case_ids_vars') ///
    vars_to_keep("s00*") /// 
    section_code("00") ///
    country_code("`pays'") ///
    year(`annee') ///
    output_dir("`data_dir_output'")

/*-----------------------------------------------------------------------------
Bases du niveau membre
-----------------------------------------------------------------------------*/

use "`data_dir_combined'/membres.dta", clear

add_case_ids, ///
    source_file("`data_dir_combined'/`fichier_principal'") ///
    case_ids(`case_ids_vars')

rename_vars_lower

tempfile membres
save "`membres'", replace

/*-----------------------------------------------------------------------------
1: Caractéristiques sociodémographiques du ménage
-----------------------------------------------------------------------------*/

rename membres__id s01q00_a
rename nom_prenoms s01q00_b

save_section, ///
    case_ids(`case_ids_vars') ///
    vars_to_keep("s01*") /// TODO: decide whether to include preloaded data
    section_code("01") ///
    country_code("`pays'") ///
    year(`annee') ///
    output_dir("`data_dir_output'")

/*-----------------------------------------------------------------------------
2: Éducation
-----------------------------------------------------------------------------*/

use "`membres'", clear

rename membres__id s02q00a
rename nom_prenoms s02q00b

save_section, ///
    case_ids(`case_ids_vars') ///
    vars_to_keep("s02*") ///
    section_code("02") ///
    country_code("`pays'") ///
    year(`annee') ///
    output_dir("`data_dir_output'")

/*-----------------------------------------------------------------------------
3: Santé
-----------------------------------------------------------------------------*/

use "`membres'", clear

rename membres__id s03q00a
rename nom_prenoms s03q00b

save_section, ///
    case_ids(`case_ids_vars') ///
    vars_to_keep("s03*") ///
    section_code("03") ///
    country_code("`pays'") ///
    year(`annee') ///
    output_dir("`data_dir_output'")

/*-----------------------------------------------------------------------------
4A: Emploi
-----------------------------------------------------------------------------*/

use "`membres'", clear

rename membres__id s04q00a
rename nom_prenoms s04q00b

capture drop verif_canaux confirme4q23 nombrerecherchenonrenseigne canaux2

save_section, ///
    case_ids(`case_ids_vars') ///
    roster_ids("s04q00a s04q00b") ///
    vars_to_keep("s04q00_0 - s04q28b") ///
    section_code("04a") ///
    country_code("`pays'") ///
    year(`annee') ///
    output_dir("`data_dir_output'")

/*-----------------------------------------------------------------------------
4B: Emploi principal
-----------------------------------------------------------------------------*/

use "`membres'", clear

rename membres__id s04q00a
rename nom_prenoms s04q00b

save_section, ///
    case_ids(`case_ids_vars') ///
    roster_ids("s04q00a s04q00b") ///
    vars_to_keep("s04q29a - s04q50b") ///
    section_code("04b") ///
    country_code("`pays'") ///
    year(`annee') ///
    output_dir("`data_dir_output'")

/*-----------------------------------------------------------------------------
4C: Emploi secondaire
-----------------------------------------------------------------------------*/

use "`membres'", clear

rename membres__id s04q00a
rename nom_prenoms s04q00b

save_section, ///
    case_ids(`case_ids_vars') ///
    roster_ids("s04q00a s04q00b") ///
    vars_to_keep("s04q51a - s04q64_controle__59") ///
    section_code("04c") ///
    country_code("`pays'") ///
    year(`annee') ///
    output_dir("`data_dir_output'")

/*-----------------------------------------------------------------------------
5: Revenus
-----------------------------------------------------------------------------*/

use "`membres'", clear

rename membres__id s05q00a
rename nom_prenoms s05q00b

save_section, ///
    case_ids(`case_ids_vars') ///
    vars_to_keep("s05*") ///
    section_code("05") ///
    country_code("`pays'") ///
    year(`annee') ///
    output_dir("`data_dir_output'")

/*-----------------------------------------------------------------------------
6: Épargne et crédit
-----------------------------------------------------------------------------*/

use "`membres'", clear

rename membres__id s06q00a
rename nom_prenoms s06q00b

drop compte2 compte1

save_section, ///
    case_ids(`case_ids_vars') ///
    vars_to_keep("s06*") ///
    section_code("06") ///
    country_code("`pays'") ///
    year(`annee') ///
    output_dir("`data_dir_output'")

/*-----------------------------------------------------------------------------
7A: Repas pris à l'extérieur du ménage - niveau membres
-----------------------------------------------------------------------------*/

use "`membres'", clear

rename membres__id s07aq00a
rename nom_prenoms s07aq00b
rename s07aq00_0 s07aq00

save_section, ///
    case_ids(`case_ids_vars') ///
    vars_to_keep("s07a*") ///
    section_code("07a_2") ///
    country_code("`pays'") ///
    year(`annee') ///
    output_dir("`data_dir_output'")

/*-----------------------------------------------------------------------------
7A: Repas pris à l'extérieur du ménage - niveau ménage
-----------------------------------------------------------------------------*/

use "`menages'", clear

save_section, ///
    case_ids(`case_ids_vars') ///
    vars_to_keep("s07a*") ///
    section_code("07a_1") ///
    country_code("`pays'") ///
    year(`annee') ///
    output_dir("`data_dir_output'")

/*-----------------------------------------------------------------------------
7B: Consommation des 7 derniers jours et achats des 30 derniers jours
-----------------------------------------------------------------------------*/

use "`data_dir_temp'/consommation_alimentaire_7j.dta", clear

add_case_ids, ////
    source_file("`data_dir_combined'/`fichier_principal'") ///
    case_ids(`case_ids_vars' s07Bq00) /// note: add section respondent via -keepusing()- inside function

rename produit__id s07bq01

rename_vars_lower

save_section, ///
    case_ids(`case_ids_vars') ///
    vars_to_keep("s07b*") ///
    section_code("07b") ///
    country_code("`pays'") ///
    year(`annee') ///
    output_dir("`data_dir_output'")

/*-----------------------------------------------------------------------------
8: Sécurité alimentaire
-----------------------------------------------------------------------------*/

use "`menages'", clear

save_section, ///
    case_ids(`case_ids_vars') ///
    vars_to_keep("s08a*") ///
    section_code("08a") ///
    country_code("`pays'") ///
    year(`annee') ///
    output_dir("`data_dir_output'")

/*-----------------------------------------------------------------------------
9A: Dépenses des fêtes et cérémonies
-----------------------------------------------------------------------------*/

use "`data_dir_temp'/depense_fete.dta", clear

add_case_ids, ////
    source_file("`data_dir_combined'/`fichier_principal'") ///
    case_ids(`case_ids_vars' s09Aq00) /// note: add section respondent via -keepusing()- inside function

rename_vars_lower

save_section, ///
    case_ids(`case_ids_vars') ///
    vars_to_keep("s09a*") ///
    section_code("09a") ///
    country_code("`pays'") ///
    year(`annee') ///
    output_dir("`data_dir_output'")

/*-----------------------------------------------------------------------------
9B: Dépenses des 7 derniers jours
-----------------------------------------------------------------------------*/

use "`data_dir_temp'/depense_7j.dta", clear

add_case_ids, ////
    source_file("`data_dir_combined'/`fichier_principal'") ///
    case_ids(`case_ids_vars')

rename_vars_lower

save_section, ///
    case_ids(`case_ids_vars') ///
    vars_to_keep("s09b*") ///
    section_code("09b") ///
    country_code("`pays'") ///
    year(`annee') ///
    output_dir("`data_dir_output'")

/*-----------------------------------------------------------------------------
9C: Dépenses des 30 derniers jours
-----------------------------------------------------------------------------*/

use "`data_dir_temp'/depense_30j.dta", clear

add_case_ids, ////
    source_file("`data_dir_combined'/`fichier_principal'") ///
    case_ids(`case_ids_vars')

rename_vars_lower

save_section, ///
    case_ids(`case_ids_vars') ///
    vars_to_keep("s09c*") ///
    section_code("09c") ///
    country_code("`pays'") ///
    year(`annee') ///
    output_dir("`data_dir_output'")

/*-----------------------------------------------------------------------------
9D: Dépenses des 3 derniers mois
-----------------------------------------------------------------------------*/

use "`data_dir_temp'/depense_3m.dta", clear

add_case_ids, ////
    source_file("`data_dir_combined'/`fichier_principal'") ///
    case_ids(`case_ids_vars')

rename_vars_lower

save_section, ///
    case_ids(`case_ids_vars') ///
    vars_to_keep("s09d*") ///
    section_code("09d") ///
    country_code("`pays'") ///
    year(`annee') ///
    output_dir("`data_dir_output'")

/*-----------------------------------------------------------------------------
9E: Dépenses des 6 derniers mois
-----------------------------------------------------------------------------*/

use "`data_dir_temp'/depense_6m.dta", clear

add_case_ids, ////
    source_file("`data_dir_combined'/`fichier_principal'") ///
    case_ids(`case_ids_vars')

rename_vars_lower

save_section, ///
    case_ids(`case_ids_vars') ///
    vars_to_keep("s09e*") ///
    section_code("09e") ///
    country_code("`pays'") ///
    year(`annee') ///
    output_dir("`data_dir_output'")

/*-----------------------------------------------------------------------------
9F: Dépenses des 6 derniers mois
-----------------------------------------------------------------------------*/

use "`data_dir_temp'/depense_12m.dta", clear

add_case_ids, ////
    source_file("`data_dir_combined'/`fichier_principal'") ///
    case_ids(`case_ids_vars')

rename_vars_lower

save_section, ///
    case_ids(`case_ids_vars') ///
    vars_to_keep("s09f*") ///
    section_code("09f") ///
    country_code("`pays'") ///
    year(`annee') ///
    output_dir("`data_dir_output'")

/*-----------------------------------------------------------------------------
10A: Entreprises
-----------------------------------------------------------------------------*/

use "`menages'", clear

* exclure la liste, comme elle parait dans le roster des entreprises
drop s10q12a__*

save_section, ///
    case_ids(`case_ids_vars') ///
    vars_to_keep("s10*") ///
    section_code("10a") ///
    country_code("`pays'") ///
    year(`annee') ///
    output_dir("`data_dir_output'")

/*-----------------------------------------------------------------------------
10B: Entreprises
-----------------------------------------------------------------------------*/

use "`data_dir_combined'/entreprises.dta", clear

* main d'oeuvre familiale
merge 1:1 interview__key interview__id entreprises__id ///
    using "`data_dir_temp'/entreprise_travailFamilial.dta", ///
    nogen assert(1 3)
* main d'oeuvre salariée
merge 1:1 interview__key interview__id entreprises__id ///
    using "`data_dir_temp'/entreprise_travailSalarie.dta", ///
    nogen assert(1 3)

add_case_ids, ////
    source_file("`data_dir_combined'/`fichier_principal'") ///
    case_ids(`case_ids_vars')

rename_vars_lower

rename entreprises__id s10q00

save_section, ///
    case_ids(`case_ids_vars') ///
    vars_to_keep("s10*") ///
    section_code("10b") ///
    country_code("`pays'") ///
    year(`annee') ///
    output_dir("`data_dir_output'")

/*-----------------------------------------------------------------------------
11: Logement
-----------------------------------------------------------------------------*/

use "`menages'", clear

save_section, ///
    case_ids(`case_ids_vars') ///
    vars_to_keep("s11*") ///
    section_code("11") ///
    country_code("`pays'") ///
    year(`annee') ///
    output_dir("`data_dir_output'")

/*-----------------------------------------------------------------------------
12: Actifs du ménage
-----------------------------------------------------------------------------*/

use "`data_dir_temp'/actifs.dta", clear

add_case_ids, ////
    source_file("`data_dir_combined'/`fichier_principal'") ///
    case_ids(`case_ids_vars' s12q00) /// NOTE: adding respondent of section via -keepusing()- inside function

rename_vars_lower

save_section, ///
    case_ids(`case_ids_vars') ///
    vars_to_keep("s12*") ///
    section_code("12") ///
    country_code("`pays'") ///
    year(`annee') ///
    output_dir("`data_dir_output'")

/*-----------------------------------------------------------------------------
13A: Transferts reçus par le ménage - niveau ménage
-----------------------------------------------------------------------------*/

use "`menages'", clear

* exclure la liste des transferts, comme ces infos figurent dans le roster
drop s13q09a__*

save_section, ///
    case_ids(`case_ids_vars') ///
    vars_to_keep("s13*") ///
    section_code("13_1") ///
    country_code("`pays'") ///
    year(`annee') ///
    output_dir("`data_dir_output'")

/*-----------------------------------------------------------------------------
13A: Transferts reçus par le ménage - niveau transfert
-----------------------------------------------------------------------------*/

use "`data_dir_combined'/transferts_recus.dta", clear

add_case_ids, ////
    source_file("`data_dir_combined'/`fichier_principal'") ///
    case_ids(`case_ids_vars')

rename s13q09a s13q09b // description du transfert
rename transferts_recus__id s13q09a // identifiant du transfert

rename_vars_lower

save_section, ///
    case_ids(`case_ids_vars') ///
    vars_to_keep("s13*") ///
    section_code("13_2") ///
    country_code("`pays'") ///
    year(`annee') ///
    output_dir("`data_dir_output'")

/*-----------------------------------------------------------------------------
14A: COVID-19 et impact sur les ménages
-----------------------------------------------------------------------------*/

use "`data_dir_temp'/s14.dta", clear

add_case_ids, ////
    source_file("`data_dir_combined'/`fichier_principal'") ///
    case_ids(`case_ids_vars' s14aq00) /// NOTE: adding respondent of section via -keepusing()- inside function

rename_vars_lower

save_section, ///
    case_ids(`case_ids_vars') ///
    vars_to_keep("s14a*") ///
    section_code("14a") ///
    country_code("`pays'") ///
    year(`annee') ///
    output_dir("`data_dir_output'")

/*-----------------------------------------------------------------------------
14B: Chocs et stratégie de survie
-----------------------------------------------------------------------------*/

use "`data_dir_temp'/chocs.dta", clear

add_case_ids, ////
    source_file("`data_dir_combined'/`fichier_principal'") ///
    case_ids(`case_ids_vars' s14bq00) /// NOTE: adding respondent of section via -keepusing()- inside function

rename_vars_lower

save_section, ///
    case_ids(`case_ids_vars') ///
    vars_to_keep("s14b*") ///
    section_code("14b") ///
    country_code("`pays'") ///
    year(`annee') ///
    output_dir("`data_dir_output'")

/*-----------------------------------------------------------------------------
15: Filets de survie
-----------------------------------------------------------------------------*/

use "`data_dir_temp'/filets_securite.dta", clear

add_case_ids, ////
    source_file("`data_dir_combined'/`fichier_principal'") ///
    case_ids(`case_ids_vars' s15q00) /// NOTE: adding respondent of section via -keepusing()- inside function

rename_vars_lower

save_section, ///
    case_ids(`case_ids_vars') ///
    vars_to_keep("s15*") ///
    section_code("15") ///
    country_code("`pays'") ///
    year(`annee') ///
    output_dir("`data_dir_output'")

/*-----------------------------------------------------------------------------
16A: Parcelles
-----------------------------------------------------------------------------*/

use "`data_dir_temp'/s16a.dta", clear   

* champs
rename champs__id s16aq02 // identifiant

* parcelles
rename s16Aa01b s16aq03b // nom
rename parcelles__id s16aq03 // identifiant

add_case_ids, ///
    source_file("`data_dir_combined'/`fichier_principal'") ///
    case_ids(`case_ids_vars' s16Aq00) /// NOTE: filter question about cropping

rename_vars_lower

save_section, ///
    case_ids(`case_ids_vars') ///
    vars_to_keep("s16a*") ///
    section_code("16a") ///
    country_code("`pays'") ///
    year(`annee') ///
    output_dir("`data_dir_output'")

/*-----------------------------------------------------------------------------
16B: Coût des intrants
-----------------------------------------------------------------------------*/

use "`data_dir_temp'/cout_intrants.dta", clear

add_case_ids, ///
    source_file("`data_dir_combined'/`fichier_principal'") ///
    case_ids(`case_ids_vars')

rename_vars_lower

save_section, ///
    case_ids(`case_ids_vars') ///
    vars_to_keep("s16b*") ///
    section_code("16b") ///
    country_code("`pays'") ///
    year(`annee') ///
    output_dir("`data_dir_output'")

/*-----------------------------------------------------------------------------
16C: Cultures
-----------------------------------------------------------------------------*/

use "`data_dir_temp'/s16c.dta", clear

* champs
rename champs__id s16cq02 // identifiant

* parcelles
rename s16Aa01b s16cq03b // nom
rename parcelles__id s16cq03 // identifiant

* cultures
rename cultures__id s16cq04

add_case_ids, ///
    source_file("`data_dir_combined'/`fichier_principal'") ///
    case_ids(`case_ids_vars')

rename_vars_lower

save_section, ///
    case_ids(`case_ids_vars') ///
    vars_to_keep("s16c*") ///
    section_code("16c") ///
    country_code("`pays'") ///
    year(`annee') ///
    output_dir("`data_dir_output'")

/*-----------------------------------------------------------------------------
16D: Utilisation de la production
-----------------------------------------------------------------------------*/

use "`data_dir_temp'/s16d.dta", clear

rename culture_utilisation__id s16dq01

add_case_ids, ///
    source_file("`data_dir_combined'/`fichier_principal'") ///
    case_ids(`case_ids_vars')

rename_vars_lower

save_section, ///
    case_ids(`case_ids_vars') ///
    vars_to_keep("s16d*") ///
    section_code("16d") ///
    country_code("`pays'") ///
    year(`annee') ///
    output_dir("`data_dir_output'")

/*-----------------------------------------------------------------------------
17: Élevage
-----------------------------------------------------------------------------*/

use "`data_dir_temp'/elevage.dta", clear

add_case_ids, ///
    source_file("`data_dir_combined'/`fichier_principal'") ///
    case_ids(`case_ids_vars')

rename_vars_lower

save_section, ///
    case_ids(`case_ids_vars') ///
    vars_to_keep("s17*") ///
    section_code("17") ///
    country_code("`pays'") ///
    year(`annee') ///
    output_dir("`data_dir_output'")

/*-----------------------------------------------------------------------------
18: Pêche
-----------------------------------------------------------------------------*/

/*- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
Niveau ménage
- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -*/

use "`menages'", clear

* exclure les listes de poisson, comme elle paraissent dans les bases des saisons
drop s18q14__* s18q20__*

rename s18q14autre s18q14_autre 
rename s18q22autre s18q22_autre 

rename_vars_lower

save_section, ///
    case_ids(`case_ids_vars') ///
    vars_to_keep("s18*") ///
    section_code("18_1") ///
    country_code("`pays'") ///
    year(`annee') ///
    output_dir("`data_dir_output'")

/*- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
Niveau haute saison
- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -*/

use "`data_dir_combined'/poisson_haute_saison.dta", clear

add_case_ids, ///
    source_file("`data_dir_combined'/`fichier_principal'") ///
    case_ids(`case_ids_vars')

rename poisson_haute_saison__id s18q14

rename_vars_lower

save_section, ///
    case_ids(`case_ids_vars') ///
    vars_to_keep("s18*") ///
    section_code("18_2") ///
    country_code("`pays'") ///
    year(`annee') ///
    output_dir("`data_dir_output'")

/*- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
Niveau basse saison
- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -*/

use "`data_dir_combined'/poisson_basse_saison.dta", clear

add_case_ids, ///
    source_file("`data_dir_combined'/`fichier_principal'") ///
    case_ids(`case_ids_vars')

rename poisson_basse_saison__id s18q20

rename_vars_lower

save_section, ///
    case_ids(`case_ids_vars') ///
    vars_to_keep("s18*") ///
    section_code("18_3") ///
    country_code("`pays'") ///
    year(`annee') ///
    output_dir("`data_dir_output'")

/*-----------------------------------------------------------------------------
19: Équipements
-----------------------------------------------------------------------------*/

use "`data_dir_combined'/equipements.dta", clear

add_case_ids, ///
    source_file("`data_dir_combined'/`fichier_principal'") ///
    case_ids(`case_ids_vars' s19q00 s19q01) /// NOTE: adding filter and respondent questions from hhold level

rename equipements__id s19q02

rename_vars_lower

save_section, ///
    case_ids(`case_ids_vars') ///
    vars_to_keep("s19*") ///
    section_code("19") ///
    country_code("`pays'") ///
    year(`annee') ///
    output_dir("`data_dir_output'")

/*-----------------------------------------------------------------------------
20A: Pauvreté subjective
-----------------------------------------------------------------------------*/

use "`menages'", clear

save_section, ///
    case_ids(`case_ids_vars') ///
    vars_to_keep("s20q00 s20a*") ///
    section_code("20a") ///
    country_code("`pays'") ///
    year(`annee') ///
    output_dir("`data_dir_output'")

/*-----------------------------------------------------------------------------
20B: Gouvernance
-----------------------------------------------------------------------------*/

/*- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
Niveau ménage
- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -*/

use "`menages'", clear

save_section, ///
    case_ids(`case_ids_vars') ///
    vars_to_keep("s20b*") ///
    section_code("20b_1") ///
    country_code("`pays'") ///
    year(`annee') ///
    output_dir("`data_dir_output'")

/*- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
Gouvernance roster
- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -*/

use "`data_dir_combined'/Gouvernance.dta", clear

add_case_ids, ///
    source_file("`data_dir_combined'/`fichier_principal'") ///
    case_ids(`case_ids_vars')

rename Gouvernance__id s20bq02

rename_vars_lower

save_section, ///
    case_ids(`case_ids_vars') ///
    vars_to_keep("s20b*") ///
    section_code("20b_2") ///
    country_code("`pays'") ///
    year(`annee') ///
    output_dir("`data_dir_output'")

/*- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
Discrimination roster
- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -*/

use "`data_dir_combined'/discrimination.dta", clear

add_case_ids, ///
    source_file("`data_dir_combined'/`fichier_principal'") ///
    case_ids(`case_ids_vars')

rename discrimination__id s20bq05

rename_vars_lower

save_section, ///
    case_ids(`case_ids_vars') ///
    vars_to_keep("s20b*") ///
    section_code("20b_3") ///
    country_code("`pays'") ///
    year(`annee') ///
    output_dir("`data_dir_output'")

/*-----------------------------------------------------------------------------
20C: Insécurité
-----------------------------------------------------------------------------*/

use "`menages'", clear

save_section, ///
    case_ids(`case_ids_vars') ///
    vars_to_keep("s20c*") ///
    section_code("20c") ///
    country_code("`pays'") ///
    year(`annee') ///
    output_dir("`data_dir_output'")
