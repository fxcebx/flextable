% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/formatters.R
\name{colformat_int}
\alias{colformat_int}
\title{format integer cells}
\usage{
colformat_int(
  x,
  i = NULL,
  j = NULL,
  big.mark = get_flextable_defaults()$big.mark,
  na_str = get_flextable_defaults()$na_str,
  prefix = "",
  suffix = ""
)
}
\arguments{
\item{x}{a flextable object}

\item{i}{rows selection}

\item{j}{columns selection.}

\item{big.mark}{see \code{\link[=format]{format()}}}

\item{na_str}{string to be used for NA values}

\item{prefix}{string to be used as prefix or suffix}

\item{suffix}{string to be used as prefix or suffix}
}
\description{
Format integer cells in a flextable.
}
\examples{
z <- flextable(head(mtcars))
j <- c("vs", "am", "gear", "carb")
z <- colformat_int(x = z, j = j, prefix = "# ")
z
}
\seealso{
Other cells formatters: 
\code{\link{colformat_char}()},
\code{\link{colformat_datetime}()},
\code{\link{colformat_date}()},
\code{\link{colformat_double}()},
\code{\link{colformat_lgl}()},
\code{\link{colformat_num}()},
\code{\link{compose}()},
\code{\link{set_formatter}()}
}
\concept{cells formatters}
