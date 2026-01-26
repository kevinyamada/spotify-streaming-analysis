library(readr)
library(dplyr)
library(ggplot2)

spotify <- read_csv("Spotify_cleaned(in).csv")

spotify <- spotify %>%
  mutate(
    log_streams  = log(streams),
    sqrt_streams = sqrt(streams),
    valence_mode = valence * mode
  )

predictor_vars <- c(
  "danceability", "valence", "energy", "acousticness",
  "instrumentalness", "liveness", "speechiness", "bpm", "charts"
)

summary(spotify[, predictor_vars])
summary(spotify$streams)
summary(spotify$log_streams)

full_predictors <- ~ charts + danceability + valence + energy +
  acousticness + instrumentalness + liveness +
  speechiness + bpm + mode + valence_mode

m_streams_full <- lm(update(full_predictors, streams ~ .), data = spotify)
m_sqrt_full    <- lm(update(full_predictors, sqrt_streams ~ .), data = spotify)
m_log_full     <- lm(update(full_predictors, log_streams ~ .), data = spotify)

model_comp <- data.frame(
  model  = c("streams", "sqrt_streams", "log_streams"),
  R2     = c(
    summary(m_streams_full)$r.squared,
    summary(m_sqrt_full)$r.squared,
    summary(m_log_full)$r.squared
  ),
  adj_R2 = c(
    summary(m_streams_full)$adj.r.squared,
    summary(m_sqrt_full)$adj.r.squared,
    summary(m_log_full)$adj.r.squared
  ),
  AIC    = c(
    AIC(m_streams_full),
    AIC(m_sqrt_full),
    AIC(m_log_full)
  )
)

print(model_comp)

par(mfrow = c(2, 2))
plot(m_streams_full)
par(mfrow = c(2, 2))
plot(m_log_full)
par(mfrow = c(1, 1))

final_formula <- log_streams ~ charts + danceability + valence +
  energy + mode + valence_mode + speechiness

m_final <- lm(final_formula, data = spotify)
summary(m_final)

vif_manual <- function(model) {
  X <- stats::model.matrix(model)
  X <- X[, -1, drop = FALSE]
  vif_vals <- numeric(ncol(X))
  names(vif_vals) <- colnames(X)
  for (j in seq_len(ncol(X))) {
    x_j      <- X[, j]
    x_others <- X[, -j, drop = FALSE]
    r2_j     <- summary(lm(x_j ~ x_others))$r.squared
    vif_vals[j] <- 1 / (1 - r2_j)
  }
  vif_vals
}

vif_manual(m_final)

set.seed(123)
K <- 5
n <- nrow(spotify)
fold_id <- sample(rep(1:K, length.out = n))
mse_vec <- numeric(K)

for (k in 1:K) {
  train_idx <- which(fold_id != k)
  test_idx  <- which(fold_id == k)
  m_k <- lm(final_formula, data = spotify[train_idx, ])
  preds  <- predict(m_k, newdata = spotify[test_idx, ])
  y_test <- spotify$log_streams[test_idx]
  mse_vec[k] <- mean((y_test - preds)^2)
}

cv_mse   <- mean(mse_vec)
cv_rmse  <- sqrt(cv_mse)
baseline_mse  <- mean((spotify$log_streams - mean(spotify$log_streams))^2)
baseline_rmse <- sqrt(baseline_mse)

cv_results <- data.frame(
  model = c("final_model", "intercept_only"),
  RMSE  = c(cv_rmse, baseline_rmse)
)

print(cv_results)

coef_final <- coef(m_final)

beta_charts <- coef_final["charts"]
beta_speech <- coef_final["speechiness"]

effect_charts_10 <- (exp(beta_charts * 10) - 1) * 100
effect_speech_10 <- (exp(beta_speech * 10) - 1) * 100

effect_sizes <- data.frame(
  variable              = c("charts (+10)", "speechiness (+10)"),
  approx_percent_change = c(effect_charts_10, effect_speech_10)
)

print(effect_sizes)

ggplot(spotify, aes(x = valence, y = log_streams,
                    colour = factor(mode))) +
  geom_point(alpha = 0.4) +
  geom_smooth(method = "lm", se = FALSE) +
  labs(
    title  = "log(Streams) vs Valence by Mode",
    x      = "Valence (%)",
    y      = "log(Streams)",
    colour = "Mode (0 = minor, 1 = major)"
  )

spotify <- spotify %>%
  mutate(
    valence_q = dplyr::ntile(valence, 4),
    valence_q = factor(
      valence_q,
      labels = c("low", "mid-low", "mid-high", "high")
    )
  )

mean_log_by_group <- spotify %>%
  group_by(mode, valence_q) %>%
  summarise(
    mean_log_streams = mean(log_streams),
    .groups = "drop"
  )

print(mean_log_by_group)

ggplot(mean_log_by_group,
       aes(x = valence_q,
           y = mean_log_streams,
           group = factor(mode),
           colour = factor(mode))) +
  geom_line() +
  geom_point() +
  labs(
    title  = "Mean log(Streams) by Valence Quartile and Mode",
    x      = "Valence quartile",
    y      = "Mean log(Streams)",
    colour = "Mode"
  ) +
  theme_minimal()

par(mfrow = c(2, 2))
plot(m_final)
par(mfrow = c(1, 1))
