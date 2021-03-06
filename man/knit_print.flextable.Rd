% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/printers.R
\name{knit_print.flextable}
\alias{knit_print.flextable}
\title{Render flextable in rmarkdown}
\usage{
\method{knit_print}{flextable}(x, ...)
}
\arguments{
\item{x}{a \code{flextable} object}

\item{...}{further arguments, not used.}
}
\description{
Function used to render flextable in knitr/rmarkdown documents.
HTML, Word, PowerPoint and PDF outputs are supported.

Table captioning is a flextable feature compatible with R Markdown
documents. The feature is available for HTML, PDF and Word document
}
\note{
For Word (docx) output, if pandoc version >= 2.0 is used, a raw XML block
with the table code will be inserted. If pandoc version < 2.0 is used, an
error will be raised. Insertion of images is not supported
with rmarkdown for Word documents (use the package officedown instead).
For PowerPoint (pptx) output, if pandoc version < 2.4 is used, an error
will be raised.
}
\section{HTML chunk options}{

Result can be aligned with chunk option \code{ft.align} that
accepts values 'left', 'center' and 'right'.

Three methods are available to add a caption and are presented below
in order of triggering:
\itemize{
\item with the \code{set_caption} function, if the function is used, this label definition
will be chosen.
\item with knitr's chunk options:
\itemize{
\item \code{tab.cap}: Caption label.
\item \code{tab.id}: Caption reference unique identifier.
}
\item with knitr chunk and bookdown options (if you're in a bookdown):
\itemize{
\item \code{tab.cap}: Caption label.
\item \code{label}: Caption reference unique identifier.
}
}
}

\section{Word chunk options}{

Result can be aligned with chunk option \code{ft.align} that
accepts values 'left', 'center' and 'right'.

Word option 'Allow row to break across pages' can be
activated with chunk option \code{ft.split} set to TRUE.

Three methods are available and are presented below in order of triggering:
\itemize{
\item with the \code{set_caption} function, if the function is used, this definition will be chosen.
\item with knitr's chunk options:
\itemize{
\item \code{tab.cap.style}: Word style name to use for table captions.
\item \code{tab.cap.pre}: Prefix for numbering chunk (default to "Table").
\item \code{tab.cap.sep}: Suffix for numbering chunk (default to ": ").
\item \code{tab.cap}: Caption label.
\item \code{tab.id}: Caption reference unique identifier.
}
\item with knitr chunk and bookdown options (if you're in a bookdown):
\itemize{
\item \code{tab.cap.style}: Word style name to use for table captions.
\item \code{tab.cap.pre}: Prefix for numbering chunk (default to "Table").
\item \code{tab.cap.sep}: Suffix for numbering chunk (default to ": ").
\item \code{tab.cap}: Caption label.
\item \code{label}: Caption reference unique identifier.
}
}
}

\section{PowerPoint chunk options}{

Position should be defined with options \code{ft.left}
and \code{ft.top}. Theses are the top left coordinates
of the placeholder that will contain the table. They
default to \code{{r ft.left=1, ft.top=2}}.
}

\section{PDF chunk options}{


Result can be aligned with chunk option \code{ft.align} that
accepts values 'left', 'center' and 'right'.

paddings are not supported in latex but you can set the values for
column spacing and row stretch:
\itemize{
\item Use chunk option \code{ft.tabcolsep=6} to change the space between the text
and the left/right border of its containing cell to 6 points, the default
value is 8 points.
\item Use chunk option \code{ft.arraystretch=2} to change the height of each row
to 2 relative to its default height, the default value is 1.5.
}

Three methods are available to add a caption and are presented below
in order of triggering:
\itemize{
\item with the \code{set_caption} function, if the function is used, this label definition
will be chosen.
\item with knitr's chunk options:
\itemize{
\item \code{tab.cap}: Caption label.
\item \code{tab.id}: Caption reference unique identifier.
}
\item with knitr chunk and bookdown options (if you're in a bookdown):
\itemize{
\item \code{tab.cap}: Caption label.
\item \code{label}: Caption reference unique identifier.
}
}
}

\examples{

# simple examples -----
demo_docx <- system.file(package = "flextable", "examples/rmd", "demo.Rmd")
rmd_file <- tempfile(fileext = ".Rmd")
file.copy(demo_docx, to = rmd_file, overwrite = TRUE)
rmd_file # R Markdown document used for demo
if(require("rmarkdown", quietly = TRUE)){
#  knitr::opts_chunk$set(webshot = "webshot2")
#  render(input = rmd_file, output_format = "word_document", output_file = "doc.docx")
#  render(input = rmd_file, output_format = "pdf_document", output_file = "doc.pdf")
#  render(input = rmd_file, output_format = "html_document", output_file = "doc.html")
#  render(input = rmd_file, output_format = "powerpoint_presentation", output_file = "pres.pptx")
#  render(input = rmd_file, output_format = "slidy_presentation", output_file = "slidy.html")
#  render(input = rmd_file, output_format = "beamer_presentation", output_file = "beamer.pdf")
#  render(input = rmd_file, output_format = "pagedown::html_paged", output_file = "paged.html")
}


# looping examples for Word output -----
demo_loop <- system.file(package = "flextable", "examples/rmd", "loop_docx.Rmd")
rmd_file <- tempfile(fileext = ".Rmd")
file.copy(demo_loop, to = rmd_file, overwrite = TRUE)
rmd_file # R Markdown document used for demo
if(require("rmarkdown", quietly = TRUE)){
#  render(input = rmd_file, output_format = "word_document", output_file = "loop_docx.docx")
}

# looping examples for HTML output -----
demo_loop <- system.file(package = "flextable", "examples/rmd", "loop_html.Rmd")
rmd_file <- tempfile(fileext = ".Rmd")
file.copy(demo_loop, to = rmd_file, overwrite = TRUE)
rmd_file # R Markdown document used for demo
if(require("rmarkdown", quietly = TRUE)){
#  render(input = rmd_file, output_format = "html_document", output_file = "loop_html.html")
}
}
\seealso{
Other flextable print function: 
\code{\link{as_raster}()},
\code{\link{docx_value}()},
\code{\link{htmltools_value}()},
\code{\link{latex_value}()},
\code{\link{plot.flextable}()},
\code{\link{print.flextable}()},
\code{\link{save_as_docx}()},
\code{\link{save_as_html}()},
\code{\link{save_as_image}()},
\code{\link{save_as_pptx}()}
}
\concept{flextable print function}
