library(macpan2)
library(bbmle)
library(shellpipes)

cal <- rdsRead()

param_est <- mp_tmb_coef(cal, back_transform = FALSE)

param_vec <- param_est[["estimate"]]

vcov_mat <- mp_tmb_fixef_cov(cal)
print(vcov_mat)

theta_samp <- MASS::mvrnorm(n = 500
  ,mu = param_vec
  ,Sigma = vcov_mat
)

print(theta_samp)

saveVars(cal, theta_samp)
