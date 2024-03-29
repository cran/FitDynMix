#' Density of a Lognormal-GPD dynamic mixture
#'
#' This function evaluates the density of a Lognormal-GPD dynamic mixture,
#' with Cauchy or exponential weight.
#' @param x non-negative vector: points where the density is evaluated.
#' @param pars numerical vector: if weight is equal to 'cau', values of \eqn{\mu_c}, \eqn{\tau},
#' \eqn{\mu}, \eqn{\sigma}, \eqn{\xi}, \eqn{\beta}; if weight is equal to 'exp', values of \eqn{\lambda},
#' \eqn{\mu}, \eqn{\sigma}, \eqn{\xi}, \eqn{\beta}.
#' @param intTol non-negative scalar: threshold for stopping the computation of the integral in the normalization
#' constant: if the integral on the interval from n-1 to n is smaller than intTol, the approximation procedure stops.
#' @param weight 'cau' or 'exp': name of weight distribution.
#' @return density of the lognormal-GPD mixture evaluated at x.
#' @keywords dynamic mixture.
#' @export
#' @examples
#' x <- seq(0,20,length.out=1000)
#' pars <- c(1,2,0,.5,.25,3.5)
#' dLNPar <- ddyn(x,pars,1e-04,'cau')

ddyn <- function(x,pars,intTol,weight)
{
  if (weight == 'cau')
  {
    muc <- pars[1]
    tau <- pars[2]
    mu <- pars[3]
    sigma <- pars[4]
    xi <- pars[5]
    beta <- pars[6]
    f <- function(x) (evir::dgpd(x, xi, mu=0, beta)-dlnorm(x,mu,sigma)) * atan((x-muc)/tau)
    p <- pcauchy(x,muc,tau)
    temp <- (1-p) * dlnorm(x,mu,sigma) + p * evir::dgpd(x, xi, mu=0, beta)
    I <- NULL
    I1 <- 10
    i <- 1
    while (abs(I1) > intTol)
    {
      temp1 <- pracma::quadinf(f,i-1,i)
      I1 <- temp1$Q
      I <- c(I,I1)
      i <- i + 1
      if (i > 2000)
      {
        print(c(muc,tau,mu,sigma,xi,beta))
        print(c(i,I1))
      }
    }
    Z <- 1+(1/pi) * sum(I)
    f <- temp/Z
  }

  if (weight == 'exp')
  {
    lambda <- pars[1]
    mu <- pars[2]
    sigma <- pars[3]
    xi <- pars[4]
    beta <- pars[5]
    f <- function(x) (dlnorm(x,mu,sigma) - evir::dgpd(x, xi, mu=0, beta)) *
      exp(-lambda*x)
    p <- pexp(x,lambda)
    temp <- (1-p) * dlnorm(x,mu,sigma) + p * evir::dgpd(x, xi, mu=0, beta)
    I <- NULL
    I1 <- 10
    i <- 1
    while (abs(I1) > intTol)
    {
      temp1 <- pracma::quadinf(f,i-1,i)
      I1 <- temp1$Q
      I <- c(I,I1)
      i <- i + 1
      if (i > 2000)
      {
        print(c(lambda,mu,sigma,xi,beta))
        print(c(i,I1))
      }
    }
    Z <- 1+(1/pi) * sum(I)
    f <- temp/Z
  }
return(f)
}
