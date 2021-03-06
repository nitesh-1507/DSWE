#' @title Power curve comparison
#'
#' @param data a list of data sets to be compared
#' @param xCol a numeric or vector stating column number of covariates
#' @param xCol.circ a numeric or vector stating column number of circular covariates
#' @param yCol A numeric value stating the column number of target
#' @param testCol a numeric/vector stating column number of covariates to used in generating test set
#' @param testSet a matrix or dataframe consisting of test points, default value NULL, if NULL computes test points internally using testCol variables
#' @param thrs A single value or vector represnting threshold for each covariates
#' @param conflevel a single value representing the statistical significance level for constructing the band
#' @param gridSize A numeric / vector to be used in constructing test set, should be provided when testSet is NuLL, else it is ignored
#'
#' @return a list containing :
#'  \itemize{
#'   \item muDiff - The testSet prediction for each of the data set
#'   \item mu1 - The test prediction for first data set
#'   \item mu2 - The test prediction for second data set
#'   \item band - The allowed statistical difference between functions
#'   \item confLevel - a single value representing the statistical significance level for constructing the band
#'   \item testSet - The test set provided by user, or generated internally
#'   \item estimatedParams - The function parameter values
#'   \item statDiff - The \% statistical difference between functions in comparison
#'   \item scaledStatDiff - The \% statistical difference scaled on entire domain of the covariates
#'   \item Diff - The \% difference between functions in comparison
#'   \item scaledDiff - The \% difference scaled on entire domain of the covariates
#'   \item reductionRatio - a list consisting of shrinkage ratio of features used in testSet
#' }
#'
#' @import dplyr
#' @importFrom magrittr %>%
#' @export

ComparePCurve = function(data, xCol, xCol.circ = NULL, yCol, testCol, testSet = NULL, thrs = 0.2, conflevel = 0.95, gridSize = c(50, 50) ){

  if(!is.list(data)){

    stop('The data must be provided as a list containing data sets')

  }

  if(length(data) != 2){


    stop('The data length should be equal to two')

  }

  if(!is.vector(xCol)){

      stop('The xcol.circ must be provided as a numeric/vector')

  }else if(!all(xCol %in% 1:ncol(data[[1]]))){

    stop('The xCol values should be the column number of data set')
  }


  if(!is.null(xCol.circ)){

    if(!is.vector(xCol.circ)){

      stop('The xCol must be provided as a numeric/vector')

    }else if(!all(xCol.circ %in% xCol)){

      stop('xCol.circ should be present in xCol')
    }
  }

  if(length(thrs) > 1){

    if(!(length(thrs) == length(xCol))){

      stop('The thrs must be provided as a single value or vector with weight for each covariate')

    }
  }

  if(!is.vector(testCol)){

    stop('The testCol must be provided as a numeric/vector')

  }else if(length(testCol) != 2){

    stop('The length of testcol vector should be of size two')
  }

  if(!is.vector(conflevel)){

    stop('conflevel must be provided as a numeric/vector')

  }else{

    if(length(conflevel) != 1){

      stop('conflevel must be provided as a single numeric value')

    }else if(!(conflevel > 0 & conflevel < 1)){

      stop('conflevel must be between 0 to 1')
    }
  }

  resultMatching = CovMatch(data, xCol, xCol.circ, thrs)

  if(is.null(testSet)){

        if(!is.vector(gridSize)){

         stop('The gridsize must be provided as a vector')

        }else if(length(gridSize) != 2){

         stop('The length of gridSize vector should be of size two')

        }else if((gridSize[1] * gridSize[2] > 2500)){

         stop('The product of gridSize should not be more than 2500')

    }

    testSet = GenerateTestset(resultMatching$matchedData, testCol, gridSize )

  }else if(!is.matrix(testSet) & !is.data.frame(testSet)){

    stop('The test set provided should be a matrix or a dataframe')

  }else if (ncol(testCol) != ncol(testSet)){

    stop('The length of testCol should be equal to the number of columns in testSet')
  }

  resultGP = funGP(resultMatching$matchedData, testCol, yCol, conflevel, testSet)

  resultWSMetric = ComputeWSMetric(data, resultGP$mu1, resultGP$mu2, resultGP$band, testSet, testCol)

  resultWSExtrapolation = ComputeWSExtrapolation(data, yCol, resultGP$mu1, resultGP$mu2, resultGP$band)

  resultWMetric = ComputeWMetric(data, resultGP$mu1, resultGP$mu2, testSet, testCol)

  resultWExtrapolation = ComputeWExtrapolation(data, yCol, resultGP$mu1, resultGP$mu2)

  reductionRatio = ComputeRatio(data, resultMatching$matchedData, testCol)

  returnList = list(Diff = resultWMetric, scaledDiff = resultWExtrapolation, statDiff = resultWSMetric, scaledStatDiff = resultWSExtrapolation, reductionRatio = reductionRatio, muDiff = resultGP$muDiff, mu2 = resultGP$mu2, mu1 = resultGP$mu1, band = resultGP$band, confLevel = conflevel, testSet = testSet, estimatedParams = resultGP$estimatedParams)

  return(returnList)
}
