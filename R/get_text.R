#' Get the full text of one or more Finnish statutes, by section
#'
#' Retrieves the body text of a Finnish statute from the Finlex Open Data
#' API, split into one row per section (*pykälä*). This complements
#' [flx_get_metadata()], which only reports the *number* of sections; this
#' function returns their actual content.
#'
#' @param year Integer vector. Year(s) of the statute(s).
#' @param number Integer vector. Number(s) of the statute(s) within that
#'   year. Recycled against `year` if shorter.
#'
#' @return A [tibble::tibble()] with one row per section (or one row with
#'   `NA` section fields if the statute has no sections, was not found, or
#'   an error occurred) and the columns:
#'   \describe{
#'     \item{year}{Year of the statute, as supplied.}
#'     \item{number}{Number of the statute, as supplied.}
#'     \item{status}{One of `"ok"`, `"no_sections"` (statute found, but
#'       contains no `section` elements — for example a very short
#'       decision), `"not_found"`, or `"error"`.}
#'     \item{section_index}{Integer. The section's position within the
#'       statute (1-based), in document order.}
#'     \item{section_id}{Character. The section's Akoma Ntoso `eId`
#'       attribute, if present (for example `"sec_1"`).}
#'     \item{heading}{Character. The section heading, if present.}
#'     \item{text}{Character. The full text of the section, including its
#'       heading.}
#'   }
#'
#' @details
#' Statutes can be long. Calling this function for many statutes at once
#' will be slow and will retrieve a large amount of text — consider
#' narrowing down to the statutes you actually need (for example with
#' [flx_download_statutes()] or [flx_get_metadata()]) before calling this
#' function.
#'
#' @export
#'
#' @examples
#' \donttest{
#' flx_get_text(year = 1992, number = 1535) # Tuloverolaki, all sections
#' }
flx_get_text <- function(year, number) {
  
  stopifnot(is.numeric(year), is.numeric(number))
  
  n <- max(length(year), length(number))
  year   <- rep_len(as.integer(year), n)
  number <- rep_len(as.integer(number), n)
  
  out <- vector("list", n)
  
  for (i in seq_len(n)) {
    out[[i]] <- flx_get_text_one(year[i], number[i])
    if (n > 1) Sys.sleep(0.3)
  }
  
  dplyr::bind_rows(out)
}

#' Get the full text of a single Finnish statute, by section
#'
#' Internal helper used by [flx_get_text()].
#'
#' @param year Integer. Year of the statute.
#' @param number Integer. Number of the statute within that year.
#'
#' @return A [tibble::tibble()] with one row per section, see
#'   [flx_get_text()] for columns.
#' @keywords internal
#' @noRd
flx_get_text_one <- function(year, number) {
  
  uri <- sprintf(
    "https://opendata.finlex.fi/finlex/avoindata/v1/akn/fi/act/statute/%d/%d/fin@",
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
  
  # An empty AknXmlList means the statute is not present in the API,
  # even though the HTTP request itself succeeded (status 200).
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