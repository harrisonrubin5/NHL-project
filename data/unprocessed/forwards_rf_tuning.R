library(tidyverse)
library(tidymodels)

load("data/unprocessed/forwards_setup.rda")

forwards_rf_model <- rand_forest(
  mode = "regression",
  mtry = tune(),
  min_n = tune()
) %>% 
  set_engine("ranger")

forwards_rf_params <- parameters(forwards_rf_model) %>% 
  update(mtry = mtry(range = c(2, 22)))

forwards_rf_grid <- grid_regular(forwards_rf_params, levels = 5)

forwards_rf_workflow <- workflow() %>% 
  add_model(forwards_rf_model) %>% 
  add_recipe(forwards_recipe)

forwards_rf_tune <- forwards_rf_workflow %>% 
  tune_grid(
    resamples = forwards_fold, 
    grid = forwards_rf_grid
  )

save(forwards_rf_tune, forwards_rf_workflow, file = "data/unprocessed/forwards_tune.rda")