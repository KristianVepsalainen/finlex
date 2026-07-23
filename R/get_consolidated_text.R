#' Get the consolidated (up-to-date) text of one or more Finnish statutes
#'
#' Retrieves the *consolidated* version of a statute -- the text as
#' currently in force, with all amendments merged in -- split into one
#' row per section (Finnish: *pykala*). This complements [flx_get_text()],
#' which returns the statute's *original*, as-enacted text.
#'
#' @param year Integer vector. Year(s) of the statute(s) as originally
#'   enacted. The consolidated version shares the same year/number as the
#'   original statute -- it is a different rendering of the same legal
#'   work, not a separate document.
#' @param number Integer vector. Number(s) of the statute(s) within that
#'   year. Recycled against `year` if shorter.
#'
#' @return A tibble with one row per section (or one row with `NA`
#'   section fields if the statute has no sections, has no consolidated
#'   version, was not found, or an error occurred) and the columns:
#'   `year`, `number`, `status` (one of `"ok"`, `"no_sections"`,
#'   `"not_found"`, or `"error"`), `section_index`, `section_id`,
#'   `heading`, and `text`.
#'
#' @details
#' Not every statute has a consolidated version available -- for example,
#' very recent statutes that have never been amended, or statutes outside
#' the API's consolidation coverage, will return `status = "not_found"`.
#'
#' @export
#'
#' @examples
#' \donttest{
#' flx_get_consolidated_text(year = 1992, number = 1535) # Tuloverolaki
#' }
flx_get_consolidated_text <- function(year, number) {
  
  stopifnot(is.numeric(year), is.numeric(number))
  
  n <- max(length(year), length(number))
  year   <- rep_len(as.integer(year), n)
  number <- rep_len(as.integer(number), n)
  
  out <- vector("list", n)
  
  for (i in seq_len(n)) {
    out[[i]] <- flx_get_consolidated_text_one(year[i], number[i])
    if (n > 1) Sys.sleep(0.3)
  }
  
  dplyr::bind_rows(out)
}

#' Get the consolidated text of a single Finnish statute, by section
#'
#' Internal helper used by [flx_get_consolidated_text()].
#'
#' @param year Integer. Year of the statute.
#' @param number Integer. Number of the statute within that year.
#'
#' @return A one-row tibble, see [flx_get_consolidated_text()] for
#'   columns.
#' @keywords internal
#' @noRd
flx_get_consolidated_text_one <- function(year, number) {
  
  uri <- sprintf(
    "https://opendata.finlex.fi/finlex/avoindata/v1/akn/fi/act/statute-consolidated/%d/%d/fin@latest",
    year, number
  )
  
  empty <- tibble::tibble(
    year          = year,
    number        = number,
    status        = NA_character_,
    section_index = NA_integer_,
    section_id    = NA_character_,
    heading       = NA_character_,
    text          = NA_character_
  )
  
  resp <- tryCatch(
    flx_request(uri, accept = "application/xml"),
    httr2_http_404 = function(e) NULL,
    error = function(e) e
  )
  
  if (inherits(resp, "error")) {
    empty$status <- "error"
    return(empty)
  }
  if (is.null(resp)) {
    empty$status <- "not_found"
    return(empty)
  }
  
  doc <- xml2::read_xml(httr2::resp_body_string(resp))
  root_name <- xml2::xml_name(doc)
  
  # An empty AknXmlList means no consolidated version is present in the
  # API, even though the HTTP request itself succeeded (status 200).
  if (identical(root_name, "AknXmlList")) {
    empty$status <- "not_found"
    return(empty)
  }
  
  ns <- xml2::xml_ns(doc)
  sections <- xml2::xml_find_all(doc, "//d1:section", ns)
  
  if (length(sections) == 0) {
    empty$status <- "no_sections"
    return(empty)
  }
  
  section_id <- xml2::xml_attr(sections, "eId")
  
  heading <- vapply(sections, function(sec) {
    h <- xml2::xml_find_first(sec, ".//d1:heading", ns)
    if (inherits(h, "xml_missing")) NA_character_ else trimws(xml2::xml_text(h))
  }, character(1))
  
  text <- trimws(xml2::xml_text(sections))
  
  tibble::tibble(
    year          = year,
    number        = number,
    status        = "ok",
    section_index = seq_along(sections),
    section_id    = section_id,
    heading       = heading,
    text          = text
  )
}