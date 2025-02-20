#' Gets frequency of columns
#' @param data data frame
#' @param col.range range of columns
#' @keywords internal
freq <- function(data, col.range){
  out <- as.data.frame(table(apply(data[,col.range], 1, paste0, collapse = ","))/nrow(data))
  new.col <- rep(paste0(min(col.range), "-", max(col.range)), nrow(out))
  out <- cbind(new.col, out)
  colnames(out) <- c("Range", "Var1", "Freq")
  return(out)
}

#' Gets credible permutations
#' @param all_ranked_perm data frame of all ranked permutations
#' @keywords internal
get_perm <- function (all_ranked_perm) {
  # takes in all the anchored permutations, groups it by permutation, and
  # calculates the sum of the frequency
  perm <- aggregate(Freq ~ Var1, data = all_ranked_perm, sum)
  return (perm)
}

#' Gets credible ranked combinations
#' @param all_ranked_perm data frame of all ranked permutations
#' @param trts vector of all the treatments
#' @keywords internal
indexed_combo <- function (all_ranked_perm,trts) {
  trts<-sort(trts)
  all_ranked_perm$Combinations <- vapply(strsplit(as.character(all_ranked_perm$Var1),','), function(x) paste(x[match(trts,x,nomatch=0)], collapse = ','), '')

  ## groups Combinations and Position and calculates sum of the frequency
  all_ranked_combo <- aggregate(Freq ~ Combinations + Range, data = all_ranked_perm, sum)
  all_ranked_combo <- all_ranked_combo[, c("Range", "Combinations", "Freq")]
  return(all_ranked_combo)
}

#' Gets credible combinations
#' @param all_ranked_combo data frame of all ranked combinations
#' @keywords internal
get_combo <- function (all_ranked_combo) {
  # takes in all ranked combinations, groups it by Combination, and sums the frequencies
  all_combo <- aggregate(Freq ~ Combinations, data = all_ranked_combo, sum)
  return(all_combo)
}

#' Compare posets with permutations
#' @param df data frame of credible hierarchies
#' @param target poset we are looking for
#' @keywords internal
compare_nonconsec<-function(df,target) {
  for(j in 1:nrow(df)) { # checks through perms
    new_string <-str_split_1(as.character(df[j,1]),",")
    positions <- match(target,new_string) # finds position number of treatments in each tbl row
    if (!anyNA(positions) && all(diff(positions) >= 0)) { # checks if its increasing
      return (TRUE)
    }
  }
  return (FALSE)
}

#' Finds supersets for posets
#' @param non_consec data frame of credible hierarchies
#' @param target poset we are looking for
#' @keywords internal
terminal_nonconsec <- function(non_consec,target) {
  for (i in seq(1:length(non_consec))) {
    current_df <- non_consec[[i]]
    for(j in seq(1:nrow(current_df))) {
      new_string <-str_split_1(as.character(current_df[j,1])," > ")
      positions <- match(target,new_string) # finds position number of treatments in new_string
      if (!anyNA(positions) && all(diff(positions) >= 0)) { # checks if its increasing
        return (TRUE)
      }
    }
  }
  return (FALSE)
}

#' Finds supersets for ranked permutations
#' @param ranked_perm data frame of credible hierarchies
#' @param current_range range of the target
#' @param target permutation we are looking for
#' @param i current index
#' @param n.filtered number of rows
#' @keywords internal
calc_terminal_ranked <- function(ranked_perm,current_range,target,i,n.filtered) {
  l <- current_range[1]
  u <- current_range[2]
  for(j in 1:n.filtered) {
    if (i != j) {
      new_range <- str_split_1(ranked_perm[j,1],"-")
      if (l >= new_range[1] && u <= new_range[2]) {
        upper <- as.numeric(u)-as.numeric(new_range[1])+1
        lower <- as.numeric(l)-as.numeric(new_range[1])+1
        new_string <- str_split_1(as.character(ranked_perm[j,2]),",")[lower:upper]
        if(identical(target,new_string)) {
          return(TRUE)
        }
      }
    }
  }
  return(FALSE)
}

#' Finds supersets for permutations
#' @param perm data frame of credible hierarchies
#' @param target permutation we are looking for
#' @param i current index
#' @param n.filtered number of rows
#' @keywords internal
calc_terminal_unranked <- function(perm,target,i,n.filtered) {
  for(j in 1:n.filtered) {
    if (i != j) {
      new_string <-as.character(perm[j,1])
      if (str_detect(new_string,target)) {
        return(TRUE)
      }
    }
  }
  return(FALSE)
}

#' Creates permutations for poset function
#' @param trts list of treatment names
#' @param trt1 first treatment in the new pair
#' @param new_trts potential new treatments to add
#' @param perm_size size of the permutation
#' @param credible list of credible size two permutations
#' @keywords internal
create_perm <- function (trts,trt1,new_trts,perm_size,credible) {
  actual_new_trts <- c()
  for (trt2 in new_trts) { # iterates through each potential new treatment to add
    pair <- paste0(trt1,",",trt2) # the potential pair to add
    if (any(pair %in% credible)) { # if the pair exists in the credible list, we can add it to the permutation
      actual_new_trts<-c(actual_new_trts,trt2)
    } # if the pair isn't credible, we do not need to add it to the permutation
  }
  size<-length(actual_new_trts)
  if(size == 0) { # no new treatments to add
    return (FALSE)
  }
  list_trts <- lapply(trts,function(x) { # create vectors where each treatment from trts is repeated size times
    rep(x,size)
  })
  list_trts[[length(list_trts)+1]] <- actual_new_trts
  trt_df <- do.call(cbind, list_trts) # binds the new treatments to the permutations
  return(trt_df)
}

#' Finds HPD intervals
#' @param ranks column of ranks and their frequency
#' @param threshold cutoff for what is considered credible
#' @param freq_sum value is always 1
#' @keywords internal
hpd <- function(ranks,threshold,freq_sum) {
  if (threshold == 0){
    hpd_ranks<-c()
    ranks$Freq<-0
  } else {
    ranks <- ranks[order(ranks$Freq), ] # sorts in increasing order
    while (freq_sum > threshold && nrow(ranks) > 0) {
      freq_sum <- freq_sum - ranks[1,2] # calculates freq_sum without smallest probability

      if (freq_sum >= threshold) { # if >= threshold, we can drop the first row
        ranks <- ranks[-1,]
      }
    }
    ranks <-ranks[order(ranks$Rank),] # re-orders it in terms of rank
    hpd_ranks <- ranks$Rank
  }

  # formatting
  if (length(hpd_ranks) == 1) { # if there is just one element
    concat_ranks <- hpd_ranks
  } else if (length(hpd_ranks) == 0) {
    concat_ranks <- "N/A"
  } else if (all(diff(as.numeric(as.character(hpd_ranks))) == 1)) { # hpd is an interval
    concat_ranks <- paste(hpd_ranks[1], hpd_ranks[[length(hpd_ranks)]], sep = "-")  # formats the ranks into an interval
  } else { # hpd is not an interval
    concat_ranks <- paste(hpd_ranks,collapse=',') # collapses the ranks into one string
  }
  hpd_vec <- list(concat_ranks,sum(ranks$Freq),hpd_ranks)
  return(hpd_vec)
}
