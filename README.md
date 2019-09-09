Nettoyage des fichiers “doc × terme”
====================================

Le nettoyage des fichiers “doc × terme” se fait grace au deux programmes suivant 
qui ont pour but :

 * de générer un fichier Excel qui permettra à un expert de valider les termes présents 
   ou de les supprimer, voire de les remplacer par un terme préférentiel, 
 * de reporter le résultat de cette expertise dans le fichier “doc × terme”. 

## listeTermes

Outil générant un fichier Excel pour permettre de supprimer certains termes 
en fonction de leur fréquence (c’est-à-dire du nombre de documents où ils 
sont présents) ou de leur pertinence telle que définie par un expert. 

### Usage

```bash
    listeTermes.pl -i input_file -x Excel_file [ -f min ] [ -u max ]
    listeTermes.pl -h
```

### Options

```text
    -e  spécifie le nom du fichier Excel à générer
    -f  spécifie le nombre minimum de documents où un terme peut être trouvé
    -h  affiche cette aide et quitte
    -i  spécifie le nom du fichier “doc × term” en entrée
    -u  spécifie le nombre maximum de documents où un terme peut être trouvé 
        (exprimé en pourcentage)
```

## limiteTermes

Outil lisant le fichier Excel généré par l'outil précédent pour reporter le 
résultat des suppressions et des remplacements dans le fichier “doc × terme”. 

### Usage

```bash
    limiteTermes.pl -i raw_input_file -e Excel_file [ -o output_file ]
    limiteTermes.pl -h
```

### Options

```text
    -e  spécifie le nom du fichier Excel à générer
    -h  affiche cette aide et quitte
    -i  spécifie le nom du fichier “doc × term” brut en entrée
    -o  spécifie le nom du fichier “doc × term” propre en sortie
```

## Docker

Pour construire une image Docker, faire&nbsp;:

```bash
   docker build -t visatm/clean-doc-term .
```

Pour éviter que l’utilitaire `cpanm` ne perde du temps en effectuant les tests des modules Perl à installer, 
utilisez l’option “--build-arg” pour modifier l’option “cpanm_args” définie dans le Dockerfile. Ça donne&nbsp;:

```bash
   docker build -t visatm/clean-doc-term --build-arg cpanm_args=--notest .
```

En fait, vous pouvez ainsi modifier ou ajouter toutes les options de [cpanm](https://www.unix.com/man-page/debian/1p/cpanm/) que vous voulez. 

À noter que les variables `http_proxy`, `https_proxy` et `no_proxy` ne sont pas définies dans le Dockerfile. 
Il est cependant possible de leur affecter une valeur lors de la création de l’image Docker&nbsp;:

```bash
   docker build --build-arg cpanm_args=--notest \
                --build-arg http_proxy="http://proxyout.inist.fr:8080/" \
                --build-arg https_proxy="http://proxyout.inist.fr:8080/" \
                --build-arg no_proxy="localhost, 127.0.0.1, .inist.fr" \
                -t visatm/clean-doc-term .
```

Il est également possible depuis la version 17.07 de Docker d’obtenir le même résultat en configurant le client Docker. 
Pour cela, il faut modifer le fichier `~/.docker/config.json` pour ajouter ces informations sous la forme suivante&nbsp;:

```json
    "proxies": {
        "default": {
            "httpProxy": "http://proxyout.inist.fr:8080",
            "httpsProxy": "http://proxyout.inist.fr:8080",
            "noProxy": "localhost,127.0.0.1,.inist.fr"
        }
    }
```

Dans l’exemple suivant, on utilise `listeTermes.pl` à partir de son image Docker pour générer un liste de termes 
sous Excel à partir d’un fichier “doc × terme”, en supposant que&nbsp;:

* l’utilisateur à l’identifiant (ou [UID](https://fr.wikipedia.org/wiki/User_identifier)) 1002
* l’utilisateur à l’identifiant de groupe (ou [GID](https://fr.wikipedia.org/wiki/Groupe_%28Unix%29)) 400
* le fichier “doc × terme” s’appelle `DocTermeBrut.txt` et se trouve dans le répertoire courant

```bash
   docker run --rm -u 1002:400 -v `pwd`:/tmp visatm/clean-doc-term listeTermes.pl -i DocTermeBrut.txt -e liste.xlsx -f 2 -u 10.0
```

Après nettoyge de la liste de termes par un expert, le même utilisateur peut obtenir un fichier “doc × terme” propre 
avec la commande&nbsp;:

```bash
   docker run --rm -u 1002:400 -v `pwd`:/tmp visatm/clean-doc-term limiteTermes.pl -i DocTerme.txt -e liste.xlsx -s DocTermePropre.txt
```

### Galaxy : fichiers de configuration

On a 2 fichiers de configuration en français :

 * limit_terms_fr.xml
 * list_terms_xlsx_fr.xml

Ces deux fichiers doivent être installés sous Galaxy, de préférence avec les noms `limit_terms.xml` et `list_terms_xlsx.xml` et il faut indiquer leur nom et leur chemin dans le fichier `config/tool_conf.xml`. Si l’on suppose que ces fichiers ont été placés dans le répertoire `tools/clustering` de Galaxy, l’entrée dans le fichier `config/tool_conf.xml` est :

```xml
  <section id="clustering" name="Clustering">
    <tool file="clustering/list_terms_xlsx.xml" />
    <tool file="clustering/limit_terms.xml" />
  </section>
```
**N.B.** : la version anglaise de ces fichiers devrait bientôt être disponible.
