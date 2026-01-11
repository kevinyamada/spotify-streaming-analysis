# Spotify Streaming Analysis (Regression + Model Validation)

**Goal:** Understand which musical + platform features are associated with higher Spotify stream counts, and test whether **valence moderates** the effect of **mode (major/minor)**.

**Tools:** R, ggplot2, dplyr  
**Methods:** Multiple linear regression, transformations, model selection (AIC / adjusted R²), diagnostics, manual VIF, 5-fold cross-validation (RMSE)

---

## 1) Problem / Research Question
Spotify is the world’s largest music streaming platform, and artists/labels want to understand what traits are linked to popularity.  
This project asks:

**To what extent do a song’s mode, danceability, and energy influence Spotify streams, and does valence moderate these effects?**

---

## 2) Dataset
- **N = 952 tracks**
- Dataset: **“Top Spotify Songs of 2023”** (Kaggle; built from the Spotify Web API)
- Response: **Spotify streams** (continuous)
- Key predictors: **danceability, energy, valence, mode (major/minor)** + platform signals (e.g., **charts**) and audio features (e.g., speechiness, bpm, etc.)
- Created an interaction term: **valence × mode** (moderation)

> Note: This dataset focuses on highly streamed 2023 tracks (mostly pop/hip-hop), so results may not generalize to all genres.

---

## 3) What I Did (Process)
### Data Preparation
- Engineered features:
  - `log_streams = log(streams)`
  - `sqrt_streams = sqrt(streams)`
  - `valence_mode = valence * mode`

### Modeling Strategy
- Fit and compared **three models** using the same predictor set:
  - Streams (raw)
  - √Streams
  - log(Streams)

- Ran regression workflow:
  1. Summary + exploratory checks
  2. Model diagnostics (linearity, residuals, leverage/influential points)
  3. **Model comparison** using **AIC + adjusted R²**
  4. **Backward selection** from a full model, keeping literature-supported terms
  5. Checked multicollinearity using **manual VIF**
  6. Validated performance with **5-fold cross-validation (RMSE)**

---

## 4) Final Model
Final specification (after selection + diagnostics):

**log(Streams) ~ charts + danceability + valence + energy + mode + (valence × mode) + speechiness**

---

## 5) Key Results (What I Found)
- **Best transformation:** log(Streams) improved linearity vs. raw streams.
- **Most meaningful predictors:** **charts** and **speechiness** were the strongest signals for log(streams).
- **Moderation test:** did **not** find strong evidence that **mode, danceability, energy, valence, or valence×mode** meaningfully changed log(streams) in this dataset.
- **Model fit:** **R² ≈ 0.04** (weak overall explanatory power)
- **Validation:** **5-fold CV RMSE ≈ 1.13** vs **~1.15** for an intercept-only baseline (small improvement)
- **Multicollinearity:** VIFs were checked (kept within acceptable range)

**Interpretation:**
Even among already-popular tracks, platform exposure signals (like being on charts) and certain audio characteristics (speechiness) were more predictive than “vibe” features like mode/danceability/energy.

---

## 6) Limitations
- Dataset is restricted to **top streamed songs of 2023** → genre + popularity selection bias.
- Some predictors come from other platforms (Apple Music, Shazam, Deezer) → potential platform/user-base bias.
- Model fit is weak (low R²) → suggests missing nonlinear relationships, interactions, or external drivers (artist popularity, marketing, playlists, release timing).

---

## 7) Future Improvements
If I expanded this project, I would:
- Add features like **artist popularity, playlist placement, label, release date, marketing signals**
- Try nonlinear / ML models:
  - Random Forest / Gradient Boosting
  - Regularized regression (Lasso/Ridge)
- Test richer interactions + genre-stratified models
- Normalize/align cross-platform measures before modeling

---

## 8) How to Run
1. Clone the repo
2. Open in RStudio
3. Install
