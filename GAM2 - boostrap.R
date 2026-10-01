library(mgcv)
source("model_protocol.R")
dat <- prepare_rsif("bootstrap")
set.seed(0)
B <- 1000L
# Resample whole states, preserving each state's temporal block and UT/OK subgroups.
state_ids <- unique(as.character(dat$STFIPS))
tables <- list()
logs <- list()
for (ii in seq_len(B)) {
  picked <- sample(state_ids, length(state_ids), replace=TRUE)
  blocks <- lapply(seq_along(picked), function(j) {
    block <- dat[as.character(dat$STFIPS) == picked[j], , drop=FALSE]
    block$STNAME <- paste0(as.character(block$STNAME), "_draw_", j)
    block
  })
  bootstrap_sample <- do.call(rbind, blocks)
  bootstrap_sample$STNAME <- factor(bootstrap_sample$STNAME)
  for (response in c("ANum_Trips", "APMT")) {
    message_text <- ""
    ok <- tryCatch({
      formula <- as.formula(paste(response,
        "~ Enforcement + Cases + Adj_Cases + Approval + Is_Weekend + National_Cases + s(Time_Index) + s(Week,k=7) + s(STNAME,bs='re') + s(Time_Index,STNAME,bs='fs') + s(Enforcement,STNAME,bs='re')"))
      # Match the final model method; each bootstrap fit has its own variable.
      bootstrap_model <- bam(formula, data=bootstrap_sample, select=TRUE,
                             family=gaussian(), method="REML")
      if (identical(bootstrap_model$converged, FALSE)) stop("GAM did not converge")
      table <- as.data.frame(summary(bootstrap_model)$p.table)
      table$Term <- rownames(table)
      table$ID <- ii
      table$Response <- response
      tables[[length(tables)+1]] <- table
      TRUE
    }, error=function(e) { message_text <<- conditionMessage(e); FALSE })
    logs[[length(logs)+1]] <- data.frame(ID=ii, Response=response, Success=ok, Error=message_text)
  }
}
write.csv(do.call(rbind, logs), file.path(RSIF_OUTPUT_DIR, "bootstrap_fit_status.csv"), row.names=FALSE)
if (!length(tables)) stop("All bootstrap fits failed; see bootstrap_fit_status.csv")
coefficients <- do.call(rbind, tables)
write.csv(coefficients, file.path(RSIF_OUTPUT_DIR, "bootstrap_coefficients.csv"), row.names=FALSE)
contrasts <- list()
for (response in c("ANum_Trips", "APMT")) {
  terms <- c("Enforcement1", "Enforcement2", "Enforcement3")
  for (j in 1:2) {
    a <- coefficients[coefficients$Response == response & coefficients$Term == terms[j], c("ID", "Estimate")]
    b <- coefficients[coefficients$Response == response & coefficients$Term == terms[j+1], c("ID", "Estimate")]
    paired <- merge(a, b, by="ID", suffixes=c("_a", "_b"))
    difference <- paired$Estimate_a - paired$Estimate_b
    difference <- difference[is.finite(difference)]
    enough <- length(difference) >= ceiling(.9 * B)
    interval <- if (enough) quantile(difference, c(.025, .975), names=FALSE) else c(NA_real_, NA_real_)
    contrasts[[length(contrasts)+1]] <- data.frame(Response=response,
      Contrast=paste(terms[j], "-", terms[j+1]), Bootstrap_Valid=length(difference), Bootstrap_Requested=B,
      Lower_95=interval[1], Upper_95=interval[2], Method="state_cluster_percentile",
      Status=if (enough) "computed" else "insufficient_successful_pairs")
  }
}
write.csv(do.call(rbind, contrasts), file.path(RSIF_OUTPUT_DIR, "bootstrap_contrasts.csv"), row.names=FALSE)
# Main predictions and fit statistics are exported only by Final_GAM2.R.
