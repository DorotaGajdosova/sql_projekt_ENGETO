## Popis zpracování dat

V tomto projektu jsem se zaměřila na analýzu vývoje mezd a cen potravin v České republice a na jejich vztah k ekonomickému vývoji reprezentovanému hrubým domácím produktem (HDP).

---

## Informace o výstupních datech

Při práci s daty jsem identifikovala několik důležitých charakteristik:

* V některých letech nebo kategoriích potravin se nevyskytují všechny kombinace rok × odvětví × potravina.
* Při výpočtech meziročních změn pomocí funkce `LAG()` chybí hodnota pro první rok časové řady, protože není k dispozici předchozí období. Tyto záznamy byly z následných analýz vyřazeny.
* V datech se nevyskytují nulové hodnoty, nicméně pro zajištění bezpečného dělení byla použita funkce `NULLIF()`.
* Spojením dat o mzdách a cenách vzniká kombinace všech odvětví a všech kategorií potravin v daném roce, což bylo nutné zohlednit při agregaci dat.

Celkově lze konstatovat, že data jsou pro účely analýzy dostatečně kvalitní, je však nutné brát v úvahu jejich agregovaný charakter a omezenou dostupnost některých kombinací.

---

## Výzkumné otázky

V rámci projektu jsem se snažila odpovědět na následující otázky:

* Rostou v průběhu let mzdy ve všech odvětvích, nebo v některých odvětvích dochází k jejich poklesu?
* Kolik litrů mléka a kilogramů chleba je možné koupit za průměrnou mzdu v prvním a posledním srovnatelném období?
* Která kategorie potravin zdražuje nejpomaleji?
* Existuje rok, ve kterém byl meziroční růst cen potravin výrazně vyšší než růst mezd (o více než 10 procentních bodů)?
* Má vývoj HDP vliv na změny mezd a cen potravin ve stejném nebo následujícím roce?

---

## Vytvoření primární a sekundární tabulky

Nejprve jsem vytvořila tabulku `t_dorota_gajdosova_project_sql_primary_final`, která vznikla spojením:

* dat o průměrných mzdách podle odvětví a roku,
* dat o cenách potravin agregovaných na úroveň jednotlivých let.

U mezd byly filtrovány pouze relevantní záznamy odpovídající průměrným mzdám a požadovanému typu výpočtu. Ceny potravin byly agregovány pomocí průměrné hodnoty za jednotlivé roky.

Dále jsem vytvořila tabulku `t_dorota_gajdosova_project_sql_secondary_final`, která obsahuje ekonomické ukazatele evropských států – konkrétně HDP, GINI koeficient a populaci. Pro analýzu vztahu mezi HDP, mzdami a cenami potravin byla následně využita data za Českou republiku.

---

## Mezivýpočty

### Meziroční změna mezd

Pro sledování vývoje mezd byla využita funkce `LAG()`, která umožňuje porovnat hodnoty mezi dvěma po sobě následujícími roky.

### Meziroční změna cen

Stejný postup byl aplikován i na ceny potravin. Nejprve byly vypočteny meziroční změny pro jednotlivé kategorie potravin a následně byly tyto změny zprůměrovány podle roku.

### Kupní síla

Kupní síla byla vyjádřena jako poměr průměrné mzdy a ceny vybrané potraviny. Analýza byla provedena pro:

* mléko,
* chléb.

Následně bylo porovnáno první a poslední dostupné období.

### HDP a jeho vliv

Pomocí sekundární tabulky byl analyzován:

* vztah mezi růstem HDP a růstem mezd,
* vztah mezi růstem HDP a růstem cen potravin,
* zpožděný efekt HDP na vývoj mezd a cen v následujícím roce.

---

## Kvalita dat a omezení

* Data jsou agregovaná a nepředstavují hodnoty jednotlivých osob nebo domácností.
* Některé kombinace rok × kategorie potravin se v datech nevyskytují.
* Ceny potravin jsou zprůměrovány napříč regiony České republiky.
* Spojením tabulek vzniká kombinace všech odvětví a kategorií potravin, což bylo nutné při interpretaci výsledků zohlednit.

---

## Shrnutí mezivýsledků

Z provedené analýzy vyplynulo, že:

* mzdy mají obecně rostoucí trend, přesto se v některých letech a odvětvích objevují poklesy,
* kupní síla obyvatel se v čase mění v závislosti na vývoji mezd i cen potravin,
* některé potraviny zdražují velmi pomalu, případně v průměru i zlevňují,
* nebyl identifikován rok, ve kterém by ceny potravin rostly výrazně rychleji než mzdy o více než 10 procentních bodů,
* vztah mezi HDP a vývojem mezd a cen potravin není jednoznačný.

---

## Závěr

Výsledky ukazují, že vývoj mezd a cen potravin není ovlivněn pouze ekonomickým růstem. Na jejich změny působí více faktorů a vztahy mezi jednotlivými proměnnými nejsou zcela lineární.
