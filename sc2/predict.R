library(survival)

## Read input data
source("/usr/local/bin/aux_functions.R")
X <- buildX("/input")

## Load models and list feautures
load("/usr/local/bin/os_model.RData")
feat <- names(coef(os_fit))

## Fill missing features in X
miss_feat <- feat[!(feat %in% colnames(X) )]
X2 <- matrix(0, nrow = nrow(X), ncol = length(miss_feat))
colnames(X2) <- miss_feat
X <- cbind(X,X2)

## Predict
temp_fit <- predict(os_fit, 
                    newdata = X[,names(coef(os_fit))])
					
## High values of the predicted survival rank must correspond to high values of actual survival
## i.e. concordance is different from Harrel's C.
output <- data.frame("lab_id" = row.names(X), "survival" = (-temp_fit))

write.csv(output, "/output/predictions.csv", row.names = F, quote = F)
