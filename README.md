Built an end-to-end CI/CD pipeline for an ML batch inference system. New data or Script updation automatically triggers inference, generates predictions, computes evaluation metrics, detects data and concept drift, logs monitoring reports, and versions all artifacts using GitHub Actions. The system is idempotent, supports continuous data integration, and mirrors real-world MLOps batch deployment patterns.


End-to-End ML CI/CD & MLOps Pipeline (Batch Inference + Monitoring)

Author: Pratik Ganguli
Domain: Machine Learning Operations (MLOps)
Focus: CI/CD, automation, monitoring, reproducibility
Tech Stack: R, GitHub Actions, tidyverse, statistical monitoring

1. Project Overview

This repository implements a production-style Machine Learning CI/CD pipeline designed to closely mirror real-world MLOps workflows used in industry.

The pipeline supports:

Continuous integration of data + code

Automated batch inference

Automated evaluation & metric logging

Data drift and concept drift monitoring

Versioned storage of predictions, metrics, and monitoring reports

Fully automated execution using GitHub Actions

Manual workflow triggering for controlled runs

 Important Note (NDA Compliance)
The original production model used in my professional work has been replaced with a dummy regression model.
This was done to comply with non-disclosure agreements.

All CI/CD, monitoring, automation, and MLOps logic remains unchanged and production-representative.

2. Objective (Why This Project Exists)

The goal is not to showcase a complex ML model.

Instead, this project demonstrates:

How ML systems are operationalised

How data continuously flows into production

How inference is triggered automatically

How performance is monitored post-deployment

How pipelines remain idempotent, traceable, and auditable

How GitHub Actions can act as a CI/CD orchestrator for ML workloads

This is intentionally designed as a realistic batch-inference MLOps system, not a notebook-driven experiment.

3. High-Level Architecture
┌──────────────┐
│  New Data    │  (CSV files pushed to repo)
│  new_data/   │
└──────┬───────┘
       │  (git push)
       ▼
┌─────────────────────────────┐
│ GitHub Actions Workflow     │
│ (CI/CD Orchestration)       │
└──────────┬──────────────────┘
           │
           ▼
┌─────────────────────────────┐
│ predict.R                   │
│ - Load model (.rds)          │
│ - Detect new datasets        │
│ - Generate predictions      │
│ - Compute metrics            │
│ - Persist outputs            │
└──────────┬──────────────────┘
           │
           ▼
┌─────────────────────────────┐
│ monitor.R                   │
│ - Data drift detection       │
│ - Concept drift detection   │
│ - Append monitoring logs    │
│ - Raise alerts              │
└──────────┬──────────────────┘
           │
           ▼
┌─────────────────────────────┐
│ Git Commit & Push            │
│ - Predictions               │
│ - Metrics                   │
│ - Monitoring reports        │
│ - Drift alerts              │
└─────────────────────────────┘

4. Repository Structure
ml_deployment/
│
├── new_data/                     # Incoming batch data (CSV)
│
├── model/
│   ├── linear_model.rds          # Serialized trained model
│   └── baseline_stats.csv        # Baseline feature statistics
│
├── predictions/                  # Auto-generated artifacts
│   ├── pred_*.csv
│   ├── metrics_*.csv
│   ├── monitoring_report.csv
│   ├── drift_alerts.log
│   └── processed_files.txt
│
├── predict.R                     # Batch inference logic
├── monitor.R                     # Drift monitoring logic
│
└── .github/
    └── workflows/
        └── ml_pipeline.yml       # CI/CD workflow

5. Model Artifact (.rds) – Why This Matters
Why .rds?

.rds is the standard R serialization format

Enables:

Exact model reproducibility

Environment-agnostic loading

Version-controlled deployment

Mirrors how models are stored in:

S3

GCS

MLflow artifacts

Model registries

How it is used
model <- readRDS("model/linear_model.rds")


This simulates model loading in production, decoupled from training code.

6. CI/CD Workflow (ml_pipeline.yml) – Deep Technical Breakdown
Workflow Triggers
on:
  push:
    branches:
      - main
    paths:
      - "new_data/**"
      - "predict.R"
  workflow_dispatch:

What this means:
Trigger Type	Purpose
push	Automatically triggers pipeline when new data or inference code changes
paths	Prevents unnecessary runs (only data/code changes trigger inference)
workflow_dispatch	Enables manual execution from GitHub UI

 This supports both automation and controlled execution, exactly like real CI/CD pipelines.

Permissions (Critical for CD)
permissions:
  contents: write


This explicitly allows the workflow to:

Commit prediction outputs

Push monitoring artifacts

Update repository state

Without this, GitHub Actions would fail during git push.

Job Execution Flow (Sequential & Deterministic)
jobs:
  run-inference:
    runs-on: ubuntu-latest


GitHub spins up a clean Linux VM for every run.

Step-by-Step Execution
1️. Checkout Repository
- uses: actions/checkout@v3


Pulls the exact commit state

Ensures reproducibility

No hidden state from previous runs

2️. Setup R Runtime
- uses: r-lib/actions/setup-r@v2


Installs a fresh R environment

Guarantees consistent runtime behavior

3️. Install System Dependencies
sudo apt-get install -y \
  libcurl4-openssl-dev \
  libssl-dev \
  libxml2-dev \
  libfontconfig1-dev \
  ...


Why this is needed:

tidyverse depends on system-level libraries

CI environments are minimal by default

This mirrors Dockerfile system dependency layers

4️. Install R Packages
Rscript -e "install.packages('tidyverse', repos='https://cloud.r-project.org')"


Ensures clean dependency installation

Avoids relying on cached or local packages

Ensures deterministic builds

5️. Run Inference Script
Rscript predict.R


This is where CD (deployment) happens:

New data → Predictions

Outputs written to disk

Metrics generated

6️. Commit & Push Artifacts (CD)
git add predictions/
git commit -m "Update predictions and monitoring reports [CI]"
git push


This step:

Persists outputs

Creates an audit trail

Enables rollback and history tracking

7. Prediction Logic (predict.R) – Idempotency & Safety
Key Design Principle: Idempotency

The script never re-processes the same dataset twice.

processed_log <- "predictions/processed_files.txt"
processed_files <- readLines(processed_log)
new_files <- setdiff(all_files, processed_files)

Why this matters in production:

Prevents duplicate predictions

Avoids metric inflation

Ensures clean monitoring signals

Mimics batch-processing safeguards used in Airflow / Databricks

Conditional Evaluation Logic
if ("height" %in% colnames(ds)) {
  # compute RMSE, MAE, R2
}


Supports delayed labels

Works for:

Inference-only data

Backfilled ground truth

This is real-world ML behavior

8. Monitoring (monitor.R) – Production-Style Drift Detection
Data Drift

Compares incoming feature distributions vs baseline

Uses:

Mean shift

Standard deviation shift

Kolmogorov–Smirnov test

ks.test(current_data, baseline_distribution)

Concept Drift

Tracks model performance over time

Uses RMSE degradation threshold (>20%)

Flags when model behavior degrades

Monitoring Persistence (Append-Only)
final_report <- bind_rows(old_report, new_report)


Monitoring reports never overwrite

Enables:

Trend analysis

Historical auditing

Compliance readiness

9. What Happens When You Push 4 New Files?

All 4 CSVs are detected

All unprocessed files are inferred in one run

Each file generates:

pred_<dataset>.csv

metrics_<dataset>.csv

Monitoring runs on latest data

All outputs committed together

Pipeline remains consistent and atomic

10. Is This CI/CD?
 Continuous Integration

New data integrated continuously

New code integrated continuously

Validation and execution automated

 Continuous Deployment

Predictions deployed automatically

Metrics deployed automatically

Monitoring deployed automatically

This is a complete ML CI/CD pipeline.

11. Why This Matters for Recruiters

This project demonstrates:

Real ML system thinking

Production-grade automation

Monitoring beyond accuracy

CI/CD applied to ML, not just software

Awareness of NDA and professional constraints

12. Final Summary

✔ Automated batch inference
✔ CI/CD using GitHub Actions
✔ Model artifact management
✔ Drift monitoring
✔ Versioned outputs
✔ Production-oriented design

This project intentionally prioritizes MLOps maturity over model complexity, reflecting how real ML systems are built and maintained in industry.
