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
Meziroční pokles mezd byl zaznamenán v několika odvětvích, nejčastěji v letech 2009 a 2013. K poklesu došlo například v odvětví těžba a dobývání, stavebnictví, informační a komunikační činnosti nebo peněžnictví a pojišťovnictví. Nejvýraznější pokles byl zaznamenán v odvětví peněžnictví a pojišťovnictví v roce 2013, kde mzdy meziročně klesly o 8,83 %.
Lze tedy konstatovat, že mzdy ve většině odvětví dlouhodobě rostly, avšak v některých letech a odvětvích docházelo i k jejich poklesu.
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
V roce 2006 bylo možné za průměrnou mzdu koupit přibližně 1313 kg chleba
a 1466 l mléka. V roce 2018 to bylo přibližně 1365 kg chleba a 1670 l mléka.
Kupní síla se tedy ve sledovaném období zvýšila, výrazněji u mléka.
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
Nejpomaleji zdražující kategorií potravin byl cukr krystalový,
u kterého vyšel průměrný meziroční růst cen -1,92 %.
Tato záporná hodnota znamená, že cena cukru ve sledovaném období
v průměru spíše klesala.
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
Ve sledovaném období nebyl nalezen žádný rok, ve kterém by byl meziroční růst cen potravin vyšší než růst mezd o více než 10 procentních bodů.

Největší rozdíl byl zaznamenán v roce 2013, kdy ceny potravin vzrostly v průměru o 6,01 %, zatímco průměrné mzdy klesly o 0,78 %. Rozdíl mezi růstem cen a mezd tak činil 6,79 procentního bodu, což je méně než stanovená hranice 10 procentních bodů.
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
Analýza ukazuje, že mezi růstem HDP a růstem mezd i cen potravin ve stejném roce existuje středně silná kladná souvislost.
Korelace mezi růstem HDP a růstem mezd dosáhla hodnoty 0,502, zatímco korelace mezi růstem HDP a růstem cen potravin činila 0,426.
Výsledky naznačují, že v letech s vyšším růstem HDP docházelo zpravidla také k růstu mezd a cen potravin. Jedná se však pouze o popisnou analýzu založenou na korelaci, která sama o sobě neprokazuje příčinný vztah mezi sledovanými ukazateli.
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
Při porovnání změny HDP s vývojem mezd a cen potravin v následujícím roce byla zjištěna poměrně silná kladná korelace mezi růstem HDP a růstem mezd, která dosáhla hodnoty 0,671.
Naopak korelace mezi růstem HDP a růstem cen potravin v následujícím roce byla velmi slabá (0,054), což naznačuje, že změny HDP se do cen potravin s ročním zpožděním pravděpodobně výrazně nepromítají.
Výsledky tedy naznačují, že růst HDP může souviset s následným růstem mezd, avšak vztah mezi HDP a cenami potravin v následujícím roce nebyl prokázán. Je však třeba zdůraznit, že korelace sama o sobě neprokazuje příčinný vztah.
*/