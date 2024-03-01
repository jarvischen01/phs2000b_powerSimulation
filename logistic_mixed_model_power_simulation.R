# power simulation example for a logistic mixed effect model
# We have 100 clusters; 50 of them are non-poor, and 50 of them are poor
# We have 100 subjects per cluster, of different ages

library(tidyverse) # allows us to use dplyr tools for data manipulation
library(lme4) # since we are going to be fitting a logistic mixed effect model
library(broom.mixed) # for tidy extraction of model results from mixed effect models

# number of simulations
n_sim <- 500

# number of clusters
n_cluster <- 100

# number of individuals per cluster
n_per_cluster <- 100

# create cluster effects from a random normal with mean zero and standard deviation 0.5
clusterid <- c(1:100)
cluster_effect <- rnorm(n_cluster, 0, 0.5)
# To understand the cluster effect, note that the standard deviation of 0.5
# has given us a distribution where the interquartile range is ~0.62
# This corresponds to an odds ratio of 1.86 comparing the odds of the outcome
# in the 75th to the 25th percentile of clusters
# Also note that in this simulation we are treating the cluster effects as fixed and known.
# But if we wanted to, we could generate new random cluster effects for each iteration of the
# simulation, by including the code defining clusters inside the simulation loop.


# We'll posit an OR for a 1 year difference in age of 0.98
# Let's look at some different values for the effect of cluster poverty
# (comparing being in a poor cluster to being in a non-poor cluster).
# Here we specify three values of the odds ratio to check.
beta_poverty <- c(log(1.2), log(1.5), log(2))
beta_age <- log(0.98)

# Create a data frame to hold all the data
# The data frame has variables cid and poverty
df <- data.frame(cid = rep(clusterid, each = n_per_cluster)) |>
  mutate(poverty = if_else(cid<=50, 0, 1))

# Create age as a continuous variable
# In class we created the mean of age to be 45,
# but when we fit the model, R told us to consider centering age.
# Since the mean of age doesn't actually affect the model results, we'll create
# a mean centered version of age (mean = 0)
df$age <- rnorm(n_cluster * n_per_cluster, 0, 9)

# Create an array to hold the results
results <- array(NA, dim=c(n_sim, 3))

for (j in 1:length(beta_poverty)){
  for (i in 1:n_sim){
  
  # Simulate the log odds of Y. Assume a baseline P(Y=1) of 0.03
  log_odds <- log(0.03/0.97) + beta_age*df$age +
    beta_poverty[j] * df$poverty + cluster_effect[df$cid]
  # Convert this to a probability
  prob_y <- exp(log_odds)/(1 + exp(log_odds))
  # Now use this to simulate y as a 0/1 variable
  df$y <- rbinom(n_cluster*n_per_cluster, 1, prob_y)
  
  # Fit a logistic random intercept model
  this_model <- glmer(y ~ age + poverty + (1 | cid),
                      family = binomial(link = "logit"),
                      data = df,
                      control = glmerControl(optimizer = "bobyqa"))
  
  # Save the p-value on the poverty term
  results[i, j] <- tidy(this_model)$p.value[3]
  # Print i and j to console so we can keep track of progress
  print(paste(i, ",", j))
  }
}


# Calculate the proportion of simulations where we detect a significant poverty effect
apply(results<0.05, 2, sum)/n_sim


png("power_simulation_logistic_mixed.png")
plot(exp(beta_poverty), apply(results<0.05, 2, sum)/n_sim, ylab = "Power", xlab = "Odds Ratio (poverty)")
lines(exp(beta_poverty),apply(results<0.05, 2, sum)/n_sim)
abline(h=0.8, lty = 2)
dev.off()




