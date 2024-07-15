SELECT * FROM layoffs;

-- 1. Menghapus Duplikat
-- 2, Standarisasi Data
-- 3. Mengisi / Menghapus nilai null atau kosong
-- 4. Menghapus kolom yang tidak diperlukan

-- Membuat duplikat table untuk menghindari perubahan pada data asli
CREATE TABLE layoffs_staging
LIKE layoffs;

SELECT * FROM layoffs_staging;

-- Mengisi table baru dengan data pada table asli
INSERT layoffs_staging
SELECT *
FROM layoffs;

SELECT *,
ROW_NUMBER() OVER(
PARTITION BY company, industry, total_laid_off, percentage_laid_off, date, location, stage, country, funds_raised_millions) AS row_num
FROM layoffs_staging;

-- Melihat data yang memiliki duplikat
WITH duplicate_cte AS
(
SELECT *,
ROW_NUMBER() OVER(
PARTITION BY company, industry, total_laid_off, percentage_laid_off, date, location, stage, country, funds_raised_millions) AS row_num
FROM layoffs_staging
)
SELECT *
FROM duplicate_cte
WHERE row_num > 1;

SELECT *
FROM layoffs_staging
WHERE company = 'casper';

-- Membuat table baru untuk mempermudah membersihkan data duplikat
CREATE TABLE `layoffs_staging2` (
  `company` text,
  `location` text,
  `industry` text,
  `total_laid_off` int DEFAULT NULL,
  `percentage_laid_off` text,
  `date` text,
  `stage` text,
  `country` text,
  `funds_raised_millions` int DEFAULT NULL,
  `row_num` int -- ini adalah kolom untuk melihat apakah terdapat data yang duplikat, ditandai dengan row num > 1
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

INSERT INTO layoffs_staging2
SELECT *,
ROW_NUMBER() OVER(
PARTITION BY company, location, industry, total_laid_off, percentage_laid_off, date, stage, country, funds_raised_millions) AS row_num
FROM layoffs_staging;

SELECT * FROM layoffs_staging2;

-- Menghapus data duplikat
DELETE
FROM layoffs_staging2
WHERE row_num > 1;

-- 2. Standarisasi Data

-- Menghapus kata yang terdapat "SPASI"
SELECT company, TRIM(company)
FROM layoffs_staging2;

UPDATE layoffs_staging2
SET company = TRIM(company);

SELECT * FROM layoffs_staging2;

-- Menyamakan nama industry yang serupa
SELECT DISTINCT industry
FROM layoffs_staging2
ORDER BY 1 ASC;

UPDATE layoffs_staging2
SET industry = 'Crypto'
WHERE industry LIKE 'Crypto%';

-- Mengapus nama negara yang memiliki titik diakhir nama
SELECT DISTINCT country
FROM layoffs_staging2
ORDER BY 1 ASC;

SELECT DISTINCT country, TRIM(TRAILING '.' FROM country)
FROM layoffs_staging2
ORDER BY 1 ASC;

UPDATE layoffs_staging2
SET country = TRIM(TRAILING '.' FROM country)
WHERE country LIKE 'United States%';

-- Mengubah tipe data string ke date
SELECT `date`
FROM layoffs_staging2;

UPDATE layoffs_staging2
SET `date` = STR_TO_DATE(`date`, '%m/%d/%Y');

ALTER TABLE layoffs_staging2
MODIFY COLUMN `date` DATE;


-- Mengisi nama industri yang kosong dengan menyamakan dengan nama company yang serupa
SELECT * 
FROM layoffs_staging2
WHERE industry IS NULL
OR industry = '';

SELECT t1.company, t1.industry, t2.industry
FROM layoffs_staging2 t1
JOIN layoffs_staging2 t2
	ON t2.location = t1.location
    AND t2.company = t1.company
WHERE (t1.industry IS NULL OR t1.industry = '')
AND t2.industry IS NOT NULL;

UPDATE layoffs_staging2
SET industry = NULL
WHERE industry = '';

UPDATE layoffs_staging2 t1
JOIN layoffs_staging2 t2
	ON t1.company = t2.company
SET t1.industry = t2.industry
WHERE t1.industry IS NULL
AND t2.industry IS NOT NULL;

SELECT *
FROM layoffs_staging2
WHERE industry IS NULL;

-- Menghapus data total laid off dan percenage laid off yang memiliki nilai NULL
SELECT *
FROM layoffs_staging2
WHERE total_laid_off IS NULL 
AND percentage_laid_off IS NULL;

DELETE 
FROM layoffs_staging2
WHERE total_laid_off IS NULL 
AND percentage_laid_off IS NULL;

SELECT *
FROM layoffs_staging2;

-- Menghapus kolom row num 
ALTER TABLE layoffs_staging2
DROP COLUMN row_num;




