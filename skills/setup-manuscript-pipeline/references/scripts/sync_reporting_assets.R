#!/usr/bin/env Rscript

args <- commandArgs(trailingOnly = FALSE)
script_arg <- grep("^--file=", args, value = TRUE)
root_override <- Sys.getenv("MANUSCRIPT_ROOT", unset = "")
script_path <- if (nzchar(root_override)) {
  file.path(normalizePath(root_override, mustWork = TRUE), "_scripts", "sync_reporting_assets.R")
} else if (length(script_arg) > 0) {
  normalizePath(sub("^--file=", "", script_arg[1]), mustWork = TRUE)
} else {
  normalizePath(file.path("_scripts", "sync_reporting_assets.R"), mustWork = TRUE)
}

script_dir <- dirname(script_path)
manuscript_root <- dirname(script_dir)
project_root <- dirname(manuscript_root)
reporting_root <- file.path(project_root, "02_anal", "03_results", "06_reporting")
dry_run <- "--dry-run" %in% commandArgs(trailingOnly = TRUE)

message("[sync_reporting_assets] Manuscript root: ", manuscript_root)
message("[sync_reporting_assets] Reporting root: ", reporting_root)
if (dry_run) message("[sync_reporting_assets] Dry run only")

copy_specs <- data.frame(
  source = c(
    file.path(reporting_root, "docs", "main", "Table_1_demographic_characteristics.docx"),
    file.path(reporting_root, "docs", "main", "Table_2_correlations.docx"),
    file.path(reporting_root, "docs", "main", "Table_3_h1_roi_responses.docx"),
    file.path(reporting_root, "docs", "main", "Table_4_h2_moderation.docx"),
    file.path(reporting_root, "docs", "supplementary", "Table_S1_community_center_and_residence.docx"),
    file.path(reporting_root, "docs", "supplementary", "Table_S2_full_pairwise_correlations.docx"),
    file.path(reporting_root, "docs", "supplementary", "Table_S3_h1_models.docx"),
    file.path(reporting_root, "docs", "supplementary", "Table_S4a_h2_caudate_models.docx"),
    file.path(reporting_root, "docs", "supplementary", "Table_S4b_h2_nacc_models.docx"),
    file.path(reporting_root, "docs", "supplementary", "Table_S4c_h2_putamen_models.docx"),
    file.path(reporting_root, "docs", "supplementary", "Table_S5_simple_slopes.docx"),
    file.path(reporting_root, "figures", "main", "Figure_H1_H1_M4_roi_caudate_ucla_intimate_w5.png"),
    file.path(reporting_root, "figures", "supplementary", "Figure_S1_complete_network_sample_highlighted.png"),
    file.path(reporting_root, "figures", "supplementary", "Figure_S2_sample_neighbor_subgraph.png"),
    file.path(reporting_root, "figures", "supplementary", "Figure_S3_network_metric_panels.png"),
    file.path(reporting_root, "figures", "supplementary", "Figure_S4_H2_caudate_intimate_moderation_panels.png"),
    file.path(reporting_root, "figures", "supplementary", "Figure_S5_H2_caudate_total_moderation_panels.png"),
    file.path(reporting_root, "figures", "supplementary", "Figure_S6_H2_putamen_total_moderation_panel.png"),
    file.path(reporting_root, "figures", "supplementary", "Figure_S4_demographic_distributions.png"),
    file.path(reporting_root, "figures", "supplementary", "Figure_S5_demographic_qq_panels.png"),
    file.path(reporting_root, "figures", "supplementary", "Figure_S6_demographic_categorical_panels.png"),
    file.path(reporting_root, "figures", "supplementary", "Figure_S7_demographic_scatter_panels.png")
  ),
  target = c(
    file.path(manuscript_root, "04_synced", "tables", "main", "Table_1_demographic_characteristics.docx"),
    file.path(manuscript_root, "04_synced", "tables", "main", "Table_2_correlations.docx"),
    file.path(manuscript_root, "04_synced", "tables", "main", "Table_3_h1_roi_responses.docx"),
    file.path(manuscript_root, "04_synced", "tables", "main", "Table_4_h2_moderation.docx"),
    file.path(manuscript_root, "04_synced", "tables", "supplementary", "Table_S1_community_center_and_residence.docx"),
    file.path(manuscript_root, "04_synced", "tables", "supplementary", "Table_S2_full_pairwise_correlations.docx"),
    file.path(manuscript_root, "04_synced", "tables", "supplementary", "Table_S3_h1_models.docx"),
    file.path(manuscript_root, "04_synced", "tables", "supplementary", "Table_S4a_h2_caudate_models.docx"),
    file.path(manuscript_root, "04_synced", "tables", "supplementary", "Table_S4b_h2_nacc_models.docx"),
    file.path(manuscript_root, "04_synced", "tables", "supplementary", "Table_S4c_h2_putamen_models.docx"),
    file.path(manuscript_root, "04_synced", "tables", "supplementary", "Table_S5_simple_slopes.docx"),
    file.path(manuscript_root, "04_synced", "figures", "Figure_2_H1_H1_M4_roi_caudate_ucla_intimate_w5.png"),
    file.path(manuscript_root, "04_synced", "figures", "Figure_S1_complete_network_sample_highlighted.png"),
    file.path(manuscript_root, "04_synced", "figures", "Figure_S2_sample_neighbor_subgraph.png"),
    file.path(manuscript_root, "04_synced", "figures", "Figure_S3_network_metric_panels.png"),
    file.path(manuscript_root, "04_synced", "figures", "Figure_S4_H2_caudate_intimate_moderation_panels.png"),
    file.path(manuscript_root, "04_synced", "figures", "Figure_S5_H2_caudate_total_moderation_panels.png"),
    file.path(manuscript_root, "04_synced", "figures", "Figure_S6_H2_putamen_total_moderation_panel.png"),
    file.path(manuscript_root, "04_synced", "figures", "Figure_S4_demographic_distributions.png"),
    file.path(manuscript_root, "04_synced", "figures", "Figure_S5_demographic_qq_panels.png"),
    file.path(manuscript_root, "04_synced", "figures", "Figure_S6_demographic_categorical_panels.png"),
    file.path(manuscript_root, "04_synced", "figures", "Figure_S7_demographic_scatter_panels.png")
  ),
  stringsAsFactors = FALSE
)

bootstrap_sources <- copy_specs[!file.exists(copy_specs$source) & file.exists(copy_specs$target), ]
if (nrow(bootstrap_sources) > 0) {
  for (i in seq_len(nrow(bootstrap_sources))) {
    message("[sync_reporting_assets] Bootstrap reporting source from existing manuscript asset: ",
            basename(bootstrap_sources$target[i]))
    if (!dry_run) {
      dir.create(dirname(bootstrap_sources$source[i]), recursive = TRUE, showWarnings = FALSE)
      ok <- file.copy(bootstrap_sources$target[i], bootstrap_sources$source[i], overwrite = TRUE)
      if (!ok) stop("Could not bootstrap reporting source: ", bootstrap_sources$source[i])
    }
  }
}

missing <- copy_specs$source[!file.exists(copy_specs$source) & !(dry_run & file.exists(copy_specs$target))]
if (length(missing) > 0) {
  stop("Missing required reporting assets:\n", paste(missing, collapse = "\n"))
}

dir.create(file.path(manuscript_root, "04_synced", "tables", "main"), recursive = TRUE, showWarnings = FALSE)
dir.create(file.path(manuscript_root, "04_synced", "tables", "supplementary"), recursive = TRUE, showWarnings = FALSE)
dir.create(file.path(manuscript_root, "04_synced", "figures"), recursive = TRUE, showWarnings = FALSE)
dir.create(file.path(manuscript_root, "_logs"), recursive = TRUE, showWarnings = FALSE)

manifest <- data.frame(
  source = copy_specs$source,
  target = copy_specs$target,
  source_md5 = unname(tools::md5sum(copy_specs$source)),
  target_md5_before = ifelse(file.exists(copy_specs$target), unname(tools::md5sum(copy_specs$target)), ""),
  action = "",
  copied_at = format(Sys.time(), "%Y-%m-%d %H:%M:%S"),
  stringsAsFactors = FALSE
)
manifest$action <- ifelse(
  manifest$source_md5 == manifest$target_md5_before,
  "unchanged",
  ifelse(file.exists(manifest$target), "updated", "created")
)

for (i in seq_len(nrow(copy_specs))) {
  message("[sync_reporting_assets] ", manifest$action[i], ": ",
          basename(copy_specs$source[i]), " -> ", basename(copy_specs$target[i]))
  if (!dry_run && manifest$action[i] != "unchanged") {
    dir.create(dirname(copy_specs$target[i]), recursive = TRUE, showWarnings = FALSE)
    ok <- file.copy(copy_specs$source[i], copy_specs$target[i], overwrite = TRUE)
    if (!ok) stop("Could not copy reporting asset: ", copy_specs$source[i])
  }
}

if (!dry_run) {
  manifest$target_md5_after <- unname(tools::md5sum(copy_specs$target))
  utils::write.csv(
    manifest,
    file.path(manuscript_root, "_logs", "reporting_asset_sync_manifest.csv"),
    row.names = FALSE,
    fileEncoding = "UTF-8"
  )
}

message("[sync_reporting_assets] Complete")
