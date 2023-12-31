#' Simulating a dynamic lognormal-Pareto mixture
#'
#' This function fits a dynamic mixture by Approximate Maximum Likelihood and by standard maximum likelihood.
#' Currently only implemented for the lognormal - generalized Pareto case.
#' @param nreps integer: number of observations sampled from the mixture.
#' @param x (6 by 1) numerical vector: values of mu_c, tau, mu, sigma, xi, beta.
#' @return ysim (nreps x 1) vector: nreps random numbers from the lognormal-GPD dynamic mixture.
#' @details This function simulates a dynamic lognormal-GPD mixture using
#' the algorithm of Frigessi et al. (2002, p. 221).
#' @keywords dynamic mixture; simulation.
#' @export
#' @examples
#' ysim <- rDynMix(100,c(1,2,0,0.5,0.25,3))
#' @references{
#'   \insertRef{fri02}{FitDynMix}
#' }
#'
#'
#' @importFrom Rdpack reprompt

rDynMix <- function(nreps,x)
{
CA1 = x[1]
CA2 = x[2]
meanlog = x[3]
sdlog = x[4]
xi = x[5]
beta = x[6]
ysim <- rep(0,nreps)
i <- 1
while (i<=nreps)
  {
  u=runif(1)
  if (u<0.5)
    {
    sample = rlnorm(n=1,meanlog,sdlog)
    prob=(1-pcauchy(sample,location=CA1,scale=CA2))
    if(runif(1)<prob)
      {
      # accept
      ysim[i]=sample
      i <- i + 1
     }
  }
  else
    {
    sample=evir::rgpd(n=1,xi=xi,mu=0,beta=beta)
    prob=pcauchy(sample,location=CA1,scale=CA2)
    if(runif(1)<prob)
    {
      ysim[i]=sample
      i <- i + 1
    }
  }
}
return(ysim)
}
