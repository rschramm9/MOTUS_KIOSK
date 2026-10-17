# functions in this module are used to implement species name aliases

# 16-Oct-2026
# discovered some people use different common names for species  (eg. Hoary Bat,
# American Bat, Northern Hoary Bat). Also sometimes they append the latin 
# name (eg.Purple Martin (subis/arboricola) ).
# This is causing problems when looking up species pages.  While it has
# worked to just duplicate the species directories using both names that is
# not an ideal solution as it can lead to inconsistencies and is not scalable.
# Also it can cause issues when deploying the app to shiney.io with filenames
# becoming too long.

# Species alias utilities. Requires package 'jsonlite'.

# The strategy of concatenating only the alpha characters together, stripping
# any non-alpha characters and lowercasing the string is retained.
# (see documentation: START_HERE.md Section 12.0 - Configure your own "Species"
# tab content)

# we now add code to load from a json file, al list of master species names and
# their aliases. Master names are the normalized lowercase alphanumeric strings.

# On any error in looking up the master key the normalized alpha-only string is returned.

# All lookups use lowercase alphanumeric-only species keys.

normalize_species_name <- function(species_name) {
 
  
  if (!is.character(species_name)) {
    ErrorPrint(paste0("normalize_species_name() Expected a character string argument; received type '",
                      typeof(species_name), "'."))
    return("unknown")
  }
  
  if (length(species_name) != 1L) {
    ErrorPrint(paste0("normalize_species_name() Expected exactly one species name argument; received length ",
                             length(species_name), "."))
    return("unknown")
  }
  
  if (!is.null(attributes(species_name))) {
    ErrorPrint("normalize_species_name() Expected a plain character scalar, not an attributed object, array, or matrix.")
    return("unknown")
  }
  
  if (is.na(species_name)) {
    ErrorPrint("normalize_species_name() Species name argument is NA.")
    return("unknown")
  }
  
  if (!nzchar(trimws(species_name))) {
    ErrorPrint("normalize_species_name() Species name argument is empty or whitespace only.")
    return("unknown")
  }
  
  tryCatch({
    key <- tolower(gsub("[^[:alnum:]]", "", species_name))
    if (is.na(key) || !nzchar(key)) {
      ErrorPrint(paste0("normalize_species_name() Normalization yielded no alphanumeric characters for input: '",
                        length(species_name), "."))
      return("unknown")
    }
    return(key)
  }, error = function(e) {
    ErrorPrint(paste0("[normalize_species_name] Unable to normalize species_name."))
    ErrorPrint(paste0("[normalize_species_name] species_name:",species_name))
    ErrorPrint(paste0("[normalize_species_name] Here is the returned error message:",conditionMessage(e)))
    return("unknown")
  })
}

# Validate the parsed JSON as a named list of alias character arrays.
# Duplicate aliases under the SAME master are acceptable, even if they
# differ only in punctuation/case; aliases shared by DIFFERENT masters are not.
validate_species_names <- function(species_names) {
  if (!is.list(species_names) || is.object(species_names) ||
      !is.null(dim(species_names)) || length(species_names) == 0L) {
    stop("Species alias data must be a nonempty JSON object of master names to alias arrays.",
         call. = FALSE)
  }
  masters <- names(species_names)
  if (is.null(masters) || length(masters) != length(species_names) ||
      anyNA(masters) || any(!nzchar(masters)) || anyDuplicated(masters)) {
    stop("Each master species name name in species alias json file must be nonempty and unique.", call. = FALSE)
  }
  if (any(!grepl("^[a-z0-9]+$", masters))) {
    stop("Master species names in species alias json file must contain only lowercase ASCII letters and digits.",
         call. = FALSE)
  }
  
  # Map normalized alias -> master in an environment for collision checks.
  seen <- new.env(parent = emptyenv(), hash = TRUE)
  for (master in masters) {
    aliases <- species_names[[master]]
    # jsonlite::fromJSON(..., simplifyVector=FALSE) produces alias lists.
    if (!is.list(aliases) || !is.null(names(aliases)) ||
        !is.null(dim(aliases)) || length(aliases) == 0L) {
      stop(sprintf("Aliases for '%s'in species alias json filemust be a nonempty JSON array of strings.", master),
           call. = FALSE)
    }
    for (alias in c(list(master), aliases)) {
      if (!is.character(alias) || length(alias) != 1L ||
          !is.null(attributes(alias)) || is.na(alias) ||
          !nzchar(trimws(alias))) {
        stop(sprintf("Invalid alias in species alias json file under master '%s': must be a nonempty string.", master),
             call. = FALSE)
      }
      key <- tolower(gsub("[^[:alnum:]]", "", alias))
      if (!nzchar(key)) {
        stop(sprintf("Invalid alias in species alias json file '%s' under '%s': no alphanumeric characters.",
                     alias, master), call. = FALSE)
      }
      if (exists(key, envir = seen, inherits = FALSE)) {
        prior <- get(key, envir = seen, inherits = FALSE)
        if (!identical(prior, master)) {
          stop(sprintf("Alias in species alias json file '%s' (normalized '%s') maps to both '%s' and '%s'.",
                       alias, key, prior, master), call. = FALSE)
        }
      } else {
        assign(key, master, envir = seen)
      }
    }
  }
  invisible(TRUE)
}

read_species_names <- function(filename) {
  if (!is.character(filename) || length(filename) != 1L || is.na(filename) ||
      !nzchar(filename)) {
    stop(" in species alias json file filename must be one nonempty path string.", call. = FALSE)
  }
  if (!requireNamespace("jsonlite", quietly = TRUE)) {
    stop("Package 'jsonlite' is not installed. Run install.packages('jsonlite').",
         call. = FALSE)
  }
  # simplifyVector=FALSE preserves JSON arrays vs objects for strict validation.
  data <- jsonlite::fromJSON(filename, simplifyVector = FALSE)
  validate_species_names(data)
  data
}

build_species_lookup <- function(species_names) {
  validate_species_names(species_names)
  lookup <- character(0)
  for (master in names(species_names)) {
    aliases <- c(master, unlist(species_names[[master]], use.names = FALSE))
    keys <- unique(tolower(gsub("[^[:alnum:]]", "", aliases)))
    lookup[keys] <- master
  }
  lookup
}

#load_species_lookup <- function(filename = "species_name_aliases.json") {
load_species_lookup <- function(filename) {
  # if the alias file is missing, just warn and proceed as will only result in
  # possible species_unknown pages

  if (!is.character(filename) || length(filename) != 1L ||
      is.na(filename) || !nzchar(filename) || !file.exists(filename)) {
    WarningPrint(paste0("Species alias json file was not found or filename invalid."))
    WarningPrint(paste0("Looking for file:", filename))
    WarningPrint(paste0("Species alias lookup will be disabled."))
    return(NULL)
  }
  
  # but if it is found, then parse validate the json and stop on error
  tryCatch({
    build_species_lookup(read_species_names(filename))
    
  }, error = function(e) {
    FatalPrint(paste0("[load_species_lookup] Failed trying to load, and validate species aliases from json file."))
    FatalPrint(paste0("[load_species_lookup] Filename:",filename))
    FatalPrint(paste0("[load_species_lookup] Here is the returned error message:",conditionMessage(e)))
    FatalPrint(paste0("[load_species_lookup] Possibly invalid json formatting, duplicate species key or alias name, missing or extra brackets, commas etc.. "))
    FatalPrint(paste0("[load_species_lookup] Check the json file carefully using the error info above."))
    stop(paste0("Fatal error reading the species alias json file:",filename," Check the json file carefully using the error info above. "),
         call. = FALSE)
    NULL
  })
}

get_species_key <- function(species_name, species_lookup = NULL) {
  #DebugPrint(paste0("entered get_species_key() with name:", species_name))
  species_key <- normalize_species_name(species_name)
  #DebugPrint(paste0("Normalized name to key:", species_key))
  if (identical(species_key, "unknown")) {
    #DebugPrint("first unknown")
    return("unknown")
  }
  if (is.null(species_lookup) || length(species_lookup) == 0L) {
    #DebugPrint("second is null or empty")
    return(species_key)
  }
  # Protect the application if a malformed lookup is passed inadvertently.
  if (!is.character(species_lookup) || is.null(names(species_lookup))) {
    ErrorPrint("get_species_key: Invalid lookup object; using normalized species key.")
    return(species_key)
  }
  
  #DebugPrint("look for master key")
  master_key <- unname(species_lookup[species_key])
  if (length(master_key) == 1L && !is.na(master_key) &&
      is.character(master_key) && nzchar(master_key)) {
    #DebugPrint(paste0("return master key:", master_key))
    return(master_key)
  }
  #DebugPrint(paste0("return original key normalized:",species_key))
  return(species_key)
}

