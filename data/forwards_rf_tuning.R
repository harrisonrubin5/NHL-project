# Forwards Random Forest Tuning----

# Load Packages----
library(tidyverse)
library(tidymodels)

set.seed(8888888)

# Load Necessary Items----
load("data/forwards_setup.rda")

# Define Model----
forwards_rf_model <- rand_forest(
  mode = "regression",
  mtry = tune(),
  min_n = tune()
) %>% 
  set_engine("ranger", importance = "impurity")

# Set up tuning grid----
forwards_rf_params <- parameters(forwards_rf_model) %>% 
  update(mtry = mtry(range = c(2, 22)))

# Define grid
forwards_rf_grid <- grid_regular(forwards_rf_params, levels = 5)

# Random Forest Workflow----
forwards_rf_workflow <- workflow() %>% 
  add_model(forwards_rf_model) %>% 
  add_recipe(forwards_recipe)

# Tuning/Fitting----
forwards_rf_tune <- forwards_rf_workflow %>% 
  tune_grid(
    resamples = forwards_fold, 
    grid = forwards_rf_grid
  )

# Write out results and workflow
save(forwards_rf_tune, forwards_rf_workflow, file = "data/forwards_rf_tune.rda")



forwards_rf_model <- rand_forest(
  mode = "regression",
  mtry = 7,
  min_n = 2
) %>% 
  set_engine("ranger", importance = "impurity")

forwards_rf_workflow <- workflow() %>% 
  add_model(forwards_rf_model) %>% 
  add_recipe(forwards_recipe)

forwards_rf_vip_fit <- forwards_rf_workflow %>% 
  fit(forwards_train)

forwards_vip <- forwards_rf_vip_fit %>% 
  pull_workflow_fit() %>% 
  vip()

forwards_vip

save(forwards_vip, file = "data/forwards_vip.rda")

