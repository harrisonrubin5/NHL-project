# Forwards Knn Tuning----

# Load Packages----
library(tidyverse)
library(tidymodels)

# Load Necessary Items----
load("data/forwards_setup.rda")

# Set Seed
set.seed(7777777)

# Define Model----
forwards_knn_model <- nearest_neighbor(
  mode = "regression",
  neighbors = tune()
) %>% 
  set_engine("kknn")

# Set up tuning grid----
forwards_knn_params <- parameters(forwards_knn_model)

# Define grid
forwards_knn_grid <- grid_regular(forwards_knn_params, levels = 5)

# Random Forest Workflow----
forwards_knn_workflow <- workflow() %>% 
  add_model(forwards_knn_model) %>% 
  add_recipe(forwards_recipe)

# Tuning/Fitting----
forwards_knn_tune <- forwards_knn_workflow %>% 
  tune_grid(
    resamples = forwards_fold, 
    grid = forwards_knn_grid
  )

# Write out results and workflow
save(forwards_knn_tune, forwards_knn_workflow, file = "data/forwards_knn_tune.rda")



