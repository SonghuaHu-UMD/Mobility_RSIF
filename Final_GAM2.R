library(car)
library(mgcv)
library(psych)
library(dplyr)
library(mgcViz)

dat <-
  read.csv('D:/COVID-19/First_Paper_State_Stay_at_Home/state_level_variables_to_R1.csv')

# Drop some state like UT OK
dat <- dat[dat$STNAME!='UT(Y)',]
dat <- dat[dat$STNAME!='OK(Y)',]
dat <- dat[dat$STNAME!='OK(N)',]
dat <- dat[dat$STNAME!='OK(N)',]

dat[is.na(dat)] <- 0
colnames(dat)
dat$Week <- as.numeric(dat$Week)
dat$STFIPS <- as.factor(dat$STFIPS)
dat$STNAME <- as.factor(dat$STNAME)
dat$Enforcement <- as.factor(dat$Enforcement)
# dat$Enforcement <- factor(dat$Enforcement,ordered = TRUE)
dat$FEMA <- as.factor(dat$FEMA)
dat$Is_Weekend <- as.factor(dat$Is_Weekend)
dat$Stay_at_home <- as.factor(dat$Stay_at_home)

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


dat$predict <- predict.gam(GAM_RES1,dat)
plot(dat$predict, dat$ANum_Trips)
abline(lm(dat$predict~dat$ANum_Trips), col="red")

# Let Enforcement to 0
dat1 <- dat
dat1$Enforcement = 0
dat1$Enforcement <- factor(dat1$Enforcement)
dat$predict_noEnforce <- predict.gam(GAM_RES1,dat1)
sum(dat$predict_noEnforce-dat$predict)
dat$Diff_Enforce <- (dat$predict-dat$predict_noEnforce)/dat$predict # The contribute of the enforcement on trip increasement
write.csv(dat,'C:/Users/Songhua Hu/Desktop/CVO-19/COVID19_Paper/Output_R_For_Plot.csv')


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

dat$predict <- predict.gam(GAM_RES2,dat)
plot(dat$predict, dat$APMT)
abline(lm(dat$predict~dat$APMT), col="red")

# Let Enforcement to 0
dat1 <- dat
dat1$Enforcement = 0
dat1$Enforcement <- factor(dat1$Enforcement)
dat$predict_noEnforce <- predict.gam(GAM_RES2,dat1)
sum(dat$predict_noEnforce-dat$predict)
dat$Diff_Enforce <- (dat$predict-dat$predict_noEnforce)/dat$predict # The contribute of the enforcement on trip increasement
write.csv(dat,'C:/Users/Songhua Hu/Desktop/CVO-19/COVID19_Paper/Output_R_For_Plot_PMT.csv')


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
write.csv(tem1,'C:/Users/Songhua Hu/Desktop/CVO-19/COVID19_Paper/plot_11.csv')

b <- getViz(GAM_RES2)
tem <- plot(b, select = 1)
tem1<-tem$plots[[1]]$data$fit
write.csv(tem1,'C:/Users/Songhua Hu/Desktop/CVO-19/COVID19_Paper/plot_21.csv')


pl <- plot(b, allTerms = T) + l_points() + l_fitLine(linetype = 3) + l_fitContour() + 
  l_ciLine(colour = 2) + l_ciBar() + l_fitPoints(size = 1, col = 2) + theme_get() + labs(title = NULL)
print(pl, pages = 1)

check(b,
      a.qq = list(method = "tnorm", a.cipoly = list(fill = "light blue")), 
      a.respoi = list(size = 0.5), 
      a.hist = list(bins = 10))

