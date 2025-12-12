# 2526_ESE_TP_FPGA_AFIF_AITALLA

##  Objectif du TP

L’objectif de ce premier TP est de :

- Créer un projet Quartus dédié au FPGA Cyclone V de la carte **DE10-Nano**.
- Écrire un premier fichier VHDL simple.
- Associer les signaux VHDL aux broches physiques (pins) du FPGA via le **Pin Planner**.
- Compiler le projet.
- Programmer physiquement la carte via l’interface **USB-Blaster II**.
- Comprendre la structure du FPGA détectée (SOC vs FPGA).

---

##  1. Création du Projet Quartus

Un projet Quartus est un espace de travail contenant :
- Les fichiers VHDL
- Le fichier de contraintes (pins)
- Les options de compilation
- Les fichiers de programmation (.sof)

Dans **File → New Project Wizard**, on définit :
1. Le dossier du projet  
2. Le nom du projet et du top-level entity  
3. Le FPGA cible :  
   **5CSEBA6U23I7** (Cyclone V SoC)

Voici un aperçu du projet dans Quartus :

![Projet VHDL](images/image1.jpeg)

---

##  2. Premier fichier VHDL

Créons un composant minimal où une LED reflète l’état du bouton `pushl`.

```vhdl
library ieee;
use ieee.std_logic_1164.all;

entity tuto_fpga is
    port (
        pushl : in  std_logic;
        led0  : out std_logic
    );
end entity tuto_fpga;

architecture rtl of tuto_fpga is
begin
    led0 <= pushl;
end architecture rtl;
---
```
## Fichier de Contraintes (Pin Planner)

Cette étape consiste à associer les signaux définis dans le fichier VHDL aux broches physiques du FPGA.  
Le rôle du fichier de contraintes est essentiel : sans lui, Quartus ne peut pas relier les signaux logiques du code aux composants de la carte (LEDs, boutons, etc.).

Dans ce TP, nous assignons :
- la LED utilisateur (`led0`)
- le bouton poussoir de l’encodeur (`pushl`)

L’image ci-dessous montre la fenêtre du **Pin Planner** après affectation des deux broches : elle confirme que chaque signal VHDL est correctement relié à sa broche physique sur le Cyclone V.

![image2](images/image2.jpeg))
---

##  Programmation de la Carte (Programmer)

Une fois la compilation terminée, le fichier `.sof` doit être envoyé dans la partie FPGA du composant Cyclone V.  
La programmation se fait via l’interface **USB-Blaster II**, en mode **JTAG**, qui permet de charger la configuration directement dans le FPGA.

Lors de la détection automatique, Quartus identifie deux composants :
- `SOCVHPS` : processeur ARM (non programmable pour ce TP)
- `5CSEBA6U23` : le FPGA, que nous devons configurer

L’image ci-dessous montre cette détection ainsi que la sélection du fichier `.sof` et la case *Program/Configure* activée avant l'envoi dans la carte.
![image3](images/image3.jpeg))

Une fois la programmation lancée, une barre verte indique que la configuration a été chargée avec succès dans le FPGA.

---
---

# Partie 2 — Blinking LED (Horloge, Reset, RTL Viewer)

##  Choix de l’horloge du FPGA

Plusieurs horloges sont disponibles sur la carte DE10-Nano.  
Dans ce TP, nous utilisons :

- **Signal** : FPGA_CLK1_50  
- **Fréquence** : 50 MHz  
- **Broche FPGA** : **PIN_V11**

Cette information est fournie dans le User Manual de la carte DE10-Nano.

![Horloge 50 MHz – PIN_V11](image4.jpeg)

Cette horloge est utilisée comme source temporelle pour le clignotement de la LED.

---

##  Blink simple (sans compteur)

Le premier design séquentiel implémente un flip-flop qui inverse son état à chaque front montant de l’horloge.  
Dans le RTL Viewer de Quartus, ce comportement se traduit par :

- un registre `r_led`  
- un multiplexeur de reset  
- une porte NOT en retour  
- la sortie `o_led` reliée au registre

![RTL Viewer – Blink simple](images/image5.jpeg)

Voici ensuite le schéma fonctionnel que nous avons dessiné pour illustrer ce comportement :

![Schéma simple blink dessiné](images/image10.PNG)

Ce schéma confirme que le VHDL a bien été synthétisé en un circuit séquentiel minimal.

---

## Blink avec diviseur de fréquence (compteur)

Le clignotement à 50 MHz est invisible à l’œil humain.  
Pour obtenir un clignotement perceptible, un **diviseur de fréquence** a été ajouté.

Un compteur incrémente à chaque cycle d’horloge et, lorsqu’il atteint une valeur maximale, il :

1. se réinitialise,  
2. inverse l’état de `r_led`.

Voici le schéma RTL généré automatiquement par Quartus :  

![RTL Viewer – Blink avec compteur](images/image6.jpeg)

Et voici notre schéma fonctionnel simplifié du design :

![Schéma compteur + LED dessiné](images/image9.PNG)

Cette représentation valide que le design VHDL a été correctement traduit en une architecture matérielle séquentielle.

---

##  Importance du signal de reset

Un signal de reset est indispensable pour garantir un état initial connu du circuit.  
Il assure :

- une mise à zéro du compteur,  
- une valeur déterministe pour `r_led` au démarrage,  
- un comportement stable et reproductible.

Sans reset, les registres démarreraient dans un état indéfini.

---

##  Bouton utilisé pour le reset

Le reset est associé au bouton poussoir :

- **Bouton** : KEY0  
- **Broche FPGA** : **PIN_AH17**

![Pin KEY0 – AH17](images/image7.jpeg)

Ce bouton permet de relancer le compteur et la LED à tout moment.

---

## Signification du suffixe `_n` dans `i_rst_n`

Le suffixe **`_n`** indique que le signal est **actif à l’état bas**.

Ainsi :

- `i_rst_n = '0'` → le circuit est réinitialisé  
- `i_rst_n = '1'` → fonctionnement normal  

Cette convention est courante en électronique numérique, car les boutons poussoirs et nombreux circuits logiques produisent un niveau bas lorsqu’ils sont activés.

---

