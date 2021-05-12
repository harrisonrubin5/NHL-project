# Defense Boosted Tree Tuning----

# Load Packages----
library(tidyverse)
library(tidymodels)

# Load Necessary Items----
load("data/defense_setup.rda")

set.seed(5556792)

# Define Model----
defense_bt_model <- boost_tree(
  mode = "regression",
  mtry = tune(),
  min_n = tune(),
  learn_rate = tune()
) %>% 
  set_engine("xgboost", importance = "impurity")

# Set up tuning grid----
defense_bt_params <- parameters(defense_bt_model) %>% 
  update(mtry = mtry(range = c(2, 22)),
         learn_rate = learn_rate(range = c(-5, -0.2)))
# Learn rate is log10

# Define grid
defense_bt_grid <- grid_regular(defense_bt_params, levels = 5)

# Random Forest Workflow----
defense_bt_workflow <- workflow() %>% 
  add_model(defense_bt_model) %>% 
  add_recipe(defense_recipe)

# Tuning/Fitting----
defense_bt_tune <- defense_bt_workflow %>% 
  tune_grid(
    resamples = defense_fold, 
    grid = defense_bt_grid
  )

# Write out results and workflow
save(defense_bt_tune, defense_bt_workflow, file = "data/defense_bt_tune.rda")



