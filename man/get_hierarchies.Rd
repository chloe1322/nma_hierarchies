% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/get_hierarchies.R
\name{get_hierarchies}
\alias{get_hierarchies}
\title{Retrieves credible hierarchies}
\usage{
get_hierarchies(inputs, largerBetter, thresholds, MID, printPlot = FALSE)
}
\arguments{
\item{inputs}{The output produced by running prep_data(), which consists of a list of the hierarchy.matrix, effects.matrix, and ranking.df}

\item{largerBetter}{Boolean value where True indicates larger values are better, and False otherwise}

\item{thresholds}{A numeric vector containing three values that define the thresholds for identifying credible hierarchies across consecutive, poset, and individual treatment question types}

\item{MID}{A number indicating the absolute minimally important difference}

\item{printPlot}{Boolean value where True indicates that the rankograms will be printed (default = False)}
}
\value{
A list of data frames containing the credible hierarchies for Ranked Permutations, Permutations, Ranked Combinations, Combinations, Posets, Individual Treatments, and HPD Intervals
}
\description{
Runs the inputs through consecutive(), get_posets(), and singular_treatment(), and returns a list of hierarchies with frequencies greater than or equal to the thresholds specified. These hierarchies are then run through get_superset() to determine which of them are supersets
}
\examples{
get_hierarchies(inputs,"Waitlist",TRUE,c(0.5,0.6,0.7),10)
}
