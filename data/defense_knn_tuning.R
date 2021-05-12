# Defense Knn Tuning----

# Load Packages----
library(tidyverse)
library(tidymodels)

# Load Necessary Items----
load("data/defense_setup.rda")

# Set Seed
set.seed(7777777)

# Define Model----
defense_knn_model <- nearest_neighbor(
  mode = "regression",
  neighbors = tune()
) %>% 
  set_engine("kknn")

# Set up tuning grid----
defense_knn_params <- parameters(defense_knn_model)

# Define grid
defense_knn_grid <- grid_regular(defense_knn_params, levels = 5)

# Random Forest Workflow----
defense_knn_workflow <- workflow() %>% 
  add_model(defense_knn_model) %>% 
  add_recipe(defense_recipe)

# Tuning/Fitting----
defense_knn_tune <- defense_knn_workflow %>% 
  tune_grid(
    resamples = defense_fold, 
    grid = defense_knn_grid
  )

# Write out results and workflow
save(defense_knn_tune, defense_knn_workflow, file = "data/defense_knn_tune.rda")



