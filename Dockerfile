## Start from this Docker image
FROM r-base

## Install R in Docker image
RUN apt-get update 
RUN apt-get install libcurl4-openssl-dev
RUN apt-get install libssl-dev


## Install R packages in Docker image
RUN R -e "install.packages('plyr',dependencies=TRUE, repos='http://cran.rstudio.com/')"
RUN R -e "install.packages('reshape2',dependencies=TRUE, repos='http://cran.rstudio.com/')"
RUN R -e "install.packages('glmnet',dependencies=TRUE, repos='http://cran.rstudio.com/')" 

## Copy files into Docker image
COPY Scripts/predict_uni_mv.R /usr/local/bin/predict.R
COPY Scripts/aux_functions.R /usr/local/bin/
COPY GeneratedData/dose_response_model_mv.RData /usr/local/bin/
COPY GeneratedData/dose_response_model.RData /usr/local/bin/
COPY GeneratedData/select_mv.RData /usr/local/bin/

## Copy training files to test docker image
#RUN mkdir /input
#RUN mkdir /output
#COPY ExternalData/clinical_categorical.csv /input/
#COPY ExternalData/clinical_categorical_legend.csv /input/
#COPY ExternalData/clinical_numerical.csv /input/
#COPY Docker/dnaseq_test.csv /input/dnaseq.csv
#COPY ExternalData/rnaseq.csv /input/

RUN chmod a+x /usr/local/bin/predict.R

## Make Docker container executable
ENTRYPOINT ["Rscript", "/usr/local/bin/predict.R"]