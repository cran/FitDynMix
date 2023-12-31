#' Log-likelihood of a Lognormal-GPD dynamic mixture
#'
#' This function evaluates the log-likelihood of a Lognormal-GPD dynamic mixture, computing the integral in the normalizing constant via quadrature methods.
#' @param x (6 by 1) numerical vector: values of CA1, CA2, meanlog, sdlog, xi, beta.
#' @param y vector: points where the function is evaluated.
#' @param intTol non-negative scalar: threshold for stopping the computation of the integral in the normalization
#' constant: if the integral on the interval from n-1 to n is smaller than intTol, the approximation procedure stops.
#' @return log-likelihood of the lognormal-GPD mixture evaluated at y.
#' @keywords dynamic mixture.
#' @export
#' @examples
#' x <- c(1,2,0,.5,.25,3.5)
#' y <- rDynMix(100,x)
#' fit <- dynloglik(x,y,1e-06)

dynloglik <- function(x,y,intTol)
{
muc <- x[1]
tau <- x[2]
mu <- x[3]
sigma <- x[4]
xi <- x[5]
beta <- x[6]
f <- function(x) (evir::dgpd(x, xi, mu=0, beta)-dlnorm(x,mu,sigma)) * atan((x-muc)/tau)
p <- pcauchy(y,muc,tau)
temp <- (1-p) * dlnorm(y,mu,sigma) + p * evir::dgpd(y, xi, mu=0, beta)
I <- NULL
I1 <- 10
i <- 1
while (abs(I1) > intTol & i <= 2001)
{
  temp1 <- pracma::quadinf(f,i-1,i)
  I1 <- temp1$Q #integral(f,i-1,i)
  I <- c(I,I1)
  i <- i + 1
}
Z <- 1+(1/pi) * sum(I)
llik <- sum(log(temp/Z))
return(llik)
}
