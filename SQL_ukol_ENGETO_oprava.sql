-- =====================================================
-- SQL projekt: Analýza mezd, cen potravin a HDP v ČR
-- Autor: Dorota Gajdošová
-- Engeto SQL projekt
-- =====================================================

/*
Úvod:
V tomto projektu pracuji s daty o mzdách, cenách potravin a ekonomickými údaji.
Nejdříve vytvářím dvě výsledné tabulky podle zadání a potom nad nimi řeším jednotlivé výzkumné otázky.

Primární tabulka obsahuje průměrné mzdy podle odvětví a průměrné ceny potravin v jednotlivých letech.
Sekundární tabulka obsahuje ekonomické ukazatele evropských států, konkrétně HDP, GINI koeficient a populaci.
U každé otázky je uveden SQL dotaz i krátká interpretace výsledku.
*/


-- =====================================================
-- ÚKOL 1: Vytvoření primární tabulky
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


-- Kontrola primární tabulky
SELECT *
FROM t_dorota_gajdosova_project_sql_primary_final
LIMIT 10;


-- =====================================================
-- ÚKOL 2: Vytvoření sekundární tabulky
-- Zadání: HDP, GINI koeficient a populace evropských států
-- =====================================================

DROP TABLE IF EXISTS t_dorota_gajdosova_project_sql_secondary_final;

CREATE TABLE t_dorota_gajdosova_project_sql_secondary_final AS
SELECT
    e.country,
    e.year,
    e.GDP,
    e.gini,
    e.population
FROM data_academy_content.economies e
JOIN data_academy_content.countries c
    ON e.country = c.country
WHERE c.continent = 'Europe'
  AND e.year BETWEEN (
      SELECT MIN(year)
      FROM t_dorota_gajdosova_project_sql_primary_final
  )
  AND (
      SELECT MAX(year)
      FROM t_dorota_gajdosova_project_sql_primary_final
  )
ORDER BY e.country, e.year;


-- Kontrola sekundární tabulky
SELECT *
FROM t_dorota_gajdosova_project_sql_secondary_final
ORDER BY country, year;


-- =====================================================
-- OTÁZKA 1
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
        (((avg_wage - prev_year_wage) / NULLIF(prev_year_wage, 0)) * 100)::numeric,
        2
    ) AS yoy_growth_percent
FROM wage_growth
WHERE prev_year_wage IS NOT NULL
ORDER BY industry_name, year;


-- Souhrn pro interpretaci otázky 1
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
),
decreases AS (
    SELECT *
    FROM wage_growth
    WHERE prev_year_wage IS NOT NULL
      AND avg_wage < prev_year_wage
)
SELECT
    COUNT(*) AS number_of_wage_decreases,
    COUNT(DISTINCT industry_branch_code) AS industries_with_decrease,
    MIN(year) AS first_year_with_decrease,
    MAX(year) AS last_year_with_decrease
FROM decreases;


-- Přehled konkrétních odvětví a let, ve kterých došlo k poklesu mzdy
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
        (((avg_wage - prev_year_wage) / NULLIF(prev_year_wage, 0)) * 100)::numeric,
        2
    ) AS yoy_growth_percent
FROM wage_growth
WHERE prev_year_wage IS NOT NULL
  AND avg_wage < prev_year_wage
ORDER BY industry_name, year;

/*
Odpověď na otázku 1:
Mzdy ve sledovaném období celkově spíše rostly, ale ne ve všech odvětvích a ne v každém roce.
Souhrnný výstup ukazuje, kolikrát se v datech objevil meziroční pokles mzdy a kolika odvětví se týkal.
Podrobný výstup potom vypisuje konkrétní odvětví, rok, aktuální mzdu, mzdu z předchozího roku a procentuální pokles - odpověď je přímo podložená daty.
*/


-- =====================================================
-- OTÁZKA 2
-- Kolik litrů mléka a kilogramů chleba je možné koupit
-- za první a poslední srovnatelné období?
-- =====================================================

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
        ROUND((w.avg_wage_all_industries / NULLIF(p.avg_price, 0))::numeric, 2) AS amount_can_buy
    FROM wages w
    JOIN prices p
        ON w.year = p.year
)
SELECT *
FROM comparison
WHERE year IN (
    SELECT MIN(year) FROM comparison
    UNION
    SELECT MAX(year) FROM comparison
)
ORDER BY year, food_category;


-- Souhrn pro interpretaci otázky 2
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
        ROUND((w.avg_wage_all_industries / NULLIF(p.avg_price, 0))::numeric, 2) AS amount_can_buy
    FROM wages w
    JOIN prices p
        ON w.year = p.year
),
first_last AS (
    SELECT *
    FROM comparison
    WHERE year IN (
        SELECT MIN(year) FROM comparison
        UNION
        SELECT MAX(year) FROM comparison
    )
)
SELECT
    food_category,
    price_unit,
    MAX(CASE WHEN year = (SELECT MIN(year) FROM first_last) THEN year END) AS first_year,
    MAX(CASE WHEN year = (SELECT MIN(year) FROM first_last) THEN amount_can_buy END) AS amount_first_year,
    MAX(CASE WHEN year = (SELECT MAX(year) FROM first_last) THEN year END) AS last_year,
    MAX(CASE WHEN year = (SELECT MAX(year) FROM first_last) THEN amount_can_buy END) AS amount_last_year,
    ROUND(
        (
            MAX(CASE WHEN year = (SELECT MAX(year) FROM first_last) THEN amount_can_buy END)
            - MAX(CASE WHEN year = (SELECT MIN(year) FROM first_last) THEN amount_can_buy END)
        )::numeric,
        2
    ) AS difference_in_amount
FROM first_last
GROUP BY food_category, price_unit
ORDER BY food_category;

/*
Odpověď na otázku 2:
Výstup porovnává první a poslední společný rok, pro který jsou dostupná data o mzdách i cenách vybraných potravin.
Sloupec amount_can_buy ukazuje, kolik kilogramů chleba nebo litrů mléka bylo možné koupit za průměrnou mzdu napříč odvětvími.
Souhrnný výstup zároveň ukazuje rozdíl mezi prvním a posledním rokem, takže je z něj vidět, zda kupní síla vůči chlebu a mléku vzrostla nebo klesla.
*/


-- =====================================================
-- OTÁZKA 3
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
            (((avg_price - prev_price) / NULLIF(prev_price, 0)) * 100)::numeric,
            2
        ) AS yoy_growth_percent
    FROM price_growth
    WHERE prev_price IS NOT NULL
),
avg_growth AS (
    SELECT
        food_category,
        ROUND(AVG(yoy_growth_percent)::numeric, 2) AS avg_yoy_growth_percent
    FROM growth_calc
    GROUP BY food_category
)
SELECT
    food_category,
    avg_yoy_growth_percent
FROM avg_growth
ORDER BY avg_yoy_growth_percent
LIMIT 1;


-- Celkové pořadí kategorií podle průměrného meziročního růstu cen
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
            (((avg_price - prev_price) / NULLIF(prev_price, 0)) * 100)::numeric,
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

/*
Odpověď na otázku 3:
Nejpomaleji zdražující potravinou je kategorie s nejnižším průměrným meziročním růstem ceny.
První výstup vrací přímo tuto jednu kategorii a její průměrný meziroční růst v procentech.
Druhý výstup nechávám jako kontrolní pořadí všech potravin; pokud některá hodnota vyjde záporně, znamená to, že daná potravina ve sledovaném období v průměru spíše zlevňovala.
*/


-- =====================================================
-- OTÁZKA 4
-- Existuje rok, ve kterém byl meziroční nárůst cen potravin
-- výrazně vyšší než růst mezd, a to o více než 10 procentních bodů?
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
price_growth_by_year AS (
    SELECT
        year,
        ROUND(AVG(price_yoy)::numeric, 2) AS avg_price_yoy
    FROM price_growth
    WHERE price_yoy IS NOT NULL
    GROUP BY year
),
comparison AS (
    SELECT
        p.year,
        p.avg_price_yoy,
        w.avg_wage_yoy,
        ROUND((p.avg_price_yoy - w.avg_wage_yoy)::numeric, 2) AS difference_percentage_points
    FROM price_growth_by_year p
    JOIN wage_growth_by_year w
        ON p.year = w.year
)
SELECT *
FROM comparison
WHERE difference_percentage_points > 10
ORDER BY year;


-- Souhrn všech let pro otázku 4, včetně největšího rozdílu mezi růstem cen a mezd
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
price_growth_by_year AS (
    SELECT
        year,
        ROUND(AVG(price_yoy)::numeric, 2) AS avg_price_yoy
    FROM price_growth
    WHERE price_yoy IS NOT NULL
    GROUP BY year
),
comparison AS (
    SELECT
        p.year,
        p.avg_price_yoy,
        w.avg_wage_yoy,
        ROUND((p.avg_price_yoy - w.avg_wage_yoy)::numeric, 2) AS difference_percentage_points
    FROM price_growth_by_year p
    JOIN wage_growth_by_year w
        ON p.year = w.year
)
SELECT *
FROM comparison
ORDER BY difference_percentage_points DESC;

/*
Odpověď na otázku 4:
V této části porovnávám průměrný meziroční růst cen potravin s průměrným meziročním růstem mezd.
První výstup ukazuje pouze roky, kdy byl růst cen potravin vyšší než růst mezd o více než 10 procentních bodů.
Druhý výstup řadí všechny roky podle rozdílu mezi růstem cen a mezd, takže je možné doložit i to, ve kterém roce byl rozdíl největší.
*/


-- =====================================================
-- OTÁZKA 5A
-- Má výška HDP vliv na změny ve mzdách a cenách potravin
-- ve stejném roce?
-- =====================================================

WITH gdp AS (
    SELECT
        year,
        GDP,
        ROUND(
            (
                (GDP - LAG(GDP) OVER (ORDER BY year))
                / NULLIF(LAG(GDP) OVER (ORDER BY year), 0) * 100
            )::numeric,
            2
        ) AS gdp_yoy
    FROM t_dorota_gajdosova_project_sql_secondary_final
    WHERE country = 'Czech Republic'
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
            (avg_wage - LAG(avg_wage) OVER (
                PARTITION BY industry_branch_code
                ORDER BY year
            ))
            / NULLIF(LAG(avg_wage) OVER (
                PARTITION BY industry_branch_code
                ORDER BY year
            ), 0) * 100
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
            (avg_price - LAG(avg_price) OVER (
                PARTITION BY category_code
                ORDER BY year
            ))
            / NULLIF(LAG(avg_price) OVER (
                PARTITION BY category_code
                ORDER BY year
            ), 0) * 100
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
),
comparison AS (
    SELECT
        g.year,
        g.GDP,
        g.gdp_yoy,
        w.avg_wage_yoy,
        p.avg_price_yoy
    FROM gdp g
    JOIN wage_growth w
        ON g.year = w.year
    JOIN price_growth p
        ON g.year = p.year
    WHERE g.gdp_yoy IS NOT NULL
)
SELECT *
FROM comparison
ORDER BY year;


-- Orientační korelace mezi změnou HDP, mezd a cen ve stejném roce
WITH gdp AS (
    SELECT
        year,
        (
            (GDP - LAG(GDP) OVER (ORDER BY year))
            / NULLIF(LAG(GDP) OVER (ORDER BY year), 0) * 100
        ) AS gdp_yoy
    FROM t_dorota_gajdosova_project_sql_secondary_final
    WHERE country = 'Czech Republic'
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
            (avg_wage - LAG(avg_wage) OVER (
                PARTITION BY industry_branch_code
                ORDER BY year
            ))
            / NULLIF(LAG(avg_wage) OVER (
                PARTITION BY industry_branch_code
                ORDER BY year
            ), 0) * 100
        ) AS wage_yoy
    FROM wages
),
wage_growth AS (
    SELECT
        year,
        AVG(wage_yoy) AS avg_wage_yoy
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
            (avg_price - LAG(avg_price) OVER (
                PARTITION BY category_code
                ORDER BY year
            ))
            / NULLIF(LAG(avg_price) OVER (
                PARTITION BY category_code
                ORDER BY year
            ), 0) * 100
        ) AS price_yoy
    FROM prices
),
price_growth AS (
    SELECT
        year,
        AVG(price_yoy) AS avg_price_yoy
    FROM price_growth_detail
    WHERE price_yoy IS NOT NULL
    GROUP BY year
),
comparison AS (
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
)
SELECT
    ROUND(CORR(gdp_yoy, avg_wage_yoy)::numeric, 3) AS corr_gdp_wages_same_year,
    ROUND(CORR(gdp_yoy, avg_price_yoy)::numeric, 3) AS corr_gdp_prices_same_year
FROM comparison;

/*
Odpověď na otázku 5A:
Výstup porovnává meziroční změnu HDP, mezd a cen potravin ve stejném roce.
Pro lepší oporu v datech je doplněná také orientační korelace mezi růstem HDP a růstem mezd a mezi růstem HDP a růstem cen.
Výsledek je vhodné brát jako popisnou analýzu vztahu mezi ukazateli, ne jako důkaz příčinné závislosti.
*/


-- =====================================================
-- OTÁZKA 5B
-- Projeví se změna HDP v jednom roce na mzdách a cenách potravin
-- v následujícím roce?
-- =====================================================

WITH gdp AS (
    SELECT
        year,
        ROUND(
            (
                (GDP - LAG(GDP) OVER (ORDER BY year))
                / NULLIF(LAG(GDP) OVER (ORDER BY year), 0) * 100
            )::numeric,
            2
        ) AS gdp_yoy
    FROM t_dorota_gajdosova_project_sql_secondary_final
    WHERE country = 'Czech Republic'
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
            (avg_wage - LAG(avg_wage) OVER (
                PARTITION BY industry_branch_code
                ORDER BY year
            ))
            / NULLIF(LAG(avg_wage) OVER (
                PARTITION BY industry_branch_code
                ORDER BY year
            ), 0) * 100
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
            (avg_price - LAG(avg_price) OVER (
                PARTITION BY category_code
                ORDER BY year
            ))
            / NULLIF(LAG(avg_price) OVER (
                PARTITION BY category_code
                ORDER BY year
            ), 0) * 100
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
),
comparison AS (
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
)
SELECT *
FROM comparison
ORDER BY gdp_year;


-- Orientační korelace mezi změnou HDP a změnou mezd/cen v následujícím roce
WITH gdp AS (
    SELECT
        year,
        (
            (GDP - LAG(GDP) OVER (ORDER BY year))
            / NULLIF(LAG(GDP) OVER (ORDER BY year), 0) * 100
        ) AS gdp_yoy
    FROM t_dorota_gajdosova_project_sql_secondary_final
    WHERE country = 'Czech Republic'
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
            (avg_wage - LAG(avg_wage) OVER (
                PARTITION BY industry_branch_code
                ORDER BY year
            ))
            / NULLIF(LAG(avg_wage) OVER (
                PARTITION BY industry_branch_code
                ORDER BY year
            ), 0) * 100
        ) AS wage_yoy
    FROM wages
),
wage_growth AS (
    SELECT
        year,
        AVG(wage_yoy) AS avg_wage_yoy
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
            (avg_price - LAG(avg_price) OVER (
                PARTITION BY category_code
                ORDER BY year
            ))
            / NULLIF(LAG(avg_price) OVER (
                PARTITION BY category_code
                ORDER BY year
            ), 0) * 100
        ) AS price_yoy
    FROM prices
),
price_growth AS (
    SELECT
        year,
        AVG(price_yoy) AS avg_price_yoy
    FROM price_growth_detail
    WHERE price_yoy IS NOT NULL
    GROUP BY year
),
comparison AS (
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
)
SELECT
    ROUND(CORR(gdp_yoy, avg_wage_yoy)::numeric, 3) AS corr_gdp_wages_next_year,
    ROUND(CORR(gdp_yoy, avg_price_yoy)::numeric, 3) AS corr_gdp_prices_next_year
FROM comparison;

/*
Odpověď na otázku 5B:
Tato část porovnává meziroční změnu HDP s růstem mezd a cen potravin v následujícím roce.
Díky tomu lze posoudit, zda se vývoj HDP mohl projevit se zpožděním jednoho roku.
Kromě přehledu po letech je doplněná také orientační korelace, ale i zde platí, že jde o popisné porovnání dat, ne o statistický důkaz kauzality.
*/


-- =====================================================
-- Závěr projektu
-- =====================================================

/*
Závěr:
V projektu jsem vytvořila primární a sekundární tabulku podle zadání. Primární tabulka spojuje údaje o mzdách a cenách potravin, sekundární tabulka doplňuje HDP, GINI koeficient a populaci evropských států.

Na základě dotazů je možné posoudit, že mzdy mají převážně rostoucí trend, ale v některých odvětvích a letech se objevují i meziroční poklesy. U chleba a mléka jsem porovnala kupní sílu průměrné mzdy v prvním a posledním dostupném období. U všech potravin jsem dále spočítala průměrný meziroční růst cen a určila kategorii, která zdražovala nejpomaleji.

V poslední části jsem porovnala vývoj HDP s vývojem mezd a cen potravin ve stejném i následujícím roce. Výstupy doplňují hodnoty meziročních změn i orientační korelace, takže odpovědi jsou podložené konkrétními daty ze SQL dotazů. Výsledky ale interpretuji opatrně, protože samotné SQL porovnání neprokazuje příčinný vztah mezi HDP, mzdami a cenami.
*/


-- =====================================================
-- FINÁLNÍ ODPOVĚDI NA VÝZKUMNÉ OTÁZKY
-- Tyto dotazy vrací konkrétní texty s čísly z dat.
-- Výstupy můžeš zkopírovat do závěrečné interpretace projektu.
-- =====================================================

-- =====================================================
-- FINÁLNÍ ODPOVĚĎ 1
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
),
decreases AS (
    SELECT *
    FROM wage_growth
    WHERE prev_year_wage IS NOT NULL
      AND avg_wage < prev_year_wage
),
summary AS (
    SELECT
        COUNT(*) AS number_of_wage_decreases,
        COUNT(DISTINCT industry_branch_code) AS industries_with_decrease,
        MIN(year) AS first_year_with_decrease,
        MAX(year) AS last_year_with_decrease
    FROM decreases
),
example_decreases AS (
    SELECT
        STRING_AGG(industry_name || ' (' || year || ')', ', ' ORDER BY industry_name, year) AS examples
    FROM (
        SELECT industry_name, year
        FROM decreases
        ORDER BY year, industry_name
        LIMIT 5
    ) x
)
SELECT
    'Mzdy ve sledovaném období nerostly úplně ve všech odvětvích a ve všech letech. ' ||
    'Meziroční pokles mzdy se v datech objevil celkem ' || s.number_of_wage_decreases ||
    'krát a týkal se ' || s.industries_with_decrease || ' různých odvětví. ' ||
    'První pokles je zachycen v roce ' || s.first_year_with_decrease ||
    ' a poslední v roce ' || s.last_year_with_decrease ||
    '; mezi příklady patří: ' || COALESCE(e.examples, 'v datech nebyl nalezen žádný pokles') || '.'
    AS final_answer_question_1
FROM summary s
CROSS JOIN example_decreases e;


-- =====================================================
-- FINÁLNÍ ODPOVĚĎ 2
-- Kolik litrů mléka a kilogramů chleba je možné koupit za první a poslední srovnatelné období?
-- =====================================================

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
        ROUND((w.avg_wage_all_industries / NULLIF(p.avg_price, 0))::numeric, 2) AS amount_can_buy
    FROM wages w
    JOIN prices p
        ON w.year = p.year
),
first_last AS (
    SELECT *
    FROM comparison
    WHERE year IN (
        SELECT MIN(year) FROM comparison
        UNION
        SELECT MAX(year) FROM comparison
    )
),
summary AS (
    SELECT
        food_category,
        price_unit,
        MAX(CASE WHEN year = (SELECT MIN(year) FROM first_last) THEN year END) AS first_year,
        MAX(CASE WHEN year = (SELECT MIN(year) FROM first_last) THEN amount_can_buy END) AS amount_first_year,
        MAX(CASE WHEN year = (SELECT MAX(year) FROM first_last) THEN year END) AS last_year,
        MAX(CASE WHEN year = (SELECT MAX(year) FROM first_last) THEN amount_can_buy END) AS amount_last_year,
        ROUND((
            MAX(CASE WHEN year = (SELECT MAX(year) FROM first_last) THEN amount_can_buy END)
            - MAX(CASE WHEN year = (SELECT MIN(year) FROM first_last) THEN amount_can_buy END)
        )::numeric, 2) AS difference_in_amount
    FROM first_last
    GROUP BY food_category, price_unit
),
bread AS (
    SELECT *
    FROM summary
    WHERE food_category = 'Chléb konzumní kmínový'
),
milk AS (
    SELECT *
    FROM summary
    WHERE food_category = 'Mléko polotučné pasterované'
)
SELECT
    'V prvním srovnatelném roce ' || b.first_year ||
    ' bylo možné za průměrnou mzdu koupit přibližně ' || b.amount_first_year ||
    ' kg chleba a ' || m.amount_first_year || ' l mléka. ' ||
    'V posledním srovnatelném roce ' || b.last_year ||
    ' to bylo přibližně ' || b.amount_last_year || ' kg chleba a ' ||
    m.amount_last_year || ' l mléka. ' ||
    'Kupní síla se tedy u chleba změnila o ' || b.difference_in_amount ||
    ' kg a u mléka o ' || m.difference_in_amount || ' l.'
    AS final_answer_question_2
FROM bread b
CROSS JOIN milk m;


-- =====================================================
-- FINÁLNÍ ODPOVĚĎ 3
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
        ROUND((((avg_price - prev_price) / NULLIF(prev_price, 0)) * 100)::numeric, 2) AS yoy_growth_percent
    FROM price_growth
    WHERE prev_price IS NOT NULL
),
avg_growth AS (
    SELECT
        food_category,
        ROUND(AVG(yoy_growth_percent)::numeric, 2) AS avg_yoy_growth_percent
    FROM growth_calc
    GROUP BY food_category
),
slowest AS (
    SELECT *
    FROM avg_growth
    ORDER BY avg_yoy_growth_percent
    LIMIT 1
)
SELECT
    'Nejpomaleji zdražující kategorií potravin je ' || food_category ||
    ', u které vyšel průměrný meziroční růst cen ' || avg_yoy_growth_percent || ' %. ' ||
    'Tato hodnota je nejnižší ze všech sledovaných kategorií potravin. ' ||
    'Pokud je hodnota záporná, znamená to, že tato potravina ve sledovaném období v průměru spíše zlevňovala než zdražovala.'
    AS final_answer_question_3
FROM slowest;


-- =====================================================
-- FINÁLNÍ ODPOVĚĎ 4
-- Existuje rok, ve kterém byl meziroční nárůst cen potravin výrazně vyšší než růst mezd o více než 10 procentních bodů?
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
        ((avg_wage - LAG(avg_wage) OVER (PARTITION BY industry_branch_code ORDER BY year)) /
        NULLIF(LAG(avg_wage) OVER (PARTITION BY industry_branch_code ORDER BY year), 0) * 100) AS wage_yoy
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
        ((avg_price - LAG(avg_price) OVER (PARTITION BY category_code ORDER BY year)) /
        NULLIF(LAG(avg_price) OVER (PARTITION BY category_code ORDER BY year), 0) * 100) AS price_yoy
    FROM prices
),
price_growth_by_year AS (
    SELECT
        year,
        ROUND(AVG(price_yoy)::numeric, 2) AS avg_price_yoy
    FROM price_growth
    WHERE price_yoy IS NOT NULL
    GROUP BY year
),
comparison AS (
    SELECT
        p.year,
        p.avg_price_yoy,
        w.avg_wage_yoy,
        ROUND((p.avg_price_yoy - w.avg_wage_yoy)::numeric, 2) AS difference_percentage_points
    FROM price_growth_by_year p
    JOIN wage_growth_by_year w
        ON p.year = w.year
),
years_over_limit AS (
    SELECT
        COUNT(*) AS number_of_years,
        STRING_AGG(year::text, ', ' ORDER BY year) AS years
    FROM comparison
    WHERE difference_percentage_points > 10
),
max_difference AS (
    SELECT *
    FROM comparison
    ORDER BY difference_percentage_points DESC
    LIMIT 1
)
SELECT
    CASE
        WHEN y.number_of_years > 0 THEN
            'Ano, v datech existuje ' || y.number_of_years ||
            ' rok/roků, kdy byl růst cen potravin vyšší než růst mezd o více než 10 procentních bodů. ' ||
            'Konkrétně se jedná o rok/roky: ' || y.years || '. ' ||
            'Největší rozdíl byl v roce ' || m.year ||
            ', kdy ceny rostly průměrně o ' || m.avg_price_yoy ||
            ' %, mzdy o ' || m.avg_wage_yoy ||
            ' % a rozdíl činil ' || m.difference_percentage_points || ' procentních bodů.'
        ELSE
            'Ne, v datech není rok, kdy by byl růst cen potravin vyšší než růst mezd o více než 10 procentních bodů. ' ||
            'Největší rozdíl byl v roce ' || m.year ||
            ', kdy ceny rostly průměrně o ' || m.avg_price_yoy ||
            ' %, mzdy o ' || m.avg_wage_yoy ||
            ' % a rozdíl činil ' || m.difference_percentage_points || ' procentních bodů. ' ||
            'Podmínka rozdílu vyššího než 10 procentních bodů tedy splněna nebyla.'
    END AS final_answer_question_4
FROM years_over_limit y
CROSS JOIN max_difference m;


-- =====================================================
-- FINÁLNÍ ODPOVĚĎ 5
-- Má výška HDP vliv na změny ve mzdách a cenách potravin ve stejném nebo následujícím roce?
-- =====================================================

WITH gdp AS (
    SELECT
        year,
        ((GDP - LAG(GDP) OVER (ORDER BY year)) /
        NULLIF(LAG(GDP) OVER (ORDER BY year), 0) * 100) AS gdp_yoy
    FROM t_dorota_gajdosova_project_sql_secondary_final
    WHERE country = 'Czech Republic'
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
        ((avg_wage - LAG(avg_wage) OVER (PARTITION BY industry_branch_code ORDER BY year)) /
        NULLIF(LAG(avg_wage) OVER (PARTITION BY industry_branch_code ORDER BY year), 0) * 100) AS wage_yoy
    FROM wages
),
wage_growth AS (
    SELECT
        year,
        AVG(wage_yoy) AS avg_wage_yoy
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
        ((avg_price - LAG(avg_price) OVER (PARTITION BY category_code ORDER BY year)) /
        NULLIF(LAG(avg_price) OVER (PARTITION BY category_code ORDER BY year), 0) * 100) AS price_yoy
    FROM prices
),
price_growth AS (
    SELECT
        year,
        AVG(price_yoy) AS avg_price_yoy
    FROM price_growth_detail
    WHERE price_yoy IS NOT NULL
    GROUP BY year
),
same_year AS (
    SELECT
        ROUND(CORR(g.gdp_yoy, w.avg_wage_yoy)::numeric, 3) AS corr_gdp_wages_same_year,
        ROUND(CORR(g.gdp_yoy, p.avg_price_yoy)::numeric, 3) AS corr_gdp_prices_same_year
    FROM gdp g
    JOIN wage_growth w
        ON g.year = w.year
    JOIN price_growth p
        ON g.year = p.year
    WHERE g.gdp_yoy IS NOT NULL
),
next_year AS (
    SELECT
        ROUND(CORR(g.gdp_yoy, w.avg_wage_yoy)::numeric, 3) AS corr_gdp_wages_next_year,
        ROUND(CORR(g.gdp_yoy, p.avg_price_yoy)::numeric, 3) AS corr_gdp_prices_next_year
    FROM gdp g
    JOIN wage_growth w
        ON g.year + 1 = w.year
    JOIN price_growth p
        ON g.year + 1 = p.year
    WHERE g.gdp_yoy IS NOT NULL
)
SELECT
    'Vztah mezi růstem HDP, růstem mezd a růstem cen potravin byl posouzen pomocí meziročních změn a orientačních korelací. ' ||
    'Ve stejném roce vyšla korelace mezi růstem HDP a růstem mezd ' || s.corr_gdp_wages_same_year ||
    ' a korelace mezi růstem HDP a růstem cen potravin ' || s.corr_gdp_prices_same_year || '. ' ||
    'Při porovnání s následujícím rokem vyšla korelace mezi růstem HDP a růstem mezd ' || n.corr_gdp_wages_next_year ||
    ' a korelace mezi růstem HDP a růstem cen potravin ' || n.corr_gdp_prices_next_year || '. ' ||
    'Výsledky proto popisují možnou souvislost mezi ukazateli, ale samy o sobě neprokazují příčinný vliv HDP na mzdy nebo ceny.'
    AS final_answer_question_5
FROM same_year s
CROSS JOIN next_year n;
