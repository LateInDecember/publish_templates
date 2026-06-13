#!/usr/bin/env Rscript

suppressPackageStartupMessages({
  library(officer)
  library(png)
  library(stringr)
  library(xml2)
  library(zip)
})

script_arg <- grep("^--file=", commandArgs(FALSE), value = TRUE)
script_path <- if (length(script_arg) > 0) {
  normalizePath(sub("^--file=", "", script_arg[1]), mustWork = TRUE)
} else {
  normalizePath("_scripts/render_with_insertions.R", mustWork = TRUE)
}
root <- dirname(dirname(script_path))
setwd(root)

input_qmd <- file.path(root, "manuscript.md")
render_qmd <- file.path(root, "manuscript_render.qmd")
output_docx <- file.path(root, "05_output", "manuscript.docx")
output_html <- file.path(root, "05_output", "manuscript.html")
tmp_docx <- file.path(root, "05_output", "manuscript_inserted_tmp.docx")

mtime <- function(path) {
  format(file.info(path)$mtime, "%Y-%m-%d %H:%M:%S")
}

message("Manuscript root: ", root)
message("Reading source: ", input_qmd)
message("Source modified: ", mtime(input_qmd))

sync_script <- file.path(root, "_scripts", "sync_reporting_assets.R")
if (file.exists(sync_script)) {
  old_manuscript_root <- Sys.getenv("MANUSCRIPT_ROOT", unset = NA_character_)
  Sys.setenv(MANUSCRIPT_ROOT = root)
  on.exit({
    if (is.na(old_manuscript_root)) {
      Sys.unsetenv("MANUSCRIPT_ROOT")
    } else {
      Sys.setenv(MANUSCRIPT_ROOT = old_manuscript_root)
    }
  }, add = TRUE)
  source(sync_script, local = new.env(parent = globalenv()))
}

figure1_pdf <- file.path(root, "03_assets", "figures", "Figure 1.pdf")
figure1_png <- file.path(root, "03_assets", "figures", "Figure_1_task_procedure.png")
render_pdf_preview <- function(pdf_path, png_path, size = 3000) {
  tmp_dir <- tempfile("figure1_preview_")
  dir.create(tmp_dir, recursive = TRUE, showWarnings = FALSE)
  on.exit(unlink(tmp_dir, recursive = TRUE), add = TRUE)

  status <- system2(
    "qlmanage",
    c("-t", "-s", as.character(size), "-o", shQuote(tmp_dir), shQuote(pdf_path)),
    stdout = TRUE,
    stderr = TRUE
  )
  if (!identical(attr(status, "status"), NULL)) {
    return(FALSE)
  }

  preview_path <- list.files(tmp_dir, pattern = "\\.png$", full.names = TRUE)
  if (length(preview_path) < 1) {
    return(FALSE)
  }
  file.copy(preview_path[1], png_path, overwrite = TRUE)
}

png_needs_refresh <- function(path, min_width = 2500) {
  if (!file.exists(path)) {
    return(TRUE)
  }
  info <- tryCatch(dim(png::readPNG(path)), error = function(e) NULL)
  is.null(info) || length(info) < 2 || info[2] < min_width
}

crop_png_to_content <- function(path, padding = 20) {
  img <- png::readPNG(path)
  rgb <- if (length(dim(img)) == 3) img[, , seq_len(min(3, dim(img)[3])), drop = FALSE] else img
  if (length(dim(rgb)) == 2) {
    rgb <- array(rep(rgb, 3), dim = c(dim(rgb), 3))
  }

  page_mask <- apply(rgb > 0.04, c(1, 2), any)
  if (!any(page_mask)) return(invisible(FALSE))
  page_rows <- which(rowSums(page_mask) > 0)
  page_cols <- which(colSums(page_mask) > 0)
  page <- rgb[min(page_rows):max(page_rows), min(page_cols):max(page_cols), , drop = FALSE]

  content_mask <- apply(page < 0.96, c(1, 2), any)
  if (!any(content_mask)) return(invisible(FALSE))
  content_rows <- which(rowSums(content_mask) > 0)
  content_cols <- which(colSums(content_mask) > 0)

  row_start <- max(1, min(page_rows) + min(content_rows) - 1 - padding)
  row_end <- min(dim(img)[1], min(page_rows) + max(content_rows) - 1 + padding)
  col_start <- max(1, min(page_cols) + min(content_cols) - 1 - padding)
  col_end <- min(dim(img)[2], min(page_cols) + max(content_cols) - 1 + padding)

  cropped <- img[row_start:row_end, col_start:col_end, , drop = FALSE]
  png::writePNG(cropped, path)
  invisible(TRUE)
}

if (
  file.exists(figure1_pdf) &&
    (
      png_needs_refresh(figure1_png) ||
        file.info(figure1_png)$mtime < file.info(figure1_pdf)$mtime
    )
) {
  status <- render_pdf_preview(figure1_pdf, figure1_png, size = 3000)
  if (!isTRUE(status)) {
    stop("Could not convert Figure 1 PDF for DOCX/HTML rendering: ", figure1_pdf)
  }
}
if (file.exists(figure1_png)) {
  crop_png_to_content(figure1_png)
}

network_manifest_path <- file.path(
  dirname(root),
  "02_anal", "03_results", "06_reporting", "tables", "supplementary",
  "Figure_S_network_manifest.csv"
)

figure_note <- function(figure_id, fallback = "") {
  if (!file.exists(network_manifest_path)) {
    return(fallback)
  }
  manifest <- utils::read.csv(network_manifest_path, stringsAsFactors = FALSE, check.names = FALSE)
  if (!all(c("figure_id", "note") %in% names(manifest))) {
    return(fallback)
  }
  note <- manifest$note[manifest$figure_id == figure_id][1]
  if (is.na(note) || !nzchar(note)) {
    return(fallback)
  }
  note
}

figure_block <- function(title, path, note = NULL, width = "100%") {
  title_block <- paste0("\n\n::: {.figure-title}\n", title, "\n:::\n")
  note_block <- if (!is.null(note) && nzchar(note)) {
    paste0("\n\n::: {.figure-note}\nNote. ", note, "\n:::\n")
  } else {
    ""
  }
  paste0(
    "![](", path, "){fig-align=\"center\" width=\"", width, "\"}",
    title_block,
    note_block
  )
}

# ============================================================
# Asset auto-resolution: {{figure:1}} / {{table:1}} -> file by NUMBER.
#   Path is found by globbing 04_synced (and 03_assets for figures) by id —
#   only the number/id must match; the descriptive part of the filename is free.
#   So dropping e.g. Table_1_anything.docx into 04_synced/tables/main and writing
#   {{table:1}} is enough — no path mapping to maintain.
#   Captions (figures) and layout flags (tables) are configured by id below.
#   If two files share the same number (ambiguous), pin the exact file in
#   `asset_override` (key "figure:<id>" / "table:<id>").
# ============================================================

id_to_token <- function(id) {
  if (grepl("^s", id)) paste0("S", substring(id, 2)) else id
}

asset_override <- list(
  # Disambiguate same-numbered files (here: demographic vs H2 supplementary figures).
  "figure:s4" = "04_synced/figures/Figure_S4_H2_caudate_intimate_moderation_panels.png",
  "figure:s5" = "04_synced/figures/Figure_S5_H2_caudate_total_moderation_panels.png",
  "figure:s6" = "04_synced/figures/Figure_S6_H2_putamen_total_moderation_panel.png"
)

resolve_asset <- function(kind, id) {
  key <- paste0(kind, ":", id)
  if (!is.null(asset_override[[key]])) return(asset_override[[key]])
  token <- id_to_token(id)
  if (kind == "table") {
    dirs <- c("04_synced/tables/main", "04_synced/tables/supplementary")
    prefix <- paste0("Table_", token, "_"); ext <- "docx"
  } else {
    dirs <- c("04_synced/figures", "03_assets/figures")
    prefix <- paste0("Figure_", token, "_"); ext <- "png"
  }
  pat <- paste0("^", prefix, ".*\\.", ext, "$")
  hits <- character(0)
  for (d in dirs) if (dir.exists(d)) hits <- c(hits, list.files(d, pattern = pat, full.names = TRUE))
  if (length(hits) == 0) {
    stop(sprintf("No %s file for {{%s:%s}} - expected %s*.%s under %s",
                 kind, kind, id, prefix, ext, paste(dirs, collapse = " or ")))
  }
  if (length(hits) > 1) {
    stop(sprintf("Ambiguous %s for {{%s:%s}} (%s). Pin it in asset_override.",
                 kind, kind, id, paste(basename(hits), collapse = ", ")))
  }
  hits[1]
}

# Markers actually used in the manuscript
.ms_text <- readLines(input_qmd, warn = FALSE)
.markers <- unique(unlist(regmatches(
  .ms_text, gregexpr("\\{\\{(?:table|figure):[a-z0-9]+\\}\\}", .ms_text, perl = TRUE))))
figure_ids <- sub("^\\{\\{figure:([a-z0-9]+)\\}\\}$", "\\1", grep("\\{\\{figure:", .markers, value = TRUE))
table_ids  <- sub("^\\{\\{table:([a-z0-9]+)\\}\\}$",  "\\1", grep("\\{\\{table:",  .markers, value = TRUE))

# Figure captions (title + optional note), keyed by id. Path is auto-resolved.
figure_captions <- list(
  "1"  = list(title = "Figure 1. Overview of the fMRI task procedure.",
              note  = "The figure illustrates the instruction/practice session, the round-robin face-viewing task, and the post-rating survey. During scanning, participants viewed village members' faces and ghost face stimuli with jittered fixation intervals. After scanning, they rated each face on familiarity, relationship duration, conversation frequency, and liking. ISI = inter-stimulus interval."),
  "2"  = list(title = "Figure 2. Association between loneliness and caudate response."),
  "s1" = list(title = "Figure S1. Complete social network with analysis participants highlighted.",
              note  = figure_note("Figure S1", "Nodes represent residents and edges represent observed social ties. Communities are color-coded; analysis participants are indicated with red borders.")),
  "s2" = list(title = "Figure S2. Analysis participants and directly connected neighbors.",
              note  = figure_note("Figure S2", "Analysis participants and their directly connected neighbors are shown with pastel node colors; edges indicate direct social ties.")),
  "s3" = list(title = "Figure S3. Network metrics on the analysis-participant subgraph.",
              note  = figure_note("Figure S3", "Panels show degree centrality, in-degree centrality, out-degree centrality, embeddedness, and brokerage; color intensity indicates metric values.")),
  "s4" = list(title = "Figure S4. Caudate response moderation plots for intimate loneliness.",
              note  = "Panels show moderation by degree centrality (A), in-degree centrality (B), and embeddedness (C)."),
  "s5" = list(title = "Figure S5. Caudate response moderation plots for total loneliness.",
              note  = "Panels show moderation by degree centrality (A), in-degree centrality (B), out-degree centrality (C), and embeddedness (D)."),
  "s6" = list(title = "Figure S6. Putamen response moderation plot for total loneliness.",
              note  = "Panel A shows moderation by in-degree centrality.")
)

figure_insertions <- list()
for (.id in figure_ids) {
  .cfg <- figure_captions[[.id]]
  if (is.null(.cfg)) message("[render] No caption config for {{figure:", .id, "}} - using default title.")
  .title <- if (!is.null(.cfg$title)) .cfg$title else paste0("Figure ", id_to_token(.id), ".")
  figure_insertions[[length(figure_insertions) + 1]] <- list(
    marker = paste0("{{figure:", .id, "}}"),
    replacement = figure_block(.title, resolve_asset("figure", .id), note = .cfg$note)
  )
}

table_insertions <- list()
for (.id in table_ids) {
  table_insertions[[paste0("{{table:", .id, "}}")]] <- resolve_asset("table", .id)
}

# Layout config (by marker): supplementary items get a page break; some tables are wide.
appendix_pagebreak_markers <- c(
  "{{figure:s2}}", "{{figure:s3}}", "{{figure:s4}}", "{{figure:s5}}", "{{figure:s6}}",
  "{{table:s1}}", "{{table:s3}}", "{{table:s4a}}", "{{table:s4b}}", "{{table:s4c}}", "{{table:s5}}"
)
wide_table_markers <- c(
  "{{table:2}}", "{{table:s2}}", "{{table:s3}}", "{{table:s4a}}", "{{table:s4b}}", "{{table:s4c}}", "{{table:s5}}"
)

qmd <- readLines(input_qmd, warn = FALSE)

add_pagebreak_before_heading <- function(lines, heading) {
  heading_idx <- which(trimws(lines) == heading)
  if (length(heading_idx) != 1) {
    stop("Expected exactly one manuscript heading for page break: ", heading)
  }
  idx <- heading_idx[1]
  c(lines[seq_len(idx - 1)], "\\newpage", "", lines[idx:length(lines)])
}

qmd <- add_pagebreak_before_heading(qmd, "## 국문요약")
qmd <- add_pagebreak_before_heading(qmd, "## 부록")

for (marker in names(table_insertions)) {
  marker_block <- if (marker %in% appendix_pagebreak_markers) {
    paste0("\n\n\\newpage\n\n", marker, "\n\n")
  } else {
    paste0("\n\n", marker, "\n\n")
  }
  qmd <- str_replace_all(qmd, fixed(marker), marker_block)
}
for (entry in figure_insertions) {
  replacement_block <- if (entry$marker %in% appendix_pagebreak_markers) {
    paste0("\n\n\\newpage\n\n", entry$replacement, "\n\n")
  } else {
    paste0("\n\n", entry$replacement, "\n\n")
  }
  qmd <- str_replace_all(qmd, fixed(entry$marker), replacement_block)
}
writeLines(qmd, render_qmd, useBytes = TRUE)
on.exit(unlink(render_qmd), add = TRUE)

render_quarto <- function(to, output) {
  cmd <- c("render", basename(render_qmd), "--to", to, "-o", output)
  status <- system2("quarto", cmd, env = "HOME=/private/tmp")
  if (!identical(status, 0L)) {
    stop("quarto render failed for ", to, "; see messages above.")
  }
}

render_quarto("docx", "manuscript.docx")
render_quarto("html", "manuscript.html")

docx_table_to_html <- function(src, marker) {
  html <- system2(
    "quarto",
    c("pandoc", shQuote(src), "-t", "html", "--wrap=none"),
    stdout = TRUE,
    stderr = TRUE
  )
  status <- attr(html, "status")
  if (!is.null(status) && !identical(status, 0L)) {
    stop("Could not convert table to HTML for ", marker, ": ", src)
  }
  table_class <- if (marker %in% wide_table_markers) {
    "inserted-table wide-table"
  } else {
    "inserted-table"
  }
  table_id <- gsub(":", "-", str_remove_all(marker, "[{}]"))
  paste0(
    '<div class="', table_class, '" data-table-id="', table_id, '">',
    paste(html, collapse = "\n"),
    "</div>"
  )
}

patch_styles_xml <- function(styles_path) {
  styles_xml <- read_xml(styles_path)
  ns <- xml_ns(styles_xml)
  myeongjo_font <- "AppleMyungjo"
  gothic_font <- "AppleGothic"

  ensure_child <- function(parent, xpath, child_name) {
    child <- xml_find_first(parent, xpath, ns)
    if (inherits(child, "xml_missing")) {
      child <- xml_add_child(parent, child_name)
    }
    child
  }

  set_style_font <- function(style_id, ascii = myeongjo_font, eastasia = myeongjo_font) {
    style <- xml_find_first(
      styles_xml,
      paste0(".//w:style[@w:styleId='", style_id, "']"),
      ns
    )
    if (inherits(style, "xml_missing")) return(invisible(NULL))
    rpr <- ensure_child(style, "./w:rPr", "w:rPr")
    rfonts <- ensure_child(rpr, "./w:rFonts", "w:rFonts")
    xml_set_attr(rfonts, "w:ascii", ascii)
    xml_set_attr(rfonts, "w:hAnsi", ascii)
    xml_set_attr(rfonts, "w:cs", ascii)
    xml_set_attr(rfonts, "w:eastAsia", eastasia)
  }

  set_style_align <- function(style_id, align) {
    style <- xml_find_first(
      styles_xml,
      paste0(".//w:style[@w:styleId='", style_id, "']"),
      ns
    )
    if (inherits(style, "xml_missing")) return(invisible(NULL))
    ppr <- ensure_child(style, "./w:pPr", "w:pPr")
    jc <- ensure_child(ppr, "./w:jc", "w:jc")
    xml_set_attr(jc, "w:val", align)
  }

  set_style_indent <- function(style_id, first_line = NULL, left = NULL, hanging = NULL) {
    style <- xml_find_first(
      styles_xml,
      paste0(".//w:style[@w:styleId='", style_id, "']"),
      ns
    )
    if (inherits(style, "xml_missing")) return(invisible(NULL))
    ppr <- ensure_child(style, "./w:pPr", "w:pPr")
    ind <- ensure_child(ppr, "./w:ind", "w:ind")
    if (!is.null(first_line)) xml_set_attr(ind, "w:firstLine", first_line)
    if (!is.null(left)) xml_set_attr(ind, "w:left", left)
    if (!is.null(hanging)) xml_set_attr(ind, "w:hanging", hanging)
  }

  set_style_bold <- function(style_id, bold = TRUE) {
    style <- xml_find_first(
      styles_xml,
      paste0(".//w:style[@w:styleId='", style_id, "']"),
      ns
    )
    if (inherits(style, "xml_missing")) return(invisible(NULL))
    rpr <- ensure_child(style, "./w:rPr", "w:rPr")
    b <- ensure_child(rpr, "./w:b", "w:b")
    bcs <- ensure_child(rpr, "./w:bCs", "w:bCs")
    if (!bold) {
      xml_set_attr(b, "w:val", "false")
      xml_set_attr(bcs, "w:val", "false")
    }
  }

  set_style_italic <- function(style_id, italic = FALSE) {
    style <- xml_find_first(
      styles_xml,
      paste0(".//w:style[@w:styleId='", style_id, "']"),
      ns
    )
    if (inherits(style, "xml_missing")) return(invisible(NULL))
    rpr <- ensure_child(style, "./w:rPr", "w:rPr")
    for (tag in c("w:i", "w:iCs")) {
      node <- ensure_child(rpr, paste0("./", tag), tag)
      xml_set_attr(node, "w:val", if (italic) "true" else "false")
    }
  }

  set_style_spacing <- function(style_id, line, before = NULL, after = NULL) {
    style <- xml_find_first(
      styles_xml,
      paste0(".//w:style[@w:styleId='", style_id, "']"),
      ns
    )
    if (inherits(style, "xml_missing")) return(invisible(NULL))
    ppr <- ensure_child(style, "./w:pPr", "w:pPr")
    spacing <- ensure_child(ppr, "./w:spacing", "w:spacing")
    xml_set_attr(spacing, "w:line", line)
    xml_set_attr(spacing, "w:lineRule", "auto")
    if (!is.null(before)) xml_set_attr(spacing, "w:before", before)
    if (!is.null(after)) xml_set_attr(spacing, "w:after", after)
  }

  set_style_size <- function(style_id, half_points) {
    style <- xml_find_first(
      styles_xml,
      paste0(".//w:style[@w:styleId='", style_id, "']"),
      ns
    )
    if (inherits(style, "xml_missing")) return(invisible(NULL))
    rpr <- ensure_child(style, "./w:rPr", "w:rPr")
    sz <- ensure_child(rpr, "./w:sz", "w:sz")
    sz_cs <- ensure_child(rpr, "./w:szCs", "w:szCs")
    xml_set_attr(sz, "w:val", half_points)
    xml_set_attr(sz_cs, "w:val", half_points)
  }

  set_default_run_style <- function() {
    doc_defaults <- ensure_child(styles_xml, "./w:docDefaults", "w:docDefaults")
    rpr_default <- ensure_child(doc_defaults, "./w:rPrDefault", "w:rPrDefault")
    rpr <- ensure_child(rpr_default, "./w:rPr", "w:rPr")
    rfonts <- ensure_child(rpr, "./w:rFonts", "w:rFonts")
    xml_set_attr(rfonts, "w:ascii", myeongjo_font)
    xml_set_attr(rfonts, "w:hAnsi", myeongjo_font)
    xml_set_attr(rfonts, "w:cs", myeongjo_font)
    xml_set_attr(rfonts, "w:eastAsia", myeongjo_font)
    sz <- ensure_child(rpr, "./w:sz", "w:sz")
    sz_cs <- ensure_child(rpr, "./w:szCs", "w:szCs")
    xml_set_attr(sz, "w:val", "20")
    xml_set_attr(sz_cs, "w:val", "20")
  }

  set_default_run_style()

  body_styles <- c(
    "Normal", "BodyText", "FirstParagraph"
  )
  for (style_id in body_styles) {
    set_style_font(style_id)
    set_style_size(style_id, "20")
    set_style_spacing(style_id, line = "384")
    set_style_align(style_id, "both")
    set_style_indent(style_id, first_line = "400")
  }

  set_style_font("Title")
  set_style_size("Title", "32")
  set_style_spacing("Title", line = "384", before = "0", after = "0")
  set_style_align("Title", "center")
  set_style_bold("Title", TRUE)
  set_style_font("TitleChar")
  set_style_size("TitleChar", "32")
  set_style_bold("TitleChar", TRUE)

  set_style_font("Bibliography")
  set_style_size("Bibliography", "20")
  set_style_spacing("Bibliography", line = "384")
  set_style_align("Bibliography", "both")
  set_style_indent("Bibliography", left = "400", hanging = "400")

  set_style_font("Heading1")
  set_style_size("Heading1", "32")
  set_style_spacing("Heading1", line = "384", before = "240", after = "120")
  set_style_align("Heading1", "center")
  set_style_bold("Heading1", TRUE)
  set_style_font("Heading1Char")
  set_style_size("Heading1Char", "32")
  set_style_bold("Heading1Char", TRUE)

  set_style_font("Heading2")
  set_style_size("Heading2", "22")
  set_style_spacing("Heading2", line = "384", before = "240", after = "0")
  set_style_align("Heading2", "center")
  set_style_bold("Heading2", TRUE)
  set_style_font("Heading2Char")
  set_style_size("Heading2Char", "22")
  set_style_bold("Heading2Char", TRUE)

  set_style_font("Heading3", ascii = gothic_font, eastasia = gothic_font)
  set_style_size("Heading3", "22")
  set_style_spacing("Heading3", line = "384", before = "240", after = "0")
  set_style_align("Heading3", "center")
  set_style_bold("Heading3", TRUE)
  set_style_font("Heading3Char", ascii = gothic_font, eastasia = gothic_font)
  set_style_size("Heading3Char", "22")
  set_style_bold("Heading3Char", TRUE)

  for (style_id in c("Heading4", "Heading5", "Heading6")) {
    set_style_font(style_id, ascii = gothic_font, eastasia = gothic_font)
    set_style_size(style_id, "20")
    set_style_spacing(style_id, line = "384", before = "240", after = "0")
    set_style_align(style_id, "left")
    set_style_bold(style_id, TRUE)
    set_style_italic(style_id, FALSE)
  }
  for (style_id in c("Heading4Char", "Heading5Char", "Heading6Char")) {
    set_style_font(style_id, ascii = gothic_font, eastasia = gothic_font)
    set_style_size(style_id, "20")
    set_style_bold(style_id, TRUE)
    set_style_italic(style_id, FALSE)
  }

  for (style_id in c("BodyTextChar", "DefaultParagraphFont")) {
    set_style_font(style_id)
    set_style_size(style_id, "20")
  }

  compact_styles <- c("Caption", "CaptionedFigure", "FootnoteText")
  for (style_id in compact_styles) {
    set_style_font(style_id)
    set_style_spacing(style_id, line = "240", before = "0", after = "120")
    set_style_align(style_id, "both")
  }
  set_style_size("Caption", "18")
  set_style_size("CaptionedFigure", "18")
  set_style_size("FootnoteText", "18")

  write_xml(styles_xml, styles_path, options = "format")
}

neutralize_embedded_docx_sections <- function(path) {
  tmpdir <- tempfile("embedded_docx_")
  dir.create(tmpdir, recursive = TRUE)
  on.exit(unlink(tmpdir, recursive = TRUE), add = TRUE)
  utils::unzip(path, exdir = tmpdir)

  document_path <- file.path(tmpdir, "word", "document.xml")
  if (!file.exists(document_path)) return(invisible(FALSE))

  doc_xml <- read_xml(document_path)
  ns <- xml_ns(doc_xml)

  paragraph_sects <- xml_find_all(doc_xml, ".//w:pPr/w:sectPr", ns)
  if (length(paragraph_sects) > 0) {
    xml_remove(paragraph_sects)
  }

  body <- xml_find_first(doc_xml, ".//w:body", ns)
  body_sect <- xml_find_first(body, "./w:sectPr", ns)
  if (inherits(body_sect, "xml_missing")) {
    body_sect <- xml_add_child(body, "w:sectPr")
  }
  old_pg <- xml_find_first(body_sect, "./w:pgSz", ns)
  if (!inherits(old_pg, "xml_missing")) {
    xml_remove(old_pg)
  }
  pg <- xml_add_child(body_sect, "w:pgSz", .where = 0)
  xml_set_attr(pg, "w:w", "15840")
  xml_set_attr(pg, "w:h", "12240")
  xml_set_attr(pg, "w:orient", "landscape")

  write_xml(doc_xml, document_path, options = "format")

  files <- list.files(tmpdir, recursive = TRUE, all.files = TRUE, no.. = TRUE)
  out <- tempfile(fileext = ".docx")
  zip::zipr(out, files = files, recurse = FALSE, include_directories = FALSE, root = tmpdir, mode = "mirror")
  file.copy(out, path, overwrite = TRUE)
  unlink(out)
  invisible(TRUE)
}

html_text <- paste(readLines(output_html, warn = FALSE), collapse = "\n")
html_text <- str_replace_all(
  html_text,
  "(<h2[^>]*>국문요약</h2>)",
  '<div class="section-page-break"></div>\n\\1'
)
html_text <- str_replace_all(
  html_text,
  "(<h2[^>]*>부록</h2>)",
  '<div class="section-page-break"></div>\n\\1'
)
for (marker in names(table_insertions)) {
  src <- normalizePath(file.path(root, table_insertions[[marker]]), mustWork = FALSE)
  if (!file.exists(src)) next
  needle <- paste0("<p>", marker, "</p>")
  if (!str_detect(html_text, fixed(needle))) next
  html_text <- str_replace_all(
    html_text,
    fixed(needle),
    docx_table_to_html(src, marker)
  )
  message("Inserted HTML ", marker, " from ", table_insertions[[marker]])
}
writeLines(html_text, output_html, useBytes = TRUE)

patch_docx_xml <- function(path) {
  tmpdir <- tempfile("docx_patch_")
  dir.create(tmpdir, recursive = TRUE)
  on.exit(unlink(tmpdir, recursive = TRUE), add = TRUE)
  utils::unzip(path, exdir = tmpdir)

  document_path <- file.path(tmpdir, "word", "document.xml")
  rels_path <- file.path(tmpdir, "word", "_rels", "document.xml.rels")
  styles_path <- file.path(tmpdir, "word", "styles.xml")
  document_xml <- readLines(document_path, warn = FALSE)
  document_xml <- paste(document_xml, collapse = "\n")

  document_xml <- str_replace_all(
    document_xml,
    fixed("Figure\u00a01: Association between loneliness and caudate response."),
    "Figure\u00a02. Association between loneliness and caudate response."
  )
  document_xml <- str_replace_all(
    document_xml,
    fixed("Figure 1: Association between loneliness and caudate response."),
    "Figure 2. Association between loneliness and caudate response."
  )
  document_xml <- str_replace_all(
    document_xml,
    fixed("Figure\u00a02: Association between loneliness and caudate response."),
    "Figure\u00a02. Association between loneliness and caudate response."
  )
  document_xml <- str_replace_all(
    document_xml,
    fixed("Figure 2: Association between loneliness and caudate response."),
    "Figure 2. Association between loneliness and caudate response."
  )
  document_xml <- str_replace_all(
    document_xml,
    fixed("Figure\u00a01: Overview of the fMRI task procedure."),
    "Figure\u00a01. Overview of the fMRI task procedure."
  )
  document_xml <- str_replace_all(
    document_xml,
    fixed("Figure 1: Overview of the fMRI task procedure."),
    "Figure 1. Overview of the fMRI task procedure."
  )

  doc_xml <- read_xml(document_xml)
  ns_doc <- xml_ns(doc_xml)

  add_sibling_fragment <- function(target, fragment, where = c("before", "after")) {
    where <- match.arg(where)
    fragment_xml <- read_xml(paste0(
      '<root xmlns:w="', ns_doc[["w"]], '" xmlns:r="', ns_doc[["r"]], '">',
      fragment,
      "</root>"
    ))
    xml_add_sibling(target, xml_children(fragment_xml)[[1]], .where = where)
  }

  ensure_ppr <- function(paragraph) {
    ppr <- xml_find_first(paragraph, "./w:pPr", ns_doc)
    if (inherits(ppr, "xml_missing")) {
      ppr <- xml_add_child(paragraph, "w:pPr", .where = 0)
    }
    ppr
  }

  set_paragraph_section <- function(paragraph, orientation = c("portrait", "landscape")) {
    orientation <- match.arg(orientation)
    ppr <- ensure_ppr(paragraph)
    old_sect <- xml_find_first(ppr, "./w:sectPr", ns_doc)
    if (!inherits(old_sect, "xml_missing")) {
      xml_remove(old_sect)
    }
    sect <- xml_add_child(ppr, "w:sectPr")
    type <- xml_add_child(sect, "w:type")
    xml_set_attr(type, "w:val", "nextPage")
    pg <- xml_add_child(sect, "w:pgSz")
    if (orientation == "landscape") {
      xml_set_attr(pg, "w:w", "15840")
      xml_set_attr(pg, "w:h", "12240")
      xml_set_attr(pg, "w:orient", "landscape")
    } else {
      xml_set_attr(pg, "w:w", "12240")
      xml_set_attr(pg, "w:h", "15840")
    }
    invisible(paragraph)
  }

  set_spacing <- function(paragraph, line = "240", before = "0", after = "120") {
    ppr <- ensure_ppr(paragraph)
    spacing <- xml_find_first(ppr, "./w:spacing", ns_doc)
    if (inherits(spacing, "xml_missing")) {
      spacing <- xml_add_child(ppr, "w:spacing")
    }
    xml_set_attr(spacing, "w:line", line)
    xml_set_attr(spacing, "w:lineRule", "auto")
    xml_set_attr(spacing, "w:before", before)
    xml_set_attr(spacing, "w:after", after)
  }

  set_compact_note <- function(paragraph) {
    set_spacing(paragraph, line = "240", before = "0", after = "0")
    ppr <- ensure_ppr(paragraph)
    jc <- xml_find_first(ppr, "./w:jc", ns_doc)
    if (inherits(jc, "xml_missing")) {
      jc <- xml_add_child(ppr, "w:jc")
    }
    xml_set_attr(jc, "w:val", "both")
    runs <- xml_find_all(paragraph, ".//w:r", ns_doc)
    for (run in runs) {
      rpr <- xml_find_first(run, "./w:rPr", ns_doc)
      if (inherits(rpr, "xml_missing")) {
        rpr <- xml_add_child(run, "w:rPr", .where = 0)
      }
      rfonts <- xml_find_first(rpr, "./w:rFonts", ns_doc)
      if (inherits(rfonts, "xml_missing")) {
        rfonts <- xml_add_child(rpr, "w:rFonts", .where = 0)
      }
      xml_set_attr(rfonts, "w:ascii", "AppleMyungjo")
      xml_set_attr(rfonts, "w:hAnsi", "AppleMyungjo")
      xml_set_attr(rfonts, "w:cs", "AppleMyungjo")
      xml_set_attr(rfonts, "w:eastAsia", "AppleMyungjo")
      sz <- xml_find_first(rpr, "./w:sz", ns_doc)
      if (inherits(sz, "xml_missing")) sz <- xml_add_child(rpr, "w:sz")
      xml_set_attr(sz, "w:val", "18")
      sz_cs <- xml_find_first(rpr, "./w:szCs", ns_doc)
      if (inherits(sz_cs, "xml_missing")) sz_cs <- xml_add_child(rpr, "w:szCs")
      xml_set_attr(sz_cs, "w:val", "18")
    }
  }

  set_paragraph_run_style <- function(
    paragraph,
    font = "AppleMyungjo",
    size = "20",
    line = "384",
    before = "0",
    after = "0",
    align = "center",
    first_line = NULL,
    bold = FALSE
  ) {
    set_spacing(paragraph, line = line, before = before, after = after)
    ppr <- ensure_ppr(paragraph)
    jc <- xml_find_first(ppr, "./w:jc", ns_doc)
    if (inherits(jc, "xml_missing")) {
      jc <- xml_add_child(ppr, "w:jc")
    }
    xml_set_attr(jc, "w:val", align)
    if (!is.null(first_line)) {
      ind <- xml_find_first(ppr, "./w:ind", ns_doc)
      if (inherits(ind, "xml_missing")) {
        ind <- xml_add_child(ppr, "w:ind")
      }
      xml_set_attr(ind, "w:firstLine", first_line)
    }
    runs <- xml_find_all(paragraph, ".//w:r", ns_doc)
    for (run in runs) {
      rpr <- xml_find_first(run, "./w:rPr", ns_doc)
      if (inherits(rpr, "xml_missing")) {
        rpr <- xml_add_child(run, "w:rPr", .where = 0)
      }
      rfonts <- xml_find_first(rpr, "./w:rFonts", ns_doc)
      if (inherits(rfonts, "xml_missing")) {
        rfonts <- xml_add_child(rpr, "w:rFonts", .where = 0)
      }
      xml_set_attr(rfonts, "w:ascii", font)
      xml_set_attr(rfonts, "w:hAnsi", font)
      xml_set_attr(rfonts, "w:cs", font)
      xml_set_attr(rfonts, "w:eastAsia", font)
      sz <- xml_find_first(rpr, "./w:sz", ns_doc)
      if (inherits(sz, "xml_missing")) sz <- xml_add_child(rpr, "w:sz")
      xml_set_attr(sz, "w:val", size)
      sz_cs <- xml_find_first(rpr, "./w:szCs", ns_doc)
      if (inherits(sz_cs, "xml_missing")) sz_cs <- xml_add_child(rpr, "w:szCs")
      xml_set_attr(sz_cs, "w:val", size)
      if (bold) {
        if (inherits(xml_find_first(rpr, "./w:b", ns_doc), "xml_missing")) xml_add_child(rpr, "w:b")
        if (inherits(xml_find_first(rpr, "./w:bCs", ns_doc), "xml_missing")) xml_add_child(rpr, "w:bCs")
      }
      for (italic_tag in c("w:i", "w:iCs")) {
        italic_node <- xml_find_first(rpr, paste0("./", italic_tag), ns_doc)
        if (!inherits(italic_node, "xml_missing")) {
          xml_set_attr(italic_node, "w:val", "false")
        }
      }
    }
  }

  set_figure_title <- function(paragraph) {
    set_paragraph_run_style(
      paragraph,
      font = "AppleMyungjo",
      size = "20",
      line = "240",
      before = "0",
      after = "0",
      align = "both",
      first_line = NULL,
      bold = TRUE
    )
  }

  has_page_break <- function(paragraph) {
    if (is.null(paragraph) || inherits(paragraph, "xml_missing")) {
      return(FALSE)
    }
    length(xml_find_all(paragraph, ".//w:br[@w:type='page']", ns_doc)) > 0
  }

  add_page_break_before_paragraph <- function(paragraph) {
    body <- xml_parent(paragraph)
    body_children <- xml_children(body)
    child_paths <- xml_path(body_children)
    idx <- match(xml_path(paragraph), child_paths)
    previous_paragraph <- if (!is.na(idx) && idx > 1) body_children[[idx - 1]] else NULL
    if (!has_page_break(previous_paragraph)) {
      add_sibling_fragment(paragraph, '<w:p><w:r><w:br w:type="page"/></w:r></w:p>', "before")
    }
    ppr <- ensure_ppr(paragraph)
    keep_next <- xml_find_first(ppr, "./w:keepNext", ns_doc)
    if (inherits(keep_next, "xml_missing")) {
      xml_add_child(ppr, "w:keepNext", .where = 0)
    }
    invisible(paragraph)
  }

  inline_docx_altchunks <- function() {
    if (!file.exists(rels_path)) {
      return(invisible(FALSE))
    }

    rels_xml <- read_xml(rels_path)
    ns_rels <- xml_ns(rels_xml)
    rels <- xml_find_all(rels_xml, ".//d1:Relationship", ns_rels)
    if (length(rels) == 0) {
      return(invisible(FALSE))
    }

    rel_ids <- xml_attr(rels, "Id")
    rel_targets <- xml_attr(rels, "Target")
    chunks <- xml_find_all(doc_xml, ".//w:altChunk", ns_doc)
    if (length(chunks) == 0) {
      return(invisible(FALSE))
    }

    for (chunk in chunks) {
      chunk_id <- xml_attr(chunk, "id")
      target <- rel_targets[match(chunk_id, rel_ids)]
      if (is.na(target) || !str_detect(target, "\\.docx$")) {
        next
      }

      embedded_path <- file.path(tmpdir, "word", target)
      if (!file.exists(embedded_path)) {
        next
      }

      embedded_tmp <- tempfile("inline_docx_")
      dir.create(embedded_tmp, recursive = TRUE)
      on.exit(unlink(embedded_tmp, recursive = TRUE), add = TRUE)
      utils::unzip(embedded_path, exdir = embedded_tmp)
      embedded_document <- file.path(embedded_tmp, "word", "document.xml")
      if (!file.exists(embedded_document)) {
        next
      }

      embedded_xml <- read_xml(embedded_document)
      embedded_ns <- xml_ns(embedded_xml)
      embedded_body <- xml_find_first(embedded_xml, ".//w:body", embedded_ns)
      embedded_children <- xml_children(embedded_body)
      embedded_children <- embedded_children[xml_name(embedded_children) != "sectPr"]

      for (child in embedded_children) {
        embedded_sects <- xml_find_all(child, ".//w:sectPr", embedded_ns)
        if (length(embedded_sects) > 0) {
          xml_remove(embedded_sects)
        }
        xml_add_sibling(chunk, child, .where = "before", .copy = TRUE)
      }
      xml_remove(chunk)
    }
    invisible(TRUE)
  }

  if (file.exists(rels_path)) {
    rels_xml <- read_xml(rels_path)
    ns_rels <- xml_ns(rels_xml)
    rels <- xml_find_all(rels_xml, ".//d1:Relationship", ns_rels)
    targets <- xml_attr(rels, "Target")
    table2_id <- xml_attr(rels[targets == "Table_2_correlations.docx"], "Id")

    if (length(table2_id) != 1) {
      message("Skipping Table 2 landscape section: Table 2 or correlation heading not present.")
    } else {
      correlation_heading <- xml_find_first(
        doc_xml,
        ".//w:p[w:pPr/w:pStyle[@w:val='Heading3'] and contains(., '상관관계')]",
        ns_doc
      )
      table2_chunk <- xml_find_first(
        doc_xml,
        paste0(".//w:altChunk[@r:id='", table2_id, "']"),
        ns_doc
      )

      if (inherits(correlation_heading, "xml_missing")) {
        message("Skipping Table 2 landscape section: Table 2 or correlation heading not present.")
      } else if (inherits(table2_chunk, "xml_missing")) {
        message("Skipping Table 2 landscape section: Table 2 or correlation heading not present.")
      } else {
        body <- xml_find_first(doc_xml, ".//w:body", ns_doc)
        body_children <- xml_children(body)
        child_paths <- xml_path(body_children)
        corr_idx <- match(xml_path(correlation_heading), child_paths)
        table2_idx <- match(xml_path(table2_chunk), child_paths)

        heading2_children <- xml_find_all(
          body,
          "./w:p[w:pPr/w:pStyle[@w:val='Heading3']]",
          ns_doc
        )
        heading2_paths <- xml_path(heading2_children)
        next_heading_candidates <- heading2_children[match(heading2_paths, child_paths) > corr_idx]
        next_heading_idx <- if (length(next_heading_candidates) > 0) {
          match(xml_path(next_heading_candidates[[1]]), child_paths)
        } else {
          NA_integer_
        }

        if (is.na(corr_idx) || is.na(table2_idx) || is.na(next_heading_idx)) {
          stop("Could not resolve Table 2 landscape section boundaries in manuscript DOCX.")
        }
        if (!(corr_idx < table2_idx && table2_idx < next_heading_idx)) {
          stop("Table 2 altChunk is not between Heading3 '상관관계' and the next Heading3.")
        }

        portrait_break <- paste0(
          '<w:p><w:pPr><w:spacing w:before="0" w:after="0" w:line="240" w:lineRule="auto"/>',
          '<w:sectPr>',
          '<w:type w:val="nextPage"/>',
          '<w:pgSz w:w="12240" w:h="15840"/>',
          '</w:sectPr></w:pPr></w:p>'
        )
        add_sibling_fragment(correlation_heading, portrait_break, "before")

        landscape_break <- paste0(
          '<w:p><w:pPr><w:spacing w:before="0" w:after="0" w:line="240" w:lineRule="auto"/><w:sectPr>',
          '<w:type w:val="nextPage"/>',
          '<w:pgSz w:w="15840" w:h="12240" w:orient="landscape"/>',
          '</w:sectPr></w:pPr></w:p>'
        )
        add_sibling_fragment(table2_chunk, landscape_break, "after")

        table2_docx_path <- file.path(tmpdir, "word", "Table_2_correlations.docx")
        if (file.exists(table2_docx_path)) {
          neutralize_embedded_docx_sections(table2_docx_path)
        }
      }
    }
  }

  inline_docx_altchunks()

  {
    body <- xml_find_first(doc_xml, ".//w:body", ns_doc)
    section_break_headings <- c("국문요약", "부록")
    section_heading_paragraphs <- xml_find_all(
      body,
      "./w:p[w:pPr/w:pStyle[@w:val='Heading2']]",
      ns_doc
    )
    for (heading_text in section_break_headings) {
      matching <- section_heading_paragraphs[trimws(xml_text(section_heading_paragraphs)) == heading_text]
      if (length(matching) != 1) {
        stop("Could not find exactly one Heading1 text for page break: ", heading_text)
      }
      add_page_break_before_paragraph(matching[[1]])
    }
  }

  find_previous_drawing_paragraph <- function(title_paragraph) {
    body <- xml_find_first(doc_xml, ".//w:body", ns_doc)
    body_children <- xml_children(body)
    child_paths <- xml_path(body_children)
    title_idx <- match(xml_path(title_paragraph), child_paths)
    if (is.na(title_idx)) {
      stop("Could not locate figure title in document body: ", xml_text(title_paragraph))
    }
    if (title_idx <= 1) {
      stop("Could not find drawing before figure title: ", xml_text(title_paragraph))
    }
    for (candidate_idx in seq.int(title_idx - 1, 1)) {
      candidate <- body_children[[candidate_idx]]
      extent <- xml_find_first(candidate, ".//wp:extent", ns_doc)
      if (!inherits(extent, "xml_missing")) {
        return(candidate)
      }
      candidate_text <- trimws(xml_text(candidate))
      if (startsWith(candidate_text, "Figure ") || startsWith(candidate_text, "Table ")) {
        break
      }
    }
    stop("Could not find drawing before figure title: ", xml_text(title_paragraph))
  }

  set_drawing_extent <- function(drawing_paragraph, image_path, target_cx) {
    img <- png::readPNG(image_path, info = TRUE)
    dim <- attr(img, "dim")
    if (length(dim) < 2) {
      stop("Could not read image dimensions for DOCX figure sizing: ", image_path)
    }
    target_cy <- round(target_cx * dim[1] / dim[2])

    wp_extents <- xml_find_all(drawing_paragraph, ".//wp:extent", ns_doc)
    for (extent in wp_extents) {
      xml_set_attr(extent, "cx", as.character(target_cx))
      xml_set_attr(extent, "cy", as.character(target_cy))
    }
    a_extents <- xml_find_all(drawing_paragraph, ".//a:ext", ns_doc)
    for (extent in a_extents) {
      xml_set_attr(extent, "cx", as.character(target_cx))
      xml_set_attr(extent, "cy", as.character(target_cy))
    }
    invisible(drawing_paragraph)
  }

  {
    body <- xml_find_first(doc_xml, ".//w:body", ns_doc)
    page_break_titles <- c(
      "Table S1."
    )
    page_break <- '<w:p><w:r><w:br w:type="page"/></w:r></w:p>'
    for (title_text in page_break_titles) {
      title_paragraph <- xml_find_first(
        body,
        paste0("./w:p[contains(., '", title_text, "')]"),
        ns_doc
      )
      if (!inherits(title_paragraph, "xml_missing")) {
        add_sibling_fragment(title_paragraph, page_break, "before")
        ppr <- ensure_ppr(title_paragraph)
        keep_next <- xml_find_first(ppr, "./w:keepNext", ns_doc)
        if (inherits(keep_next, "xml_missing")) {
          xml_add_child(ppr, "w:keepNext", .where = 0)
        }
      }
    }
  }

  {
    body <- xml_find_first(doc_xml, ".//w:body", ns_doc)
    landscape_figure_titles <- c(
      "Figure S4. Caudate response moderation plots for intimate loneliness.",
      "Figure S5. Caudate response moderation plots for total loneliness.",
      "Figure S6. Putamen response moderation plot for total loneliness."
    )
    landscape_figure_files <- c(
      file.path(root, "04_synced", "figures", "Figure_S4_H2_caudate_intimate_moderation_panels.png"),
      file.path(root, "04_synced", "figures", "Figure_S5_H2_caudate_total_moderation_panels.png"),
      file.path(root, "04_synced", "figures", "Figure_S6_H2_putamen_total_moderation_panel.png")
    )
    landscape_figure_cx <- c(6858000, 6858000, 6400800)

    portrait_break <- paste0(
      '<w:p><w:pPr><w:spacing w:before="0" w:after="0" w:line="240" w:lineRule="auto"/>',
      '<w:sectPr>',
      '<w:type w:val="continuous"/>',
      '<w:pgSz w:w="12240" w:h="15840"/>',
      '</w:sectPr></w:pPr></w:p>'
    )
    landscape_break <- paste0(
      '<w:p><w:pPr><w:spacing w:before="0" w:after="0" w:line="240" w:lineRule="auto"/>',
      '<w:sectPr>',
      '<w:type w:val="continuous"/>',
      '<w:pgSz w:w="15840" w:h="12240" w:orient="landscape"/>',
      '</w:sectPr></w:pPr></w:p>'
    )

    find_figure_end <- function(title_paragraph) {
      body_children <- xml_children(body)
      child_paths <- xml_path(body_children)
      title_idx <- match(xml_path(title_paragraph), child_paths)
      if (is.na(title_idx)) {
        stop("Could not locate supplementary figure title in document body.")
      }
      note_idx <- title_idx + 1
      if (
        note_idx <= length(body_children) &&
          startsWith(trimws(xml_text(body_children[[note_idx]])), "Note.")
      ) {
        return(body_children[[note_idx]])
      }
      title_paragraph
    }

    for (idx in seq_along(landscape_figure_titles)) {
      title_text <- landscape_figure_titles[[idx]]
      title_paragraph <- xml_find_first(
        body,
        paste0("./w:p[contains(., '", title_text, "')]"),
        ns_doc
      )
      if (inherits(title_paragraph, "xml_missing")) {
        stop("Could not find supplementary landscape figure title: ", title_text)
      }
      drawing_paragraph <- find_previous_drawing_paragraph(title_paragraph)
      add_sibling_fragment(drawing_paragraph, portrait_break, "before")
      set_drawing_extent(drawing_paragraph, landscape_figure_files[[idx]], landscape_figure_cx[[idx]])
      for (keep_paragraph in list(drawing_paragraph, title_paragraph)) {
        ppr <- ensure_ppr(keep_paragraph)
        keep_next <- xml_find_first(ppr, "./w:keepNext", ns_doc)
        if (inherits(keep_next, "xml_missing")) {
          xml_add_child(ppr, "w:keepNext", .where = 0)
        }
      }
      figure_end <- find_figure_end(title_paragraph)
      add_sibling_fragment(figure_end, landscape_break, "after")
    }
  }

  {
    body <- xml_find_first(doc_xml, ".//w:body", ns_doc)
    landscape_table_titles <- c(
      "Table S3. Model-specific associations between loneliness and region-of-interest responses",
      "Table S4a. Model-specific moderation analyses for caudate response",
      "Table S4b. Model-specific moderation analyses for NAcc response",
      "Table S4c. Model-specific moderation analyses for putamen response",
      "Table S5. Simple slopes for intimate loneliness by levels of social network moderators"
    )

    portrait_break <- paste0(
      '<w:p><w:pPr><w:spacing w:before="0" w:after="0" w:line="240" w:lineRule="auto"/>',
      '<w:sectPr>',
      '<w:type w:val="continuous"/>',
      '<w:pgSz w:w="12240" w:h="15840"/>',
      '</w:sectPr></w:pPr></w:p>'
    )
    landscape_break <- paste0(
      '<w:p><w:pPr><w:spacing w:before="0" w:after="0" w:line="240" w:lineRule="auto"/>',
      '<w:sectPr>',
      '<w:type w:val="continuous"/>',
      '<w:pgSz w:w="15840" w:h="12240" w:orient="landscape"/>',
      '</w:sectPr></w:pPr></w:p>'
    )
    page_break <- '<w:p><w:r><w:br w:type="page"/></w:r></w:p>'

    find_table_end <- function(title_paragraph) {
      body_children <- xml_children(body)
      child_paths <- xml_path(body_children)
      title_idx <- match(xml_path(title_paragraph), child_paths)
      if (is.na(title_idx)) {
        stop("Could not locate supplementary table title in document body.")
      }
      following_titles <- xml_find_all(
        body,
        "./w:p[contains(., 'Table ') or contains(., 'Figure ') or w:pPr/w:pStyle[@w:val='Heading1'] or w:pPr/w:pStyle[@w:val='Heading2'] or w:pPr/w:pStyle[@w:val='Heading3'] or w:pPr/w:pStyle[@w:val='Heading4']]",
        ns_doc
      )
      following_indices <- match(xml_path(following_titles), child_paths)
      next_idx <- following_indices[following_indices > title_idx][1]
      end_idx <- if (!is.na(next_idx)) {
        next_idx - 1
      } else {
        body_sect_idx <- match(xml_path(xml_find_first(body, "./w:sectPr", ns_doc)), child_paths)
        if (is.na(body_sect_idx)) length(body_children) else body_sect_idx - 1
      }
      while (end_idx > title_idx && xml_name(body_children[[end_idx]]) %in% c("bookmarkEnd", "bookmarkStart")) {
        end_idx <- end_idx - 1
      }
      if (end_idx <= title_idx) {
        stop("Could not resolve the end of supplementary landscape table: ", xml_text(title_paragraph))
      }
      body_children[[end_idx]]
    }

    for (title_text in landscape_table_titles) {
      title_paragraph <- xml_find_first(
        body,
        paste0("./w:p[contains(., '", title_text, "')]"),
        ns_doc
      )
      if (inherits(title_paragraph, "xml_missing")) {
        stop("Could not find supplementary landscape table title: ", title_text)
      }
      add_sibling_fragment(title_paragraph, portrait_break, "before")
      add_sibling_fragment(title_paragraph, page_break, "before")
      table_end <- find_table_end(title_paragraph)
      add_sibling_fragment(table_end, landscape_break, "after")
    }
  }

  figure_caption <- xml_find_all(
    doc_xml,
    ".//w:p[contains(., 'Association between loneliness and caudate response.')]",
    ns_doc
  )
  if (length(figure_caption) > 0) {
    for (caption in figure_caption) {
      set_spacing(caption, line = "240", before = "0", after = "120")
      runs <- xml_find_all(caption, ".//w:r", ns_doc)
      for (run in runs) {
        rpr <- xml_find_first(run, "./w:rPr", ns_doc)
        if (inherits(rpr, "xml_missing")) {
          rpr <- xml_add_child(run, "w:rPr", .where = 0)
        }
        sz <- xml_find_first(rpr, "./w:sz", ns_doc)
        if (inherits(sz, "xml_missing")) sz <- xml_add_child(rpr, "w:sz")
        xml_set_attr(sz, "w:val", "18")
        sz_cs <- xml_find_first(rpr, "./w:szCs", ns_doc)
        if (inherits(sz_cs, "xml_missing")) sz_cs <- xml_add_child(rpr, "w:szCs")
        xml_set_attr(sz_cs, "w:val", "18")
      }
    }
  }

  figure_title_paragraphs <- xml_find_all(
    doc_xml,
    ".//w:body/w:p[starts-with(normalize-space(.), 'Figure ')]",
    ns_doc
  )
  if (length(figure_title_paragraphs) > 0) {
    for (figure_title_paragraph in figure_title_paragraphs) {
      set_figure_title(figure_title_paragraph)
    }
  }

  compact_note_paragraphs <- xml_find_all(
    doc_xml,
    paste0(
      ".//w:body/w:p[starts-with(normalize-space(.), 'Note.')",
      " or starts-with(normalize-space(.), 'Values are')",
      " or starts-with(normalize-space(.), 'Model 1 =')",
      " or starts-with(normalize-space(.), 'Model 2 =')",
      " or starts-with(normalize-space(.), 'Model 3 =')",
      " or starts-with(normalize-space(.), 'Model 4 =')",
      " or starts-with(normalize-space(.), 'Low, mean, and high slopes')",
      " or starts-with(normalize-space(.), 'Models adjusted')",
      " or starts-with(normalize-space(.), '† p')]"
    ),
    ns_doc
  )
  if (length(compact_note_paragraphs) > 0) {
    for (note_paragraph in compact_note_paragraphs) {
      set_compact_note(note_paragraph)
    }
  }

  first_h1 <- xml_find_first(
    doc_xml,
    ".//w:p[w:pPr/w:pStyle[@w:val='Heading1']][1]",
    ns_doc
  )
  if (!inherits(first_h1, "xml_missing")) {
    ppr <- xml_find_first(first_h1, "./w:pPr", ns_doc)
    if (inherits(ppr, "xml_missing")) {
      ppr <- xml_add_child(first_h1, "w:pPr", .where = 0)
    }
    jc <- xml_find_first(ppr, "./w:jc", ns_doc)
    if (inherits(jc, "xml_missing")) {
      jc <- xml_add_child(ppr, "w:jc")
    }
    xml_set_attr(jc, "w:val", "center")
    runs <- xml_find_all(first_h1, ".//w:r", ns_doc)
    for (run in runs) {
      rpr <- xml_find_first(run, "./w:rPr", ns_doc)
      if (inherits(rpr, "xml_missing")) rpr <- xml_add_child(run, "w:rPr", .where = 0)
      sz <- xml_find_first(rpr, "./w:sz", ns_doc)
      if (inherits(sz, "xml_missing")) sz <- xml_add_child(rpr, "w:sz")
      xml_set_attr(sz, "w:val", "32")
      sz_cs <- xml_find_first(rpr, "./w:szCs", ns_doc)
      if (inherits(sz_cs, "xml_missing")) sz_cs <- xml_add_child(rpr, "w:szCs")
      xml_set_attr(sz_cs, "w:val", "32")
      b <- xml_find_first(rpr, "./w:b", ns_doc)
      if (inherits(b, "xml_missing")) xml_add_child(rpr, "w:b")
      bcs <- xml_find_first(rpr, "./w:bCs", ns_doc)
      if (inherits(bcs, "xml_missing")) xml_add_child(rpr, "w:bCs")
    }

    body <- xml_find_first(doc_xml, ".//w:body", ns_doc)
    body_children <- xml_children(body)
    child_paths <- xml_path(body_children)
    title_idx <- match(xml_path(first_h1), child_paths)
    if (!is.na(title_idx)) {
      following_paragraphs <- body_children[
        seq.int(title_idx + 1, min(length(body_children), title_idx + 8))
      ]
      following_paragraphs <- following_paragraphs[
        xml_name(following_paragraphs) == "p" &
          trimws(xml_text(following_paragraphs)) %in% c("익명", "소속 익명(OO 대학교)")
      ]
      if (length(following_paragraphs) >= 1) {
        set_paragraph_run_style(following_paragraphs[[1]], size = "22", line = "384", align = "center")
      }
      if (length(following_paragraphs) >= 2) {
        set_paragraph_run_style(following_paragraphs[[2]], size = "20", line = "384", align = "center")
      }
    }
  }

  author_note_paragraphs <- xml_find_all(
    doc_xml,
    paste0(
      ".//w:body/w:p[starts-with(normalize-space(.), '본 연구는 2017년 대한민국 교육부와 한국연구재단')",
      " or starts-with(normalize-space(.), '교신저자: 최진영')",
      " or starts-with(normalize-space(.), 'E-mail: jychey@snu.ac.kr')]"
    ),
    ns_doc
  )
  if (length(author_note_paragraphs) > 0) {
    for (note_paragraph in author_note_paragraphs) {
      set_paragraph_run_style(
        note_paragraph,
        size = "18",
        line = "312",
        before = "0",
        after = "0",
        align = "both",
        first_line = "400"
      )
    }
  }

  final_sect <- xml_find_first(doc_xml, ".//w:body/w:sectPr", ns_doc)
  if (!inherits(final_sect, "xml_missing")) {
    final_pg <- xml_find_first(final_sect, "./w:pgSz", ns_doc)
    if (inherits(final_pg, "xml_missing")) {
      final_pg <- xml_add_child(final_sect, "w:pgSz", .where = 0)
    }
    xml_set_attr(final_pg, "w:w", "12240")
    xml_set_attr(final_pg, "w:h", "15840")
    xml_set_attr(final_pg, "w:orient", "portrait")
  }

  write_xml(doc_xml, document_path, options = "format")

  if (file.exists(styles_path)) {
    patch_styles_xml(styles_path)
  }

  files <- list.files(tmpdir, recursive = TRUE, all.files = TRUE, no.. = TRUE)
  zip::zipr(path, files = files, recurse = FALSE, include_directories = FALSE, root = tmpdir, mode = "mirror")
}

doc <- officer::read_docx(output_docx)
summary_text <- function(x) {
  text <- officer::docx_summary(x)$text
  text[!is.na(text)]
}

for (marker in names(table_insertions)) {
  src <- normalizePath(file.path(root, table_insertions[[marker]]), mustWork = FALSE)
  if (!file.exists(src)) {
    warning("Missing table file for ", marker, ": ", src)
    next
  }
  if (!any(summary_text(doc) == marker)) {
    message("Marker not found, skipping: ", marker)
    next
  }
  doc <- officer::cursor_reach(doc, marker, fixed = TRUE)
  doc <- officer::body_add_docx(doc, src = src, pos = "on")
  message("Inserted ", marker, " from ", table_insertions[[marker]])
}

print(doc, target = tmp_docx)
invisible(file.copy(tmp_docx, output_docx, overwrite = TRUE))
unlink(tmp_docx)
patch_docx_xml(output_docx)

html_text <- paste(readLines(output_html, warn = FALSE), collapse = "\n")
html_text <- str_replace_all(
  html_text,
  fixed("Figure&nbsp;1: Association between loneliness and caudate response."),
  "Figure&nbsp;2. Association between loneliness and caudate response."
)
html_text <- str_replace_all(
  html_text,
  fixed("Figure 1: Association between loneliness and caudate response."),
  "Figure 2. Association between loneliness and caudate response."
)
html_text <- str_replace_all(
  html_text,
  fixed("Figure&nbsp;2: Association between loneliness and caudate response."),
  "Figure&nbsp;2. Association between loneliness and caudate response."
)
html_text <- str_replace_all(
  html_text,
  fixed("Figure 2: Association between loneliness and caudate response."),
  "Figure 2. Association between loneliness and caudate response."
)
html_text <- str_replace_all(
  html_text,
  fixed("Figure&nbsp;1: Overview of the fMRI task procedure."),
  "Figure&nbsp;1. Overview of the fMRI task procedure."
)
html_text <- str_replace_all(
  html_text,
  fixed("Figure 1: Overview of the fMRI task procedure."),
  "Figure 1. Overview of the fMRI task procedure."
)

heading2_matches <- str_match_all(
  html_text,
  '<h2[^>]*data-anchor-id="([^"]+)"[^>]*>(.*?)</h2>'
)[[1]]
if (nrow(heading2_matches) > 0) {
  toc_items <- vapply(seq_len(nrow(heading2_matches)), function(i) {
    heading_id <- heading2_matches[i, 1 + 1]
    heading_label <- heading2_matches[i, 2 + 1]
    heading_label <- str_replace_all(heading_label, "<[^>]+>", "")
    heading_label <- str_squish(heading_label)
    sprintf('<li><a href="#%s" class="nav-link">%s</a></li>', heading_id, heading_label)
  }, character(1))
  toc_html <- paste0(
    '<nav id="TOC" role="doc-toc" class="toc-active">',
    '<h2 id="toc-title">Table of contents</h2>',
    '<ul>',
    paste(toc_items, collapse = "\n"),
    '</ul>',
    '</nav>'
  )
  if (str_detect(html_text, '<nav id="TOC"')) {
    html_text <- str_replace(
      html_text,
      '<nav id="TOC"[^>]*>.*?</nav>',
      toc_html
    )
  } else {
    html_text <- str_replace(
      html_text,
      '(<div id="quarto-margin-sidebar" class="sidebar margin-sidebar">\\s*)',
      paste0("\\1\n", toc_html, "\n")
    )
  }
}
writeLines(html_text, output_html, useBytes = TRUE)
unlink(render_qmd)

message("Saved manuscript with insertions: ", output_docx)
message("DOCX modified: ", mtime(output_docx))
message("Saved HTML preview: ", output_html)
message("HTML modified: ", mtime(output_html))
