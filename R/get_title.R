#' Get the title of one or more Finnish statutes
#'
#' Retrieves the official title of one or more Finnish statutes from the
#' Finlex Open Data API, given each statute's year and number.
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
#'     \item{title}{The statute's official title, or `NA` if unavailable.}
#'   }
#'
#' @details
#' Not every statute in Finnish legal history is available through the
#' Finlex Open Data API (very old statutes in particular are not covered).
#' When a statute cannot be found, `status` is set to `"not_found"` rather
#' than raising an error, so that vectorized calls complete even when some
#' statutes are missing.
#'
#' @export
#'
#' @examples
#' \donttest{
#' flx_get_title(year = 1992, number = 1535) # Tuloverolaki
#' flx_get_title(year = c(1992, 1993), number = c(1535, 1501))
#' }
flx_get_title <- function(year, number) {

  stopifnot(is.numeric(year), is.numeric(number))

  n <- max(length(year), length(number))
  year   <- rep_len(as.integer(year), n)
  number <- rep_len(as.integer(number), n)

  out <- vector("list", n)

  for (i in seq_len(n)) {
    out[[i]] <- flx_get_title_one(year[i], number[i])
    if (n > 1) Sys.sleep(0.3)
  }

  dplyr::bind_rows(out)
}

#' Get the title of a single Finnish statute
#'
#' Internal helper used by [flx_get_title()].
#'
#' @param year Integer. Year of the statute.
#' @param number Integer. Number of the statute within that year.
#'
#' @return A one-row [tibble::tibble()], see [flx_get_title()] for columns.
#' @keywords internal
#' @noRd
flx_get_title_one <- function(year, number) {

  uri <- sprintf(
    "https://opendata.finlex.fi/finlex/avoindata/v1/akn/fi/act/statute/%d/%d/fin@",
    year, number
  )

  resp <- tryCatch(
    flx_request(uri, accept = "application/xml"),
    httr2_http_404 = function(e) NULL,
    error = function(e) e
  )

  if (inherits(resp, "error")) {
    return(tibble::tibble(year = year, number = number, status = "error", title = NA_character_))
  }
  if (is.null(resp)) {
    return(tibble::tibble(year = year, number = number, status = "not_found", title = NA_character_))
  }

  doc <- xml2::read_xml(httr2::resp_body_string(resp))
  root_name <- xml2::xml_name(doc)

  # An empty AknXmlList means the statute is not present in the API,
  # even though the HTTP request itself succeeded (status 200).
  if (identical(root_name, "AknXmlList")) {
    return(tibble::tibble(year = year, number = number, status = "not_found", title = NA_character_))
  }

  ns <- xml2::xml_ns(doc)
  titles <- xml2::xml_text(xml2::xml_find_all(doc, "//d1:docTitle", ns))
  titles <- trimws(titles[nzchar(trimws(titles))])

  tibble::tibble(
    year   = year,
    number = number,
    status = "ok",
    title  = if (length(titles) == 0) NA_character_ else titles[1]
  )
}
