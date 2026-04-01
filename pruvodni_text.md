# Průvodní text – SQL projekt

## Popis zpracování dat

V tomto projektu jsem se zaměřila na analýzu vývoje mezd a cen potravin v České republice a na to, jak spolu tyto veličiny souvisí, případně jak na ně působí ekonomický růst (HDP).

---
##Informace o výstupních datech

Při práci s daty jsem zaznamenala několik důležitých charakteristik:

V některých letech nebo kategoriích potravin se nevyskytují hodnoty pro všechny kombinace rok × odvětví × potravina.
Při výpočtech meziročních změn (pomocí funkce LAG()) chybí hodnota pro první rok každé časové řady, protože není k dispozici předchozí rok. Tyto případy byly z analýzy vyřazeny.
V datech se nevyskytují nulové hodnoty, které by ovlivnily výpočty, nicméně pro jistotu byla použita funkce NULLIF() při dělení.
Spojením dat o mzdách a cenách vzniká kombinace všech odvětví a všech kategorií potravin v daném roce. To bylo zohledněno při výpočtech (např. použitím DISTINCT nebo agregací).

Celkově lze říci, že data jsou pro účely analýzy dostatečně kvalitní, ale je nutné brát v úvahu jejich agregovaný charakter a omezenou dostupnost některých kombinací.

## Výzkumné otázky

V rámci projektu jsem se snažila odpovědět na následující otázky:

* Rostou v průběhu let mzdy ve všech odvětvích, nebo v některých klesají?
* Kolik je možné si koupit litrů mléka a kilogramů chleba za první a poslední srovnatelné období v dostupných datech cen a mezd?
* Která kategorie potravin zdražuje nejpomaleji (má nejnižší meziroční nárůst)?
* Existuje rok, ve kterém byl meziroční nárůst cen potravin výrazně vyšší než růst mezd (více než o 10 %)?
* Má výška HDP vliv na změny ve mzdách a cenách potravin? Jinými slovy, pokud HDP v jednom roce výrazně vzroste, projeví se to na mzdách nebo cenách potravin ve stejném nebo následujícím roce?

---

## Vytvoření primární tabulky

Nejprve jsem vytvořila primární tabulku `t_dorota_gajdosova_project_sql_primary_final`, která vznikla spojením dvou hlavních zdrojů dat:

* data o mzdách podle odvětví a roku
* data o cenách potravin

U mezd jsem filtrovala pouze relevantní hodnoty (průměrná mzda a odpovídající typ výpočtu).
Ceny potravin jsem agregovala na úroveň roku pomocí průměru.

Obě části jsem následně propojila podle roku.

---

## Mezivýpočty

### Meziroční změna mezd

Pro sledování vývoje mezd jsem využila funkci `LAG()`, díky které jsem mohla porovnat hodnotu mzdy v daném roce s předchozím rokem a spočítat meziroční procentní změnu.

---

### Meziroční změna cen

Stejný postup jsem použila i u cen potravin. Nejprve jsem spočítala meziroční změnu pro jednotlivé kategorie a následně jsem tyto hodnoty zprůměrovala pro jednotlivé roky.

---

### Kupní síla

Kupní sílu jsem vyjádřila jako poměr průměrné mzdy a ceny konkrétní potraviny.

Zaměřila jsem se na:

* mléko
* chléb

a porovnala jsem první a poslední dostupné období.

---

### HDP a jeho vliv

Dále jsem vytvořila sekundární tabulku s HDP pro Českou republiku.

Na jejím základě jsem zkoumala:

* vztah mezi růstem HDP a růstem mezd
* vztah mezi růstem HDP a růstem cen potravin
* a také to, jestli se změny HDP projeví až v následujícím roce

---

## Kvalita dat a omezení

Při práci s daty jsem narazila na několik omezení:

* data jsou agregovaná (nejde o jednotlivce, ale průměry)
* některé kombinace rok × kategorie se v datech nevyskytují
* ceny jsou zprůměrované napříč regiony
* spojením tabulek vzniká kombinace všech odvětví a všech potravin, což bylo potřeba při analýze zohlednit

---

## Shrnutí mezivýsledků

Z analýzy vyplynulo, že:

* mzdy mají obecně rostoucí trend, i když ne úplně ve všech letech
* kupní síla se v čase mění v závislosti na cenách i mzdách
* některé potraviny zdražují jen velmi pomalu (například cukr krystal)
* nenašel se rok, kdy by ceny rostly výrazně rychleji než mzdy
* HDP má určitý vliv na mzdy, ale na ceny potravin už mnohem méně

---

## Závěr

Výsledky ukazují, že vývoj mezd a cen potravin není dán pouze ekonomickým růstem. Vliv má celá řada dalších faktorů a vztah mezi jednotlivými proměnnými není úplně přímočarý.
