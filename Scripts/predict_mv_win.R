library(glmnet)

setwd("k:/FORSK-Projekt/Projekter/Scientific Projects/201_Beat_AML/")

## Read input data
source("Scripts/aux_functions.R")
X <- buildX("ExternalData")
X <- as.matrix(X)

## Load models and list feautures
load("GeneratedData/dose_response_model_mv.RData")
feat <- row.names(coef(fit_mv)[[1]])[-1]

## Fill missing features in X
miss_feat <- feat[!(feat %in% colnames(X) )]
X2 <- matrix(0, nrow = nrow(X), ncol = length(miss_feat))
colnames(X2) <- miss_feat
X <- cbind(X,X2)

## Predict
pred_fit_mv <- predict(fit_mv,
                       newx = X[,feat],
                       s = "lambda.min")

pred_fit_mv_long <- melt(pred_fit_mv[,,1])
names(pred_fit_mv_long) <- c("lab_id", "inhibitor", "auc")

write.csv(pred_fit_mv_long, "output/predictions.csv", row.names = F, quote = F)
