# LAYOFF_DATA_CLEANING & EDA (SQL PROJECT)
This project focuses on how to clean raw layoff data and perform EDA using MYSQL.
The workflow follows the systematic approach:-
1. Creating Staging table
2. Cleaning duplicates
3. Standardizing data
4. Analyzing layoff trends
---

# PROJECT STEPS
## 1. Create Stage Tables
Backed up raw data into staging table `layoff_staging`.

`CREATE TABLE layoff_staging LIKE layoffs;`
`INSERT INTO layoff_staging SELECT * FROM layoffs;`
 
