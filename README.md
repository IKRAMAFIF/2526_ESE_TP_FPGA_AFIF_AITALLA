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

![Projet VHDL](image1.png)

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

![image2](image2.png)
---

##  Programmation de la Carte (Programmer)

Une fois la compilation terminée, le fichier `.sof` doit être envoyé dans la partie FPGA du composant Cyclone V.  
La programmation se fait via l’interface **USB-Blaster II**, en mode **JTAG**, qui permet de charger la configuration directement dans le FPGA.

Lors de la détection automatique, Quartus identifie deux composants :
- `SOCVHPS` : processeur ARM (non programmable pour ce TP)
- `5CSEBA6U23` : le FPGA, que nous devons configurer

L’image ci-dessous montre cette détection ainsi que la sélection du fichier `.sof` et la case *Program/Configure* activée avant l'envoi dans la carte.
![image3](image3.png)
Une fois la programmation lancée, une barre verte indique que la configuration a été chargée avec succès dans le FPGA.

---

