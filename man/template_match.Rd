% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/template_match.R
\name{template_match}
\alias{template_match}
\title{Optimal Matching with Two Criteria.}
\usage{
template_match(
  template,
  X,
  Z,
  dataset,
  multiple = 1,
  lambda = 1,
  caliper_gscore = 1,
  k_gscore = NULL,
  penalty_gscore = Inf,
  caliper_pscore = 1,
  k_pscore = NULL,
  penalty_pscore = Inf
)
}
\arguments{
\item{template}{A dataframe of template units.}

\item{X}{A n-by-p matrix of covariates with column names.}

\item{Z}{A length-n vector of treatment indicator.}

\item{dataset}{Dataset to be matched.}

\item{multiple}{Number of treated units matched to each template unit. Default is 1.}

\item{lambda}{A tuning parameter controlling the trade-off between internal and external validity. A large lambda favors internal validity of the matched sample. A small lambda favors resemblance to the template.}

\item{caliper_gscore}{Size of generalizability caliper.}

\item{k_gscore}{Connect each template unit to k_gscore treated units closest in the generalizability score.}

\item{penalty_gscore}{Penalty for violating the generalizability caliper. Set to Inf by default.}

\item{caliper_pscore}{Size of propensity score caliper.}

\item{k_pscore}{Connect each treated to k_pscore control units closest in the propensity score.}

\item{penalty_pscore}{Penalty for violating the propensity score caliper. Set to Inf by default.}
}
\value{
This function returns a list of three objects: 1) feasible: 0/1 depending on the
feasibility of the matching problem; 2) match_treated: a data frame of the matched treated
units; 3) match_control: a data frame of the matched control units.
}
\description{
This function takes as arguments a dataset to be matched and a template, and
outputs matched pairs that are closely matched, well balanced, and mimicking
the user-supplied template in covariates' distributions of the given template.
}
\details{
Please refer to the vignette for reproducible examples.
}
