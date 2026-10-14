# Louvain Method — Community Detection

**Vak:** Algoritmen en Datastructuren II  
**Onderdeel:** Taak 1 - Grafen  
**Auteur:** Lisa Wei  
**Academiejaar:** 2024–2025 (1e zittijd)

---

## Overzicht

Voor deze implementatie van de **Louvain Method** is gebruikgemaakt van de `adjacency-list` uit de `a-d`-bibliotheek en is er een zelfstandig toegevoegde `AVL dictionary` gebruikt uit de WPO-oefeningen. Er zijn geen bestaande bestanden van de `a-d`-folder gewijzigd.

### Referenties & Bronnen
* [Louvain method of community detection - Step by Step](https://youtu.be/wLyAJj6da9g?si=E9AatOc6C0EX-7sN)
* [NetSci 06-2 Modularity and the Louvain Method](https://youtu.be/QfTxqAxJp0U?si=SAATt3tbaB3DMw9)
* Cursusmateriaal van *Algoritmen en Datastructuren 1* en *Structuur van Computerprogramma's 1*.

---

## Hulpprocedures

* **`degrees`**:  
  Maakt eerst een vector aan gevuld met nullen en berekent vervolgens de graad van elke node door over alle bogen te itereren. De som wordt opgeslagen in `total`, toegevoegd aan de vector op de juiste index, en uiteindelijk wordt de vector teruggegeven.

* **`modularity`**:  
  Houdt de nodige variabelen bij voor de modulariteitsformule. Hierbij is `apply` gecombineerd met `vector->list` om eenvoudiger over lijsten te kunnen itereren. Vervolgens worden alle knopen en hun buren doorlopen; indien knopen zich in dezelfde community bevinden, wordt de modulariteit berekend (waarbij bogen zonder verbinding gewicht $0$ krijgen).

* **`in-community-degree`**:  
  Berekent de interne graad binnen een community, waarbij zelfbogen expliciet buiten beschouwing worden gelaten.

---

## Fase 1: Incrementele optimalisatie van modulariteit

Tijdens de initialisatie worden de basiswaarden klaargezet en wordt een AVL-dictionary aangemaakt voor de *intra-degrees*. De keuze voor een AVL-structuur boven een hash table biedt consistente performantie en een overzichtelijke implementatie binnen het project.

1. **Initialisatie:**  
   De community-vector wordt geïnitialiseerd met `-1` om verwarring met intra-degrees (waarde `0`) te voorkomen. Vervolgens wordt elke node toegekend aan zijn eigen unieke community.
2. **Lokale optimalisatie:**  
   In een hoofditeratie wordt `best-delta-Q` initieel op `-1` gezet. Buren worden bijgehouden in `neighbor-comms` als lijst. Via een `named let` worden alle mogelijke verplaatsingen van een node naar naburige communities geëvalueerd.
3. **Formule & `sig-tot`:**  
   Binnen een `let*` wordt de $\Delta Q$-formule geëvalueerd. De hulpprocedure `sig-tot` berekent hierbij de totale graad van communities $A$ en $B$ (analoog aan `in-community-degree`, maar mét het meetellen van zelfbogen).
4. **Update & Terminatie:**  
   Wanneer een verplaatsing resulteert in een positieve $\Delta Q$, worden de totale modulariteitswinst, de dictionaries en de community-vector bijgewerkt. Dit herhaalt zich totdat er geen verdere verbetering mogelijk is.

De procedure retourneert een lijst met:
* De totale modulariteitsverbetering
* De geüpdatete `communities`-vector
* De dictionary met intra-degrees

---

## Fase 2: Aggregatie van communities

In deze fase worden de gevonden communities samengevoegd tot supernodes om een nieuwe gereduceerde graaf op te bouwen.

1. **Nodebepaling (`comm-ids` & `new-comm-ids`):**  
   Omdat de community-vector niet geordend is per unieke community, verzamelt `comm-ids` alle unieke community-identificatoren. De lengte hiervan (`comm-count`) bepaalt het aantal knopen in de nieuwe graaf. `new-comm-ids` koppelt elke community als key aan een nieuwe opeenvolgende knoop-index via een AVL-dictionary.
2. **Booggewichten & Ordening (`edge-weights`):**  
   Om booggewichten tussen communities bij te houden, wordt een AVL-dictionary gebruikt met cons-cellen `(ci . cj)` als key. Hiervoor is een custom kleiner-dan operator geschreven zodat cons-cellen correct vergeleken en gesorteerd kunnen worden zonder dubbeltellingen ($i < j$).
3. **Zelfbogen (`self-loops`):**  
   Voor elke samengevoegde community wordt via `sigma-ins` / de intra-degrees uit Fase 1 het gewicht van de interne bogen opgehaald en als zelfboog toegevoegd aan de corresponderende nieuwe knoop.
4. **Graafconstructie:**  
   Ten slotte itereert het algoritme over de lijst met unieke bogen (`edges`) om alle berekende gewichten in te stellen in de resulterende geaggregeerde graaf, waarna deze wordt teruggegeven.
