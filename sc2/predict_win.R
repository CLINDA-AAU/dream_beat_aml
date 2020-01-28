library(survival)
setwd("k:/FORSK-Projekt/Projekter/Scientific Projects/201_Beat_AML/")

## Read input data
source("Scripts/aux_functions.R")
X <- buildX("ExternalData")

## Load models and list feautures
load("GeneratedData/os_model.RData")
feat <- names(coef(os_fit))

## Fill missing features in X
miss_feat <- feat[!(feat %in% colnames(X) )]
X2 <- matrix(0, nrow = nrow(X), ncol = length(miss_feat))
colnames(X2) <- miss_feat
X <- cbind(X,X2)

## Predict
temp_fit <- predict(os_fit, 
                      newdata = X[,names(coef(os_fit))])
output <- data.frame("lab_id" = row.names(X), "survival" = (-temp_fit))

write.csv(output, "output/predictions.csv", row.names = F, quote = F)
