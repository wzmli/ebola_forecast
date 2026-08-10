library(macpan2)
library(shellpipes)

loadEnvironments()

spec = mp_tmb_model_spec(
    before = initialize_state
  , during = flow
  , default = default
)

rdsSave(spec)

