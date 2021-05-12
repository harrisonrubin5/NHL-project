library(tidyverse)
library(tidymodels)

load("data/unprocessed/defense_setup.rda")

defense_bt_model <- boost_tree(
  mode = "regression",
  mtry = tune(),
  min_n = tune(),
  learn_rate = tune()
) %>% 
  set_engine("xgboost")

defense_bt_params <- parameters(defense_bt_model) %>% 
  update(mtry = mtry(range = c(2, 22)))

defense_bt_grid <- grid_regular(defense_bt_params, levels = 5)

defense_bt_workflow <- workflow() %>% 
  add_model(defense_bt_model) %>% 
  add_recipe(defense_recipe)

defense_bt_tune <- defense_bt_workflow %>% 
  tune_grid(
    resamples = defense_fold, 
    grid = defense_bt_grid
  )

save(defense_bt_tune, defense_bt_workflow, file = "data/unprocessed/defense_bt_tune.rda")