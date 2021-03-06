# Computes best k using generalized cross validation
computeBestK = function(dataX, dataY, rangeK ){
  bestK = NULL
  dataX = as.matrix(dataX)
  maxK = max(rangeK)
  nnIdx = knnx.index(dataX, query = dataX, k = maxK)
  gcv = rep(0,length(rangeK))
  for (i in 1:length(rangeK)){
    predY = rowMeans(matrix(dataY[nnIdx[, 1:rangeK[i]]], ncol = ncol(nnIdx[, 1:rangeK[i]])))
    gcv[i] = sqrt(mean(((dataY - predY) / (1 - (1 / rangeK[i])))^2))
  }
  bestK = rangeK[which.min(gcv)]
  bestRMSE = min(gcv)
  returnList = list(bestK = bestK, bestRMSE = bestRMSE)
  if (bestK == maxK){
    rangeK = maxK + seq(5,50,5)
    returnList = computeBestK(dataX, dataY, rangeK)
  }
  return(returnList)

}


# Computes best Subset from given features
computeBestSubset = function(data, xCol, yCol,rangeK){

  bestSubset = NULL
  bestRMSE = Inf
  bestK = NULL

  .computeBestSubset = function(data, xCol, yCol, rangeK, bestSubset, bestRMSE, bestK){
    nCov = length(xCol)
    bestCol = NULL
    for (i in 1:nCov){
      result = computeBestK(data[, c(bestSubset, xCol[i])], data[, yCol], rangeK)
      RMSE = result$bestRMSE
      if (RMSE < bestRMSE){
        bestRMSE = RMSE
        bestK = result$bestK
        bestCol = xCol[i]
      }
    }

    returnList = list(bestSubset = bestSubset, bestK = bestK, bestRMSE = bestRMSE)

    if (length(bestCol)>0){
      bestSubset = c(bestSubset, bestCol)
      xColDiff = setdiff(xCol, bestSubset)
      if (length(xColDiff)>0){
        returnList = .computeBestSubset(data, xColDiff, yCol, rangeK, bestSubset, bestRMSE, bestK)
      }else {
        returnList = list(bestSubset = bestSubset, bestK = bestK, bestRMSE = bestRMSE)
      }
    }

    return(returnList)
  }

  returnList = .computeBestSubset(data, xCol, yCol, rangeK, bestSubset, bestRMSE)
  return(returnList)

}
