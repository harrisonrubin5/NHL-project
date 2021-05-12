library(tidyverse)
library(tidymodels)

load("data/unprocessed/defense_setup.rda")

defense_rf_model <- rand_forest(
  mode = "regression",
  mtry = tune(),
  min_n = tune()
) %>% 
  set_engine("ranger")

defense_rf_params <- parameters(defense_rf_model) %>% 
  update(mtry = mtry(range = c(2, 22)))

defense_rf_grid <- grid_regular(defense_rf_params, levels = 5)

defense_rf_workflow <- workflow() %>% 
  add_model(defense_rf_model) %>% 
  add_recipe(defense_recipe)

defense_rf_tune <- defense_rf_workflow %>% 
  tune_grid(
    resamples = defense_fold, 
    grid = defense_rf_grid
  )

save(defense_rf_tune, defense_rf_workflow, file = "data/unprocessed/defense_tune.rda")