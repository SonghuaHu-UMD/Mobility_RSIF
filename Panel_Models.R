library(car)
library(mgcv)
library(psych)
library(dplyr)
library(mgcViz)

dat <-
  read.csv('D:/COVID-19/First_Paper_State_Stay_at_Home/state_level_variables_to_R1.csv')

dat[is.na(dat)] <- 0
colnames(dat)
dat$Week <- as.factor(dat$Week)
dat$STFIPS <- as.factor(dat$STFIPS)
dat$STNAME <- as.factor(dat$STNAME)
dat$Enforcement <- as.factor(dat$Enforcement)
dat$FEMA <- as.factor(dat$FEMA)
dat$Is_Weekend <- as.factor(dat$Is_Weekend)
dat$Stay_at_home <- as.factor(dat$Stay_at_home)

dat <- dat[dat$STNAME!='UT(Y)',]
dat <- dat[dat$STNAME!='OK(Y)',]
dat <- dat[dat$STNAME!='OK(N)',]
dat <- dat[dat$STNAME!='OK(N)',]

# GAM
GAM_RES1 <-
  bam(
    ANum_Trips ~ Enforcement +
      Cases +  Adj_Cases + Approval + Is_Weekend 
    + s(Time_Index)
    + s(STNAME, bs = 're')
    + s(Enforcement, bs = 're')
    + s(Cases, STNAME, bs='fs')
    + s(Cases, Time_Index, bs='fs'),
    data = dat,
    select = TRUE,
    family = c("gaussian"),
    method = "REML"
  )
summary(GAM_RES1)

dat$predict <- predict(GAM_RES1,dat)
plot(dat$predict, dat$ANum_Trips)
abline(lm(dat$predict~dat$ANum_Trips), col="red")

# Let Enforcement to 0
dat1 <- dat
dat1$Enforcement = 0
dat1$Enforcement <- as.factor(dat1$Enforcement)
dat$predict_noEnforce <- predict(GAM_RES1,dat1)
sum(dat$predict_noEnforce-dat$predict)
dat$Diff_Enforce <- (dat$predict-dat$predict_noEnforce)/dat$predict # The contribute of the enforcement on trip increasement

# Let Case to 0
dat1 <- dat
dat1$Cases = 0
dat1$Adj_Cases = 0
dat$predict_noCase <- predict(GAM_RES1,dat1)
sum(dat$predict_noCase-dat$predict)
dat$Diff_Case <- (dat$predict-dat$predict_noCase)/dat$predict # The contribute of the enforcement on trip increasement

ggplot(dat, aes(x = Time_Index, y = Diff_Case)) + 
  geom_line(aes(group = STNAME), alpha = 0.6) + 
  theme_bw(base_size = 16) +  # changes default theme
  xlab("Number of Days") +  # changes x-axis label
  ylab("Model Implied Values")   # changes y-axis label


Predict_agg_sub <- dat[dat$STNAME=='IL',]
plot(Predict_agg_sub$Time_Index, Predict_agg_sub$Diff_Enforce,type='b',col='green',ylim=range(Predict_agg_sub$Diff_Enforce,Predict_agg_sub$Diff_Case),lwd=2)
lines(Predict_agg_sub$Time_Index, Predict_agg_sub$Diff_Case, col="red",type='b',lwd=2)



# Visulazation
b <- getViz(GAM_RES1)
print(plot(b, allTerms = T), pages = 1) # Calls print.plotGam()

pl <- plot(b, allTerms = T) + l_points() + l_fitLine(linetype = 3) + l_fitContour() + 
  l_ciLine(colour = 2) + l_ciBar() + l_fitPoints(size = 1, col = 2) + theme_get() + labs(title = NULL)
print(pl, pages = 1)

check(b,
      a.qq = list(method = "tnorm", a.cipoly = list(fill = "light blue")), 
      a.respoi = list(size = 0.5), 
      a.hist = list(bins = 10))

# Predict using raw data
pred2 <- as.vector(predict.gam(GAM_RES1, data=dat))
Predict_agg <- dat %>%
  mutate(pred=pred2)

# Let Enforcement to 0
dat1 <- dat
dat1$Enforcement = 0
dat1$Enforcement <- as.factor(dat1$Enforcement)
pred3 <- as.vector(predict.gam(GAM_RES1,dat1))
Predict_agg <- Predict_agg %>%
  mutate(pred_no_enforce=pred3)
# sum(Predict_agg$pred_no_enforce-Predict_agg$pred)
Predict_agg$adetal1 <- (Predict_agg$pred_no_enforce - Predict_agg$pred)/Predict_agg$pred

# Let Case to 0
dat1 <- dat
dat1$Cases = 0
pred3 <- as.vector(predict.gam(GAM_RES1,dat1))
Predict_agg <- Predict_agg %>%
  mutate(pred_no_case=pred3)
# sum(Predict_agg$pred_no_enforce-Predict_agg$pred)
Predict_agg$adetal1_nocase <- (Predict_agg$pred_no_case - Predict_agg$pred)/Predict_agg$pred
  
ggplot(Predict_agg, aes(x = Time_Index, y = pred_no_enforce)) + 
  geom_line(aes(group = STNAME), alpha = 0.6) + 
  theme_bw(base_size = 16) +  # changes default theme
  xlab("Number of Days") +  # changes x-axis label
  ylab("Model Implied Values")   # changes y-axis label

Predict_agg_sub <- Predict_agg[Predict_agg$STNAME=='UT(N)',]
ggplot(Predict_agg_sub, aes(x = Time_Index, y = adetal1)) + 
  geom_line(aes(group = STNAME), alpha = 0.6) + 
  theme_bw(base_size = 16) +  # changes default theme
  xlab("Number of Days") +  # changes x-axis label
  ylab("Model Implied Values")   # changes y-axis label

Predict_agg[Predict_agg$adetal1==min(Predict_agg$adetal1)]


ggplot(Predict_agg_sub, aes(x = Time_Index, y = adetal1_nocase)) + 
  geom_line(aes(group = STNAME), alpha = 0.6) + 
  theme_bw(base_size = 16) +  # changes default theme
  xlab("Number of Days") +  # changes x-axis label
  ylab("Model Implied Values")   # changes y-axis label








# GAMM
lmer4 <- gamm(ANum_Trips ~ 
                Enforcement  + Cases +  Adj_Cases + Approval + Is_Weekend + 
                s(Time_Index)+s(Time_Index, STNAME, bs='fs'),
              random=list(STNAME = ~1, Time_Index = ~1),
              # random=list(STNAME=~1),
              correlation = corAR1(form = ~ Time_Index | STNAME),
              method = "REML",
              family = c("gaussian"),
              data = dat)

summary(lmer4$lme)
summary(lmer4$gam)

anova(GAM_RES1,lmer4) # Smaller AIC is better

anova(GAM_RES1,lmer4$gam,test="F")

AIC(GAM_RES1,lmer4$gam)


b <- getViz(lmer4$gam)
print(plot(b, allTerms = T), pages = 1) # Calls print.plotGam()

pl <- plot(b, allTerms = T) + l_points() + l_fitLine(linetype = 3) + l_fitContour() + 
  l_ciLine(colour = 2) + l_ciBar() + l_fitPoints(size = 1, col = 2) + theme_get() + labs(title = NULL)
pl$empty # FALSE: because we added gamLayers
print(pl, pages = 1)

check(b,
      a.qq = list(method = "tnorm", 
                  a.cipoly = list(fill = "light blue")), 
      a.respoi = list(size = 0.5), 
      a.hist = list(bins = 10))

lmer4 <- gamm(APMT ~ Enforcement + FEMA  +
                Cases    +  Adj_Cases   + Approval+
                Is_Weekend + s(Time_Index),
              random=list(STNAME=~1),
              #random=list(STNAME=~1),
              correlation=corAR1(form=~Time_Index|STNAME),
              method = "REML",
              family = c("gaussian"),
              data = dat)

summary(lmer4$gam)

pred <- predict(lmer4$lme)
re <- coef(lmer4$lme)[ncol(coef(lmer4$lme))]
pred_ref <- re[[1]][match(dat$STNAME, gsub(".*/", "", rownames(re)))]
pred2 <- as.vector(predict(lmer4$gam, data=dat) - pred_ref)
Predict_agg <- dat %>%
  mutate(pred1=pred2)
ggplot(Predict_agg, aes(x = Time_Index, y = pred2)) + 
  geom_line(aes(group = STNAME), alpha = 0.6) + 
  theme_bw(base_size = 16) +  # changes default theme
  xlab("Number of Days") +  # changes x-axis label
  ylab("Model Implied Values")   # changes y-axis label
