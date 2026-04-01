## Popis zpracování dat

V tomto projektu jsem se zaměřila na analýzu vývoje mezd a cen potravin v České republice a na jejich vztah k ekonomickému růstu (HDP).

---

## Informace o výstupních datech

Při práci s daty jsem zaznamenala několik důležitých charakteristik:

* V některých letech nebo kategoriích potravin se nevyskytují všechny kombinace rok × odvětví × potravina.
* Při výpočtech meziročních změn (pomocí funkce `LAG()`) chybí hodnota pro první rok časové řady, protože není k dispozici předchozí rok. Tyto případy byly z analýzy vyřazeny.
* V datech se nevyskytují nulové hodnoty, nicméně pro jistotu byla při dělení použita funkce `NULLIF()`.
* Spojením dat o mzdách a cenách vzniká kombinace všech odvětví a všech kategorií potravin v daném roce, což bylo nutné zohlednit při agregaci dat.

Celkově lze říci, že data jsou pro účely analýzy dostatečně kvalitní, ale je potřeba brát v úvahu jejich agregovaný charakter a omezenou dostupnost některých kombinací.

---

## Výzkumné otázky

V rámci projektu jsem se snažila odpovědět na následující otázky:

* Rostou v průběhu let mzdy ve všech odvětvích, nebo v některých klesají?
* Kolik je možné si koupit litrů mléka a kilogramů chleba za první a poslední srovnatelné období?
* Která kategorie potravin zdražuje nejpomaleji (má nejnižší meziroční nárůst)?
* Existuje rok, ve kterém byl meziroční nárůst cen potravin výrazně vyšší než růst mezd (o více než 10 %)?
* Má výška HDP vliv na změny ve mzdách a cenách potravin (ve stejném nebo následujícím roce)?

---

## Vytvoření primární tabulky

Nejprve jsem vytvořila tabulku `t_dorota_gajdosova_project_sql_primary_final`, která vznikla spojením:

* dat o mzdách podle odvětví a roku
* dat o cenách potravin

U mezd jsem filtrovala pouze relevantní hodnoty (průměrná mzda a odpovídající typ výpočtu).
Ceny potravin jsem agregovala na úroveň roku pomocí průměru.

Obě části jsem následně propojila podle roku.

---

## Mezivýpočty

### Meziroční změna mezd

Pro sledování vývoje mezd jsem využila funkci `LAG()`, která umožňuje porovnání hodnot mezi dvěma po sobě jdoucími roky.

### Meziroční změna cen

Stejný postup jsem použila i u cen potravin. Nejprve jsem spočítala meziroční změny pro jednotlivé kategorie a následně je zprůměrovala podle roku.

### Kupní síla

Kupní sílu jsem vyjádřila jako poměr průměrné mzdy a ceny potraviny.
Zaměřila jsem se konkrétně na:

* mléko
* chléb

a porovnala jsem první a poslední dostupné období.

### HDP a jeho vliv

Dále jsem vytvořila sekundární tabulku s HDP pro Českou republiku a zkoumala:

* vztah mezi růstem HDP a růstem mezd
* vztah mezi růstem HDP a růstem cen potravin
* a také zpožděný efekt (vliv HDP na následující rok)

---

## Kvalita dat a omezení

* Data jsou agregovaná (nejde o jednotlivce, ale o průměrné hodnoty).
* Některé kombinace rok × kategorie se v datech nevyskytují.
* Ceny jsou zprůměrované napříč regiony.
* Spojením tabulek vzniká kombinace všech odvětví a všech potravin, což bylo nutné při analýze zohlednit.

---

## Shrnutí mezivýsledků

Z analýzy vyplynulo, že:

* Mzdy mají obecně rostoucí trend, i když ne ve všech letech.
* Kupní síla se v čase mění v závislosti na vývoji mezd i cen.
* Některé potraviny zdražují velmi pomalu (například cukr krystal).
* Nebyl nalezen rok, kdy by ceny potravin rostly výrazně rychleji než mzdy.
* HDP má určitý vliv na vývoj mezd, ale na ceny potravin se tento vztah neprojevuje jednoznačně.

---

## Závěr

Výsledky ukazují, že vývoj mezd a cen potravin není dán pouze ekonomickým růstem. Na jejich změny působí více faktorů a vztahy mezi proměnnými nejsou zcela lineární.
