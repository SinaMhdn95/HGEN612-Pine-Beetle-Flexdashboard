#Load the libraries
library(tidymodels)      # for the parsnip package, along with the rest of tidymodels
library(tidyverse)       # for importing data
library(dotwhisker)      # for inspecting model coefficients
library(skimr)           # for variable summaries
library(patchwork)       # plot composer
library(broom.mixed)     # for converting bayesian model output to tidy tibbles
library(readxl)          # for reading an Excel file into a dataframe
library(broom)           # for converting model outputs into tidy data frames
library(car)             # for regression diagnostics and multicollinearity checks
library(ggfortify)       # for visualization
library(vip)             # for computing and visualizing variable importance in ML model
library(performance)     # for assessing model quality
library(plotly)          # for creating interactive plots
library(ggplot2)
library(knitr)
library(dplyr)
library(glmnet)
library(flexdashboard)
library(gaugeR)
install.packages("see")

#Load the dataset
data_work1 <- read_excel("Data_1993.xlsx", sheet = 1)
data_work1 <- na.omit(data_work1)
View(data_work1)

#Summary of dataset
str(data_work1)
summary(data_work1)
skim(data_work1)

# Select variables and make a dictionary

data.frame(
  Variables = c("DeadDist", "TreeDiam", "Infest_Serv1", "Ind_DeadDist", 
                "SDI_20th", "BA_20th", "Neigh_1/2th", "Neigh_1", 
                "BA_Inf_20th", "BA_Infest_1/2th", "BA_Infest_1"),
  
  Description = c("Minimum linear distance to nearest brood tree",
                  "Tree diameter", 
                  "Infestation severity of the nearest affected tree", 
                  "Indicator if nearest brood tree is within 50m effective distance found",
                  "Stand Density Index at 1/20th-acre neighborhood surrounding the tree",
                  "Basal Area at 1/20th-acre neighborhood surrounding response tree",
                  "Basal area total summed for all trees within 1/2th-acre neighborhood of response tree",
                  "Basal area total summed for all trees within 1-acre neighborhood of response tree",
                  "Basal area total for all infested trees within 1/20th-acre neighborhood",
                  "Basal area of infested trees within 1/2th-acre neighborhood of response tree", 
                  "Basal area of infested trees within 1-acre neighborhood of response tree"),
  
  Outcome_or_Predictor = c("Outcome", "Predictor", "Predictor", "Predictor", 
                           "Predictor", "Predictor", "Predictor", "Predictor", 
                           "Predictor", "Predictor", "Predictor")) %>% 
  kable()

#Visualizing the attacked trees

# Convert Response to a factor before plotting
data_work1$Response_Factor <- factor(data_work1$Response, labels = c("Alive", "JPB-attacked"))

# Create ggplot with correctly formatted `paste()`
plot1 <- ggplot(data = data_work1, aes(x = Easting, y = Northing)) +
  geom_point(aes(
    color = Response_Factor,
    text = paste(
      "TreeNum:", TreeNum,
      "<br>Status:", Response_Factor,
      "<br>Tree Diameter:", TreeDiam, 
      "<br>Infestation Severity 1:", Infest_Serv1,
      "<br>Infestation Severity 2:", Infest_Serv2,
      "<br>Stand Density Index (SDI):", SDI_20th,
      "<br>Basal Area:", BA_20th)), alpha = 0.7) +  
  scale_color_manual("Tree Condition", values = c("darkgreen", "#f765a3")) +  
  theme_bw() +
  theme(
    legend.title = element_text(face = "bold", size = 16),
    axis.title.x = element_text(face = "bold"),
    axis.title.y = element_text(face = "bold"),
    legend.text = element_text(size = 12)
  )

# Convert to interactive plot
ggplotly(plot1, tooltip = "text")

# Fit the model (primary model)
lm_fit <- lm(DeadDist ~ TreeDiam+Infest_Serv1+Ind_DeadDist+SDI_20th+BA_20th+
               `Neigh_1/2th`+Neigh_1+BA_Inf_20th+BA_Infest_1, data = data_work1)

lm_fit %>%
  tidy()

lm_fit %>% 
  glance()

vif(lm_fit)

# SDI_20th, BA_20th, Neigh_1/2th, Neigh_1 has high multicollinearity based on their vif
# The first step is excluding SDI_20th and refit model. Since SDI_20th has the biggest vif

lm_fit2 <- lm(DeadDist ~ TreeDiam+Infest_Serv1+Ind_DeadDist+BA_20th+
               `Neigh_1/2th`+Neigh_1+BA_Inf_20th+BA_Infest_1, data = data_work1)
lm_fit2 %>%
  tidy()

lm_fit2 %>% 
  glance()

# Check multicollinearity
vif(lm_fit2)

#Check model (check the assumptions)
check_model(lm_fit2)


pine_fit %>% 
  extract_fit_parsnip() %>% 
  check_model( dot_size = .6,
               line_size = 0.8,
               check = c("vif", "qq", "pp_check", "linearity"), 
               colors = c("#AA0078", "#669966", "#cd201f"),
               base_size = 7,
               theme = "ggplot2::theme_bw()")


# Still we can see some multicollinearity
# We do use LASSO to handle the multicollinearity
#we're gonna use tidy model

# Feature Engineering ( to improve linearity, reduce skewness and stabilize variances)
# Variable transformation
data_work1 <- data_work1 %>% 
  mutate(DeadDist_log = log(data_work1$DeadDist)) %>% 
  mutate(DeadDist_sqrt = sqrt(data_work1$DeadDist))

hist(data_work1$DeadDist)
hist(data_work1$DeadDist_log)
hist(data_work1$DeadDist_sqrt) # the best one

# Create Recipe
data_work2 <- data_work1 %>% 
  recipe(DeadDist_sqrt ~ TreeDiam+Infest_Serv1+Ind_DeadDist+BA_20th+
           `Neigh_1/2th`+Neigh_1+BA_Inf_20th+BA_Infest_1) %>% 
  step_sqrt(all_outcomes()) %>% 
  step_corr(all_predictors())

# View feature engineered data
data_work2 %>%
  prep() %>% 
  bake(new_data = NULL)    #supercedes juice()

# * Create Model ----
lm_mod <- 
  linear_reg() %>% 
  set_engine("lm")


# * Create Workflow ----
data_workflow <- 
  workflow() %>% 
  add_model(lm_mod) %>% 
  add_recipe(data_work2)

data_workflow


pine_fit <- 
  data_workflow %>% 
  fit(data = data_work1)


pine_fit %>% 
  extract_fit_parsnip() %>% 
  tidy()

pine_fit %>% 
  extract_fit_parsnip() %>% 
  glance()

pine_fit %>% 
  extract_fit_parsnip() %>% 
  check_model()

pine_fit %>% 
  extract_preprocessor()

pine_fit %>% 
  extract_spec_parsnip()

pine_fit %>%
  extract_fit_parsnip() %>%
  glance()%>%
  select(r.squared)


# RIDGE REGRESSION
# Create training/testing data
pine_split <- initial_split(data_work1)
pine_train <- training(pine_split)
pine_test <- testing(pine_split)

ridge_mod <-
  linear_reg(mixture = 0, penalty = 0.1629751) %>%  #validation sample or resampling can estimate this
  set_engine("glmnet")

# verify what we are doing
ridge_mod %>% 
  translate()

# create a new recipe; could use `add_step()` to recipe created above
pine_recipe2 <- pine_train %>% 
  recipe(DeadDist_sqrt ~ TreeDiam+Infest_Serv1+Ind_DeadDist+BA_20th+
           `Neigh_1/2th`+Neigh_1+BA_Inf_20th+BA_Infest_1) %>% 
  step_sqrt(all_outcomes()) %>% 
  step_corr(all_predictors()) %>% 
  step_normalize(all_numeric(), -all_outcomes()) %>% 
  step_zv(all_numeric(), -all_outcomes())

pine_ridge_wflow <- 
  workflow() %>% 
  add_model(ridge_mod) %>% 
  add_recipe(pine_recipe2)

pine_ridge_wflow


pine_ridge_fit <- 
  pine_ridge_wflow %>% 
  fit(data = pine_train)


pine_ridge_fit %>% 
  extract_fit_parsnip() %>% 
  tidy()

pine_ridge_fit %>% 
  extract_preprocessor()

pine_ridge_fit %>% 
  extract_spec_parsnip()

# refit best model on training and evaluate on testing
last_fit(
  pine_ridge_wflow,
  pine_split
) %>%
  collect_metrics()

# verify Ridge Regression performance with standard linear regression approach
ridge_mod <- lm(sqrt(DeadDist) ~ TreeDiam+Infest_Serv1+Ind_DeadDist+BA_20th+
     `Neigh_1/2th`+Neigh_1+BA_Inf_20th+BA_Infest_1, data = data_work1) %>% 
  glance()


ridge_mod %>% 
  select(r.squared, sigma, statistic, p.value, df, AIC) %>% 
  kable(digits = 2)


### **Model Performance: R-squared ($R^2$) for RIDGE Model** 


# refit best model on training and evaluate on testing
ridge_rsq <- last_fit( # uses different predictors of the model to find which one best fits to the model
  pine_ridge_wflow,
  pine_split
) %>%
  collect_metrics() %>% 
  filter(.metric == "rsq") %>% 
  select(.estimate)
gauge(round(as.numeric(ridge_rsq*100),2), min = 0, max = 100, symbol = "%",  gaugeSectors(success = c(60, 100), colors = '#AA0078'))


### **RMSE: Root Mean Square Error**


ridge_rmse <- last_fit( # uses different predictors of the model to find which one best fits to the model
  pine_ridge_wflow,
  pine_split
) %>%
  collect_metrics() %>% 
  filter(.metric == "rmse") %>% 
  select(.estimate)
gauge(round(as.numeric(ridge_rmse),2), min = 0, max = 5,  gaugeSectors(success = c(1, 5), colors = '#AA0078'))







# Create training/testing data
pine_split <- initial_split(data_work1)
pine_train <- training(pine_split)
pine_test <- testing(pine_split)


# picking Dr. Smirnova's best lambda estimate; can estimate with tune() - see below
ridge_mod <-
  linear_reg(mixture = 0, penalty = 0.1629751) %>%  #validation sample or resampling can estimate this
  set_engine("glmnet")

# verify what we are doing
ridge_mod %>% 
  translate()


# create a new recipe; could use `add_step()` to recipe created above
pine_rec <- pine_train %>% 
  recipe(DeadDist_sqrt ~ TreeDiam+Infest_Serv1+Ind_DeadDist+BA_20th+
           `Neigh_1/2th`+Neigh_1+BA_Inf_20th+BA_Infest_1) %>% 
  step_sqrt(all_outcomes()) %>% 
  step_corr(all_predictors()) %>% 
  step_normalize(all_numeric(), -all_outcomes()) %>% 
  step_zv(all_numeric(), -all_outcomes()) #%>% 
# prep()


pine_ridge_wflow <- 
  workflow() %>% 
  add_model(ridge_mod) %>% 
  add_recipe(pine_rec)

pine_ridge_wflow


pine_ridge_fit <- 
  pine_ridge_wflow %>% 
  fit(data = pine_train)


pine_ridge_fit %>% 
  extract_fit_parsnip() %>% 
  tidy()

pine_ridge_fit %>% 
  extract_preprocessor()

pine_ridge_fit %>% 
  extract_spec_parsnip()


# refit best model on training and evaluate on testing
last_fit(
  pine_ridge_wflow,
  pine_split
) %>%
  collect_metrics()


# verify Ridge Regression performance with standard linear regression approach
lm(sqrt(DeadDist) ~ TreeDiam+Infest_Serv1+Ind_DeadDist+BA_20th+
     `Neigh_1/2th`+Neigh_1+BA_Inf_20th+BA_Infest_1, data = data_work1) %>% 
  glance()



### **List of Predictors Retained via LASSO Regression Model**
```{r LASSO-model}

# create bootstrap samples for resampling and tuning the penalty parameter
set.seed(1234)
pine_boot <- bootstraps(pine_train)

# create a grid of tuning parameters
lambda_grid <- grid_regular(penalty(), levels = 50)


lasso_mod <-
  linear_reg(mixture = 1, penalty = tune()) %>% # tune() to figure out the best fit number is from the botstrap 
  set_engine("glmnet")


# create workflow
pine_lasso_wflow <- 
  workflow() %>% 
  add_model(lasso_mod) %>% 
  add_recipe(pine_recipe2)


set.seed(2020)
lasso_grid <- tune_grid(
  pine_lasso_wflow,
  resamples = pine_boot,
  grid = lambda_grid
)




lowest_rmse <- select_best(lasso_grid, metric = "rmse")

# update our final model with lowest rmse
final_lasso <- finalize_workflow(
  pine_lasso_wflow,
  lowest_rmse
)


final_lasso
