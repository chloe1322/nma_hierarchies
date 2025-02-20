% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/get_posets.R
\name{get_posets}
\alias{get_posets}
\title{Retrieves credible hierarchies for poset question types}
\usage{
get_posets(effects.matrix, MID, threshold, largerBetter)
}
\arguments{
\item{effects.matrix}{A matrix where the column headers are treatment names and each row displays each treatment’s sampled relative effect for that iteration}

\item{MID}{A number indicating the absolute minimally important difference}

\item{threshold}{A number that determines which hierarchies are credible}

\item{largerBetter}{Boolean value where True indicates larger values are better, and False otherwise}
}
\value{
A data frame containing the credible hierarchies for Posets
}
\description{
Finds all Posets reflecting treatment differences greater than or equal to the MID and with frequencies greater than or equal to the threshold
}
\examples{
get_posets(effects.matrix,10,0.2,TRUE)
}
