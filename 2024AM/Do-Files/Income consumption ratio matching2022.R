#load required libraries
library(StatMatch)
library(survey)
library(questionr)
library(reldist)
library(glmnet)
library(useful)
library(data.table)
library(readstata13)
library(statar)
library(parallel)
library(foreach)
library(doParallel)
library(dplyr)
library(dineq)
library(survey)
library(convey)
#clear all
rm(list=ls())
# parallel set
numCores <- detectCores()
registerDoParallel(numCores) 

#set country and dir
#setwd("/Users/Israel/Library/CloudStorage/OneDrive-Personal/WBG/ETIRI/Projects/FY24/FY24 5 SAS - Bangladesh/BGD_branch/02_SM2024/Data")
#setwd("C:/Users/WB308767/OneDrive - WBG/ETIRI/Projects/FY24/FY24 5 SAS - Bangladesh/BGD_branch/02_SM2024/Data")
setwd("C:/Users/WB308767/OneDrive/WBG/ETIRI/Projects/FY25/FY25 - SAR MPO AM24/BGD-MPO-Microsimulation/2024AM/Data/OUTPUT")

year=2026
macro_cons_gr= 0.1096
#BaU
#2022     2023      2024      2025      2026    
#0.00000	0.0105	  0.01332	  0.05301	  0.09833

#Crisis
#2022     2023      2024      2025      2026    
#0.0000	  0.0105	  0.01332	  0.0692	  0.1096


#BaU
#2022     2023      2024      2025      2026    
#0.00000	0.00942	  0.01332	  0.05301	  0.09833

#Crisis
#2022     2023      2024      2025      2026    
#0.0000	  0.0105	  0.0400	  0.0692	  0.1096

#SM2024
#2022      2023         2024          2025        2026   
#0.0000   0.009424708	  0.0133218	  0.053010795	  0.09833253	

  
#0.017094132	0.047833608	0.081937694	0.114043323 
#0.009424708	0.0133218	0.053010795	0.09833253	0.149219544


inputfile=paste("basesim_",year,".dta",sep="")

#receiver
samp.b=read.dta13(inputfile,nonint.factors = TRUE,generate.factors = TRUE)
samp.b=subset(samp.b,h_head==1)

#samp.b$welfare_ppp17=with(samp.b,welfare*welfarenom_ppp17/welfarenom)
samp.b$welfare_ppp17=with(samp.b,(12/365)*welfarenat/cpi2017/icp2017)

samp.b$vtil=xtile(samp.b$welfare,n=20,wt=samp.b$wgt)
samp.b=samp.b[!is.na(samp.b$region) & !is.na(samp.b$vtil) &
                !is.na(samp.b$age) & !is.na(samp.b$urban)  & 
                !is.na(samp.b$pop_wgt) ,]
samp.b$ratio_orig=samp.b$ipcf_ppp17/samp.b$welfare_ppp17


#donor
samp.a=samp.b
samp.a$ratio=samp.a$ipcf_ppp17/samp.a$welfare_ppp17
samp.a$pc_inc_s = samp.a$ipcf_ppp17

group.v <- c("region","vtil","urban")  # donation classes
X.mtc=c("age","hsize","pc_inc_s") 
set.seed(123456)
rnd.2 <- RANDwNND.hotdeck(data.rec=samp.b, data.don=samp.a,
                          match.vars=X.mtc, don.class=group.v,
                          dist.fun="Euclidean",
                          cut.don="min")
#Create synthetic panel
fA.wrnd <- create.fused(data.rec=samp.b, data.don=samp.a,
                        mtc.ids=rnd.2$mtc.ids,
                        z.vars=c("ratio"))


#avgratio=wtd.mean(fA.wrnd$ratio,fA.wrnd$pop_wgt)
fA.wrnd$ratio=ifelse(abs(fA.wrnd$ratio_orig-fA.wrnd$ratio)/fA.wrnd$ratio_orig-1>0.2,
                     fA.wrnd$ratio_orig,fA.wrnd$ratio)

fA.wrnd$ratio=ifelse(is.na(fA.wrnd$ratio),fA.wrnd$ratio_orig,fA.wrnd$ratio)

#fA.wrnd$ratio=ifelse(fA.wrnd$ratio==0,avgratio,fA.wrnd$ratio)


fA.wrnd$welfare_ppp17_s=fA.wrnd$pc_inc_s/fA.wrnd$ratio


fA.wrnd$welfare_ppp17_s=ifelse(fA.wrnd$ratio<=0,
                                  fA.wrnd$welfare_ppp17*(1+macro_cons_gr),
                                  fA.wrnd$welfare_ppp17_s)
actual_cons_gr=wtd.mean(fA.wrnd$welfare_ppp17_s,fA.wrnd$pop_wgt)/
               wtd.mean(fA.wrnd$welfare_ppp17  ,fA.wrnd$pop_wgt)-1


fA.wrnd$welfare_ppp17_s=fA.wrnd$welfare_ppp17_s*(1+macro_cons_gr-actual_cons_gr)


des <- svydesign(ids = ~hhid, data = fA.wrnd, weights = ~pop_wgt)
des <- convey_prep(des)

#line
results=numeric()
lines=c(2.15,3.65,6.85,3.103274)

for (line in lines){
poverty_hc <- svyfgt(~welfare_ppp17_s, design = des, abs_thresh = line, g = 0,
                     na.rm = TRUE)
coef(poverty_hc)
#poverty gap
poverty_gap <- svyfgt(~welfare_ppp17_s, design = des, abs_thresh = line, g = 1,
                      na.rm = TRUE)
coef(poverty_gap)
#poverty severity
poverty_sev <- svyfgt(~welfare_ppp17_s, design = des, abs_thresh = line, g = 2,
                      na.rm = TRUE)
coef(poverty_sev)
resultstemp=c(coef(poverty_hc),coef(poverty_gap),coef(poverty_sev))
results=append(results,resultstemp)
}
results=append(results,gini.wtd(fA.wrnd$welfare_ppp17_s,fA.wrnd$pop_wgt))

write.csv(100*results,paste("results_",year,".csv",sep=""))
