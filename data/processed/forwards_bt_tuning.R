# Forwards Boosted Tree Tuning----

# Load Packages----
library(tidyverse)
library(tidymodels)

# Load Necessary Items----
load("data/forwards_setup.rda")

set.seed(5556792)

# Define Model----
forwards_bt_model <- boost_tree(
  mode = "regression",
  mtry = tune(),
  min_n = tune(),
  learn_rate = tune()
) %>% 
  set_engine("xgboost", importance = "impurity")

# Set up tuning grid----
forwards_bt_params <- parameters(forwards_bt_model) %>% 
  update(mtry = mtry(range = c(2, 22)),
         learn_rate = learn_rate(range = c(-5, -0.2)))
# Learn rate is log10

# Define grid
forwards_bt_grid <- grid_regular(forwards_bt_params, levels = 5)

# Random Forest Workflow----
forwards_bt_workflow <- workflow() %>% 
  add_model(forwards_bt_model) %>% 
  add_recipe(forwards_recipe)

# Tuning/Fitting----
forwards_bt_tune <- forwards_bt_workflow %>% 
  tune_grid(
    resamples = forwards_fold, 
    grid = forwards_bt_grid
  )

# Write out results and workflow
save(forwards_bt_tune, forwards_bt_workflow, file = "data/forwards_bt_tune.rda")

