html_str <- function(x, bookdown = FALSE, ... ){

  dims <- dim(x)
  tab_props <- opts_current_table()

  # caption str value
  bookdown_ref_label <- ref_label()
  if(!is.null(tab_props$id)){
    bookdown_ref_label <- paste0("(\\#tab:", tab_props$id, ")")
  }
  caption_label <- tab_props$cap
  if(!is.null(x$caption$value)){
    caption_label <- x$caption$value
  }
  caption <- ""
  if(!is.null(caption_label)){
    caption <- paste0(
      if ( bookdown ) "<!--/html_preserve-->",
      "<caption>",
      if(bookdown) bookdown_ref_label,
      caption_label,
      "</caption>",
      if ( bookdown ) "<!--html_preserve-->"
    )
  }

  fixed_layout <- x$properties$layout %in% "fixed"
  if(!fixed_layout){
    tbl_width <- paste0("width:", formatC(x$properties$width*100), "%;")
    tabcss <- paste0("table-layout:auto;border-collapse:collapse;", tbl_width)
  } else {
    tabcss <- "border-collapse:collapse;"
  }

  codes <- html_gen(x)

  classname <- UUIDgenerate(n = 1, use.time = TRUE)
  classname <- gsub("(^[[:alnum:]]+)(.*)$", "cl-\\1", classname)
  tabcss <- paste0(".", classname, "{", tabcss, "}")

  sprintf("<style>%s%s</style><table class='%s'>%s%s</table>",
          tabcss, codes$css, classname, caption, codes$html)
}

# to html/css  ----
#' @importFrom data.table setnames setorderv := setcolorder setDT setDF dcast
html_gen <- function(x){

  cell_heights <- fortify_height(x)
  cell_widths <- fortify_width(x)
  cell_hrule <- fortify_hrule(x)
  par_data_f <- fortify_style(x, "pars")
  cell_data_f <- fortify_style(x, "cells")

  txt_data <- as_table_text(x)

  par_data <- fortify_par_style(par_data_f, cell_data_f)

  cell_data <- fortify_cell_style(par_data_f, cell_data_f)
  cell_data$width  <- NULL# need to get rid of originals that are empty, should probably rm them
  cell_data$height  <- NULL
  cell_data$hrule  <- NULL
  cell_data <- merge(cell_data, cell_widths, by = "col_id")
  cell_data <- merge(cell_data, cell_heights, by = c("part", "ft_row_id"))
  cell_data <- merge(cell_data, cell_hrule, by = c("part", "ft_row_id"))
  span_data <- fortify_span(x)

  data_ref_text <- part_style_list(txt_data, fun = officer::fp_text)
  data_ref_pars <- par_style_list(par_data)
  data_ref_cells <- cell_style_list(cell_data)

  setDT(txt_data)
  setDT(data_ref_text)
  setDT(par_data)
  setDT(data_ref_pars)
  setDT(cell_data)
  setDT(data_ref_cells)

  by_columns <- intersect(colnames(data_ref_text), colnames(txt_data))
  txt_data <- merge(txt_data, data_ref_text, by = by_columns)
  setorderv(txt_data, c("ft_row_id", "col_id", "seq_index"))

  is_hlink <- !is.na(txt_data$url)
  is_raster <- sapply(txt_data$img_data, function(x) {
    inherits(x, "raster") || is.character(x)
  })

  # manage raster
  txt_data[is_raster==TRUE, c("txt") := list(img_as_html(img_data = .SD$img_data, width = .SD$width, height = .SD$height))]
  # manage txt
  txt_data[is_raster==FALSE, c("txt") := list(sprintf("<span class=\"%s\">%s</span>", .SD$classname, htmlize(.SD$txt)))]
  # manage hlinks
  txt_data[is_hlink==TRUE, c("txt") := list(paste0("<a href=\"", .SD$url, "\">", .SD$txt, "</a>"))]
  txt_data <- txt_data[, list(span_tag = paste0(get("txt"), collapse = "")), by = c("part", "ft_row_id", "col_id")]

  by_columns <- intersect(colnames(par_data), colnames(data_ref_pars))
  par_data <- merge(par_data, data_ref_pars, by = by_columns)
  par_data <- par_data[, list(p_tag = paste0("<p class=\"", get("classname"), "\">")), by = c("part", "ft_row_id", "col_id")]

  by_columns <- intersect(colnames(cell_data), colnames(data_ref_cells))
  cell_data <- merge(cell_data, data_ref_cells, by = by_columns)
  cell_data <- merge(cell_data, span_data, by = c("part", "ft_row_id", "col_id"))

  cell_data <- cell_data[, list(
    td_tag = paste0("<td ",
                    paste0(
                      ifelse(get("rowspan") > 1, paste0(" colspan=\"", get("rowspan"),"\""), ""),
                      ifelse(get("colspan") > 1, paste0(" rowspan=\"", get("colspan"),"\""), "")
                    ),
                    "class=\"", get("classname"), "\">")
  ),
  by = c("part", "ft_row_id", "col_id")]

  dat <- merge(txt_data, par_data , by = c("part", "ft_row_id", "col_id"))
  dat$p_tag <- paste0(dat$p_tag, dat$span_tag, "</p>")
  dat <- merge(dat, cell_data , by = c("part", "ft_row_id", "col_id"))
  dat$td_tag <- paste0(dat$td_tag, dat$p_tag, "</td>")

  rows_data <- fortify_rows_styles(x)
  rows_data$tr_tag <- ifelse(rows_data$hrule %in% "exact", "<tr>", "<tr style=\"overflow-wrap:break-word;\">")
  rows_data <- rows_data[c("part", "ft_row_id",  "tr_tag")]

  dat <- merge(dat, span_data, by = c("part", "ft_row_id", "col_id"))
  dat$col_id <- factor(dat$col_id, levels = x$col_keys)
  dat$td_tag[dat$rowspan < 1 | dat$colspan < 1] <- ""

  z <- dcast(dat, part + ft_row_id ~ col_id, drop=TRUE, fill="", value.var = "td_tag", fun.aggregate = I)
  z <- merge(z, rows_data, by = c("part", "ft_row_id"))
  setorderv(z, c("part", "ft_row_id"))
  z$tr_end <- "</tr>"

  parts <- z$part
  header_start <- head(which(parts %in% "header"), n = 1)
  header_end <- tail(which(parts %in% "header"), n = 1)
  body_start <- head(which(parts %in% "body"), n = 1)
  body_end <- tail(which(parts %in% "body"), n = 1)
  footer_start <- head(which(parts %in% "footer"), n = 1)
  footer_end <- tail(which(parts %in% "footer"), n = 1)

  z$tpart_start <- ""
  z$tpart_end <- ""
  z$tpart_start[header_start] <- "<thead>"
  z$tpart_end[header_end] <- "</thead>"
  z$tpart_start[body_start] <- "<tbody>"
  z$tpart_end[body_end] <- "</tbody>"
  z$tpart_start[footer_start] <- "<tfoot>"
  z$tpart_end[footer_end] <- "</tfoot>"
  setcolorder(z, neworder = c("tpart_start", "tr_tag"))

  z[, c("part", "ft_row_id") := NULL]

  html <- apply(as.matrix(z), 1, paste0, collapse = "")
  html <- paste0(html, collapse = "")

  span_style_str <- text_css_styles(data_ref_text)
  par_style_str <- par_css_styles(data_ref_pars)
  cell_style_str <- cell_css_styles(data_ref_cells)

  list(
    html = html,
    css = paste0(span_style_str, par_style_str, cell_style_str)
  )
}



# html chunks ----
htmlize <- function(x){
  x <-  gsub("\n", "<br>", htmlEscape(x))
  x <-  gsub("\t", "&emsp;", x)
  x
}

img_as_html <- function(img_data, width, height){
  str_raster <- mapply(function(img_raster, width, height ){
    if(inherits(img_raster, "raster")){
      img_raster <- paste("data:image/png;base64,", gdtools::raster_str(img_raster, width*72, height*72))
    } else if(is.character(img_raster)){

      if( grepl("\\.png", ignore.case = TRUE, x = img_raster) ){
        mime <- "image/png"
      } else if( grepl("\\.gif", ignore.case = TRUE, x = img_raster) ){
        mime <- "image/gif"
      } else if( grepl("\\.jpg", ignore.case = TRUE, x = img_raster) ){
        mime <- "image/jpeg"
      } else if( grepl("\\.jpeg", ignore.case = TRUE, x = img_raster) ){
        mime <- "image/jpeg"
      } else if( grepl("\\.svg", ignore.case = TRUE, x = img_raster) ){
        mime <- "image/svg+xml"
      } else if( grepl("\\.tiff", ignore.case = TRUE, x = img_raster) ){
        mime <- "image/tiff"
      } else if( grepl("\\.webp", ignore.case = TRUE, x = img_raster) ){
        mime <- "image/webp"
      } else {
        stop("this format is not implemented")
      }
      img_raster <- base64enc::dataURI(file = img_raster, mime = mime )

    } else  {
      stop("unknown image format")
    }
    sprintf("<img style=\"vertical-align:middle;width:%.0fpx;height:%.0fpx;\" src=\"%s\" />", width*72, height*72, img_raster)
  }, img_data, width, height, SIMPLIFY = FALSE, USE.NAMES = FALSE)
  str_raster <- as.character(unlist(str_raster))
  str_raster
}

# css ----
text_css_styles <- function(x){

  shading <- ifelse(
    colalpha(x$shading.color) > 0,
    sprintf("background-color:%s;", colcodecss(x$shading.color) ),
    "background-color:transparent;")
  color <- ifelse(
    colalpha(x$color) > 0,
    sprintf("color:%s;", colcodecss(x$color) ),
    "")

  family <- sprintf("font-family:'%s';", x$font.family )

  positioning_val <- ifelse( x$vertical.align %in% "superscript", .3,
                             ifelse(x$vertical.align %in% "subscript", .3, NA_real_ ) )
  positioning_what <- ifelse( x$vertical.align %in% "superscript", "bottom",
                              ifelse(x$vertical.align %in% "subscript", "top", NA_character_ ) )
  vertical.align <- sprintf("position: relative;%s:%s;", positioning_what,
                            css_pt(x$font.size * positioning_val))
  vertical.align <- ifelse(is.na(positioning_val), "", vertical.align)

  font.size <- sprintf(
    "font-size:%s;", css_pt(x$font.size * ifelse(
      x$vertical.align %in% "superscript", .6,
      ifelse(x$vertical.align %in% "subscript", .6, 1.0 )
    ) )
  )

  bold <- ifelse(x$bold, "font-weight:bold;", "font-weight:normal;" )
  italic <- ifelse(x$italic, "font-style:italic;", "font-style:normal;" )
  underline <- ifelse(x$underlined, "text-decoration:underline;", "text-decoration:none;" )


  style_column <- paste0(family, font.size, bold, italic, underline,
                         color, shading, vertical.align)

  paste0(".", x$classname, "{", style_column, "}", collapse = "")
}

par_css_styles <- function(x){
  shading <- ifelse( colalpha(x$shading.color) > 0,
                     sprintf("background-color:%s;", colcodecss(x$shading.color) ),
                     "background-color:transparent;")

  textdir <- ifelse(x$text.direction %in% "tbrl", "writing-mode:vertical-rl;",
                    ifelse(x$text.direction %in% "btlr", "writing-mode:vertical-lr;transform: rotate(180deg);", "")
  )
  textalign <- sprintf("text-align:%s;", x$text.align )
  textalign_margins <- rep("", nrow(x))

  textalign_margins[x$text.direction %in% "tbrl" & x$vertical.align %in% "center"] <- "margin-left:auto;margin-right:auto;"
  textalign_margins[x$text.direction %in% "tbrl" & x$vertical.align %in% "top"] <- "margin-left:auto;"
  textalign_margins[x$text.direction %in% "tbrl" & x$vertical.align %in% "bottom"] <- "margin-right:auto;"
  textalign_margins[x$text.direction %in% "btlr" & x$vertical.align %in% "center"] <- "margin-left:auto;margin-right:auto;"
  textalign_margins[x$text.direction %in% "btlr" & x$vertical.align %in% "top"] <- "margin-right:auto;"
  textalign_margins[x$text.direction %in% "btlr" & x$vertical.align %in% "bottom"] <- "margin-left:auto;"
  textalign <- paste0(textalign, textalign_margins)

  bb <- border_css(
    color = x$border.color.bottom, width = x$border.width.bottom,
    style = x$border.style.bottom, side = "bottom")
  bt <- border_css(
    color = x$border.color.top, width = x$border.width.top,
    style = x$border.style.top, side = "top")
  bl <- border_css(
    color = x$border.color.left, width = x$border.width.left,
    style = x$border.style.left, side = "left")
  br <- border_css(
    color = x$border.color.right, width = x$border.width.right,
    style = x$border.style.right, side = "right")

  padding.bottom <- sprintf("padding-bottom:%s;", css_pt(x$padding.bottom) )
  padding.top <- sprintf("padding-top:%s;", css_pt(x$padding.top) )
  padding.left <- sprintf("padding-left:%s;", css_pt(x$padding.left) )
  padding.right <- sprintf("padding-right:%s;", css_pt(x$padding.right) )

  line_spacing <- sprintf("line-height: %s;", css_no_unit(x$line_spacing, 2) )

  style_column <- paste0("margin:0;", textalign, textdir, bb, bt, bl, br,
                         padding.bottom, padding.top, padding.left, padding.right,
                         line_spacing, shading )
  paste0(".", x$classname, "{", style_column, "}", collapse = "")
}

cell_css_styles <- function(x){

  background.color <- ifelse( colalpha(x$background.color) > 0,
                              sprintf("background-clip: padding-box;background-color:%s;", colcodecss(x$background.color) ),
                              "background-color:transparent;")

  width <- ifelse( is.na(x$width), "", sprintf("width:%s;", css_pt(x$width * 72) ) )
  height <- ifelse( !is.na(x$height) & x$hrule %in% c("exact", "atleast"), sprintf("height:%s;", css_pt(x$height * 72 ) ), "" )

  vertical.align <- ifelse(
    x$vertical.align %in% "center", "vertical-align: middle;",
    ifelse(x$vertical.align %in% "top", "vertical-align: top;", "vertical-align: bottom;") )
  vertical.align[x$text.direction %in% "tbrl" & x$text.align %in% "center"] <- "vertical-align:middle;"
  vertical.align[x$text.direction %in% "tbrl" & x$text.align %in% "left"] <- "vertical-align:top;"
  vertical.align[x$text.direction %in% "tbrl" & x$text.align %in% "right"] <- "vertical-align:bottom;"

  bb <- border_css(
    color = x$border.color.bottom, width = x$border.width.bottom,
    style = x$border.style.bottom, side = "bottom")
  bt <- border_css(
    color = x$border.color.top, width = x$border.width.top,
    style = x$border.style.top, side = "top")
  bl <- border_css(
    color = x$border.color.left, width = x$border.width.left,
    style = x$border.style.left, side = "left")
  br <- border_css(
    color = x$border.color.right, width = x$border.width.right,
    style = x$border.style.right, side = "right")

  margin.bottom <- sprintf("margin-bottom:%s;", css_pt(x$margin.bottom) )
  margin.top <- sprintf("margin-top:%s;", css_pt(x$margin.top) )
  margin.left <- sprintf("margin-left:%s;", css_pt(x$margin.left) )
  margin.right <- sprintf("margin-right:%s;", css_pt(x$margin.right) )

  style_column <- paste0(width, height, background.color, vertical.align, bb, bt, bl, br,
                         margin.bottom, margin.top, margin.left, margin.right)
  paste0(".", x$classname, "{", style_column, "}", collapse = "")
}


