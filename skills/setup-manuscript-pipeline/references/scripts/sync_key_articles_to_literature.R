#!/usr/bin/env Rscript

args <- commandArgs(trailingOnly = TRUE)
dry_run <- "--dry-run" %in% args

script_args <- commandArgs(trailingOnly = FALSE)
script_arg <- grep("^--file=", script_args, value = TRUE)
script_path <- if (length(script_arg) > 0) {
  normalizePath(sub("^--file=", "", script_arg[1]), mustWork = TRUE)
} else {
  normalizePath(file.path("_scripts", "sync_key_articles_to_literature.R"), mustWork = TRUE)
}

script_dir <- dirname(script_path)
root <- dirname(script_dir)
source_root <- "/Users/gangjingi/Library/Mobile Documents/com~apple~CloudDocs/02_Academy/대학원/Analysis note/Key articles"
bib_path <- file.path(root, "01_source", "references.bib")
literature_dir <- file.path(root, "02_literature")
logs_dir <- file.path(root, "_logs", "literature")
dir.create(logs_dir, recursive = TRUE, showWarnings = FALSE)
pdf_dir <- file.path(literature_dir, "pdfs")
notes_dir <- file.path(literature_dir, "notes")
manifest_path <- file.path(logs_dir, "literature_manifest.csv")
children_inventory_path <- file.path(logs_dir, "zotero_children_inventory.csv")

dir.create(pdf_dir, recursive = TRUE, showWarnings = FALSE)

manual_source_overrides <- data.frame(
  source_rel = c(
    "experimental study/Cacioppo et al(2009).pdf",
    "background/Cacioppo, Cacioppo, & Boomsma(2014).pdf",
    "background/Cornwell & Waite(2009).pdf"
  ),
  citation_key = c(
    "cacioppoEyeBeholderIndividual2009",
    "cacioppoEvolutionaryMechanismsLoneliness2014",
    "cornwellSocialDisconnectednessPerceived2009"
  ),
  stringsAsFactors = FALSE
)

manual_review_overrides <- data.frame(
  source_rel = c(
    "background/Cacioppo, Capatanio, & Cacioppo(2014).pdf",
    "background/Cacioppo & Cacioppo(2014).pdf",
    "background/Cornwell(2009).pdf",
    "background/Kim & Sul(2023).pdf",
    "neural correlates/Kim & Sul(2023).pdf"
  ),
  reason = c(
    "title_metadata_unavailable_author_mismatch",
    "duplicate_prefer_three_author_filename",
    "duplicate_prefer_two_author_filename",
    "already_present_in_literature_pdfs",
    "already_present_in_literature_pdfs"
  ),
  stringsAsFactors = FALSE
)

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

field <- function(entry, name, default = "") {
  value <- entry[[name, exact = TRUE]]
  if (is.null(value) || is.na(value) || !nzchar(value)) default else value
}

normalize_for_match <- function(value) {
  value <- tolower(clean_braces(value))
  gsub("[^0-9a-z가-힣]+", "", value)
}

safe_name <- function(value, max_len = 120) {
  value <- gsub("[/:*?\"<>|]", "", value)
  value <- gsub("\\s+", " ", value)
  value <- trimws(value)
  if (nchar(value) > max_len) value <- substr(value, 1, max_len)
  while (nchar(value, type = "bytes") > 180) value <- substr(value, 1, nchar(value) - 1)
  trimws(value)
}

split_authors <- function(author) {
  if (is.null(author) || !nzchar(author)) return(character())
  parts <- unlist(strsplit(author, "\\s+and\\s+"))
  trimws(parts[nzchar(trimws(parts))])
}

author_surname <- function(author) {
  if (length(author) == 0 || !nzchar(author)) return("Unknown")
  if (grepl(",", author)) {
    label <- trimws(strsplit(author, ",")[[1]][1])
  } else {
    bits <- strsplit(author, "\\s+")[[1]]
    label <- tail(bits, 1)
  }
  label <- gsub("[/:*?\"<>|]", "", label)
  if (!nzchar(label)) "Unknown" else label
}

author_label <- function(authors) {
  if (length(authors) == 0) return("Unknown")
  labels <- vapply(authors, author_surname, character(1))
  if (length(labels) == 1) return(labels[1])
  if (length(labels) == 2) return(paste(labels, collapse = " & "))
  if (length(labels) == 3) return(paste0(labels[1], ", ", labels[2], " & ", labels[3]))
  paste0(labels[1], " et al")
}

first_author_label <- function(authors) {
  if (length(authors) == 0) return("Unknown")
  author_surname(authors[1])
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
  if (is.null(title) || !nzchar(title)) return("Untitled")
  title <- sub(":.*$", "", title)
  title <- sub("\\?.*$", "", title)
  title <- gsub("[.!?,;:]+$", "", title)
  title <- gsub("\\s+", " ", title)
  words <- strsplit(trimws(title), "\\s+")[[1]]
  if (length(words) > 7) title <- paste(words[1:7], collapse = " ")
  title
}

parse_bib <- function(path) {
  lines <- readLines(path, warn = FALSE, encoding = "UTF-8")
  starts <- grep("^@", lines)
  if (length(starts) == 0) return(list())
  ends <- c(starts[-1] - 1, length(lines))
  entries <- vector("list", length(starts))
  for (i in seq_along(starts)) {
    block <- lines[starts[i]:ends[i]]
    key <- sub("^@[^\\{]+\\{([^,]+),.*$", "\\1", block[1])
    type <- sub("^@([^\\{]+)\\{.*$", "\\1", block[1])
    fields <- list()
    current_key <- NULL
    current_value <- character()
    brace_balance <- 0
    flush_field <- function() {
      if (!is.null(current_key)) {
        value <- paste(current_value, collapse = "\n")
        value <- sub(",\\s*$", "", value)
        value <- sub("^\\s*[A-Za-z]+\\s*=\\s*", "", value)
        value <- trimws(value)
        if (startsWith(value, "{") && endsWith(value, "}")) {
          value <- substring(value, 2, nchar(value) - 1)
        }
        fields[[tolower(current_key)]] <<- clean_braces(value)
      }
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
    entries[[i]] <- c(list(key = key, type = type), fields)
  }
  entries
}

note_stems <- function(entries) {
  stems <- character(length(entries))
  for (i in seq_along(entries)) {
    entry <- entries[[i]]
    authors <- split_authors(field(entry, "author", field(entry, "editor")))
    stem <- safe_name(paste0(
      author_label(authors), "(", entry_year(entry), ") - ", short_title(field(entry, "title"))
    ))
    if (stem %in% stems) stem <- paste0(stem, " - ", field(entry, "key"))
    stems[i] <- stem
  }
  stems
}

source_author_year <- function(path) {
  stem <- tools::file_path_sans_ext(basename(path))
  year_match <- regexpr("\\((\\d{4}|n\\.d\\.)[a-z]?\\)", stem, ignore.case = TRUE)
  if (year_match < 0) {
    return(list(year = "", first_author = "", coauthors = character(), stem = stem))
  }
  year <- regmatches(stem, year_match)
  year <- gsub("[^0-9]", "", year)
  author_part <- trimws(substr(stem, 1, year_match - 1))
  author_part <- gsub("^dissertive[_ -]*", "", author_part, ignore.case = TRUE)
  author_part <- gsub("^scan[_ -]*", "", author_part, ignore.case = TRUE)
  author_part <- gsub("^FULLTEXT[0-9]*$", "", author_part, ignore.case = TRUE)
  author_part <- gsub("’", "'", author_part)
  author_part <- gsub("Andews-Hanna", "Andrews-Hanna", author_part, ignore.case = TRUE)
  author_part <- gsub("Farari", "Fareri", author_part, ignore.case = TRUE)
  author_part <- gsub("Zeruvabel", "Zerubavel", author_part, ignore.case = TRUE)
  author_part <- gsub("Delagdo", "Delgado", author_part, ignore.case = TRUE)
  parts <- trimws(unlist(strsplit(author_part, "\\s*(,|&| and | et al| 외)\\s*", perl = TRUE)))
  parts <- parts[nzchar(parts)]
  first <- if (length(parts) == 0) "" else parts[1]
  list(
    year = year,
    first_author = normalize_for_match(first),
    coauthors = normalize_for_match(parts[-1]),
    stem = stem
  )
}

entry_match_fields <- function(entry) {
  authors <- split_authors(field(entry, "author", field(entry, "editor")))
  first <- first_author_label(authors)
  first <- sub("\\s+et al$", "", first, ignore.case = TRUE)
  coauthors <- character()
  if (length(authors) > 1) {
    coauthors <- vapply(authors[-1], function(author) {
      first_author_label(author)
    }, character(1))
  }
  list(
    key = field(entry, "key"),
    year = entry_year(entry),
    first_author = normalize_for_match(first),
    coauthors = normalize_for_match(coauthors),
    title = field(entry, "title"),
    norm_title = normalize_for_match(field(entry, "title"))
  )
}

match_source_to_entries <- function(source, eligible) {
  info <- source_author_year(source)
  if (!nzchar(info$year) || !nzchar(info$first_author)) return(data.frame())
  candidates <- eligible[eligible$year == info$year & eligible$first_author == info$first_author, ]
  if (nrow(candidates) <= 1 || length(info$coauthors) == 0) return(candidates)
  overlap_count <- vapply(candidates$coauthors, function(value) {
    if (!nzchar(value)) return(0L)
    sum(info$coauthors %in% unlist(strsplit(value, ";", fixed = TRUE)))
  }, integer(1))
  if (max(overlap_count) > 0) {
    candidates <- candidates[overlap_count == max(overlap_count), ]
  }
  candidates
}

md5 <- function(path) {
  if (!file.exists(path)) return("")
  unname(tools::md5sum(path))
}

relative_attachment <- function(target) {
  file.path("..", "pdfs", basename(target))
}

read_children_inventory <- function(path) {
  if (!file.exists(path)) {
    return(data.frame(zotero_item_key = character(), attachment_count = integer()))
  }
  df <- read.csv(path, stringsAsFactors = FALSE)
  if (!"zotero_item_key" %in% names(df)) return(data.frame(zotero_item_key = character(), attachment_count = integer()))
  if (!"attachment_count" %in% names(df)) df$attachment_count <- 0
  df
}

replace_or_append_line <- function(lines, pattern, replacement) {
  hit <- grep(pattern, lines)
  if (length(hit) > 0) {
    lines[hit[1]] <- replacement
  } else {
    lines <- c(lines, replacement)
  }
  lines
}

update_note_attachment <- function(note_path, attachment) {
  if (!file.exists(note_path)) return(FALSE)
  lines <- readLines(note_path, warn = FALSE, encoding = "UTF-8")
  lines <- replace_or_append_line(lines, "^attachment:", paste0("attachment: \"", gsub("\"", "\\\\\"", attachment), "\""))
  pdf_line <- paste0("- PDF/HTML: [", basename(attachment), "](", attachment, ")")
  lines <- replace_or_append_line(lines, "^- PDF/HTML:", pdf_line)
  if (!dry_run) writeLines(lines, note_path, useBytes = TRUE)
  TRUE
}

entries <- parse_bib(bib_path)
if (length(entries) == 0) stop("No BibTeX entries found: ", bib_path)
stems <- note_stems(entries)
entries_by_key <- setNames(entries, vapply(entries, function(entry) field(entry, "key"), character(1)))
stems_by_key <- setNames(stems, names(entries_by_key))
manifest <- read.csv(manifest_path, stringsAsFactors = FALSE)
children_inventory <- read_children_inventory(children_inventory_path)

match_rows <- list()
for (entry in entries) {
  key <- field(entry, "key")
  manifest_row <- manifest[manifest$key == key, ][1, ]
  if (nrow(manifest_row) == 0 || !nzchar(manifest_row$zotero_item_key)) next
  fields <- entry_match_fields(entry)
  match_rows[[length(match_rows) + 1]] <- data.frame(
    key = key,
    zotero_item_key = manifest_row$zotero_item_key,
    year = fields$year,
    first_author = fields$first_author,
    coauthors = paste(fields$coauthors, collapse = ";"),
    title = fields$title,
    note_stem = stems_by_key[[key]],
    stringsAsFactors = FALSE
  )
}
eligible <- do.call(rbind, match_rows)

all_source_files <- list.files(source_root, recursive = TRUE, full.names = TRUE, all.files = FALSE)
all_source_files <- all_source_files[file.info(all_source_files)$isdir == FALSE]
extensions <- tolower(tools::file_ext(all_source_files))
usable_files <- all_source_files[extensions %in% c("pdf", "html", "htm")]
unsupported_files <- all_source_files[!(extensions %in% c("pdf", "html", "htm"))]

confirmed <- list()
review <- list()
unmatched <- list()

for (source in usable_files) {
  source_rel <- substring(source, nchar(source_root) + 2)
  review_override <- manual_review_overrides[manual_review_overrides$source_rel == source_rel, ]
  if (nrow(review_override) == 1) {
    source_info <- source_author_year(source)
    review[[length(review) + 1]] <- data.frame(
      source_file = source,
      source_author = source_info$first_author,
      source_year = source_info$year,
      candidate_keys = "",
      candidate_titles = "",
      reason = review_override$reason[1],
      stringsAsFactors = FALSE
    )
    next
  }

  source_override <- manual_source_overrides[manual_source_overrides$source_rel == source_rel, ]
  if (nrow(source_override) == 1) {
    candidates <- eligible[eligible$key == source_override$citation_key[1], ]
    if (nrow(candidates) != 1) {
      stop("Manual override did not resolve to one reference: ", source_rel)
    }
    ext <- tolower(tools::file_ext(source))
    target <- file.path(pdf_dir, paste0(candidates$note_stem[1], ".", ifelse(ext == "htm", "html", ext)))
    confirmed[[length(confirmed) + 1]] <- data.frame(
      source_file = source,
      target_file = target,
      citation_key = candidates$key[1],
      zotero_item_key = candidates$zotero_item_key[1],
      title = candidates$title[1],
      manifest_status_before = manifest$status[manifest$key == candidates$key[1]][1],
      match_status = "manual_override",
      source_md5 = md5(source),
      target_md5_before = md5(target),
      stringsAsFactors = FALSE
    )
    next
  }

  candidates <- match_source_to_entries(source, eligible)
  source_info <- source_author_year(source)
  if (nrow(candidates) == 1) {
    candidate_coauthors <- unlist(strsplit(candidates$coauthors[1], ";", fixed = TRUE))
    candidate_coauthors <- candidate_coauthors[nzchar(candidate_coauthors)]
    if (length(source_info$coauthors) > 0 && !all(source_info$coauthors %in% candidate_coauthors)) {
      review[[length(review) + 1]] <- data.frame(
        source_file = source,
        source_author = source_info$first_author,
        source_year = source_info$year,
        candidate_keys = candidates$key[1],
        candidate_titles = candidates$title[1],
        reason = "coauthor_mismatch",
        stringsAsFactors = FALSE
      )
      next
    }
    ext <- tolower(tools::file_ext(source))
    target <- file.path(pdf_dir, paste0(candidates$note_stem[1], ".", ifelse(ext == "htm", "html", ext)))
    confirmed[[length(confirmed) + 1]] <- data.frame(
      source_file = source,
      target_file = target,
      citation_key = candidates$key[1],
      zotero_item_key = candidates$zotero_item_key[1],
      title = candidates$title[1],
      manifest_status_before = manifest$status[manifest$key == candidates$key[1]][1],
      match_status = "confirmed_author_year",
      source_md5 = md5(source),
      target_md5_before = md5(target),
      stringsAsFactors = FALSE
    )
  } else if (nrow(candidates) > 1) {
    review[[length(review) + 1]] <- data.frame(
      source_file = source,
      source_author = source_info$first_author,
      source_year = source_info$year,
      candidate_keys = paste(candidates$key, collapse = ";"),
      candidate_titles = paste(candidates$title, collapse = " | "),
      reason = "ambiguous_author_year",
      stringsAsFactors = FALSE
    )
  } else {
    unmatched[[length(unmatched) + 1]] <- data.frame(
      source_file = source,
      source_author = source_info$first_author,
      source_year = source_info$year,
      reason = "no_reference_match",
      stringsAsFactors = FALSE
    )
  }
}

confirmed_df <- if (length(confirmed) > 0) do.call(rbind, confirmed) else data.frame()
review_df <- if (length(review) > 0) do.call(rbind, review) else data.frame()
unmatched_df <- if (length(unmatched) > 0) do.call(rbind, unmatched) else data.frame()
unsupported_df <- data.frame(source_file = unsupported_files, extension = tolower(tools::file_ext(unsupported_files)), stringsAsFactors = FALSE)

if (nrow(confirmed_df) > 0) {
  duplicate_keys <- names(which(table(confirmed_df$citation_key) > 1))
  if (length(duplicate_keys) > 0) {
    duplicate_rows <- confirmed_df[confirmed_df$citation_key %in% duplicate_keys, ]
    duplicate_review <- data.frame(
      source_file = duplicate_rows$source_file,
      source_author = "",
      source_year = "",
      candidate_keys = duplicate_rows$citation_key,
      candidate_titles = duplicate_rows$title,
      reason = "duplicate_confirmed_sources",
      stringsAsFactors = FALSE
    )
    review_df <- rbind(review_df, duplicate_review)
    confirmed_df <- confirmed_df[!(confirmed_df$citation_key %in% duplicate_keys), ]
  }
}

copied_count <- 0
unchanged_count <- 0
if (nrow(confirmed_df) > 0) {
  confirmed_df$target_md5_after <- confirmed_df$target_md5_before
  confirmed_df$file_action <- "dry_run"
  for (i in seq_len(nrow(confirmed_df))) {
    source <- confirmed_df$source_file[i]
    target <- confirmed_df$target_file[i]
    source_hash <- confirmed_df$source_md5[i]
    before_hash <- confirmed_df$target_md5_before[i]
    if (confirmed_df$manifest_status_before[i] == "copied") {
      confirmed_df$file_action[i] <- "existing_manifest_copy"
      unchanged_count <- unchanged_count + 1
    } else if (source_hash == before_hash && nzchar(source_hash)) {
      confirmed_df$file_action[i] <- "unchanged"
      unchanged_count <- unchanged_count + 1
    } else {
      confirmed_df$file_action[i] <- "copied"
      copied_count <- copied_count + 1
      if (!dry_run) {
        dir.create(dirname(target), recursive = TRUE, showWarnings = FALSE)
        ok <- file.copy(source, target, overwrite = TRUE)
        if (!ok) stop("Failed to copy: ", source, " -> ", target)
      }
    }
    confirmed_df$target_md5_after[i] <- if (dry_run) before_hash else md5(target)
  }
}

if (nrow(confirmed_df) > 0) {
  for (i in seq_len(nrow(confirmed_df))) {
    if (confirmed_df$file_action[i] == "existing_manifest_copy") next
    key <- confirmed_df$citation_key[i]
    attachment <- relative_attachment(confirmed_df$target_file[i])
    row_index <- which(manifest$key == key)
    if (length(row_index) == 1) {
      manifest$status[row_index] <- "copied"
      manifest$attachment[row_index] <- attachment
    }
    note_path <- file.path(notes_dir, paste0(stems_by_key[[key]], ".md"))
    update_note_attachment(note_path, attachment)
  }
}

if (nrow(confirmed_df) > 0) {
  confirmed_df$has_existing_zotero_attachment <- "unknown"
  if (nrow(children_inventory) > 0) {
    counts <- setNames(children_inventory$attachment_count, children_inventory$zotero_item_key)
    confirmed_df$has_existing_zotero_attachment <- ifelse(
      as.integer(counts[confirmed_df$zotero_item_key]) > 0,
      "yes",
      "no"
    )
    confirmed_df$has_existing_zotero_attachment[is.na(confirmed_df$has_existing_zotero_attachment)] <- "unknown"
  }
  queue_df <- confirmed_df[confirmed_df$has_existing_zotero_attachment != "yes", c(
    "zotero_item_key", "citation_key", "source_file", "target_file", "match_status"
  )]
} else {
  queue_df <- data.frame(
    zotero_item_key = character(),
    citation_key = character(),
    source_file = character(),
    target_file = character(),
    match_status = character()
  )
}

index_path <- file.path(literature_dir, "index.md")
if (file.exists(index_path)) {
  index_lines <- readLines(index_path, warn = FALSE, encoding = "UTF-8")
  index_lines[grepl("^Generated:", index_lines)] <- paste0("Generated: ", format(Sys.time(), "%Y-%m-%d %H:%M:%S"))
  index_lines[grepl("^Copied attachments:", index_lines)] <- paste0("Copied attachments: ", sum(manifest$status == "copied"))
  index_lines[grepl("^Missing attachments:", index_lines)] <- paste0("Missing attachments: ", sum(manifest$status != "copied"))
  for (i in seq_len(nrow(manifest))) {
    stem <- stems_by_key[[manifest$key[i]]]
    if (is.null(stem) || !nzchar(stem)) next
    pattern <- paste0("^\\- \\[\\[", gsub("([][(){}.+*?^$\\\\|])", "\\\\\\1", stem), "\\]\\]")
    status_label <- if (manifest$status[i] == "copied") "PDF/HTML" else "missing"
    replacement <- paste0("- [[", stem, "]] - `", manifest$key[i], "` - ", status_label)
    hit <- grep(pattern, index_lines)
    if (length(hit) > 0) index_lines[hit[1]] <- replacement
  }
  if (!dry_run) writeLines(index_lines, index_path, useBytes = TRUE)
}

missing_lines <- c(
  "# Missing Zotero Attachments",
  "",
  paste0("Generated: ", format(Sys.time(), "%Y-%m-%d %H:%M:%S")),
  "",
  if (sum(manifest$status != "copied") == 0) {
    "No missing attachments."
  } else {
    paste0("- `", manifest$key[manifest$status != "copied"], "` - ", manifest$title[manifest$status != "copied"], " (", manifest$status[manifest$status != "copied"], ")")
  }
)

if (!dry_run) {
  write.csv(manifest, manifest_path, row.names = FALSE, fileEncoding = "UTF-8")
  write.csv(confirmed_df, file.path(logs_dir, "key_articles_sync_manifest.csv"), row.names = FALSE, fileEncoding = "UTF-8")
  write.csv(review_df, file.path(logs_dir, "key_articles_review_needed.csv"), row.names = FALSE, fileEncoding = "UTF-8")
  write.csv(unmatched_df, file.path(logs_dir, "key_articles_unmatched.csv"), row.names = FALSE, fileEncoding = "UTF-8")
  write.csv(unsupported_df, file.path(logs_dir, "unsupported_files.csv"), row.names = FALSE, fileEncoding = "UTF-8")
  write.csv(queue_df, file.path(logs_dir, "zotero_attachment_queue.csv"), row.names = FALSE, fileEncoding = "UTF-8")
  writeLines(missing_lines, file.path(literature_dir, "missing_attachments.md"), useBytes = TRUE)
} else {
  write.csv(confirmed_df, file.path(logs_dir, "key_articles_sync_manifest.dry_run.csv"), row.names = FALSE, fileEncoding = "UTF-8")
  write.csv(review_df, file.path(logs_dir, "key_articles_review_needed.dry_run.csv"), row.names = FALSE, fileEncoding = "UTF-8")
  write.csv(unmatched_df, file.path(logs_dir, "key_articles_unmatched.dry_run.csv"), row.names = FALSE, fileEncoding = "UTF-8")
  write.csv(unsupported_df, file.path(logs_dir, "unsupported_files.dry_run.csv"), row.names = FALSE, fileEncoding = "UTF-8")
}

message("[sync_key_articles_to_literature] dry_run: ", dry_run)
message("[sync_key_articles_to_literature] source files: ", length(all_source_files))
message("[sync_key_articles_to_literature] PDF/HTML files: ", length(usable_files))
message("[sync_key_articles_to_literature] unsupported files: ", length(unsupported_files))
message("[sync_key_articles_to_literature] confirmed matches: ", nrow(confirmed_df))
message("[sync_key_articles_to_literature] ambiguous matches: ", nrow(review_df))
message("[sync_key_articles_to_literature] unmatched files: ", nrow(unmatched_df))
message("[sync_key_articles_to_literature] copied actions: ", copied_count)
message("[sync_key_articles_to_literature] unchanged actions: ", unchanged_count)
message("[sync_key_articles_to_literature] queue entries: ", nrow(queue_df))
