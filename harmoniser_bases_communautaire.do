/*=============================================================================
Parmétrage
=============================================================================*/

/*-----------------------------------------------------------------------------
Paramètres du programme
-----------------------------------------------------------------------------*/

local proj_dir 	""
local fichier_principal ""
local case_ids_vars "grappe vague"
local pays ""
local annee "2021"

/*-----------------------------------------------------------------------------
Confirmer les paramètres fournis
-----------------------------------------------------------------------------*/

* répertoire proj_dir existe
capture cd "`prog_dir'"
if _rc ! = 0 {
    di as error "Le répertoire désigné dans le paramètre -prog_dir- n'existe pas"
    error 1
}

* fichier_principal
* case_ids_vars


* pays n'est pas vide
capture assert "`pays'" != ""
if _rc ! = 0 {
    di as error "Le paramètre -pays- a été laissé vide"
    error 1
}

* annee n'est pas vide
capture assert "`annee'" != ""
if _rc ! = 0 {
    di as error "Le paramètre -annee- a été laissé vide"
    error 1
}

/*-----------------------------------------------------------------------------
Définir les répertoires
-----------------------------------------------------------------------------*/

* données
local data_dir_raw      "`proj_dir'/data/0_downloaded/communautaire/"	// données brutes
local data_dir_combined "`proj_dir'/data/1_combined/communautaire/" 	// données légèrement modifiées
local data_dir_temp     "`proj_dir'/data/2_temp/communautaire/" 		// fichiers temporaires
local data_dir_output   "`proj_dir'/data/3_output/communautaire/" 	    // données finales

* étiquettes
local lbl_dir_temp  "`proj_dir'/labels/temp/communautaire/"
local lbl_dir_out   "`proj_dir'/labels/output/communautaire/"

* programmes
local prog_dir "`proj_dir'/programs/"

/*-----------------------------------------------------------------------------
Comportement de Stata
-----------------------------------------------------------------------------*/

set more 1

/*-----------------------------------------------------------------------------
Charger les programmes de service
-----------------------------------------------------------------------------*/

include "`prog_dir'/appendAll.do"
include "`prog_dir'/reshape_multi_select_yn.do"
include "`prog_dir'/reshape_nested_to_wide.do"
include "`prog_dir'/add_case_ids.do"
include "`prog_dir'/rename_vars_lower.do"
include "`prog_dir'/recode_yes1_no2.do"
include "`prog_dir'/save_section.do"

/*=============================================================================
Purger les fichiers de séances passées
=============================================================================*/

/*-----------------------------------------------------------------------------
Répertoires avec des fichiers Stata à la racine
-----------------------------------------------------------------------------*/

local dirs "data_dir_combined data_dir_temp data_dir_output"

foreach dir of local dirs {

    local files: dir "``dir''" files "*.dta"

    foreach file of local files {
        rm "``dir''/`file'"
    }

}

/*-----------------------------------------------------------------------------
Répertoires avec des fichiers do à la racide
-----------------------------------------------------------------------------*/

local dirs "lbl_dir_temp lbl_dir_out"

foreach dir of local dirs {

    local files: dir "``dir''" files "*.do"

    foreach file of local files {
        rm "``dir''/`file'"
    }

}

/*=============================================================================
Fusionner les bases
=============================================================================*/

/*-----------------------------------------------------------------------------
Toutes les bases
-----------------------------------------------------------------------------*/

* confirm that the download folder contains sub-folders
local data_folders : dir "`data_dir_raw'" dirs "*", respectcase

capture assert `"`data_folders'"' ! = ""
if _rc != 0 {
    di as error "Le répertoire /0_downloaded/ doit contenir des sous-répertoires qui, eux, contiennent des fichiers dta."
    error 1
}

* append together same-named files from different template versions
appendAll, 							    ///
	inputDir("`data_dir_raw'") 		    ///	où chercher les données téléchargées
	outputDir("`data_dir_combined'")    /// où sauvegarder la concatination

/*=============================================================================
Modifier le nom des fichiers (au besoin)
=============================================================================*/

/* 

* Modèle pour modifier
* voir le code à partir d'ici: https://github.com/arthur-shaw/ehcvm-transformer-bases/blob/24e32bf79f4588c783793fb967759aa62d1aa548/transformerQnrMenage.do#L97 

local ancien_nom ""
local nouveau_nom ""

cd "`data_dir_combined'"

ren "`ancien_nom'" "`nouveau_nom'"

 */

/*=============================================================================
Vérifier l'existence des bases escomptés
=============================================================================*/

#delim ;
local bases_attendus "
section0.dta
`fichier_principal'
infrastructures.dta
service_sociaux.dta
";
#delim cr

foreach base of local bases_attendus {

    capture confirm file "`data_dir_combined'/`base'"

    if _rc != 0 {

        di as error "Fichier `base' pas retrouvé dans le répertoire /data/combined/"
        error 1

    }

}


/*=============================================================================
Rendre les rosters conformes à leur forme dans questionnaire papier
=============================================================================*/

/*-----------------------------------------------------------------------------
Ramener la question filtre oui/non dans le roster
-----------------------------------------------------------------------------*/

* Section 2: Existence et accessibilité aux services sociaux
reshape_multi_select_yn, ///
    input_dir("`data_dir_combined'") ///
    main_file("`fichier_principal'") ///
    roster_file("service_sociaux.dta") ///
    trigger_var("s02q01") ///
    item_code_var("service_sociaux__id") ///
    new_roster_id_var("s02q00") ///
    output_dir("`data_dir_temp'") ///

* section 4: Participation communautaire
reshape_multi_select_yn, ///
    input_dir("`data_dir_combined'") ///
    main_file("`fichier_principal'") ///
    roster_file("infrastructures.dta") ///
    trigger_var("s04q01") ///
    item_code_var("infrastructures__id") ///
    new_roster_id_var("s04q00") ///
    output_dir("`data_dir_temp'") ///

/*-----------------------------------------------------------------------------
reshape nested roster to wide
-----------------------------------------------------------------------------*/

* N/A

/*=============================================================================
Créer des fichiers par section
=============================================================================*/

/*-----------------------------------------------------------------------------
Section 0: Liste des personnes répondantes
-----------------------------------------------------------------------------*/

use "`data_dir_combined'/section0.dta", clear

add_case_ids, ///
    source_file("`data_dir_combined'/`fichier_principal'") ///
    case_ids(`case_ids_vars')

rename section0__id s00q00
capture rename s00q011 s00q01

save_section, ///
    case_ids(`case_ids_vars') ///
    vars_to_keep("s00*") /// 
    section_code("00") ///
    country_code("`pays'") ///
    type("comm") ///
    year(`annee') ///
    output_dir("`data_dir_output'")

/*-----------------------------------------------------------------------------
Section 1: Caractéristiques du village
-----------------------------------------------------------------------------*/

use "`data_dir_combined'/`fichier_principal'", clear

recode_yes1_no2, vars("s01q08__*")
recode_yes1_no2, vars("s01q13__*")
recode_yes1_no2, vars("s01q14__*")

save_section, ///
    case_ids(`case_ids_vars') ///
    vars_to_keep("s01*") /// 
    section_code("01") ///
    country_code("`pays'") ///
    type("comm") ///
    year(`annee') ///
    output_dir("`data_dir_output'")

/*-----------------------------------------------------------------------------
Section 2: Existence et accessibilité aux services sociaux
-----------------------------------------------------------------------------*/

use "`data_dir_temp'/service_sociaux.dta", clear

add_case_ids, ///
    source_file("`data_dir_combined'/`fichier_principal'") ///
    case_ids(`case_ids_vars')

save_section, ///
    case_ids(`case_ids_vars') ///
    vars_to_keep("s02*") /// 
    section_code("02") ///
    country_code("`pays'") ///
    type("comm") ///
    year(`annee') ///
    output_dir("`data_dir_output'")

/*-----------------------------------------------------------------------------
Section 3: Agriculture
-----------------------------------------------------------------------------*/

use "`data_dir_combined'/`fichier_principal'", clear

recode_yes1_no2, vars("s03q04__*")

save_section, ///
    case_ids(`case_ids_vars') ///
    vars_to_keep("s03*") /// 
    section_code("03") ///
    country_code("`pays'") ///
    type("comm") ///
    year(`annee') ///
    output_dir("`data_dir_output'")

/*-----------------------------------------------------------------------------
Section 4: Participation communautaire
-----------------------------------------------------------------------------*/

use "`data_dir_temp'/infrastructures.dta", clear

add_case_ids, ///
    source_file("`data_dir_combined'/`fichier_principal'") ///
    case_ids(`case_ids_vars')

recode_yes1_no2, vars("s04q07__*")
recode_yes1_no2, vars("s04q09__*")

save_section, ///
    case_ids(`case_ids_vars') ///
    vars_to_keep("s04*") /// 
    section_code("04") ///
    country_code("`pays'") ///
    type("comm") ///
    year(`annee') ///
    output_dir("`data_dir_output'")
