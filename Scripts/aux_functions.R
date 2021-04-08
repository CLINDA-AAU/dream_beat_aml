#library(plyr)
#library(reshape2)
#library(glmnet)

# Function to perform median imputation
medImp <- function(x){
  missing <- which(is.na(x))
  x[missing] <- median(x[-missing])
  return(x)
}

# Function to build X matrix for training or prediction
buildX <- function(input_dir){
    clin_num_cols <- c(1,3,4)
    
    clin_cat    <- read.csv(file.path(input_dir,"clinical_categorical.csv"), stringsAsFactors = F, row.names = 1, check.names = F)
    clin_num    <- read.csv(file.path(input_dir,"clinical_numerical.csv"), stringsAsFactors = F, row.names = 1)
    clin_legend <- read.csv(file.path(input_dir,"clinical_categorical_legend.csv"), stringsAsFactors = F)
    rna <- read.csv(file.path(input_dir,"rnaseq.csv"), check.names = F, stringsAsFactors = F)
    dna <- read.csv(file.path(input_dir,"dnaseq.csv"), stringsAsFactors = F)
    
  
  #####################
  ### Clinical data ###
  #####################
  
  ## Impute missing numerical clinical data
  rn <- row.names(clin_num)
  clin_num <- sapply(clin_num, medImp)
  row.names(clin_num) <- rn
  
  ## Recode categorical clinical data and build design matrix
  ## If levels are not specified for the factor the design matrix in the 
  ## validation set might have fewer columns than the training set
  ## resulting in errors.
  
  for(feat in names(clin_cat)){
    clin_cat[[feat]] <- factor(mapvalues(clin_cat[[feat]],
                                         from = clin_legend$enum[clin_legend$column==feat],
                                         to = clin_legend$value[clin_legend$column==feat]),
                               levels = clin_legend$value[clin_legend$column==feat]
                               )
  }
  
  #clin_cat_model <- model.matrix(rep(1,nrow(clin_cat)) ~ ., data = clin_cat)
  clin_cat_model <- glmnet::makeX(train = clin_cat)
  
  ################
  ### DNA data ###
  ################
  
  ## Reshape DNA data to wide with 0/1 values for variation within gene
  dnaWide <- dcast(dna, lab_id ~ Hugo_Symbol,
                   value.var = "Hugo_Symbol",
                   fun.aggregate = function(x) as.numeric(length(x)>0)
  )
  row.names(dnaWide) <- dnaWide$lab_id
  dnaWide <- dnaWide[,-1] 
  
  ## Not all ids have mutation data - "impute" as none
  missIDs <- row.names(clin_num)[!row.names(clin_num) %in% row.names(dnaWide)]
  missDNAwide <- matrix(nrow = length(missIDs), ncol = ncol(dnaWide), 0)
  row.names(missDNAwide) <- missIDs
  colnames(missDNAwide)  <- colnames(dnaWide)
  
  ## Combine
  dnaWide <- rbind(dnaWide, missDNAwide)
  dnaWide <- dnaWide[order(row.names(dnaWide)),]
  
  ############################
  ### Make combined matrix ###
  ############################
  X <- cbind(t(rna[,-c(1,2)]),
             dnaWide,
             clin_cat_model,
             clin_num[,clin_num_cols])
  
  colnames(X) <- c(rna$Gene,
                   paste("dna", colnames(dnaWide), sep = "_"),
                   colnames(clin_cat_model),   
                   colnames(clin_num)[clin_num_cols]
  )
 return(X) 
}

