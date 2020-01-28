library(glmnet)

## Read input data
source("/usr/local/bin/aux_functions.R")
X <- buildX("/input")
X <- as.matrix(X)

## Load models and list feautures
load("/usr/local/bin/dose_response_model_mv.RData")
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

## Remove drugs where uni models are better
load("/usr/local/bin/select_mv.RData")
pred_fit_mv_long <- pred_fit_mv_long[pred_fit_mv_long$inhibitor %in% selectMV, ]


## Load uni models and predict for remaining drugs
load("/usr/local/bin/dose_response_model.RData")

## Predict
pred_fit <- list()
remainDrugs <- names(dose_response_models)[-which(names(dose_response_models) %in% selectMV)]
for(drug in remainDrugs){
  fit <- dose_response_models[[drug]]
  temp_fit <- predict(fit, 
                      newx = as.matrix(X[,row.names(coef(fit))[-1]]), 
                      s = "lambda.min")
  pred_fit[[drug]] <- data.frame("lab_id" = row.names(temp_fit),
                                 "inhibitor"  = rep(drug, nrow(temp_fit)),
                                 "auc" = temp_fit[,1])
}

output <- rbind(pred_fit_mv_long, do.call(rbind, pred_fit))
output <- output[order(output$inhibitor, output$lab_id),]


write.csv(output, "/output/predictions.csv", row.names = F, quote = F)