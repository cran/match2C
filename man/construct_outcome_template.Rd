% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/construct_outcome_template.R
\name{construct_outcome_template}
\alias{construct_outcome_template}
\title{Construct an output for template matching.}
\usage{
construct_outcome_template(res, num_edges_left, Z, dataset)
}
\arguments{
\item{res}{A callrelax output.}

\item{num_edges_left}{Number of edges in the template-to-treatment network.}

\item{Z}{A vector of treatment status.}

\item{dataset}{The original dataset.}
}
\value{
This function returns a list of three objects: 1) feasible: 0/1 depending on the
feasibility of the matching problem; 2) match_treated: a data frame of the matched treated
units; 3) match_control: a data frame of the matched control units.
}
\description{
This function constructs the output for template matching given
the relaxsolution to the network flow problem,
number of edges in the template-to-treated network,
a vector of treatment status, and the original dataset. This function
is of little interest to users.
}
