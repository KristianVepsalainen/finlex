#' Download the catalogue of Finnish statutes
#'
#' Retrieves the list of Finnish statutes (*saadokset*) published via the
#' Finlex Open Data REST API (<https://opendata.finlex.fi>), for a given
#' range of years and statute categories. Only the Finnish-language (`fin`)
#' version of each statute is returned.
#'
#' @param start_year Integer. First year to include. The Finlex Open Data
#'   API currently starts from 1987.
#' @param end_year Integer. Last year to include. Defaults to the current
#'   year.
#' @param categories Character vector. One or more of `"new-statute"`,
#'   `"amending-statute"`, `"repealing-statute"`. Defaults to all three.
#' @param quiet Logical. If `FALSE` (the default), prints one progress
#'   message per year processed.
#'
#' @return A [tibble::tibble()] with one row per statute and the columns:
#'   \describe{
#'     \item{akn_uri}{The Akoma Ntoso URI identifying the statute.}
#'     \item{year}{Year of the statute, as an integer.}
#'     \item{number}{Statute number within that year, as an integer.}
#'     \item{statute_type}{One of `"NewStatute"`, `"Amendment"`, `"Repeal"`.}
#'   }
#'   Returns a zero-row tibble with the same columns if nothing matches.
#'
#' @export
#'
#' @examples
#' \donttest{
#' flx_download_statutes(
#'   start_year = 2023,
#'   end_year   = 2023,
#'   categories = "new-statute"
#' )
#' }
flx_download_statutes <- function(start_year = 1987,
                                   end_year = as.integer(format(Sys.Date(), "%Y")),
                                   categories = c("new-statute", "amending-statute", "repealing-statute"),
                                   quiet = FALSE) {

  stopifnot(
    is.numeric(start_year), length(start_year) == 1,
    is.numeric(end_year), length(end_year) == 1,
    start_year <= end_year
  )

  categories <- match.arg(
    categories,
    choices = c("new-statute", "amending-statute", "repealing-statute"),
    several.ok = TRUE
  )

  base_url <- "https://opendata.finlex.fi/finlex/avoindata/v1/akn/fi/act/statute/list"

  empty_out <- tibble::tibble(
    akn_uri      = character(),
    year         = integer(),
    number       = integer(),
    statute_type = character()
  )

  results <- list()
  idx <- 1L

  for (year in seq.int(start_year, end_year)) {
    for (category in categories) {

      page <- 1L
      repeat {
        resp <- flx_request(
          base_url,
          query = list(
            format          = "json",
            page            = page,
            limit           = 10,
            sortBy          = "dateIssued",
            startYear       = year,
            endYear         = year,
            categoryStatute = category
          )
        )

        parsed <- httr2::resp_body_json(resp, simplifyVector = TRUE)

        no_rows <- length(parsed) == 0 ||
          (is.data.frame(parsed) && nrow(parsed) == 0)

        if (no_rows) break

        parsed <- parsed[grepl("/fin@$", parsed$akn_uri), , drop = FALSE]

        if (nrow(parsed) > 0) {
          uri_tail <- regmatches(
            parsed$akn_uri,
            regexpr("[0-9]{4}/[0-9]+/fin@$", parsed$akn_uri)
          )

          results[[idx]] <- tibble::tibble(
            akn_uri      = parsed$akn_uri,
            year         = as.integer(sub("/.*", "", uri_tail)),
            number       = as.integer(sub("^[0-9]+/([0-9]+)/fin@$", "\\1", uri_tail)),
            statute_type = category
          )
          idx <- idx + 1L
        }

        page <- page + 1L
        Sys.sleep(0.3)
      }
    }

    if (!quiet) {
      n_so_far <- sum(vapply(results, nrow, integer(1)))
      message(sprintf("Year %d done (%d rows so far)", year, n_so_far))
    }
  }

  if (length(results) == 0) return(empty_out)

  out <- dplyr::bind_rows(results)

  out$statute_type <- dplyr::recode(
    out$statute_type,
    "new-statute"       = "NewStatute",
    "amending-statute"  = "Amendment",
    "repealing-statute" = "Repeal"
  )

  out
}
