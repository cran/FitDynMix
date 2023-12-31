#' Estimating a dynamic mixture via AMLE
#'
#' This function fits a dynamic mixture via Approximate Maximum Likelihood.
#' Currently only implemented for the lognormal - generalized Pareto case.
#' The bootstrap estimation of the standard errors of the MLEs (used for finding
#' the supports of the uniform priors) is carried outed via parallel computing.
#' @param yObs numerical vector: observed sample.
#' @param epsilon non-negative scalar: scale parameter of the Markov kernel.
#' @param k non-negative integer: number of samples generated in the AMLE
#' approach, such that k*epsilon = ABC sample size.
#' @param bootreps positive integer: number of bootstrap replications.
#' @param intTol non-negative scalar: threshold for stopping the computation of the integral in the normalization
#' constant: if the integral on the interval from n-1 to n is smaller than intTol, the approximation procedure stops.
#' @return A list with the following elements:
#'
#' AMLEpars a list of four 6-dimensional vectors: approximate maximum likelihood estimates computed via sample mean,
#' maxima of the marginal kernel densities, maximum of the multivariate kernel densities,
#' maximum of the product of the marginal kernel densities.
#'
#' ABCsam ((k x epsilon) x 6) matrix: ABC sample.
#' 
#' MLEpars (7 x 1) vector: maximum likelihood estimates and
#' maximized log-likelihood.
#'
#' MLEboot (bootreps x 6) matrix: maximum likelihood estimates obtained in
#' each bootstrap replication.
#' @details 
#' For the lognormal and GPD parameters, the support of the uniform
#' prior is set equal to the 99% confidence interval of the bootstrap
#' distribution after discarding the outliers.
#' For the Cauchy parameters, the support is given by the range of the
#' bootstrap distribution after discarding the outliers.
#' Be aware that computing times are large when k and/or bootreps are large.
#' @keywords dynamic mixture; approximate maximum likelihood.
#' @seealso{\code{\link{AMLEmode}}.}
#' @export
#' @import stats graphics
#' @examples
#' \donttest{k <- 5000
#' epsilon <- .02
#' bootreps <- 2
#' res = AMLEfit(Metro2019, epsilon, k, bootreps)}
#' @references{
#'   \insertRef{bee22b}{FitDynMix}
#' }
#'
#'
#' @importFrom Rdpack reprompt

AMLEfit <- function(yObs,epsilon,k,bootreps,intTol=1e-4)
{
  n = length(yObs)
  mediana = median(yObs)
  y1 = yObs[yObs<mediana]
  y2 = yObs[yObs>=mediana]
  mu0 = MASS::fitdistr(y1,'lognormal')$estimate[1]
  sigma0 = MASS::fitdistr(y1,'lognormal')$estimate[2]
  xi0 = evir::gpd(y2,mediana)$par.ests['xi']
  beta0 = evir::gpd(y2,mediana)$par.ests['beta']
  muc0 = quantile(yObs,.5)
  tau0 = log(sd(yObs)/2)
  x0Lik = as.numeric(c(muc0,tau0,mu0,sigma0,xi0,beta0))
  res <- optim(x0Lik,dynloglik, gr=NULL,yObs,intTol,method='L-BFGS-B',lower=c(-Inf,.01,-Inf,.05,10^-10,.1),upper=c(Inf,Inf,Inf,10,Inf,10),control=list(fnscale=-1))
  estMLE <- c(res$par,res$value) # muc, tau, mu, sigma, xi, beta
  nreps.list <- sapply(1:bootreps, list)
  
  chk <- Sys.getenv("_R_CHECK_LIMIT_CORES_", "")
  if (nzchar(chk) && chk == "TRUE") {
    n.cores <- 2L
  } else {
    n.cores <- parallel::detectCores()
  }
  clust <- parallel::makeCluster(n.cores)
  MLEboot = matrix(0,bootreps,6)
  temp <- parallel::parLapply(clust,nreps.list, MLEBoot,yObs,intTol)
  parallel::stopCluster(cl=clust)
  for (i in 1:bootreps)
  {
    MLEboot[i,] = as.vector(unlist(temp[[i]]))
  }
  varcov = cov(MLEboot)
  stddev = sqrt(diag(varcov))
  CI99a = apply(MLEboot[,1:2],2,range)
  CI99b = apply(MLEboot[,3:6],2,quantile,c(.005,.995))
  CI99 = cbind(CI99a,CI99b)
  boxCA1 = boxplot(MLEboot[,1],plot = FALSE)
  boxCA2 = boxplot(MLEboot[,2],plot = FALSE)
  CA1 = MLEboot[,1]
  CA2 = MLEboot[,2]
  outl1 = boxCA1$out
  outl2 = boxCA2$out
  nout1 = length(outl1)
  nout2 = length(outl2)
  if (nout1 > 0)
  {
    indiciCA1 = rep(0,nout1)
    for (i in 1:nout1)
    {
      indiciCA1[i] = which(CA1==outl1[i])
    }
    CA1noout = CA1[-indiciCA1]
  }
  if (nout1 == 0)
    CA1noout = CA1
  if (nout2 > 0)
  {
    indiciCA2 = rep(0,nout2)
    for (i in 1:nout2)
    {
      indiciCA2[i] = which(CA2==outl2[i])
    }
    CA2noout = CA2[-indiciCA2]
  }
  if (nout2 == 0)
    CA2noout = CA2
  CI99[,1] = c(min(CA1noout),max(CA1noout))
  CI99[,2] = c(min(CA2noout),max(CA2noout)) # muc, tau, mu, sigma, xi, beta
  CI99[1,2] = pmin(0,abs(CI99[1,2]))
  CI99[1,5] = abs(CI99[1,5])
  
  # ABC algorithm
  
  distCVM <- rep(0,k)
  xiV <- runif(k,CI99[1,5],CI99[2,5])
  betaV <- runif(k,CI99[1,6],CI99[2,6])
  muV <- runif(k,CI99[1,3],CI99[2,3])
  sigmaV <- runif(k,CI99[1,4],CI99[2,4])
  CA1V <- runif(k,CI99[1,1],CI99[2,1])
  CA2V <- runif(k,CI99[1,2],CI99[2,2])

  for (j in 1:k)
  {
    dataSim <- rDynMix(n,c(CA1V[j],CA2V[j],muV[j],sigmaV[j],xiV[j],betaV[j]))
    distCVM[j] = cvm_stat_M(yObs,dataSim,power = 2)
  }
  
  # Select only epsilon values
  
  distCVM_jit <- jitter(distCVM)
  thresh <- quantile(distCVM_jit,epsilon)[1]
  indici <- which(distCVM_jit<thresh)
  Matr <- cbind(xiV,betaV,muV,sigmaV,CA1V,CA2V)
  ABCsam = Matr[indici,]
  estAMLE = AMLEmode(ABCsam)
  out <- list(AMLEpars=estAMLE,ABCsam=ABCsam,MLEpars=estMLE,MLEboot=MLEboot)
  return(out)
}
