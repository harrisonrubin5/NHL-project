# Defense Random Forest Tuning----

# Load Packages----
library(tidyverse)
library(tidymodels)

set.seed(8888888)

# Load Necessary Items----
load("data/defense_setup.rda")

# Define Model----
defense_rf_model <- rand_forest(
  mode = "regression",
  mtry = tune(),
  min_n = tune()
) %>% 
  set_engine("ranger", importance = "impurity")

# Set up tuning grid----
defense_rf_params <- parameters(defense_rf_model) %>% 
  update(mtry = mtry(range = c(2, 22)))

# Define grid
defense_rf_grid <- grid_regular(defense_rf_params, levels = 5)

# Random Forest Workflow----
defense_rf_workflow <- workflow() %>% 
  add_model(defense_rf_model) %>% 
  add_recipe(defense_recipe)

# Tuning/Fitting----
defense_rf_tune <- defense_rf_workflow %>% 
  tune_grid(
    resamples = defense_fold, 
    grid = defense_rf_grid
  )

# Write out results and workflow
save(defense_rf_tune, defense_rf_workflow, file = "data/defense_rf_tune.rda")



