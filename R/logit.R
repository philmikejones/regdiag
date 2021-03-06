#' check_logit
#'
#' Check logistic regression statistics and assumptions
#'
#' @param model a logit model object to test
#'
#' @return A list containing two data frames ('ind' and 'over'):
#' \itemize{
#'   \item \code{ind}
#'     \itemize{
#'       \item \code{predictor} Predictor variable
#'       \item \code{beta} Beta coefficient
#'       \item \code{lower_ci} Lower odds ratio confidence interval (95\%)
#'       \item \code{odds_ratio} Odds ratio
#'       \item \code{upper_ratio} Upper odds ratio confidence interval (95\%)
#'     }
#'   \item \code{over}
#'     \itemize{
#'       \item \code{diff_deviance} the difference between the null deviance
#'       and model deviance
#'       \item \code{diff_df} the difference in degrees of freedom
#'       \item \code{chisq_prob} the chi-squared probability of the deviance statistic
#'       \item \code{cox_snell} Cox and Snell pseudo R-squared
#'       \item \code{nagelkerke} Nagelkerke pseudo R-squared
#'       \item \code{hosmer} Hosmer-Lemeshow pseudo R-squared
#'     }
#' }
#' @export
check_logit <- function(model) {

  # Individual predictor value results
  predictor  <- attr(model[["coefficients"]], "names")
  beta       <- model[["coefficients"]]
  p_value    <- summary(model)[["coefficients"]][, 4]
  sig        <- " "
  odds_ratio <- exp(beta)
  conf_int   <- exp(stats::confint(model))  # MASS must be loaded for glm method
  lower_ci   <- conf_int[, 1]
  upper_ci   <- conf_int[, 2]


  ind_res <- data.frame(

    predictor,
    beta,
    p_value,
    sig,
    lower_ci,
    odds_ratio,
    upper_ci,

    stringsAsFactors = FALSE

  )

  ind_res["(Intercept)", "lower_ci"]   <- NA_real_
  ind_res["(Intercept)", "odds_ratio"] <- NA_real_
  ind_res["(Intercept)", "upper_ci"]   <- NA_real_

  ind_res$sig[ind_res$"p_value" < 0.05] <- "*"
  ind_res$sig[ind_res$"p_value" < 0.01] <- "**"


  # Model overall results
  # Difference between null model and model should be positive
  # I.e. if model deviance < null model deviance, model is an improvement
  diff_deviance <- model[["null.deviance"]] - model[["deviance"]]

  # Difference in degrees of freedom used to calculate chisq p value
  diff_df       <- model[["df.null"]] - model[["df.residual"]]

  # Determine statistical significance (because diff_deviance is chisq dist)
  chisq_prob    <- 1 - stats::pchisq(q  = diff_deviance, df = diff_df)

  # Pseudo R squares
  cox_snell <- 1 - exp((model[["deviance"]] - model[["null.deviance"]]) /
                         length(model[["fitted.values"]]))
  nagelkerke <- cox_snell /
    (1 - (exp(-(model[["null.deviance"]] / length(model[["fitted.values"]])))))
  hosmer <- diff_deviance / model[["null.deviance"]]

  # List of outputs
    over_res <- data.frame(

    "diff_deviance" = diff_deviance,
    "diff_df"       = diff_df,
    "chisq_prob"    = chisq_prob,
    "cox_snell"     = cox_snell,
    "nagelkerke"    = nagelkerke,
    "hosmer"        = hosmer,

    stringsAsFactors = FALSE

  )

  list(
    "ind"  = ind_res,
    "over" = over_res
  )

}


#' test_residuals
#'
#' Calculate what percentage of studentised or standardised residuals
#' are outliers, either +- 1.96 standard deviations or +- 2.58 standard
#' deviations
#'
#' @param df the data frame used in the logistic regression model containing
#'  the residuals
#' @param residuals a character name of the column containing the residuals
#' @param which which level to test, either 5\% (1.96 standard deviations) or
#' 1% (2.58 standard deviations)
#'
#' @return the proportion of outlying cases. Ideally this should be less than 5%
#' for 1.96 standard deviations, or less than 1% for 2.58 standard devations.
#' @export
#'
#' @examples
test_residuals <- function(df, residuals, which = "sd5") {

  # 5% lie outside +- 1.96 sd from mean
  sd5plus  <- mean(df[[residuals]]) + (1.96 * sd(df[[residuals]]))
  sd5minus <- mean(df[[residuals]]) - (1.96 * sd(df[[residuals]]))

  # 1% lie outside +- 2.58 sd from mean
  sd1plus  <- mean(df[[residuals]]) + (2.58 * sd(df[[residuals]]))
  sd1minus <- mean(df[[residuals]]) - (2.58 * sd(df[[residuals]]))

  if (which == "sd5") {
    (length(df[[residuals]][df[[residuals]] > sd5plus])  / nrow(df)) +
      (length(df[[residuals]][df[[residuals]] < sd5minus]) / nrow(df))
  } else {
    if (which == "sd1") {
      (length(df[[residuals]][df[[residuals]] > sd1plus])  / nrow(df)) +
        (length(df[[residuals]][df[[residuals]] < sd1minus]) / nrow(df))
    }
  }

}
