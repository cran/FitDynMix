% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/rDynMix.R
\name{rDynMix}
\alias{rDynMix}
\title{Simulating a dynamic lognormal-Pareto mixture}
\usage{
rDynMix(nreps, x, weight)
}
\arguments{
\item{nreps}{integer: number of observations sampled from the mixture.}

\item{x}{numerical vector: if weight = 'cau', values of \ifelse{html}{\out{&mu;<sub>c</sub>}}{\eqn{mu_c}}, \eqn{\tau}, \eqn{\mu},
\eqn{\sigma}, \eqn{\xi}, \eqn{\beta}; if weight = 'exp', values of \eqn{\lambda}, \eqn{\mu}, \eqn{\sigma}, \eqn{\xi}, \eqn{\beta}.}

\item{weight}{'cau' or 'exp': name of weight distribution.}
}
\value{
ysim (nreps x 1) vector: nreps random numbers from the lognormal-GPD dynamic mixture.
}
\description{
This function simulates a dynamic mixture.
Currently only implemented for the lognormal - generalized Pareto case,
with Cauchy or exponential weight.
}
\details{
This function simulates a dynamic lognormal-GPD mixture using
the algorithm of Frigessi et al. (2002, p. 221).
}
\examples{
ysim <- rDynMix(100,c(1,2,0,0.5,0.25,3),'cau')
}
\references{
{
\insertRef{fri02}{FitDynMix}
}
}
