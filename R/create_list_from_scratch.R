#'Create a sparse list representation of treatment-to-control distance
#'matrix with a caliper.
#'
#'This function takes in a n-by-p matrix of observed covariates,
#'a length-n vector of treatment indicator, a caliper, and construct
#'a possibly sparse list representation of the distance matrix.
#'
#'Currently, there are 4 methods implemented in this function: 'maha'
#'(Mahalanobis distance), robust maha' (robust Mahalanobis distance),
#''0/1' (distance = 0 if and only if covariates are the same),
#''Hamming' (Hamming distance).
#'
#'Users can also supply their own distance function by setting method = 'other' and
#'using the argument ``dist_func''. ``dist_func'' is a user-supplied distance
#'function in the following format:
#'dist_func(controls, treated), where treated is a length-p vector
#'of covaraites and controls is a n_c-by-p matrix of covariates.
#'The output of function dist_func is a length-n_c vector of distance
#'between each control and the treated.
#'
#'There are two options for users to make a network sparse. Option caliper
#'is a value applied to the vector p to avoid connecting treated to controls
#'whose covariate or propensity score defined by p is outside p +/- caliper.
#'Second, within a specified caliper, sometimes there are still too many controls
#'connected to each treated, and we can further trim down this number up to k
#'by restricting our attention to the k nearest (in p) to each treated.
#'
#'By default a hard caliper is applied, i.e., option penalty is set to Inf by default.
#'Users may make the caliper a soft one by setting penalty to a large yet finite number.
#'
#'
#'
#'@param Z A length-n vector of treatment indicator.
#'@param X A n-by-p matrix of covariates.
#'@param exact A vector of strings indicating which variables need to be exactly matched.
#'@param soft_exact If set to TRUE, the exact constraint is enforced up to a large penalty.
#'@param p A length-n vector on which a caliper applies, e.g. a vector of propensity score.
#'@param caliper_low Size of caliper low.
#'@param caliper_high Size of caliper high.
#'@param k Connect each treated to the nearest k controls. See details section.
#'@param alpha Tuning parameter.
#'@param penalty Penalty for violating the caliper. Set to Inf by default.
#'@param method Method used to compute treated-control distance
#'@param dist_func A user-specified function that compute treate-control distance. See
#'                 details section.
#'
#'
#'@return  This function returns a list of three objects: start_n, end_n, and d.
#'         See documentation of function ``create_list_from_mat'' for more details.
#'
#'@examples
#'\dontrun{
#'# We first prepare the input X, Z, propensity score
#'
#'attach(dt_Rouse)
#'X = cbind(female,black,bytest,dadeduc,momeduc,fincome)
#'Z = IV
#'propensity = glm(IV~female+black+bytest+dadeduc+momeduc+fincome,
#'                 family=binomial)$fitted.values
#'detach(dt_Rouse)
#'
#'# Create distance lists with built-in options.
#'
#'# Mahalanobis distance with propensity score caliper = 0.05
#'# and k = 100.
#'
#' dist_list_pscore_maha = create_list_from_scratch(Z, X, p = propensity,
#'                                caliper_low = 0.05, k = 100, method = 'maha')
#'
#'
#'# More examples, including how to use a user-supplied
#'# distance function, can be found in the vignette.
#'}
#'@importFrom mvnfast maha
#'@importFrom stats cov var
#'@export

create_list_from_scratch <- function(Z, X, exact = NULL, soft_exact = FALSE,
                                     p = NULL, caliper_low = NULL, caliper_high = NULL,
                                     k = NULL, alpha = 1,
                                     penalty = Inf, method = 'maha', dist_func = NULL){

  if (is.null(k)) k = length(Z) - sum(Z)

  # Cast X into matrix if it is a vector
  if (is.vector(X)) X = matrix(X, ncol=1)

  if (method == 'maha'){
    cov_matrix = chol(stats::cov(X))
    # Costomized function computing Maha distance
    compute_maha_dist <- function(X_control, X_treated_i){
      return(mvnfast::maha(X_control, t(as.matrix(X_treated_i)), cov_matrix, isChol=TRUE))
    }
    output = create_list_from_scratch_overall(Z, X, exact, soft_exact, p, caliper_low, caliper_high, k,
                                              penalty, dist_func = compute_maha_dist)
  }

  if (method == 'Hamming'){
    compute_hamming_dist <- function(X_control, X_treated_i){
      return(ncol(X_control) - rowSums(sweep(X_control, 2, as.matrix(X_treated_i)) == 0))
    }
    output = create_list_from_scratch_overall(Z, X, exact, soft_exact, p, caliper_low, caliper_high, k,
                                              penalty, dist_func = compute_hamming_dist)
  }

  if (method == 'L1') {
    compute_L1_dist <- function(X_control, X_treated_i){
      return(rowSums(abs(sweep(X_control, 2, as.matrix(X_treated_i)))))
    }
    output = create_list_from_scratch_overall(Z, X, exact, soft_exact, p, caliper_low, caliper_high, k,
                                              penalty, dist_func = compute_L1_dist)
  }

  if (method == 'L1_convex') {
    compute_L1_convex_dist <- function(X_control, X_treated_i){
      return(alpha*(-rowSums(sweep(X_control, 2, as.matrix(X_treated_i)))) - 0)
    }
    output = create_list_from_scratch_overall(Z, X, exact, soft_exact, p, caliper_low, caliper_high, k,
                                                penalty, dist_func = compute_L1_convex_dist)
  }


  if (method == 'vanilla_directional') {
    compute_vanilla_dir_dist <- function(X_control, X_treated_i){
      return(alpha*(-rowSums(sweep(X_control, 2, as.matrix(X_treated_i))) - 0))
    }
    output = create_list_from_scratch_overall(Z, X, exact, soft_exact, p, caliper_low, caliper_high, k,
                                              penalty, dist_func = compute_vanilla_dir_dist)
  }

  if (method == 'hockey_stick') {
    compute_hockey_stick_dist <- function(X_control, X_treated_i){
      d_1 = pmax(-rowSums(sweep(X_control, 2, as.matrix(X_treated_i))), 0)
      #d_2 = pmax(rowSums(sweep(X_control, 2, as.matrix(X_treated_i))), 0)
      return(alpha*(d_1 - 0.01))
    }
    output = create_list_from_scratch_overall(Z, X, exact, soft_exact, p, caliper_low, caliper_high, k,
                                              penalty, dist_func = compute_hockey_stick_dist)
  }

  if (method == '0/1/directional'){
    compute_0_1_dir_dist <- function(X_control, X_treated_i){
      d_1 = (((-rowSums(sweep(X_control, 2, as.matrix(X_treated_i)))) > 0) + 0)
      #d_2 = (((rowSums(sweep(X_control, 2, as.matrix(X_treated_i)))) >= 0) + 0)
      return(alpha*(d_1  - 0.01))
    }
    output = create_list_from_scratch_overall(Z, X, exact, soft_exact, p, caliper_low, caliper_high, k,
                                              penalty, dist_func = compute_0_1_dir_dist)
  }

  if (method == '0/1') {
    compute_01_dist <- function(X_control, X_treated_i){
      return(1 - (rowSums(sweep(X_control, 2, X_treated_i) == 0) == dim(X_control)[2]))
    }
    output = create_list_from_scratch_overall(Z, X, exact, soft_exact, p, caliper_low, caliper_high, k,
                                              penalty, dist_func = compute_01_dist)
  }

  if (method == 'robust maha') {
    if (is.vector(X)) X = matrix(X, ncol=1)

    X <- as.matrix(X)
    n<-dim(X)[1]
    rownames(X) <- 1:n
    for (j in 1:dim(X)[2]) X[,j]<-rank(X[,j])
    cv<-stats::cov(X)
    vuntied<-stats::var(1:n)
    rat<-sqrt(vuntied/diag(cv))
    cv<-diag(rat)%*%cv%*%diag(rat)
    cov_matrix = chol(cv) # Cholesky decomp of cov matrix

    compute_maha_dist <- function(X_control, X_treated_i){
      return(mvnfast::maha(X_control, t(as.matrix(X_treated_i)), cov_matrix, isChol=TRUE))
    }
    output = create_list_from_scratch_overall(Z, X, exact, soft_exact, p, caliper_low, caliper_high, k,
                                              penalty, dist_func = compute_maha_dist)
  }


  if (method == 'other')
    output = create_list_from_scratch_overall(Z, X, exact, soft_exact, p, caliper_low, caliper_high,
                                              k, penalty, dist_func = dist_func)


  if (is.character(output)) {
    cat("Hard caliper fails. Please specify a soft caliper.", '\n')
    return(NA)
  }
  else {
    start_n = output[[1]]
    end_n = output[[2]]
    d = output[[3]]

    return(list(start_n = unname(start_n),
                end_n = unname(end_n),
                d = unname(d)))
  }
}

