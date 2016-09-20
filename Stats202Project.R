##############################################################################
#                                                                            #
#                                                                            #
#                                                                            #
#                         Final Project                                      #
#                                                                            #
#                                                                            #
#                                                                            #
#                                                                            #
##############################################################################


########## Read Data ##########

setwd('C:/Users/Arun/Desktop/Stats 202/Project')
finalTestData   <- read.csv("test.csv", header=TRUE);
trainData       <- read.csv("training.csv", header=TRUE);
signals   <- trainData[,3:12]
response  <- as.data.frame(trainData[,13])

########## Data Exploration ##########
table(response)
table(signals[,1])
table(signals[,2])
summary(signals)

# plot the data
library(PerformanceAnalytics)
chart.Correlation(signals)

#Data Transformations

#library('MASS')
#library('car')
#Box Cox transformation - find Optimal Lambda
#bc <- boxcox(signals[,8]+4~1,lambda=seq(-4,4,4/10))
#plot(bc)
#bc$x[which.max(bc$y)]

#sig6<-as.data.frame(bcPower(signals[,8]+4, -1.65, jacobian.adjusted=TRUE))
#sig6<-as.data.frame(yjPower(signals[,8]+4, -1.65, jacobian.adjusted=TRUE))
#colnames(sig6)<-c("sig6")
#yjPower(U+3, .5, jacobian.adjusted=TRUE)

transformSignals <- cbind(signals[,1:4],log(signals[,5:8]+1),signals[,9:10])
chart.Correlation(transformSignals)

########## Further Data Exploration ##########
plotECDF = function(signal, mainTitle="", xlab="", xlim=NULL){
  plot(ecdf(signal), verticals = TRUE,
       xlab = '', 
       ylab = expression(hat(F)[n](x)), 
       main = mainTitle)
}

par(mfrow=c(2,5))
# sig1
plotECDF(signals[,1],main="Signal 1")
plotECDF(signals[,2],main="Signal 2")
plotECDF(signals[,3],main="Signal 3")
plotECDF(signals[,4],main="Signal 4")
plotECDF(signals[,5],main="Signal 5")
plotECDF(signals[,6],main="Signal 6")
plotECDF(signals[,7],main="Signal 7")
plotECDF(signals[,8],main="Signal 8")
plotECDF(signals[,9],main="Signal 9")
plotECDF(signals[,10],main="Signal 10")
title( "ECDF Functions for all Signals", outer = TRUE )
dev.off()

#Create a Holdout sample and a model training sample
sampleSet <- sample(1:80046, 60000);
modelSetData        <- transformSignals[sampleSet,];
modelSetResponse    <- as.data.frame(trainData[sampleSet,13])
holdOutSetData      <- transformSignals[-sampleSet,];
holdOutSetResponse  <- as.data.frame(trainData[-sampleSet,13])

colnames(modelSetResponse)   <- c("response")
colnames(holdOutSetResponse) <- c("response")

#############################################################################################################
#                                                                                                           #
#                                                                                                           #
#                                           Fit Models!                                                     #               
#                                                                                                           #
#                                                                                                           #
#############################################################################################################

########## Naïve Bayes ##########
library(e1071)

# 5 fold cross validation of the modeling approach 
k=5
# use the data in the training set
#across all CV for all models
list <- 1:k

id <- sample(1:k,nrow(modelSetData),replace=TRUE) #Initialize this once

prediction <- data.frame()
testsetCopy <- data.frame()
modelError     <- NULL
modelList      <- NULL
modelTestError <- NULL
for (i in 1:k){
  trainingSet       <- subset(modelSetData, id %in% list[-i])
  trainingResponse  <- subset(modelSetResponse, id %in% list[-i])
  testSet           <- subset(modelSetData, id %in% c(i))
  testResponse      <- subset(modelSetResponse, id %in% c(i))
  
  model       = naiveBayes(as.factor(trainingResponse$response)~., trainingSet[])
  #modelList   <- c(modelList,list(model))
  error <- sum(trainingResponse$response!=(as.numeric(predict(model,trainingSet[]))-1))/length(trainingResponse$response)
  modelError  <- c(modelError,list(error))
  errorTest   <- sum(testResponse$response!=(as.numeric(predict(model,testSet[]))-1))/length(testResponse$response)
  modelTestError  <- c(modelTestError,list(errorTest))
}
mean(as.numeric(modelError))
mean(as.numeric(modelTestError))
bayesModel <- naiveBayes(as.factor(modelSetResponse$response)~., modelSetData[])
bayesTrain = sum(modelSetResponse$response!=(as.numeric(predict(bayesModel,modelSetData[]))-1))/length(modelSetResponse$response)
bayesTest  = sum(holdOutSetResponse$response!=(as.numeric(predict(bayesModel,holdOutSetData[]))-1))/length(holdOutSetResponse$response)



########## Naïve Bayes with laplace smoothing ##########
library(e1071)

# 5 fold cross validation of the modeling approach 
# use the data in the training set

k=5 #Folds
list <- 1:k
prediction <- data.frame()
testsetCopy <- data.frame()
modelError     <- NULL
modelList      <- NULL
modelTestError <- NULL
for (i in 1:k){
  trainingSet       <- subset(modelSetData, id %in% list[-i])
  trainingResponse  <- subset(modelSetResponse, id %in% list[-i])
  testSet           <- subset(modelSetData, id %in% c(i))
  testResponse      <- subset(modelSetResponse, id %in% c(i))
  laplace = 0
  for (count in 1:5){
    laplace     = laplace + 0.4
    model       <- naiveBayes(as.factor(trainingResponse$response)~., trainingSet[],laplace)
    #modelList   <- c(modelList,list(model))
    error <- sum(trainingResponse$response!=(as.numeric(predict(model,trainingSet[]))-1))/length(trainingResponse$response)
    modelError  <- c(modelError,list(error))
    errorTest   <- sum(testResponse$response!=(as.numeric(predict(model,testSet[]))-1))/length(testResponse$response)
    modelTestError  <- c(modelTestError,list(errorTest))
  }
}
mean(as.numeric(modelError))
mean(as.numeric(modelTestError))
bayeslaplaceModel <- naiveBayeslaplace(as.factor(modelSetResponse$response)~., modelSetData[])
bayeslaplaceTrain = sum(modelSetResponse$response!=(as.numeric(predict(bayesModel,modelSetData[]))-1))/length(modelSetResponse$response)
bayeslaplaceTest  = sum(holdOutSetResponse$response!=(as.numeric(predict(bayesModel,holdOutSetData[]))-1))/length(holdOutSetResponse$response)



########## Decision Tree ##########
library(rpart)
# 5 fold cross validation of the modeling approach 
# use the data in the training set

k=5 #Folds
list <- 1:k
prediction <- data.frame()
testsetCopy <- data.frame()
modelError     <- NULL
modelList      <- NULL
modelTestError <- NULL
for (i in 1:k){
  trainingSet       <- subset(modelSetData, id %in% list[-i])
  trainingResponse  <- subset(modelSetResponse, id %in% list[-i])
  testSet           <- subset(modelSetData, id %in% c(i))
  testResponse      <- subset(modelSetResponse, id %in% c(i))
  depth = 5
  #model       <- rpart(trainingResponse$response~.,trainingSet,control=rpart.control(maxdepth=depth, cp=0.001))
  modelList   <- c(modelList,list(model))
  error <- sum(trainingResponse$response!=(predict(model,trainingSet)>0.5))/length(trainingResponse$response)
  modelError  <- c(modelError,list(error))
  errorTest   <- sum(testResponse$response!=(predict(model,testSet)>0.5))/length(testResponse$response)
  modelTestError  <- c(modelTestError,list(errorTest))
}
mean(as.numeric(modelError))
mean(as.numeric(modelTestError))
depth =5
decisionTreeModel <- rpart(modelSetResponse$response~.,modelSetData[],control=rpart.control(maxdepth=depth, cp=0.001)) 
decisionTreeTrain = sum(modelSetResponse$response!=(predict(decisionTreeModel,modelSetData)>0.5))/length(modelSetResponse$response)
decisionTreeTest  = sum(holdOutSetResponse$response!=(predict(decisionTreeModel,holdOutSetData)>0.5))/length(holdOutSetResponse$response)

#Error as a function of tree depth
dTreeError <- NULL
dTreeErrorTest <- NULL
for(i in 1:10){
  depth = i
  decisionTreeModel <- rpart(modelSetResponse$response~.,modelSetData[],control=rpart.control(maxdepth=depth, cp=0.001)) 
  decisionTreeTrain = sum(modelSetResponse$response!=(predict(decisionTreeModel,modelSetData)>0.5))/length(modelSetResponse$response)
  decisionTreeTest  = sum(holdOutSetResponse$response!=(predict(decisionTreeModel,holdOutSetData)>0.5))/length(holdOutSetResponse$response)
  dTreeError       <- c(dTreeError,list(decisionTreeTrain))
  dTreeErrorTest   <- c(dTreeErrorTest,list(decisionTreeTest))
}



########## K-Nearest Neighbor ##########
library(class)
# 5 fold cross validation of the modeling approach 
# use the data in the training set
k=5 #Folds
list <- 1:k
prediction <- data.frame()
testsetCopy <- data.frame()
modelError     <- NULL
modelList      <- NULL
modelTestError <- NULL
for (i in 1:k){
  trainingSet       <- subset(modelSetData, id %in% list[-i])
  trainingResponse  <- subset(modelSetResponse, id %in% list[-i])
  testSet           <- subset(modelSetData, id %in% c(i))
  testResponse      <- subset(modelSetResponse, id %in% c(i))
  model       <- knn(trainingSet[,3:10],trainingSet[,3:10],trainingResponse[,1],k=1)
  #modelList   <- c(modelList,list(model))
  error       <- 1-sum(trainingResponse[,1]==model)/length(trainingResponse$response) 
  modelError  <- c(modelError,list(error))
  modelTest   <- knn(trainingSet[,3:10],testSet[,3:10],trainingResponse[,1],k=1)
  errorTest   <- 1-sum(testResponse[,1]==modelTest)/length(testResponse$response) 
  modelTestError  <- c(modelTestError,list(errorTest))
}
mean(as.numeric(modelError))
mean(as.numeric(modelTest))
## Error as a function of K ##
knnTrain<-NULL
knnTest <-NULL
for(i in 1:9){
  modelKNNTrain<-knn(modelSetData[,3:10],modelSetData,modelSetResponse[,1],k=i)
  modelKNNTest<-knn(modelSetData[,3:10],holdOutSetData[,3:10],modelSetResponse$response,k=i)
  knnTrain = 1-sum(modelSetResponse[,1]==modelKNNTrain)/length(modelSetResponse$response)
  knnTest  = 1-sum(holdOutSetResponse$response==modelKNNTest)/length(holdOutSetResponse$response)
  kerror       <- c(kerror,list(knnTrain))
  kerrorTest   <- c(kerrorTest,list(knnTest))
}

modelKNNTrain<-knn(modelSetData[,3:10],modelSetData[,3:10],modelSetResponse[,1],k=40)
modelKNNTest<-knn(modelSetData[,3:10],holdOutSetData[,3:10],modelSetResponse$response,k=40)
knnTrain = 1-sum(modelSetResponse[,1]==modelKNNTrain)/length(modelSetResponse$response)
knnTest  = 1-sum(holdOutSetResponse$response==modelKNNTest)/length(holdOutSetResponse$response)


########## Support Vector Machines ##########
library(e1071)

# 5 fold cross validation of the modeling approach 
# use the data in the training set
k=5 #Folds
list <- 1:k
id <- sample(1:k,nrow(modelSetData),replace=TRUE) #Initialize this once
prediction <- data.frame()
testsetCopy <- data.frame()
modelError     <- NULL
modelList      <- NULL
modelTestError <- NULL
for (i in 1:k){
  trainingSet       <- subset(modelSetData, id %in% list[-i])
  trainingResponse  <- subset(modelSetResponse, id %in% list[-i])
  testSet           <- subset(modelSetData, id %in% c(i))
  testResponse      <- subset(modelSetResponse, id %in% c(i))
  model             <- svm(modelSetData,modelSetResponse$response,kernel="linear")
  modelList   <- c(modelList,list(model))
  error       <- 1-sum(trainingResult$result==predict(model,trainingSet))/length(trainingSet$response)
  modelError  <- c(modelError,list(error))
  errorTest   <- 1-sum(testSet$result==predict(model,testResult))/length(testResult$response) 
  modelTestError  <- c(modelTestError,list(errorTest))
}
mean(as.numeric(modelError))
mean(as.numeric(modelTestError))

svmmodel = svm(modelSetData,modelSetResponse$response,kernel="linear")
svmTrain = 1-sum(modelSetResponse==as.data.frame(predict(svmmodel,modelSetData[,3:10])>0.5))/length(modelSetResponse$response)
svmTest  = 1-sum(holdOutSetResponse==as.data.frame(predict(svmmodel,holdOutSetData[,3:10])>0.5))/length(holdOutSetResponse$response)

########## Random Forest ##########
library(randomForest)
library(foreach)
library(doSNOW)
library(parallel)
# 5 fold cross validation of the modeling approach 
# use the data in the training set
k=5 #Folds
list <- 1:k
prediction <- data.frame()
testsetCopy <- data.frame()
modelError     <- NULL
modelList      <- NULL
modelTestError <- NULL
for (i in 1:k){
  trainingSet       <- subset(modelSetData, id %in% list[-i])
  trainingResponse  <- subset(modelSetResponse, id %in% list[-i])
  testSet           <- subset(modelSetData, id %in% c(i))
  testResponse      <- subset(modelSetResponse, id %in% c(i))
  
  ncores <- 4
  cl <- makeCluster(ncores)
  registerDoSNOW(cl)
  model <- foreach(icore=1:ncores, ntree=rep(10, ncores), .packages='randomForest', .combine=combine) %dopar% {
    set.seed(icore)
    randomForest(trainingSet,trainingResponse$response,ntree=ntree)
  }
  stopCluster(cl)
  #modelList   <- c(modelList,list(model)) 
  error       <- 1-sum(trainingResponse==as.data.frame(predict(model,trainingSet)>0.5)+0)/length(trainingResponse$response)
  modelError  <- c(modelError,list(error))
  errorTest   <- 1-sum(testResponse==as.data.frame(predict(model,testSet)>0.5)+0)/length(testResponse$response) 
  modelTestError  <- c(modelTestError,list(errorTest))
}
mean(as.numeric(modelError))
mean(as.numeric(modelTestError))

set.seed(123)
ncores <- 4
cl <- makeCluster(ncores)
registerDoSNOW(cl)
randomForestModel <- foreach(i=1:ncores, ntree=rep(100, ncores), .packages='randomForest', .combine=combine) %dopar% {
  set.seed(i)
  #randomForest(testSet,testResponse$response,ntree=ntree)
  randomForest(modelSetData,modelSetResponse$response,ntree=ntree)
}
stopCluster(cl)
randomForestTrain <- 1-sum(modelSetResponse==as.data.frame(predict(randomForestModel,modelSetData)>0.5)+0)/length(modelSetResponse$response)
randomForestTest  <- 1-sum(holdOutSetResponse==as.data.frame(predict(randomForestModel,holdOutSetData)>0.5)+0)/length(holdOutSetResponse$response)

########## AdaBoost ##########
#I do not use the method from class. Instead, I chose to use the Ada package and caret
library(rpart)
library(ada)
library(caret)

# 5 fold cross validation of the modeling approach 
# use the data in the training set
k=5 #Folds
list <- 1:k
id <- sample(1:k,nrow(modelSetData),replace=TRUE) #Initialize this once
prediction <- data.frame()
testsetCopy <- data.frame()
modelError     <- NULL
modelList      <- NULL
modelTestError <- NULL
for (i in 1:k){
  trainingSet       <- subset(modelSetData, id %in% list[-i])
  trainingResponse  <- subset(modelSetResponse, id %in% list[-i])
  testSet           <- subset(modelSetData, id %in% c(i))
  testResponse      <- subset(modelSetResponse, id %in% c(i))
  model             <- ada(trainingResponse$response ~ ., data=trainingSet, control=rpart.control(maxdepth=30, cp=0.01, minsplit=20, nu=0.1), iter=i)
  #modelList   <- c(modelList,list(model))
  error       <- 1-sum(trainingResponse$result==as.data.frame.factor(predict(model,trainingSet)))/length(trainingResponse$response)
  modelError  <- c(modelError,list(error))
  errorTest   <- 1-sum(testResponse==as.data.frame.factor(predict(model,testSet)))/length(testResponse$response) 
  modelTestError  <- c(modelTestError,list(errorTest))
}
mean(as.numeric(modelError))
mean(as.numeric(modelTestError))

modelADA <- ada(modelSetResponse$response ~ ., data=modelSetData, control=rpart.control(maxdepth=30, cp=0.01, minsplit=20, nu=0.1), iter=100)
adaBoostTrain <- 1-sum(modelSetResponse==as.data.frame.factor(predict(modelADA, modelSetData)))/length(modelSetResponse$response) 
adaBoostTest  <- 1-sum(holdOutSetResponse==as.data.frame.factor(predict(modelADA,holdOutSetData)))/length(holdOutSetResponse$response) 

#Save Models
save(modelADA, file = "modelADA.rda")
save(decisionTreeModel, file = "decisionTreeModel.rda")
save(bayesModel, file = "bayesModel.rda")
save(randomForestModel, file = "randomForestModel.rda")
save(svmmodel, file = "svmmodel.rda")

#ROC Curve
bayesPred = as.data.frame(as.numeric(predict(bayesModel,holdOutSetData[]))-1)
dTreePred = as.data.frame((predict(decisionTreeModel,holdOutSetData)>0.5)+0)
knnPred   = as.data.frame.factor(modelKNNTest)
svmPred   = as.data.frame((predict(svmmodel,holdOutSetData[,3:10])>0.5)+0)
rForPred  = as.data.frame(predict(randomForestModel,holdOutSetData)>0.5)+0
adaBPred  = as.data.frame.factor(predict(modelADA,holdOutSetData))

colnames(bayesPred)   <- c("bayes")
colnames(dTreePred)   <- c("dTree")
colnames(knnPred)     <- c("kNNPr")
colnames(svmPred)     <- c("svmPr")
colnames(rForPred)    <- c("randF")
colnames(adaBPred)    <- c("boost")


library('ROCR')

library(ROCR)
pred <- prediction(abs(predicted), actual)
pred2 <- prediction(abs(ROCR.simple$predictions + 
                          rnorm(length(ROCR.simple$predictions), 0, 0.1)), 
                    ROCR.simple$labels)
perf <- performance( pred, "tpr", "fpr" )
perf2 <- performance(pred2, "tpr", "fpr")
plot( perf, colorize = TRUE)
plot(perf2, add = TRUE, colorize = TRUE)

plotROC <- function(actual, predicted,color,title){
  pred <- prediction(abs(predicted), actual)    
  perf <- performance(pred,"tpr","fpr")
  plot(perf,col=color)
  lines( par()$usr[1:2], par()$usr[3:4] )
  title(main=title)
}

par(mfrow=c(3,2))
plotROC(holdOutSetResponse,bayesPred,'green','Bayes')
plotROC(holdOutSetResponse,dTreePred,'red','Decision Tree')
plotROC(holdOutSetResponse,as.numeric(knnPred[,1]),'orange','knn')
plotROC(holdOutSetResponse,svmPred,'blue','SVM')
plotROC(holdOutSetResponse,rForPred,'pink','RandForest')
plotROC(holdOutSetResponse,as.numeric(adaBPred[,1]),'yellow','Boost')

allPredAct <- cbind(holdOutSetResponse,bayesPred,dTreePred,as.numeric(knnPred[,1]),svmPred,rForPred,as.numeric(adaBPred[,1]))
library('pROC')
auc(allPredAct$response,allPredAct$bayes)
auc(allPredAct$response,allPredAct$dTree)
auc(allPredAct$response,as.numeric(allPredAct$kNNPr))
auc(allPredAct$response,allPredAct$svmPr)
auc(allPredAct$response,allPredAct$randF)
auc(allPredAct$response,as.numeric(allPredAct$boost))

######## Max Vote Predictor - Ensemble #########
allPredAct <- cbind(holdOutSetResponse,bayesPred,dTreePred,knnPred,svmPred,rForPred,adaBPred)
ensemblePredictVote <- ((allPredAct$bayes+allPredAct$dTree+as.numeric(allPredAct$kNNPr)+allPredAct$svmPr+allPredAct$randF+as.numeric(allPredAct$boost))>=4)+0
1-(sum(holdOutSetResponse == ensemblePredictVote))/length(holdOutSetResponse$response)

auc(allPredAct$response,as.numeric(ensemblePredictVote))

#Unseen Test sample to be submitted

testPredict  = as.data.frame.factor(predict(modelADA,finalTestData))
write.table(testPredict, "C:/Users/Arun/Desktop/Stats 202/Project/Prediction.txt", sep="\t")

colnames(testPredict)<-c("Predict")

sum(as.numeric(testPredict$Predict))