#' Get structured metadata for one or more Finnish statutes
#'
#' Retrieves core bibliographic metadata for one or more Finnish statutes
#' from the Finlex Open Data API: the date of issue, the official title,
#' and the number of sections (Finnish: *pykälät*) in the statute text.
#'
#' @param year Integer vector. Year(s) of the statute(s).
#' @param number Integer vector. Number(s) of the statute(s) within that
#'   year. Recycled against `year` if shorter.
#'
#' @return A [tibble::tibble()] with one row per `(year, number)` pair and
#'   the columns:
#'   \describe{
#'     \item{year}{As supplied.}
#'     \item{number}{As supplied.}
#'     \item{status}{One of `"ok"`, `"not_found"`, or `"error"`.}
#'     \item{date_issued}{Date the statute was issued, as a [Date].}
#'     \item{title}{The statute's official title.}
#'     \item{n_sections}{Integer. Number of `section` elements found in the
#'       Akoma Ntoso document — a rough, purely structural proxy for
#'       statute length.}
#'   }
#'
#' @details
#' This function intentionally returns only raw, directly observed fields.
#' Any derived classification (for example, grouping statutes into
#' categories such as "Act", "Decree", or "Decision" based on title
#' patterns) is left to a separate function, since that involves
#' methodological choices rather than data retrieval.
#'
#' @export
#'
#' @examples
#' \donttest{
#' flx_get_metadata(year = 1992, number = 1535) # Tuloverolaki
#' }
flx_get_metadata <- function(year, number) {

  stopifnot(is.numeric(year), is.numeric(number))

  n <- max(length(year), length(number))
  year   <- rep_len(as.integer(year), n)
  number <- rep_len(as.integer(number), n)

  out <- vector("list", n)

  for (i in seq_len(n)) {
    out[[i]] <- flx_get_metadata_one(year[i], number[i])
    if (n > 1) Sys.sleep(0.3)
  }

  dplyr::bind_rows(out)
}

#' Get structured metadata for a single Finnish statute
#'
#' Internal helper used by [flx_get_metadata()].
#'
#' @param year Integer. Year of the statute.
#' @param number Integer. Number of the statute within that year.
#'
#' @return A one-row [tibble::tibble()], see [flx_get_metadata()] for
#'   columns.
#' @keywords internal
#' @noRd
flx_get_metadata_one <- function(year, number) {

  uri <- sprintf(
    "https://opendata.finlex.fi/finlex/avoindata/v1/akn/fi/act/statute/%d/%d/fin@",
    year, number
  )

  empty <- tibble::tibble(
    year        = year,
    number      = number,
    status      = NA_character_,
    date_issued = as.Date(NA_character_),
    title       = NA_character_,
    n_sections  = NA_integer_
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

  date_node <- xml2::xml_find_first(
    doc, "//d1:FRBRWork/d1:FRBRdate[@name='dateIssued']", ns
  )
  date_issued <- if (inherits(date_node, "xml_missing")) {
    NA_character_
  } else {
    xml2::xml_attr(date_node, "date")
  }

  titles <- xml2::xml_text(xml2::xml_find_all(doc, "//d1:docTitle", ns))
  titles <- trimws(titles[nzchar(trimws(titles))])

  n_sections <- length(xml2::xml_find_all(doc, "//d1:section", ns))

  tibble::tibble(
    year        = year,
    number      = number,
    status      = "ok",
    date_issued = as.Date(date_issued),
    title       = if (length(titles) == 0) NA_character_ else titles[1],
    n_sections  = as.integer(n_sections)
  )
}
