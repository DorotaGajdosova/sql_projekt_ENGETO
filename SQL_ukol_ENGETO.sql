-- =====================================================
-- SQL projekt: Analýza mezd, cen potravin a HDP v ČR
-- Autor: Dorota Gajdošová
-- =====================================================


-- =====================================================
-- Vytvoření primární tabulky
-- =====================================================

DROP TABLE IF EXISTS t_dorota_gajdosova_project_sql_primary_final;

CREATE TABLE t_dorota_gajdosova_project_sql_primary_final AS
WITH payroll_cte AS (
    SELECT
        cp.payroll_year AS year,
        cp.industry_branch_code,
        cpib.name AS industry_name,
        ROUND(AVG(cp.value)::numeric, 2) AS avg_wage
    FROM data_academy_content.czechia_payroll cp
    JOIN data_academy_content.czechia_payroll_industry_branch cpib
        ON cp.industry_branch_code = cpib.code
    WHERE cp.value_type_code = 5958
        AND cp.calculation_code = 200
        AND cp.industry_branch_code IS NOT NULL
    GROUP BY
        cp.payroll_year,
        cp.industry_branch_code,
        cpib.name
),
price_cte AS (
    SELECT
        EXTRACT(YEAR FROM cp.date_from)::int AS year,
        cp.category_code,
        cpc.name AS food_category,
        cpc.price_unit,
        ROUND(AVG(cp.value)::numeric, 2) AS avg_price
    FROM data_academy_content.czechia_price cp
    JOIN data_academy_content.czechia_price_category cpc
        ON cp.category_code = cpc.code
    GROUP BY
        EXTRACT(YEAR FROM cp.date_from)::int,
        cp.category_code,
        cpc.name,
        cpc.price_unit
)
SELECT
    p.year,
    p.industry_branch_code,
    p.industry_name,
    p.avg_wage,
    pr.category_code,
    pr.food_category,
    pr.price_unit,
    pr.avg_price
FROM payroll_cte p
JOIN price_cte pr
    ON p.year = pr.year;


-- Kontrola vytvořené primární tabulky
SELECT *
FROM t_dorota_gajdosova_project_sql_primary_final
LIMIT 10;


-- =====================================================
-- Otázka 1
-- Rostou v průběhu let mzdy ve všech odvětvích, nebo v některých klesají?
-- =====================================================

WITH wages AS (
    SELECT DISTINCT
        year,
        industry_branch_code,
        industry_name,
        avg_wage
    FROM t_dorota_gajdosova_project_sql_primary_final
),
wage_growth AS (
    SELECT
        year,
        industry_branch_code,
        industry_name,
        avg_wage,
        LAG(avg_wage) OVER (
            PARTITION BY industry_branch_code
            ORDER BY year
        ) AS prev_year_wage
    FROM wages
)
SELECT
    year,
    industry_name,
    avg_wage,
    prev_year_wage,
    ROUND(
        (
            ((avg_wage - prev_year_wage) / NULLIF(prev_year_wage, 0)) * 100
        )::numeric,
        2
    ) AS yoy_growth_percent
FROM wage_growth
WHERE prev_year_wage IS NOT NULL
ORDER BY industry_name, year;


-- Přehled odvětví a let, ve kterých došlo k poklesu mzdy
WITH wages AS (
    SELECT DISTINCT
        year,
        industry_branch_code,
        industry_name,
        avg_wage
    FROM t_dorota_gajdosova_project_sql_primary_final
),
wage_growth AS (
    SELECT
        year,
        industry_branch_code,
        industry_name,
        avg_wage,
        LAG(avg_wage) OVER (
            PARTITION BY industry_branch_code
            ORDER BY year
        ) AS prev_year_wage
    FROM wages
)
SELECT
    industry_name,
    year,
    avg_wage,
    prev_year_wage,
    ROUND(
        (
            ((avg_wage - prev_year_wage) / NULLIF(prev_year_wage, 0)) * 100
        )::numeric,
        2
    ) AS yoy_growth_percent
FROM wage_growth
WHERE prev_year_wage IS NOT NULL
  AND avg_wage < prev_year_wage
ORDER BY industry_name, year;


-- =====================================================
-- Otázka 2
-- Kolik litrů mléka a kilogramů chleba je možné koupit za první a poslední srovnatelné období?
-- =====================================================

-- Kontrola prvního a posledního společného roku
SELECT
    MIN(year) AS first_year,
    MAX(year) AS last_year
FROM t_dorota_gajdosova_project_sql_primary_final;


WITH wages AS (
    SELECT
        year,
        ROUND(AVG(avg_wage)::numeric, 2) AS avg_wage_all_industries
    FROM (
        SELECT DISTINCT
            year,
            industry_branch_code,
            avg_wage
        FROM t_dorota_gajdosova_project_sql_primary_final
    ) w
    GROUP BY year
),
prices AS (
    SELECT DISTINCT
        year,
        food_category,
        price_unit,
        avg_price
    FROM t_dorota_gajdosova_project_sql_primary_final
    WHERE food_category IN ('Chléb konzumní kmínový', 'Mléko polotučné pasterované')
),
comparison AS (
    SELECT
        w.year,
        w.avg_wage_all_industries,
        p.food_category,
        p.price_unit,
        p.avg_price,
        ROUND(
            (w.avg_wage_all_industries / NULLIF(p.avg_price, 0))::numeric,
            2
        ) AS amount_can_buy
    FROM wages w
    JOIN prices p
        ON w.year = p.year
)
SELECT *
FROM comparison
WHERE year IN (
    (SELECT MIN(year) FROM comparison),
    (SELECT MAX(year) FROM comparison)
)
ORDER BY year, food_category;


-- Kontrola názvů kategorií potravin
SELECT DISTINCT
    food_category
FROM t_dorota_gajdosova_project_sql_primary_final
ORDER BY food_category;


-- =====================================================
-- Otázka 3A
-- Která kategorie potravin zdražuje nejpomaleji?
-- =====================================================

WITH prices AS (
    SELECT DISTINCT
        year,
        category_code,
        food_category,
        avg_price
    FROM t_dorota_gajdosova_project_sql_primary_final
),
price_growth AS (
    SELECT
        year,
        category_code,
        food_category,
        avg_price,
        LAG(avg_price) OVER (
            PARTITION BY category_code
            ORDER BY year
        ) AS prev_price
    FROM prices
),
growth_calc AS (
    SELECT
        year,
        category_code,
        food_category,
        ROUND(
            (
                ((avg_price - prev_price) / NULLIF(prev_price, 0)) * 100
            )::numeric,
            2
        ) AS yoy_growth_percent
    FROM price_growth
    WHERE prev_price IS NOT NULL
)
SELECT
    food_category,
    ROUND(AVG(yoy_growth_percent)::numeric, 2) AS avg_yoy_growth_percent
FROM growth_calc
GROUP BY food_category
ORDER BY avg_yoy_growth_percent;


-- =====================================================
-- Otázka 3B
-- Existuje rok, ve kterém byl meziroční nárůst cen potravin výrazně vyšší než růst mezd (více než 10 %)?
-- =====================================================

WITH wages AS (
    SELECT DISTINCT
        year,
        industry_branch_code,
        avg_wage
    FROM t_dorota_gajdosova_project_sql_primary_final
),
wage_growth AS (
    SELECT
        year,
        industry_branch_code,
        ROUND(
            (
                (
                    avg_wage - LAG(avg_wage) OVER (
                        PARTITION BY industry_branch_code
                        ORDER BY year
                    )
                ) / NULLIF(
                    LAG(avg_wage) OVER (
                        PARTITION BY industry_branch_code
                        ORDER BY year
                    ),
                    0
                ) * 100
            )::numeric,
            2
        ) AS wage_yoy
    FROM wages
),
wage_growth_by_year AS (
    SELECT
        year,
        ROUND(AVG(wage_yoy)::numeric, 2) AS avg_wage_yoy
    FROM wage_growth
    WHERE wage_yoy IS NOT NULL
    GROUP BY year
),
prices AS (
    SELECT DISTINCT
        year,
        category_code,
        avg_price
    FROM t_dorota_gajdosova_project_sql_primary_final
),
price_growth AS (
    SELECT
        year,
        category_code,
        ROUND(
            (
                (
                    avg_price - LAG(avg_price) OVER (
                        PARTITION BY category_code
                        ORDER BY year
                    )
                ) / NULLIF(
                    LAG(avg_price) OVER (
                        PARTITION BY category_code
                        ORDER BY year
                    ),
                    0
                ) * 100
            )::numeric,
            2
        ) AS price_yoy
    FROM prices
),
price_growth_by_year AS (
    SELECT
        year,
        ROUND(AVG(price_yoy)::numeric, 2) AS avg_price_yoy
    FROM price_growth
    WHERE price_yoy IS NOT NULL
    GROUP BY year
)
SELECT
    p.year,
    p.avg_price_yoy,
    w.avg_wage_yoy,
    ROUND((p.avg_price_yoy - w.avg_wage_yoy)::numeric, 2) AS difference
FROM price_growth_by_year p
JOIN wage_growth_by_year w
    ON p.year = w.year
WHERE (p.avg_price_yoy - w.avg_wage_yoy) > 10
ORDER BY p.year;


-- =====================================================
-- Vytvoření sekundární tabulky
-- =====================================================

DROP TABLE IF EXISTS t_dorota_gajdosova_project_sql_secondary_final;

CREATE TABLE t_dorota_gajdosova_project_sql_secondary_final AS
SELECT
    e.year,
    e.country,
    e.GDP
FROM data_academy_content.economies e
WHERE e.country = 'Czech Republic';


-- Kontrola vytvořené sekundární tabulky
SELECT *
FROM t_dorota_gajdosova_project_sql_secondary_final
ORDER BY year;


-- =====================================================
-- Otázka 4A
-- Má výška HDP vliv na změny ve mzdách a cenách potravin ve stejném roce?
-- =====================================================

WITH gdp AS (
    SELECT
        year,
        GDP,
        ROUND(
            (
                (
                    GDP - LAG(GDP) OVER (ORDER BY year)
                ) / NULLIF(LAG(GDP) OVER (ORDER BY year), 0) * 100
            )::numeric,
            2
        ) AS gdp_yoy
    FROM t_dorota_gajdosova_project_sql_secondary_final
),
wages AS (
    SELECT DISTINCT
        year,
        industry_branch_code,
        avg_wage
    FROM t_dorota_gajdosova_project_sql_primary_final
),
wage_growth_detail AS (
    SELECT
        year,
        industry_branch_code,
        (
            (
                avg_wage - LAG(avg_wage) OVER (
                    PARTITION BY industry_branch_code
                    ORDER BY year
                )
            ) / NULLIF(
                LAG(avg_wage) OVER (
                    PARTITION BY industry_branch_code
                    ORDER BY year
                ),
                0
            ) * 100
        ) AS wage_yoy
    FROM wages
),
wage_growth AS (
    SELECT
        year,
        ROUND(AVG(wage_yoy)::numeric, 2) AS avg_wage_yoy
    FROM wage_growth_detail
    WHERE wage_yoy IS NOT NULL
    GROUP BY year
),
prices AS (
    SELECT DISTINCT
        year,
        category_code,
        avg_price
    FROM t_dorota_gajdosova_project_sql_primary_final
),
price_growth_detail AS (
    SELECT
        year,
        category_code,
        (
            (
                avg_price - LAG(avg_price) OVER (
                    PARTITION BY category_code
                    ORDER BY year
                )
            ) / NULLIF(
                LAG(avg_price) OVER (
                    PARTITION BY category_code
                    ORDER BY year
                ),
                0
            ) * 100
        ) AS price_yoy
    FROM prices
),
price_growth AS (
    SELECT
        year,
        ROUND(AVG(price_yoy)::numeric, 2) AS avg_price_yoy
    FROM price_growth_detail
    WHERE price_yoy IS NOT NULL
    GROUP BY year
)
SELECT
    g.year,
    g.gdp_yoy,
    w.avg_wage_yoy,
    p.avg_price_yoy
FROM gdp g
JOIN wage_growth w
    ON g.year = w.year
JOIN price_growth p
    ON g.year = p.year
WHERE g.gdp_yoy IS NOT NULL
ORDER BY g.year;


-- =====================================================
-- Otázka 4B
-- Projeví se výraznější růst HDP v jednom roce na mzdách a cenách potravin v následujícím roce?
-- =====================================================

WITH gdp AS (
    SELECT
        year,
        ROUND(
            (
                (
                    GDP - LAG(GDP) OVER (ORDER BY year)
                ) / NULLIF(LAG(GDP) OVER (ORDER BY year), 0) * 100
            )::numeric,
            2
        ) AS gdp_yoy
    FROM t_dorota_gajdosova_project_sql_secondary_final
),
wages AS (
    SELECT DISTINCT
        year,
        industry_branch_code,
        avg_wage
    FROM t_dorota_gajdosova_project_sql_primary_final
),
wage_growth_detail AS (
    SELECT
        year,
        industry_branch_code,
        (
            (
                avg_wage - LAG(avg_wage) OVER (
                    PARTITION BY industry_branch_code
                    ORDER BY year
                )
            ) / NULLIF(
                LAG(avg_wage) OVER (
                    PARTITION BY industry_branch_code
                    ORDER BY year
                ),
                0
            ) * 100
        ) AS wage_yoy
    FROM wages
),
wage_growth AS (
    SELECT
        year,
        ROUND(AVG(wage_yoy)::numeric, 2) AS avg_wage_yoy
    FROM wage_growth_detail
    WHERE wage_yoy IS NOT NULL
    GROUP BY year
),
prices AS (
    SELECT DISTINCT
        year,
        category_code,
        avg_price
    FROM t_dorota_gajdosova_project_sql_primary_final
),
price_growth_detail AS (
    SELECT
        year,
        category_code,
        (
            (
                avg_price - LAG(avg_price) OVER (
                    PARTITION BY category_code
                    ORDER BY year
                )
            ) / NULLIF(
                LAG(avg_price) OVER (
                    PARTITION BY category_code
                    ORDER BY year
                ),
                0
            ) * 100
        ) AS price_yoy
    FROM prices
),
price_growth AS (
    SELECT
        year,
        ROUND(AVG(price_yoy)::numeric, 2) AS avg_price_yoy
    FROM price_growth_detail
    WHERE price_yoy IS NOT NULL
    GROUP BY year
)
SELECT
    g.year AS gdp_year,
    g.gdp_yoy,
    w.year AS compared_year,
    w.avg_wage_yoy,
    p.avg_price_yoy
FROM gdp g
JOIN wage_growth w
    ON g.year + 1 = w.year
JOIN price_growth p
    ON g.year + 1 = p.year
WHERE g.gdp_yoy IS NOT NULL
ORDER BY g.year;
