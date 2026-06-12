#!/usr/bin/env Rscript

args <- commandArgs(trailingOnly = FALSE)
script_arg <- grep("^--file=", args, value = TRUE)
script_path <- if (length(script_arg) > 0) {
  normalizePath(sub("^--file=", "", script_arg[1]), mustWork = TRUE)
} else {
  normalizePath(file.path("_scripts", "sync_zotero_literature.R"), mustWork = TRUE)
}

script_dir <- dirname(script_path)
root <- dirname(script_dir)
bib_path <- file.path(root, "01_source", "references.bib")
inventory_path <- file.path(root, "_logs", "literature", "zotero_inventory.json")
pdf_dir <- file.path(root, "02_literature", "pdfs")
notes_dir <- file.path(root, "02_literature", "notes")
dir.create(pdf_dir, recursive = TRUE, showWarnings = FALSE)
dir.create(notes_dir, recursive = TRUE, showWarnings = FALSE)

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

load_zotero_inventory <- function(path) {
  if (!file.exists(path) || !requireNamespace("jsonlite", quietly = TRUE)) {
    return(data.frame(key = character(), title = character(), year = character()))
  }
  items <- jsonlite::fromJSON(path, simplifyDataFrame = TRUE)
  if (!is.data.frame(items) || !all(c("key", "title") %in% names(items))) {
    return(data.frame(key = character(), title = character(), year = character()))
  }
  if (!"year" %in% names(items)) items$year <- ""
  items$norm_title <- normalize_for_match(items$title)
  items$year <- ifelse(is.na(items$year), "", as.character(items$year))
  items
}

zotero_key_for_entry <- function(entry, inventory) {
  if (nrow(inventory) == 0) return("")
  norm_title <- normalize_for_match(field(entry, "title"))
  year <- entry_year(entry)
  matches <- inventory[inventory$norm_title == norm_title, ]
  if (nrow(matches) == 0) return("")
  if (year != "n.d." && any(matches$year == year)) {
    matches <- matches[matches$year == year, ]
  }
  matches$key[1]
}

parse_bib <- function(path) {
  lines <- readLines(path, warn = FALSE, encoding = "UTF-8")
  starts <- grep("^@", lines)
  if (length(starts) == 0) return(list())
  ends <- c(starts[-1] - 1, length(lines))
  entries <- vector("list", length(starts))
  for (i in seq_along(starts)) {
    block <- lines[starts[i]:ends[i]]
    head <- block[1]
    key <- sub("^@[^\\{]+\\{([^,]+),.*$", "\\1", head)
    type <- sub("^@([^\\{]+)\\{.*$", "\\1", head)
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
  for (field in c("date", "year")) {
    value <- entry[[field, exact = TRUE]]
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

safe_name <- function(value, max_len = 120) {
  value <- gsub("[/:*?\"<>|]", "", value)
  value <- gsub("\\s+", " ", value)
  value <- trimws(value)
  if (nchar(value) > max_len) value <- substr(value, 1, max_len)
  while (nchar(value, type = "bytes") > 180) value <- substr(value, 1, nchar(value) - 1)
  trimws(value)
}

entry_topics <- function(entry) {
  text <- tolower(paste(field(entry, "title"), field(entry, "abstract")))
  topics <- character()
  add <- function(pattern, topic) {
    if (grepl(pattern, text)) topics <<- unique(c(topics, topic))
  }
  add("loneliness|외로움", "loneliness")
  add("social network|network|연결망", "social-network")
  add("reward|보상|striatal|striatum|caudate|accumbens|putamen", "reward")
  add("aging|older|elderly|노인|노화", "aging")
  add("depress|우울", "depression")
  add("fmri|brain|neural|neuro", "neuroimaging")
  add("exclusion|rejection|배제|거절", "social-exclusion")
  if (length(topics) == 0) "reference" else topics
}

`%||%` <- function(left, right) {
  if (is.null(left) || is.na(left) || !nzchar(left)) right else left
}

yaml_escape <- function(value) {
  value <- gsub("\\\\", "\\\\\\\\", value)
  value <- gsub("\"", "\\\\\"", value)
  paste0("\"", value, "\"")
}

attachment_paths <- function(entry) {
  value <- field(entry, "file")
  if (!nzchar(value)) return(character())
  paths <- trimws(unlist(strsplit(value, ";")))
  paths[nzchar(paths)]
}

entries <- parse_bib(bib_path)
if (length(entries) == 0) stop("No BibTeX entries found: ", bib_path)
zotero_inventory <- load_zotero_inventory(inventory_path)

note_names <- character(length(entries))
topics_by_key <- list()
for (i in seq_along(entries)) {
  entry <- entries[[i]]
  authors <- split_authors(field(entry, "author", field(entry, "editor")))
  stem <- safe_name(paste0(
    author_label(authors), "(", entry_year(entry), ") - ", short_title(field(entry, "title"))
  ))
  if (stem %in% note_names) stem <- paste0(stem, " - ", field(entry, "key"))
  note_names[i] <- stem
  topics_by_key[[field(entry, "key")]] <- entry_topics(entry)
}

copied_rows <- list()
missing_rows <- list()

for (i in seq_along(entries)) {
  entry <- entries[[i]]
  paths <- attachment_paths(entry)
  existing <- paths[file.exists(paths)]
  usable <- existing[tolower(tools::file_ext(existing)) %in% c("pdf", "html", "htm")]
  copied_path <- ""
  status <- "missing"
  if (length(usable) > 0) {
    chosen <- usable[order(tolower(tools::file_ext(usable)) != "pdf")][1]
    ext <- tools::file_ext(chosen)
    target <- file.path(pdf_dir, paste0(note_names[i], ".", ext))
    ok <- file.copy(chosen, target, overwrite = TRUE)
    if (ok) {
      copied_path <- file.path("..", "pdfs", basename(target))
      status <- "copied"
    } else {
      status <- "copy_failed"
    }
  }
  copied_rows[[i]] <- data.frame(
    key = field(entry, "key"),
    zotero_item_key = zotero_key_for_entry(entry, zotero_inventory),
    title = field(entry, "title"),
    status = status,
    attachment = copied_path,
    stringsAsFactors = FALSE
  )
  if (status != "copied") {
    missing_rows[[length(missing_rows) + 1]] <- copied_rows[[i]]
  }
}

copied_df <- do.call(rbind, copied_rows)
notes_by_key <- setNames(note_names, vapply(entries, function(entry) field(entry, "key"), character(1)))

for (i in seq_along(entries)) {
  entry <- entries[[i]]
  topics <- topics_by_key[[field(entry, "key")]]
  related <- character()
  for (j in seq_along(entries)) {
    if (i == j) next
    overlap <- intersect(topics, topics_by_key[[field(entries[[j]], "key")]])
    if (length(overlap) > 0) related <- c(related, paste0("[[", notes_by_key[[field(entries[[j]], "key")]], "]]"))
    if (length(related) >= 5) break
  }
  attachment <- copied_df$attachment[copied_df$key == field(entry, "key")][1]
  authors <- split_authors(field(entry, "author", field(entry, "editor")))
  zotero_item_key <- copied_df$zotero_item_key[copied_df$key == field(entry, "key")][1]
  note <- c(
    "---",
    paste0("citation_key: ", yaml_escape(field(entry, "key"))),
    paste0("zotero_item_key: ", yaml_escape(zotero_item_key %||% "")),
    paste0("year: ", yaml_escape(entry_year(entry))),
    paste0("authors: ", yaml_escape(paste(authors, collapse = "; "))),
    paste0("title: ", yaml_escape(field(entry, "title"))),
    paste0("doi: ", yaml_escape(field(entry, "doi"))),
    paste0("url: ", yaml_escape(field(entry, "url"))),
    paste0("attachment: ", yaml_escape(attachment %||% "")),
    paste0("tags: [paper, gyosan, ", paste(topics, collapse = ", "), "]"),
    "---",
    "",
    paste0("# ", field(entry, "title", field(entry, "key"))),
    "",
    "- Index: [[02_literature/index]]",
    "- Manuscript: [[manuscript]]",
    paste0("- Citation key: `", field(entry, "key"), "`"),
    paste0("- PDF/HTML: ", if (nzchar(attachment)) paste0("[", basename(attachment), "](", attachment, ")") else "missing"),
    "",
    "## Topics",
    paste0("- [[topic-", topics, "]]"),
    "",
    "## Related notes",
    if (length(related) > 0) paste0("- ", related) else "- None assigned",
    "",
    "## Notes",
    "- "
  )
  writeLines(note, file.path(notes_dir, paste0(note_names[i], ".md")), useBytes = TRUE)
}

index_lines <- c(
  "# Literature Index",
  "",
  paste0("Generated: ", format(Sys.time(), "%Y-%m-%d %H:%M:%S")),
  paste0("Entries: ", length(entries)),
  paste0("Copied attachments: ", sum(copied_df$status == "copied")),
  paste0("Missing attachments: ", sum(copied_df$status != "copied")),
  "",
  "## Papers"
)
for (i in seq_along(entries)) {
  row <- copied_df[copied_df$key == entries[[i]]$key, ][1, ]
  mark <- if (row$status == "copied") "PDF/HTML" else "missing"
  index_lines <- c(index_lines, paste0("- [[", note_names[i], "]] - `", entries[[i]]$key, "` - ", mark))
}
writeLines(index_lines, file.path(root, "02_literature", "index.md"), useBytes = TRUE)

if (length(missing_rows) > 0) {
  missing_df <- do.call(rbind, missing_rows)
} else {
  missing_df <- data.frame(key = character(), title = character(), status = character(), attachment = character())
}
missing_lines <- c(
  "# Missing Zotero Attachments",
  "",
  paste0("Generated: ", format(Sys.time(), "%Y-%m-%d %H:%M:%S")),
  "",
  if (nrow(missing_df) == 0) "No missing attachments." else paste0("- `", missing_df$key, "` - ", missing_df$title, " (", missing_df$status, ")")
)
writeLines(missing_lines, file.path(root, "02_literature", "missing_attachments.md"), useBytes = TRUE)
utils::write.csv(copied_df, file.path(root, "_logs", "literature", "literature_manifest.csv"), row.names = FALSE, fileEncoding = "UTF-8")

expected_files <- basename(copied_df$attachment[nzchar(copied_df$attachment)])
actual_files <- list.files(pdf_dir, full.names = FALSE)
stale_files <- setdiff(actual_files, expected_files)
if (length(stale_files) > 0) {
  stale_archive <- file.path(root, "_archive", paste0("literature_stale_", format(Sys.Date(), "%Y%m%d")))
  dir.create(stale_archive, recursive = TRUE, showWarnings = FALSE)
  for (file in stale_files) {
    file.rename(file.path(pdf_dir, file), file.path(stale_archive, file))
  }
}

message("[sync_zotero_literature] Entries: ", length(entries))
message("[sync_zotero_literature] Copied attachments: ", sum(copied_df$status == "copied"))
message("[sync_zotero_literature] Missing attachments: ", sum(copied_df$status != "copied"))
message("[sync_zotero_literature] Archived stale attachment copies: ", length(stale_files))
