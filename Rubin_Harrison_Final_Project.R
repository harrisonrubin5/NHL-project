# Final Project -----------------------------------------------------------

# Load Packages
library(tidyverse)
library(tidymodels)
library(lubridate)
library(readxl)
library(janitor)
library(broom)
library(naniar)
library(skimr)
library(patchwork)
library(vip)

# Set Seed
set.seed(8675309)

# Read in Data
skaters <- read_excel("data/unprocessed/skaters.xlsx")
salaries <- read_excel("data/unprocessed/skaters_salaries.xlsx")
advanced_stats <- read_csv("data/unprocessed/nhl_advanced.csv")

# Data Cleaning and Mutation
skaters <- skaters %>% 
  clean_names() %>% 
  rename(
    plus_minus = x,
    shots = s)

skim_without_charts(advanced_stats)

skaters_salaries <- skaters %>% 
  left_join(salaries, by = "player") %>% 
  filter(!is.na(salary))

salary_dat <- skaters_salaries %>% 
  select(player, salary) %>% 
  mutate(
    salary = as.numeric(salary)
  )

skaters_salaries <- skaters_salaries %>% 
  mutate(
    salary = as.numeric(salary),
    s_percent = as.numeric(s_percent),
    fow_percent = as.numeric(fow_percent)
  )

# Convert time on ice into minutes
toi_df <- data.frame(skaters_salaries$toi_gp)

toi_min <- toi_df %>% 
  separate(skaters_salaries.toi_gp, into = c("pre", "post")) %>% 
  pull("pre")

toi_sec <- toi_df %>% 
  separate(skaters_salaries.toi_gp, into = c("pre", "post")) %>% 
  pull("post")

toi <- (as.numeric(toi_min) + as.numeric(toi_sec) / 60)

skaters_salaries <- skaters_salaries %>% 
  mutate(
    toi_gp = toi
  )

skaters_salaries <- skaters_salaries %>% 
  left_join(advanced_stats, by = "player")

# Remove rookies and players who played fewer than 25 games
skaters_salaries <- skaters_salaries %>% 
  rename(hand = s_c) %>% 
  filter(gp >= 25) %>% 
  filter(salary >= 925000) %>% 
  mutate(tk_gv = tk / gv)

# Remove Duplicates
skaters_salaries <- skaters_salaries[!duplicated(skaters_salaries$player) ,] %>% 
  mutate(salary = log10(salary))

# Create distinct data frames for forwards and defensemen
forwards <- skaters_salaries %>% 
  filter(pos == "C" | pos == "L" | pos == "R")

defense <- skaters_salaries %>% 
  filter(pos == "D") %>% 
  filter(!is.na(corsi_pct))

# EDA
sal_f <- forwards %>% 
  ggplot(aes(x = salary)) +
  geom_density()

sal_d <- defense %>% 
  ggplot(aes(x = salary)) +
  geom_density()

sal_f / sal_d

forwards %>% 
  ggplot(aes(x = p, y= exp_plus_minus)) +
  geom_point() +
  xlab("Points") +
  ylab("Expected Plus-Minus") +
  geom_smooth()

forwards %>% 
  ggplot(aes(x = shots, y= s_percent)) +
  geom_point() +
  xlab("Shots") +
  ylab("Shooting Percentage") +
  geom_smooth()

forwards %>% 
  ggplot(aes(y = pdo, x= corsi_pct)) +
  geom_point() +
  ylab("PDO") +
  xlab("Corsi") +
  geom_smooth()

defense %>% 
  ggplot(aes(x = tk_gv, y = p)) +
  geom_point() +
  xlab("Takeaway/Giveaway Ratio") +
  ylab("Points") +
  geom_smooth()

defense %>% 
  ggplot(aes(x = p, y= exp_plus_minus)) +
  geom_point() +
  xlab("Points") +
  ylab("Expected Plus-Minus") +
  geom_smooth()

defense %>% 
  ggplot(aes(y = pdo, x= corsi_pct)) +
  geom_point() +
  ylab("PDO") +
  xlab("Corsi")

# Split Data
forwards_split <- initial_split(data = forwards, prop = 0.6, strata = salary)
forwards_train <- training(forwards_split)
forwards_test <- testing(forwards_split)
forwards_split

defense_split <- initial_split(data = defense, prop = 0.6, strata = salary)
defense_train <- training(defense_split)
defense_test <- testing(defense_split)
defense_split

forwards_fold <- vfold_cv(data = forwards_train, v = 5, repeats = 5, strata = salary)

defense_fold <- vfold_cv(data = defense_train, v = 5, repeats = 5, strata = salary)

# Forwards Recipe
forwards_recipe <- recipe(salary ~ ., data = forwards_train) %>% 
  step_rm(player) %>% 
  step_rm(fow_percent) %>% 
  step_dummy(all_nominal(), one_hot = TRUE) %>% 
  step_interact(~ p:exp_plus_minus + shots:s_percent + pdo:exp_plus_minus) %>% 
  step_lincomb(all_predictors()) %>% 
  step_normalize(all_predictors())

forwards_recipe %>% 
  prep() %>% 
  bake(new_data = NULL)

save(forwards_fold, forwards_recipe, forwards_split, file = "data/forwards_setup.rda")


# Defense Recipe
defense_recipe <- recipe(salary ~ ., data = defense_train) %>% 
  step_rm(player) %>% 
  step_rm(fow_percent) %>% 
  step_rm(pos) %>% 
  step_dummy(all_nominal(), one_hot = TRUE) %>% 
  step_interact(~ tk_gv:p + p:exp_plus_minus + pdo:exp_plus_minus) %>% 
  step_lincomb(all_predictors()) %>% 
  step_normalize(all_predictors())

defense_recipe %>% 
  prep() %>% 
  bake(new_data = NULL)

save(defense_fold, defense_recipe, defense_split, file = "data/defense_setup.rda")

# Forwards Tuning
load("data/forwards_rf_tune.rda")
load("data/forwards_bt_tune.rda")
load("data/forwards_knn_tune.rda")

forwards_rf_tune %>% 
  autoplot(metric = "rmse")

forwards_bt_tune %>% 
  autoplot(metric = "rmse")

forwards_knn_tune %>% 
  autoplot(metric = "rmse")

forwards_rf_tune %>% 
  select_best(metric = "rmse")

forwards_bt_tune %>% 
  select_best(metric = "rmse")

forwards_knn_tune %>% 
  select_best(metric = "rmse")

forwards_rf_tune %>% 
  select_by_one_std_err(metric = "rmse", mtry)

forwards_rf_tune %>% 
  collect_metrics() %>% 
  filter(.metric == "rmse") %>% 
  slice_min(mean)

tune_results <- tibble(
  model_type = c("rf", "boost", "knn"),
  tune_info = list(forwards_rf_tune, forwards_bt_tune, forwards_knn_tune),
  assessment_info = map(tune_info, collect_metrics),
  best_model = map(tune_info, ~ select_best(.x, metric = "rmse"))
)

tune_results %>% 
  select(model_type, best_model) %>% 
  unnest(best_model)

tune_results %>% 
  select(model_type, assessment_info) %>% 
  unnest(assessment_info) %>% 
  filter(.metric == "rmse") %>% 
  arrange(mean) %>% 
  View()

forwards_rf_workflow_tuned <- forwards_rf_workflow %>% 
  finalize_workflow(select_best(forwards_rf_tune, metric = "rmse"))

forwards_rf_results <- fit(forwards_rf_workflow_tuned, forwards_train)

forwards_metric <- metric_set(rmse)

predict(forwards_rf_results, new_data = forwards_test) %>% 
  bind_cols(forwards_test %>% select(salary)) %>% 
  forwards_metric(truth = salary, estimate = .pred)

# Defense Tuning
load("data/defense_rf_tune.rda")
load("data/defense_bt_tune.rda")
load("data/defense_knn_tune.rda")

defense_rf_tune %>% 
  autoplot(metric = "rmse")

defense_knn_tune %>% 
  autoplot(metric = "rmse")

defense_rf_tune %>% 
  select_best(metric = "rmse")

defense_bt_tune %>% 
  select_best(metric = "rmse")

defense_knn_tune %>% 
  select_best(metric = "rmse")

defense_rf_tune %>% 
  select_by_one_std_err(metric = "rmse", mtry)

defense_rf_tune %>% 
  collect_metrics() %>% 
  filter(.metric == "rmse") %>% 
  slice_min(mean)

defense_bt_tune %>% 
  autoplot(metric = "rmse")


tune_results <- tibble(
  model_type = c("rf", "boost", "knn"),
  tune_info = list(defense_rf_tune, defense_bt_tune, defense_knn_tune),
  assessment_info = map(tune_info, collect_metrics),
  best_model = map(tune_info, ~ select_best(.x, metric = "rmse"))
)

tune_results %>% 
  select(model_type, best_model) %>% 
  unnest(best_model)

tune_results %>% 
  select(model_type, assessment_info) %>% 
  unnest(assessment_info) %>% 
  filter(.metric == "rmse") %>% 
  arrange(mean) %>% 
  View()

defense_rf_workflow_tuned <- defense_rf_workflow %>% 
  finalize_workflow(select_best(defense_rf_tune, metric = "rmse"))

defense_rf_results <- fit(defense_rf_workflow_tuned, defense_train)

defense_metric <- metric_set(rmse)

predict(defense_rf_results, new_data = defense_test) %>% 
  bind_cols(defense_test %>% select(salary)) %>% 
  defense_metric(truth = salary, estimate = .pred)