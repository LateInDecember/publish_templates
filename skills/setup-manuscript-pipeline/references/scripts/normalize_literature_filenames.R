#!/usr/bin/env Rscript

args <- commandArgs(trailingOnly = TRUE)
apply_changes <- "--apply" %in% args

script_args <- commandArgs(trailingOnly = FALSE)
script_arg <- grep("^--file=", script_args, value = TRUE)
script_path <- if (length(script_arg) > 0) {
  normalizePath(sub("^--file=", "", script_arg[1]), mustWork = TRUE)
} else {
  normalizePath(file.path("_scripts", "normalize_literature_filenames.R"), mustWork = TRUE)
}

root <- dirname(dirname(script_path))
literature_dir <- file.path(root, "02_literature")
logs_dir <- file.path(root, "_logs", "literature")
dir.create(logs_dir, recursive = TRUE, showWarnings = FALSE)
pdf_dir <- file.path(literature_dir, "pdfs")
notes_dir <- file.path(literature_dir, "notes")
bib_path <- file.path(root, "01_source", "references.bib")
manifest_path <- file.path(logs_dir, "literature_manifest.csv")
review_dir <- file.path(logs_dir, "filename_normalization_review", format(Sys.time(), "%Y%m%d_%H%M%S"))

clean_braces <- function(value) {
  value <- gsub("\\{\\\\\"u\\}", "ü", value)
  value <- gsub("\\{\\\\`e\\}", "è", value)
  value <- gsub("\\{\\\\u\\s+g\\}", "ğ", value)
  value <- gsub("\\{\\\\'a\\}", "á", value)
  value <- gsub("\\{\\\\'e\\}", "é", value)
  value <- gsub("\\{\\\\'i\\}", "í", value)
  value <- gsub("\\{\\\\'o\\}", "ó", value)
  value <- gsub("\\{\\\\'u\\}", "ú", value)
  value <- gsub("\\\\\"\\{u\\}", "ü", value)
  value <- gsub("\\\\`\\{e\\}", "è", value)
  value <- gsub("\\\\u\\s*\\{g\\}", "ğ", value)
  value <- gsub("\\\\'\\{a\\}", "á", value)
  value <- gsub("\\\\'\\{e\\}", "é", value)
  value <- gsub("\\\\'\\{i\\}", "í", value)
  value <- gsub("\\\\'\\{o\\}", "ó", value)
  value <- gsub("\\\\'\\{u\\}", "ú", value)
  value <- gsub("\\\\[[:alpha:]]+\\{([^}]*)\\}", "\\1", value)
  value <- gsub("[{}]", "", value)
  value <- gsub("\\\\&", "&", value)
  value <- gsub("\\\\'", "'", value)
  value <- gsub("\\\\\"", "\"", value)
  value <- gsub("\\s+", " ", value)
  trimws(value)
}

safe_name <- function(value, max_len = 120) {
  value <- gsub("[/:*?\"<>|]", "", value)
  value <- gsub("\\s+", " ", value)
  value <- trimws(value)
  if (nchar(value) > max_len) value <- substr(value, 1, max_len)
  while (nchar(value, type = "bytes") > 180) value <- substr(value, 1, nchar(value) - 1)
  trimws(value)
}

normalize_for_match <- function(value) {
  value <- tolower(clean_braces(value))
  gsub("[^0-9a-z가-힣]+", "", value)
}

field <- function(entry, name, default = "") {
  value <- entry[[name, exact = TRUE]]
  if (is.null(value) || is.na(value) || !nzchar(value)) default else value
}

parse_bib <- function(path) {
  lines <- readLines(path, warn = FALSE, encoding = "UTF-8")
  starts <- grep("^@", lines)
  ends <- c(starts[-1] - 1, length(lines))
  entries <- vector("list", length(starts))
  for (i in seq_along(starts)) {
    block <- lines[starts[i]:ends[i]]
    fields <- list()
    current_key <- NULL
    current_value <- character()
    brace_balance <- 0
    flush_field <- function() {
      value <- paste(current_value, collapse = "\n")
      value <- sub(",\\s*$", "", value)
      value <- sub("^\\s*[A-Za-z]+\\s*=\\s*", "", value)
      value <- trimws(value)
      if (startsWith(value, "{") && endsWith(value, "}")) value <- substring(value, 2, nchar(value) - 1)
      fields[[tolower(current_key)]] <<- clean_braces(value)
    }
    for (line in block[-1]) {
      if (grepl("^\\s*[A-Za-z]+\\s*=", line)) {
        if (!is.null(current_key)) flush_field()
        current_key <- sub("^\\s*([A-Za-z]+)\\s*=.*$", "\\1", line)
        current_value <- line
        brace_balance <- lengths(regmatches(line, gregexpr("\\{", line))) -
          lengths(regmatches(line, gregexpr("\\}", line)))
      } else if (!is.null(current_key)) {
        current_value <- c(current_value, line)
        brace_balance <- brace_balance +
          lengths(regmatches(line, gregexpr("\\{", line))) -
          lengths(regmatches(line, gregexpr("\\}", line)))
      }
      if (!is.null(current_key) && brace_balance <= 0 && grepl(",\\s*$", line)) {
        flush_field()
        current_key <- NULL
        current_value <- character()
      }
    }
    if (!is.null(current_key)) flush_field()
    entries[[i]] <- c(list(key = sub("^@[^\\{]+\\{([^,]+),.*$", "\\1", block[1])), fields)
  }
  entries
}

split_authors <- function(author) {
  if (!nzchar(author)) return(character())
  trimws(unlist(strsplit(author, "\\s+and\\s+")))
}

author_surname <- function(author) {
  if (length(author) == 0 || !nzchar(author)) return("Unknown")
  if (grepl(",", author)) {
    label <- trimws(strsplit(author, ",")[[1]][1])
  } else {
    label <- tail(strsplit(author, "\\s+")[[1]], 1)
  }
  label <- gsub("[/:*?\"<>|]", "", label)
  if (!nzchar(label)) "Unknown" else label
}

apa_author_label <- function(authors) {
  if (length(authors) == 0) return("Unknown")
  labels <- vapply(authors, author_surname, character(1))
  if (length(labels) == 1) return(labels[1])
  if (length(labels) == 2) return(paste(labels, collapse = " & "))
  if (length(labels) == 3) return(paste0(labels[1], ", ", labels[2], " & ", labels[3]))
  paste0(labels[1], " et al")
}

legacy_author_label <- function(authors) {
  if (length(authors) == 0) return("Unknown")
  first <- author_surname(authors[1])
  if (length(authors) > 1) paste0(first, " et al") else first
}

entry_year <- function(entry) {
  for (name in c("date", "year")) {
    value <- entry[[name, exact = TRUE]]
    if (!is.null(value)) {
      year <- regmatches(value, regexpr("\\d{4}", value))
      if (length(year) > 0 && nzchar(year)) return(year)
    }
  }
  "n.d."
}

short_title <- function(title) {
  if (!nzchar(title)) return("Untitled")
  title <- sub(":.*$", "", title)
  title <- sub("\\?.*$", "", title)
  title <- gsub("[.!?,;:]+$", "", title)
  title <- gsub("\\s+", " ", title)
  words <- strsplit(trimws(title), "\\s+")[[1]]
  if (length(words) > 7) title <- paste(words[1:7], collapse = " ")
  title
}

entry_stem <- function(entry, label_fun) {
  authors <- split_authors(field(entry, "author", field(entry, "editor")))
  safe_name(paste0(label_fun(authors), "(", entry_year(entry), ") - ", short_title(field(entry, "title"))))
}

attachment_basenames <- function(entry) {
  value <- field(entry, "file")
  if (!nzchar(value)) return(character())
  paths <- trimws(unlist(strsplit(value, ";", fixed = TRUE)))
  basenames <- basename(paths[tolower(tools::file_ext(paths)) == "pdf"])
  basenames[nzchar(basenames)]
}

entries <- parse_bib(bib_path)
keys <- vapply(entries, function(entry) field(entry, "key"), character(1))
old_stems <- vapply(entries, entry_stem, character(1), label_fun = legacy_author_label)
new_stems <- vapply(entries, entry_stem, character(1), label_fun = apa_author_label)

expected <- data.frame(
  key = keys,
  year = vapply(entries, entry_year, character(1)),
  apa_label = vapply(entries, function(entry) {
    apa_author_label(split_authors(field(entry, "author", field(entry, "editor"))))
  }, character(1)),
  legacy_label = vapply(entries, function(entry) {
    legacy_author_label(split_authors(field(entry, "author", field(entry, "editor"))))
  }, character(1)),
  old_pdf = paste0(old_stems, ".pdf"),
  new_pdf = paste0(new_stems, ".pdf"),
  old_note = paste0(old_stems, ".md"),
  new_note = paste0(new_stems, ".md"),
  norm_short_title = vapply(entries, function(entry) {
    normalize_for_match(short_title(field(entry, "title")))
  }, character(1)),
  stringsAsFactors = FALSE
)
expected <- expected[!duplicated(expected$key), ]

manifest <- if (file.exists(manifest_path)) read.csv(manifest_path, stringsAsFactors = FALSE) else data.frame()
manifest_pdf_to_key <- setNames(manifest$key, basename(manifest$attachment))
old_pdf_to_key <- setNames(expected$key, expected$old_pdf)
new_pdf_to_key <- setNames(expected$key, expected$new_pdf)
attachment_names <- unlist(lapply(entries, attachment_basenames), use.names = FALSE)
attachment_keys <- rep(keys, lengths(lapply(entries, attachment_basenames)))
attachment_pdf_to_key <- setNames(attachment_keys, attachment_names)

resolve_key <- function(pdf_name) {
  if (pdf_name %in% names(new_pdf_to_key)) return(new_pdf_to_key[[pdf_name]])
  if (pdf_name %in% names(old_pdf_to_key)) return(old_pdf_to_key[[pdf_name]])
  if (pdf_name %in% names(manifest_pdf_to_key)) return(manifest_pdf_to_key[[pdf_name]])
  if (pdf_name %in% names(attachment_pdf_to_key)) return(attachment_pdf_to_key[[pdf_name]])
  info <- filename_info(pdf_name)
  if (!nzchar(info$year) || !nzchar(info$author)) return("")
  candidates <- expected[expected$year == info$year, ]
  candidates <- candidates[
    normalize_author(candidates$apa_label) == normalize_author(info$author) |
      normalize_author(candidates$legacy_label) == normalize_author(info$author),
  ]
  if (nrow(candidates) > 1 && nzchar(info$title)) {
    title_norm <- normalize_for_match(info$title)
    title_candidates <- candidates[
      candidates$norm_short_title == title_norm |
        startsWith(candidates$norm_short_title, title_norm) |
        startsWith(title_norm, candidates$norm_short_title),
    ]
    if (nrow(title_candidates) > 0) candidates <- title_candidates
  }
  if (nrow(candidates) == 1) return(candidates$key[1])
  ""
}

filename_info <- function(pdf_name) {
  stem <- tools::file_path_sans_ext(pdf_name)
  year_match <- regexpr("\\((\\d{4}|n\\.d\\.)[a-z]?\\)", stem, ignore.case = TRUE)
  if (year_match < 0) year_match <- regexpr("\\d{4}", stem)
  if (year_match < 0) return(list(author = "", year = "", has_short_title = FALSE))
  year_text <- regmatches(stem, year_match)
  author <- trimws(substr(stem, 1, year_match - 1))
  author <- sub("\\s*-\\s*$", "", author)
  list(
    author = author,
    year = gsub("[^0-9]", "", year_text),
    title = trimws(sub("^.*\\)\\s*-\\s*", "", stem)),
    has_short_title = grepl("\\)\\s*-\\s*\\S", stem)
  )
}

normalize_author <- function(value) {
  value <- gsub("[’‘`]", "'", value)
  value <- gsub("[‐‑‒–—]", "-", value)
  normalize_for_match(value)
}

needs_pdf_rename <- function(pdf_name, expected_row) {
  info <- filename_info(pdf_name)
  if (!info$has_short_title) return(TRUE)
  normalize_author(info$author) != normalize_author(expected_row$apa_label)
}

pdf_paths <- list.files(pdf_dir, pattern = "\\.pdf$", full.names = TRUE)
pdf_plan <- data.frame(
  key = character(),
  old_path = character(),
  new_path = character(),
  action = character(),
  reason = character(),
  stringsAsFactors = FALSE
)

for (path in pdf_paths) {
  name <- basename(path)
  key <- resolve_key(name)
  if (!nzchar(key)) {
    pdf_plan <- rbind(pdf_plan, data.frame(key = "", old_path = path, new_path = file.path(review_dir, name), action = "review_move", reason = "no_bib_match"))
    next
  }
  row <- expected[expected$key == key, ][1, ]
  target <- file.path(pdf_dir, row$new_pdf)
  action <- if (needs_pdf_rename(name, row)) "rename" else "keep"
  pdf_plan <- rbind(pdf_plan, data.frame(key = key, old_path = path, new_path = target, action = action, reason = "matched_metadata"))
}

rename_plan <- pdf_plan[pdf_plan$action == "rename", ]
target_counts <- table(rename_plan$new_path)
conflicts <- rename_plan[rename_plan$new_path %in% names(target_counts[target_counts > 1]), ]
existing_conflicts <- rename_plan[file.exists(rename_plan$new_path), ]
if (nrow(conflicts) > 0 || nrow(existing_conflicts) > 0) {
  hit <- pdf_plan$old_path %in% c(conflicts$old_path, existing_conflicts$old_path)
  pdf_plan$action[hit] <- "review_move"
  pdf_plan$reason[hit] <- "target_exists_or_duplicate"
  pdf_plan$new_path[hit] <- file.path(review_dir, basename(pdf_plan$old_path[hit]))
}

if (apply_changes) {
  for (i in seq_len(nrow(pdf_plan))) {
    if (!(pdf_plan$action[i] %in% c("rename", "review_move"))) next
    dir.create(dirname(pdf_plan$new_path[i]), recursive = TRUE, showWarnings = FALSE)
    ok <- file.rename(pdf_plan$old_path[i], pdf_plan$new_path[i])
    if (!ok) stop("Failed to move PDF: ", pdf_plan$old_path[i], " -> ", pdf_plan$new_path[i])
  }
}

replace_all <- function(lines, old, new) {
  for (i in seq_along(old)) {
    if (!identical(old[i], new[i])) lines <- gsub(old[i], new[i], lines, fixed = TRUE)
  }
  lines
}

note_plan <- data.frame(old_path = character(), new_path = character(), action = character(), stringsAsFactors = FALSE)
for (i in seq_len(nrow(expected))) {
  old_path <- file.path(notes_dir, expected$old_note[i])
  new_path <- file.path(notes_dir, expected$new_note[i])
  if (file.exists(old_path) && old_path != new_path) {
    action <- if (file.exists(new_path)) "conflict" else "rename"
    note_plan <- rbind(note_plan, data.frame(old_path = old_path, new_path = new_path, action = action))
  }
}

if (apply_changes) {
  for (i in seq_len(nrow(note_plan))) {
    if (note_plan$action[i] == "rename" && !file.rename(note_plan$old_path[i], note_plan$new_path[i])) {
      stop("Failed to rename note: ", note_plan$old_path[i], " -> ", note_plan$new_path[i])
    }
  }
  note_paths <- list.files(notes_dir, pattern = "\\.md$", full.names = TRUE)
  for (path in note_paths) {
    lines <- readLines(path, warn = FALSE, encoding = "UTF-8")
    lines <- replace_all(lines, expected$old_pdf, expected$new_pdf)
    writeLines(lines, path, useBytes = TRUE)
  }
  if (nrow(manifest) > 0) {
    actual_attachment <- setNames(character(), character())
    for (i in seq_len(nrow(pdf_plan))) {
      if (!nzchar(pdf_plan$key[i]) || pdf_plan$action[i] == "review_move") next
      actual_path <- if (pdf_plan$action[i] == "rename") pdf_plan$new_path[i] else pdf_plan$old_path[i]
      actual_attachment[[pdf_plan$key[i]]] <- file.path("..", "pdfs", basename(actual_path))
    }
    for (i in seq_len(nrow(expected))) {
      hit <- which(manifest$key == expected$key[i])
      attachment <- if (expected$key[i] %in% names(actual_attachment)) actual_attachment[[expected$key[i]]] else ""
      if (length(hit) == 1 && !is.null(attachment) && nzchar(attachment)) {
        manifest$status[hit] <- "copied"
        manifest$attachment[hit] <- attachment
      }
    }
    write.csv(manifest, manifest_path, row.names = FALSE, fileEncoding = "UTF-8")
  }
  for (path in c(file.path(literature_dir, "index.md"), file.path(literature_dir, "missing_attachments.md"))) {
    if (!file.exists(path)) next
    lines <- readLines(path, warn = FALSE, encoding = "UTF-8")
    lines <- replace_all(lines, expected$old_note, expected$new_note)
    lines <- replace_all(lines, expected$old_pdf, expected$new_pdf)
    writeLines(lines, path, useBytes = TRUE)
  }
}

write.csv(pdf_plan, file.path(logs_dir, "filename_normalization_plan.csv"), row.names = FALSE, fileEncoding = "UTF-8")
write.csv(note_plan, file.path(logs_dir, "filename_normalization_note_plan.csv"), row.names = FALSE, fileEncoding = "UTF-8")

message("[normalize_literature_filenames] apply: ", apply_changes)
message("[normalize_literature_filenames] pdfs: ", nrow(pdf_plan))
message("[normalize_literature_filenames] pdf rename: ", sum(pdf_plan$action == "rename"))
message("[normalize_literature_filenames] pdf keep: ", sum(pdf_plan$action == "keep"))
message("[normalize_literature_filenames] pdf review_move: ", sum(pdf_plan$action == "review_move"))
message("[normalize_literature_filenames] pdf conflict: ", sum(pdf_plan$action == "conflict"))
message("[normalize_literature_filenames] note rename: ", sum(note_plan$action == "rename"))
message("[normalize_literature_filenames] note conflict: ", sum(note_plan$action == "conflict"))
