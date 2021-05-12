library(tidyverse)
library(tidymodels)

load("data/unprocessed/forwards_setup.rda")

forwards_bt_model <- boost_tree(
  mode = "regression",
  mtry = tune(),
  min_n = tune(),
  learn_rate = tune()
) %>% 
  set_engine("xgboost")

forwards_bt_params <- parameters(forwards_bt_model) %>% 
  update(mtry = mtry(range = c(2, 22)))

forwards_bt_grid <- grid_regular(forwards_bt_params, levels = 5)

forwards_bt_workflow <- workflow() %>% 
  add_model(forwards_bt_model) %>% 
  add_recipe(forwards_recipe)

forwards_bt_tune <- forwards_bt_workflow %>% 
  tune_grid(
    resamples = forwards_fold, 
    grid = forwards_bt_grid
  )

save(forwards_bt_tune, forwards_bt_workflow, file = "data/unprocessed/forwards_bt_tune.rda")