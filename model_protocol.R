# Shared population and output protocol for all GAM scripts (run from repository root).
RSIF_OUTPUT_DIR <- Sys.getenv("RSIF_OUTPUT_DIR", ".")
dir.create(RSIF_OUTPUT_DIR, recursive=TRUE, showWarnings=FALSE)
prepare_rsif <- function(label) {
  input <- Sys.getenv("RSIF_DATA_PATH", "data/state_level_variables_to_R1.csv")
  dat <- read.csv(input)
  required <- c("ANum_Trips", "APMT", "Enforcement", "Cases", "Adj_Cases", "Approval",
                "Is_Weekend", "National_Cases", "Time_Index", "Week", "STNAME", "STFIPS")
  if (!all(required %in% names(dat))) stop("Missing required model columns")
  exclusions <- Sys.getenv("RSIF_EXCLUSIONS", "")
  reason <- rep("included", nrow(dat))
  if (nzchar(exclusions)) {
    catalog <- read.csv(exclusions, stringsAsFactors=FALSE)
    if (!all(c("STNAME", "reason") %in% names(catalog)) ||
        any(is.na(catalog$reason) | !nzchar(trimws(catalog$reason)))) stop("State exclusions require recorded reasons")
    excluded <- dat$STNAME %in% catalog$STNAME
    reason[excluded] <- paste0("declared exclusion: ", catalog$reason[match(dat$STNAME[excluded], catalog$STNAME)])
  }
  complete <- complete.cases(dat[, required, drop=FALSE])
  numeric_columns <- required[vapply(dat[, required, drop=FALSE], is.numeric, logical(1))]
  if (length(numeric_columns)) complete <- complete & apply(dat[, numeric_columns, drop=FALSE], 1, function(x) all(is.finite(x)))
  reason[reason == "included" & !complete] <- "missing or nonfinite model variable"
  coverage <- data.frame(Row=seq_len(nrow(dat)), STNAME=dat$STNAME, Date=dat$Date, Status=reason)
  write.csv(coverage, file.path(RSIF_OUTPUT_DIR, paste0(label, "_population_coverage.csv")), row.names=FALSE)
  dat <- dat[reason == "included", , drop=FALSE]
  if (!nrow(dat)) stop("No complete model observations")
  dat$Week <- as.numeric(dat$Week)
  for (name in intersect(c("STFIPS", "STNAME", "Enforcement", "FEMA", "Is_Weekend", "Stay_at_home"), names(dat))) dat[[name]] <- factor(dat[[name]])
  if (!("0" %in% levels(dat$Enforcement))) stop("Enforcement=0 counterfactual baseline is absent")
  dat$Enforcement <- relevel(dat$Enforcement, ref="0")
  dat
}
export_gam_predictions <- function(dat, model, response, filename) {
  dat$predict <- as.numeric(predict(model, dat, type="response"))
  counterfactual <- dat
  counterfactual$Enforcement <- factor(rep("0", nrow(dat)), levels=levels(dat$Enforcement))
  dat$predict_noEnforce <- as.numeric(predict(model, counterfactual, type="response"))
  dat$Diff_Enforce <- ifelse(dat$predict != 0, (dat$predict - dat$predict_noEnforce) / dat$predict, NA_real_)
  stats <- summary(model)
  dat$Model_R2_adj <- stats$r.sq
  dat$Model_EDF <- sum(model$edf)
  dat$Model_Residual_DF <- model$df.residual
  dat$Model_Response <- response
  dat$Model_Statistic_Source <- "mgcv::summary.gam"
  dat$Model_Evaluation <- "in_sample_full_fit"
  write.csv(dat, file.path(RSIF_OUTPUT_DIR, filename), row.names=FALSE)
  saveRDS(model, file.path(RSIF_OUTPUT_DIR, paste0(filename, ".model.rds")))
  invisible(dat)
}
