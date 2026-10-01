library(car)
library(mgcv)
library(psych)
library(dplyr)
library(mgcViz)

source("model_protocol.R")
dat <- prepare_rsif("final")

# GAM
GAM_RES1 <-
  bam(
    ANum_Trips ~ Enforcement +
      Cases +  Adj_Cases + Approval + Is_Weekend + National_Cases
    + s(Time_Index)
    + s(Week,k=7)
    + s(STNAME, bs = 're')
    + s(Time_Index, STNAME, bs='fs')
    + s(Enforcement, STNAME,bs='re'),
    data = dat,
    select = TRUE,
    family = c("gaussian"),
    method = "REML"
  )
summary(GAM_RES1)

GAM_RES1$smooth


export_gam_predictions(dat, GAM_RES1, "ANum_Trips", "Output_R_For_Plot.csv")


# GAM
GAM_RES2 <-
  bam(
    APMT ~ Enforcement +
      Cases +  Adj_Cases + Approval + Is_Weekend + National_Cases
    + s(Time_Index)
    + s(Week,k=7)
    + s(STNAME, bs = 're')
    + s(Time_Index, STNAME, bs='fs')
    + s(Enforcement, STNAME,bs='re'),
    data = dat,
    select = TRUE,
    family = c("gaussian"),
    method = "REML"
  )
summary(GAM_RES2)

export_gam_predictions(dat, GAM_RES2, "APMT", "Output_R_For_Plot_PMT.csv")

# Visulazation
b <- getViz(GAM_RES1)
plot(b, select = 1)+ xlab("Time Index") + ylab("S(Time Index)")
ggsave("1-Time.png", units="in", width=3.1, height=3, dpi=1200)
plot(b, select = 2)+ xlab("Week") + ylab("S(Week)") 
ggsave("1-Week.png", units="in", width=3.1, height=3, dpi=1200)
plot(b, select = 3)+ xlab("Gaussian Quantiles") + ylab("Effects") + ggtitle('S(State)')
ggsave("1-State.png", units="in", width=3.1, height=3, dpi=1200)
plot(b, select = 4)+ xlab("Time Index") + ylab("S(Time Index, State)") 
ggsave("1-S_T.png", units="in", width=3.1, height=3, dpi=1200)



b <- getViz(GAM_RES2)
plot(b, select = 1)+ xlab("Time Index") + ylab("S(Time Index)")
ggsave("2-Time.png", units="in", width=3.1, height=3, dpi=1200)
plot(b, select = 2)+ xlab("Week") + ylab("S(Week)") 
ggsave("2-Week.png", units="in", width=3.1, height=3, dpi=1200)
plot(b, select = 3)+ xlab("Gaussian Quantiles") + ylab("Effects") + ggtitle('S(State)')
ggsave("2-State.png", units="in", width=3.1, height=3, dpi=1200)
plot(b, select = 4)+ xlab("Time Index") + ylab("S(Time Index, State)") 
ggsave("2-S_T.png", units="in", width=3.1, height=3, dpi=1200)
# plot(b, select = 5)+ xlab("Gaussian Quantiles") + ylab("Effects") + ggtitle('S(Order, State)')
# ggsave("2-E-S.png", units="in", width=3.1, height=3, dpi=1200)
# print(plot(b, allTerms = T), pages = 1) # Calls print.plotGam()

# OUTPUT DATA
b <- getViz(GAM_RES1)
tem <- plot(b, select = 1)
tem1<-tem$plots[[1]]$data$fit
write.csv(tem1,file.path(RSIF_OUTPUT_DIR, 'plot_11.csv'))

b <- getViz(GAM_RES2)
tem <- plot(b, select = 1)
tem1<-tem$plots[[1]]$data$fit
write.csv(tem1,file.path(RSIF_OUTPUT_DIR, 'plot_21.csv'))


pl <- plot(b, allTerms = T) + l_points() + l_fitLine(linetype = 3) + l_fitContour() + 
  l_ciLine(colour = 2) + l_ciBar() + l_fitPoints(size = 1, col = 2) + theme_get() + labs(title = NULL)
print(pl, pages = 1)

check(b,
      a.qq = list(method = "tnorm", a.cipoly = list(fill = "light blue")), 
      a.respoi = list(size = 0.5), 
      a.hist = list(bins = 10))

