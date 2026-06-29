# SQL projekt – Analýza mezd, cen potravin a HDP v České republice

## Cíl projektu

Cílem projektu bylo vytvořit dvě výsledné tabulky sloužící k analýze dostupnosti základních potravin v České republice a k posouzení vztahu mezi vývojem mezd, cen potravin a makroekonomickými ukazateli.

Na základě připravených datových podkladů byly zodpovězeny výzkumné otázky týkající se vývoje mezd, kupní síly obyvatel, vývoje cen potravin a možného vlivu HDP na mzdy a ceny potravin.

---

## Vytvořené tabulky

### Primární tabulka

Byla vytvořena tabulka:

`t_dorota_gajdosova_project_sql_primary_final`

Tato tabulka obsahuje:

- průměrné mzdy podle jednotlivých odvětví a let,
- průměrné ceny potravin agregované na úroveň jednotlivých let.

Data byla sjednocena na společné časové období dostupné v obou zdrojových datových sadách.

Při tvorbě tabulky byly využity následující zdroje:

- `czechia_payroll`
- `czechia_payroll_industry_branch`
- `czechia_price`
- `czechia_price_category`

---

### Sekundární tabulka

Byla vytvořena tabulka:

`t_dorota_gajdosova_project_sql_secondary_final`

Tabulka obsahuje ekonomické ukazatele evropských států:

- HDP,
- GINI koeficient,
- populaci.

Data byla získána z tabulek:

- `economies`
- `countries`

Pro následné analýzy vztahu mezi HDP, mzdami a cenami potravin byla využita data za Českou republiku.

---

## Popis zpracování dat

Při tvorbě datových podkladů byla nejprve agregována data o mzdách a cenách potravin na úroveň jednotlivých let.

U mezd byly vybrány pouze záznamy odpovídající průměrné hrubé mzdě a požadovanému typu výpočtu. Ceny potravin byly agregovány pomocí průměrné hodnoty za jednotlivé roky.

Pro výpočty meziročních změn byla využita analytická funkce `LAG()`, která umožňuje porovnání hodnot mezi dvěma po sobě následujícími roky.

---

## Mezivýpočty

### Meziroční změna mezd

Pro jednotlivá odvětví byl vypočten meziroční růst nebo pokles průměrné mzdy.

### Meziroční změna cen potravin

Pro každou kategorii potravin byl vypočten meziroční procentuální růst ceny. Následně byly tyto změny agregovány na úroveň jednotlivých let.

### Kupní síla

Kupní síla byla vyjádřena jako poměr průměrné mzdy a ceny vybrané potraviny.

Analýza byla provedena pro:

- chléb konzumní kmínový,
- mléko polotučné pasterované.

Bylo porovnáno první a poslední společné období dostupné v datech.

### HDP a jeho vliv

Pomocí sekundární tabulky byl analyzován:

- vztah mezi růstem HDP a růstem mezd ve stejném roce,
- vztah mezi růstem HDP a růstem cen potravin ve stejném roce,
- možný vliv růstu HDP na mzdy a ceny potravin v následujícím roce.

---

## Informace o kvalitě dat a omezení

Při práci s daty byly identifikovány následující skutečnosti:

- Při výpočtu meziročních změn pomocí funkce `LAG()` není pro první rok časové řady dostupná předchozí hodnota, a proto byly tyto záznamy z analýz vyloučeny.
- Pro bezpečné dělení byla využita funkce `NULLIF()`, která zabraňuje dělení nulou.
- Ceny potravin představují průměrné hodnoty za celou Českou republiku a nezohledňují regionální rozdíly.
- Data jsou agregovaná a nepopisují situaci jednotlivých domácností nebo osob.
- Spojením dat o mzdách a cenách vzniká kombinace všech odvětví a kategorií potravin v daném roce, což bylo nutné zohlednit při interpretaci výsledků.

Celkově lze konstatovat, že datové sady jsou pro účely analýzy dostatečně kvalitní.

---

## Výzkumné otázky

V rámci projektu byly řešeny následující otázky:

1. Rostou v průběhu let mzdy ve všech odvětvích, nebo v některých klesají?
2. Kolik litrů mléka a kilogramů chleba je možné koupit za první a poslední srovnatelné období?
3. Která kategorie potravin zdražuje nejpomaleji?
4. Existuje rok, ve kterém byl meziroční růst cen potravin výrazně vyšší než růst mezd?
5. Má vývoj HDP vliv na změny mezd a cen potravin ve stejném nebo následujícím roce?

---

## Shrnutí výsledků

Z provedené analýzy vyplynulo, že:

- mzdy mají dlouhodobě převážně rostoucí trend, přesto se v některých odvětvích a letech objevují poklesy,
- kupní síla obyvatel se ve sledovaném období zvýšila,
- nejpomaleji zdražující kategorií potravin byl cukr krystalový, jehož cena v průměru klesala,
- nebyl identifikován rok, ve kterém by ceny potravin rostly o více než 10 procentních bodů rychleji než mzdy,
- mezi růstem HDP a růstem mezd existuje určitá souvislost, zatímco vztah mezi HDP a cenami potravin je slabší.

---

## Závěr

Výsledky ukazují, že vývoj mezd a cen potravin není ovlivněn pouze ekonomickým růstem reprezentovaným HDP. Na změny působí více faktorů a vztahy mezi jednotlivými ukazateli nejsou jednoznačné. Přesto analýza naznačuje, že růst HDP může souviset zejména s následným růstem mezd.
