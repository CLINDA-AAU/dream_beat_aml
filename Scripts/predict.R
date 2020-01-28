library(glmnet)

## Read input data
source("/usr/local/bin/aux_functions.R")
X <- buildX("/input")
X <- as.matrix(X)

## Load models and list feautures
load("/usr/local/bin/dose_response_model.RData")
feat <- lapply(dose_response_models, function(x) row.names(coef(x))[-1])
feat <- unique(unlist(feat))

## Fill missing features in X
miss_feat <- feat[!(feat %in% colnames(X) )]
X2 <- matrix(0, nrow = nrow(X), ncol = length(miss_feat))
colnames(X2) <- miss_feat
X <- cbind(X,X2)

## Predict
pred_fit <- list()
for(drug in names(dose_response_models)){
  fit <- dose_response_models[[drug]]
  temp_fit <- predict(fit, 
                      newx = X[,row.names(coef(fit))[-1]], 
                      s = "lambda.min")
  pred_fit[[drug]] <- data.frame("lab_id" = row.names(temp_fit),
                                 "inhibitor"  = rep(drug, nrow(temp_fit)),
                                 "auc" = temp_fit[,1])
}

output <- do.call(rbind, pred_fit)
write.csv(output, "/output/predictions.csv", row.names = F, quote = F)
