## Contexte du projet _NSA-810_

La compagnie fait face à une crise après le départ de l'administrateur système, laissant une infrastructure critique partiellement cassée et vulnérable. De nombreux services sont paralysés sans la plateforme web, et il y a une menace de cyberattaque imminente. La mission consiste à prendre en charge et réparer cette infrastructure rapidement. Les contraintes incluent la séparation de l'API et de l'application web sur des hôtes différents, l'utilisation de services containerisés, et le lancement de tous les containers avec l'utilisateur service − web. Il est également nécessaire de mettre en place un système de journalisation complet, un système d'intégration et de déploiement automatisé via Gitlab, et d'utiliser un logiciel de gestion des artefacts. Les informations laissées par l'ancien administrateur sont fragmentaires et peu fiables.

## Gestion de projet

Dans le cadre de ce projet, à la suite de l'investigation, il a été décidé d'utiliser un outil intégré à discord, du nom de 'bnder_app', ce qui nous permet de mutualiser les communications du serveur discord ainsi que l'avancement du projet. Bnder nous permet d'avoir un accès direct à un tableau Kanban ou nous avons renseingés les tâches nécessaires à la réalisation de ce projet alliant à la fois de la MCO, de l'infrastructure des SI aini que de la sécurisation des SI.   


![image](https://github.com/EpitechMscProPromo2025/T-NSA-810-LIL_11/assets/148775915/7dd15464-d515-4cb8-9938-f0b5a05cd804)
Chaque tâche est labellisée par sa spécialité : 
- Services Critiques : Tout service ayant de la criticité quant à la production.
- Sécurité : Tout service pouvant faire l'objet d'une politique de sécurité (type ISO 27001, RGPD).
- Automatisation : Tout service ayant un potentiel de robotisation afin de pouvoir limiter les interventions humaines. 
- Documentation : Archiver et mettre au plat nos avancées ainsi que nos réflexions.
[Lien du Kanban](https://bnder.net/app/task/1230577115397623858/default/7)

Sur ces tâches, nous avons aussi mentionnés des sous tâches afin de pouvoir être suffisament précis sur les actions à effectuer ou à verifier.   

## Investigation
⚠️ Attention :   
_Les adresses IP et les machines virtuelles mentionnées ci-dessous ainsi que les tests de pénétration des SI et de connectivité ont été réalisées dans un environement de test et non sur l'environnement de production._   

### Étape 1 : Scanner les hôtes sur le réseau

Nous avons effectué un scan réseau avec Nmap pour identifier les services actifs sur le sous-réseau `192.168.215.0/24` :

```sh
➜  .lst sudo nmap 192.168.215.*
[sudo] Mot de passe de alexandre : 
Starting Nmap 7.93 ( https://nmap.org ) at 2024-04-29 14:23 CEST

Nmap scan report for 192.168.215.91
Host is up (0.000082s latency).
Not shown: 997 closed tcp ports (reset)
PORT     STATE SERVICE
22/tcp   open  ssh
80/tcp   open  http
3306/tcp open  mysql
MAC Address: 08:00:27:53:4C:8D (Oracle VirtualBox virtual NIC)

Nmap scan report for 192.168.215.132
Host is up (0.000088s latency).
Not shown: 996 closed tcp ports (reset)
PORT     STATE SERVICE
21/tcp   open  ftp
22/tcp   open  ssh
80/tcp   open  http
8080/tcp open  http-proxy
MAC Address: 08:00:27:81:00:D4 (Oracle VirtualBox virtual NIC)

Nmap scan report for 192.168.215.217
Host is up (0.00012s latency).
Not shown: 997 closed tcp ports (reset)
PORT     STATE SERVICE
22/tcp   open  ssh
8000/tcp open  http-alt
9000/tcp open  cslistener
MAC Address: 08:00:27:0A:59:47 (Oracle VirtualBox virtual NIC)

Nmap scan report for 192.168.215.249
Host is up (0.000088s latency).
Not shown: 999 closed tcp ports (reset)
PORT   STATE SERVICE
22/tcp open  ssh
MAC Address: 08:00:27:74:9C:BA (Oracle VirtualBox virtual NIC)
```

### Étape 2 : Exploitation des services ouverts

#### Port 22 (SSH) sur l'hôte `192.168.215.249`

Nous avons tenté une attaque par force brute sur le service SSH de l'hôte `192.168.215.249` à l'aide d'Hydra :

```sh
➜  .lst hydra -L .username.txt -P .pass.txt 192.168.215.249 ssh
Hydra v9.4 (c) 2022 by van Hauser/THC & David Maciejak - Please do not use in military or secret service organizations, or for illegal purposes (this is non-binding, these *** ignore laws and ethics anyway).

Hydra (https://github.com/vanhauser-thc/thc-hydra) starting at 2024-04-29 14:29:38
[WARNING] Many SSH configurations limit the number of parallel tasks, it is recommended to reduce the tasks: use -t 4
[DATA] max 16 tasks per 1 server, overall 16 tasks, 99 login tries (l:9/p:11), ~7 tries per task
[DATA] attacking ssh://192.168.215.249:22/
[22][ssh] host: 192.168.215.249   login: root   password: admin
1 of 1 target successfully completed, 1 valid password found
Hydra (https://github.com/vanhauser-thc/thc-hydra) finished at 2024-04-29 14:29:53
```

Le mot de passe root a été trouvé (root/admin). Nous pouvons donc commencer l'investigation des machines.

### Investigation des machines

#### Machine 1 (192.168.215.91)

```sh
[root@device-33 ~]# ss -lntp
State      Recv-Q Send-Q Local Address:Port Peer Address:Port              
LISTEN     0      128      *:22             *:*          users:(("sshd",pid=902,fd=3))
LISTEN     0      100 127.0.0.1:25         *:*          users:(("master",pid=1550,fd=13))
LISTEN     0      128     :::8080          :::*         users:(("docker-proxy",pid=2683,fd=4))
LISTEN     0      128     :::80            :::*         users:(("docker-proxy",pid=2639,fd=4))
LISTEN     0      128     :::21            :::*         users:(("docker-proxy",pid=2555,fd=4))
LISTEN     0      128     :::22            :::*         users:(("sshd",pid=902,fd=4))
LISTEN     0      100     ::1:25           :::*         users:(("master",pid=1550,fd=14))
```

**Ports ouverts :**
- 21/tcp (FTP)
- 22/tcp (SSH)
- 25/tcp (SMTP, restreint)
- 80/tcp (HTTP, erreur 403)
- 8080/tcp (Environnement de dev front de l'application react)

**Port 80 (HTTP) :**
```sh
[root@device-33 front]# curl 127.0.0.1
<html>
<head><title>403 Forbidden</title></head>
<body>
<center><h1>403 Forbidden</h1></center>
<hr><center>nginx/1.16.1</center>
</body>
</html>
```

**Port 25 (SMTP) :**
```sh
telnet 192.168.1.14 25
Trying 192.168.1.14...
telnet: Unable to connect to remote host: Connexion refusée
```

#### Machine 2 (192.168.215.132)

```sh
[root@device-31 home]# ss -lntp 
State      Recv-Q Send-Q Local Address:Port Peer Address:Port              
LISTEN     0      128      *:22             *:*          users:(("sshd",pid=908,fd=3))
LISTEN     0      100 127.0.0.1:25         *:*          users:(("master",pid=1531,fd=13))
LISTEN     0      128     :::80            :::*         users:(("docker-proxy",pid=2409,fd=4))
LISTEN     0      128     :::22            :::*         users:(("sshd",pid=908,fd=4))
LISTEN     0      100     ::1:25           :::*         users:(("master",pid=1531,fd=14))
LISTEN     0      128     :::222           :::*         users:(("docker-proxy",pid=2421,fd=4))
```

**Ports ouverts :**
- 22/tcp (SSH)
- 25/tcp (SMTP, restreint)
- 80/tcp (Gitea)
- 222/tcp (Gitea)

**Port 222 (Gitea) :**
```sh
nc -vz 192.168.1.13 222
Connection to 192.168.1.13 222 port [tcp/*] succeeded!
```

**Port 25 (SMTP) :**
```sh
telnet 192.168.1.11 25
Trying 192.168.1.11...
telnet: Unable to connect to remote host: Connexion refusée
```

#### Machine 3 (192.168.215.217)

```sh
[root@device-30 back]# ss -lntp
State      Recv-Q Send-Q Local Address:Port Peer Address:Port              
LISTEN     0      128      *:22             *:*          users:(("sshd",pid=916,fd=3))
LISTEN     0      100 127.0.0.1:25         *:*          users:(("master",pid=1586,fd=13))
LISTEN     0      128     :::80            :::*         users:(("docker-proxy",pid=2325,fd=4))
LISTEN     0      128     :::22            :::*         users:(("sshd",pid=916,fd=4))
LISTEN     0      100     ::1:25           :::*         users:(("master",pid=1586,fd=14))
```

**Ports ouverts :**
- 22/tcp (SSH)
- 25/tcp (SMTP, restreint)
- 8000/tcp (OctoberCMS)
- 9000/tcp (Portainer)

**Port 25 (SMTP) :**
```sh
telnet 192.168.1.11 25
Trying 192.168.1.11...
telnet: Unable to connect to remote host: Connexion refusée
```

### Conclusion de l'investigation

Nous avons réussi à pénétrer l'infrastructure en utilisant une attaque par force brute. Les investigations sur les différentes machines ont révélé des configurations et services variés, dont plusieurs ports ouverts et quelques services restreints.

Cette analyse a également mis en évidence de nombreuses défaillances au niveau de la sécurité :

- **Utilisation de ProFTP** : Le serveur FTP (ProFTP) utilisé présente des vulnérabilités connues qui peuvent être exploitées pour obtenir un accès non autorisé. Il est crucial de remplacer ce logiciel par une alternative plus sécurisée ou de s'assurer qu'il est correctement configuré et mis à jour.
- **Systèmes CentOS 7 en fin de vie (EOL)** : Plusieurs machines tournent sous CentOS 7, une version du système d'exploitation qui est désormais en fin de vie et ne reçoit plus de mises à jour de sécurité, exposant ainsi l'infrastructure à des risques accrus. Il est impératif de migrer vers une version supportée ou un autre système d'exploitation plus sécurisé.
- **Mots de passe faibles et politiques de sécurité laxistes** : La facilité avec laquelle nous avons pu obtenir des accès root démontre une mauvaise gestion des mots de passe et des politiques de sécurité insuffisantes. Une politique de mots de passe robustes et un mécanisme de verrouillage de compte en cas de tentatives répétées de connexion échouées doivent être mis en place.
- **Ports ouverts non nécessaires** : De nombreux services inutilisés ou mal configurés sont exposés sur des ports ouverts, ce qui augmente la surface d'attaque. Un audit régulier des ports ouverts et la fermeture de ceux non nécessaires doivent être effectués.
- **Absence de segmentation réseau** : L'absence de segmentation adéquate du réseau permet un accès non restreint à l'ensemble des machines une fois qu'une seule est compromise. La mise en place de sous-réseaux sécurisés et de règles strictes de pare-feu est essentielle pour limiter les mouvements latéraux d'un attaquant.
- **Configurations par défaut non modifiées** : Plusieurs services utilisent leurs configurations par défaut, ce qui représente un risque de sécurité important. Chaque service doit être configuré de manière sécurisée selon les meilleures pratiques.

Ces faiblesses de sécurité identifiées nous permettront de mieux comprendre les vulnérabilités présentes et d'élaborer des stratégies pour sécuriser l'infrastructure lors de la refonte totale du projet _NSA-810_. Il est impératif de mettre à jour ou de remplacer les logiciels obsolètes, de renforcer la sécurité des services exposés, d'implémenter des politiques de sécurité strictes et de surveiller activement l'infrastructure pour protéger contre de futures attaques.

## Migration des VMs sur de l'alma
En réponse à l'annonce de la fin de vie (EOL) de CentOS 7 en juin 2024, nous avons pris la décision de migrer l'ensemble de notre infrastructure vers AlmaLinux (et Rocky Linux pour les tests). Nous avons initialement adopté la version 9.3 lors de la création de notre nouvelle infrastructure, qui a depuis été mise à jour vers la version 9.4. Cette infrastructure est déployée localement sur VMware.

Dans le cadre de cette migration, nous avons effectué une refonte complète de notre environnement. Plusieurs services obsolètes ont été remplacés par des alternatives plus modernes et sécurisées. Les détails des configurations du frontend et du backend sont disponibles sur notre SharePoint.

## ProFTP
Etant donné qu'après notre investigation nous n'avons pas trouvé d'utilité cliente à proftp, nous avons conclus qu'il fallait mieux passer sur un protocole tout de même plus sécurisé, ou sur du SFTP ou bien sur du FTPS (dépendant le nombre d'utilisateurs qui utilisent encore ce serivce).
Typqieuement une configuration SFTP utilisera le protocole SSH avec un user défini, qui n'aura accès qu'à son répertoire donné sur la config sshd.
Exemple :
```sh
Match user example
    ChrootDirectory /home/%u
    ForceCommand internal-sftp
    AllowTcpForwarding no
    X11Forwarding no
```
Nous pouvons dès lors seguementer par user ou par groupe l'accès au serveur.

## Utilisation d'un KeepassXC pour palier à la politique de mot de passe laxiste.
Afin  de palier à la politique de mot de passe laxiste, nous avons utilisés KeepassXC, ce qui nous permet de génerer des mots de passe plus robuste et unique pour chaque utilisateur/service de notre infrastructure.

## Cloisonnement Réseau
Dans le but de palier le manque de séparation côté réseau, nous avons décidé de mettre en place un routeur Opnsense et un VLAN qui regroupe l'ensemble de notre infrastructure.


## Investigation et Intervention sur l'applicatif front et back sur les CentOS.
### Stock test

En lancant la commande `npm audit`, nous pouvons avoir un aperçu de la résilience de notre code ainsi que de notre image docker grâce à Trivy.
En voici un extrait:
```sh
123 packages are looking for funding
  run `npm fund` for details

found 102 vulnerabilities (2 low, 58 moderate, 38 high, 4 critical)
  run `npm audit fix` to fix them, or `npm audit` for details
[root@localhost front]# npm audit

                       === npm audit security report ===

# Run  npm install react-scripts@5.0.1  to resolve 64 vulnerabilities
SEMVER WARNING: Recommended action is a potentially breaking change
┌───────────────┬──────────────────────────────────────────────────────────────┐
│ Moderate      │ OS Command Injection in node-notifier                        │
├───────────────┼──────────────────────────────────────────────────────────────┤
│ Package       │ node-notifier                                                │
├───────────────┼──────────────────────────────────────────────────────────────┤
│ Dependency of │ react-scripts                                                │
├───────────────┼──────────────────────────────────────────────────────────────┤
│ Path          │ react-scripts > jest > jest-cli > @jest/core >               │
│               │ @jest/reporters > node-notifier                              │
├───────────────┼──────────────────────────────────────────────────────────────┤
│ More info     │ https://github.com/advisories/GHSA-5fw9-fq32-wv5p            │
└───────────────┴──────────────────────────────────────────────────────────────┘


┌───────────────┬──────────────────────────────────────────────────────────────┐
│ Moderate      │ Cross-Site Scripting in serialize-javascript                 │
├───────────────┼──────────────────────────────────────────────────────────────┤
│ Package       │ serialize-javascript                                         │
├───────────────┼──────────────────────────────────────────────────────────────┤
│ Dependency of │ react-scripts                                                │
├───────────────┼──────────────────────────────────────────────────────────────┤
│ Path          │ react-scripts > terser-webpack-plugin > serialize-javascript │
├───────────────┼──────────────────────────────────────────────────────────────┤
│ More info     │ https://github.com/advisories/GHSA-h9rv-jmmf-4pgx            │
└───────────────┴──────────────────────────────────────────────────────────────┘
...

┌───────────────┬──────────────────────────────────────────────────────────────┐
│ High          │ Command Injection in lodash                                  │
├───────────────┼──────────────────────────────────────────────────────────────┤
│ Package       │ lodash.template                                              │
├───────────────┼──────────────────────────────────────────────────────────────┤
│ Patched in    │ No patch available                                           │
├───────────────┼──────────────────────────────────────────────────────────────┤
│ Dependency of │ react-scripts                                                │
├───────────────┼──────────────────────────────────────────────────────────────┤
│ Path          │ react-scripts > workbox-webpack-plugin > workbox-build >     │
│               │ lodash.template                                              │
├───────────────┼──────────────────────────────────────────────────────────────┤
│ More info     │ https://github.com/advisories/GHSA-35jh-r3h4-6jhm            │
└───────────────┴──────────────────────────────────────────────────────────────┘
┌───────────────┬──────────────────────────────────────────────────────────────┐
│ High          │ kangax html-minifier REDoS vulnerability                     │
├───────────────┼──────────────────────────────────────────────────────────────┤
│ Package       │ html-minifier                                                │
├───────────────┼──────────────────────────────────────────────────────────────┤
│ Patched in    │ No patch available                                           │
├───────────────┼──────────────────────────────────────────────────────────────┤
│ Dependency of │ react-scripts                                                │
├───────────────┼──────────────────────────────────────────────────────────────┤
│ Path          │ react-scripts > html-webpack-plugin > html-minifier          │
├───────────────┼──────────────────────────────────────────────────────────────┤
│ More info     │ https://github.com/advisories/GHSA-pfq8-rq6v-vf5m            │
└───────────────┴──────────────────────────────────────────────────────────────┘
┌───────────────┬──────────────────────────────────────────────────────────────┐
│ High          │ ip SSRF improper categorization in isPublic                  │
├───────────────┼──────────────────────────────────────────────────────────────┤
│ Package       │ ip                                                           │
├───────────────┼──────────────────────────────────────────────────────────────┤
│ Patched in    │ No patch available                                           │
├───────────────┼──────────────────────────────────────────────────────────────┤
│ Dependency of │ react-scripts                                                │
├───────────────┼──────────────────────────────────────────────────────────────┤
│ Path          │ react-scripts > webpack-dev-server > ip                      │
├───────────────┼──────────────────────────────────────────────────────────────┤
│ More info     │ https://github.com/advisories/GHSA-2p57-rm9w-gvfp            │
└───────────────┴──────────────────────────────────────────────────────────────┘
┌───────────────┬──────────────────────────────────────────────────────────────┐
│ High          │ ip SSRF improper categorization in isPublic                  │
├───────────────┼──────────────────────────────────────────────────────────────┤
│ Package       │ ip                                                           │
├───────────────┼──────────────────────────────────────────────────────────────┤
│ Patched in    │ No patch available                                           │
├───────────────┼──────────────────────────────────────────────────────────────┤
│ Dependency of │ react-scripts                                                │
├───────────────┼──────────────────────────────────────────────────────────────┤
│ Path          │ react-scripts > webpack-dev-server > bonjour > multicast-dns │
│               │ > dns-packet > ip                                            │
├───────────────┼──────────────────────────────────────────────────────────────┤
│ More info     │ https://github.com/advisories/GHSA-2p57-rm9w-gvfp            │
└───────────────┴──────────────────────────────────────────────────────────────┘
found 102 vulnerabilities (2 low, 58 moderate, 38 high, 4 critical) in 1879 scanned packages
  run `npm audit fix` to fix 17 of them.
  71 vulnerabilities require semver-major dependency updates.
  14 vulnerabilities require manual review. See the full report for details.
```
Et avec trivy :
```sh
front (alpine 3.13.5)

Total: 37 (UNKNOWN: 0, LOW: 0, MEDIUM: 6, HIGH: 27, CRITICAL: 4)

┌──────────────┬────────────────┬──────────┬────────┬───────────────────┬───────────────┬──────────────────────────────────────────────────────────────┐
│   Library    │ Vulnerability  │ Severity │ Status │ Installed Version │ Fixed Version │                            Title                             │
├──────────────┼────────────────┼──────────┼────────┼───────────────────┼───────────────┼──────────────────────────────────────────────────────────────┤
│ apk-tools    │ CVE-2021-36159 │ CRITICAL │ fixed  │ 2.12.5-r0         │ 2.12.6-r0     │ libfetch: an out of boundary read while libfetch uses strtol │
│              │                │          │        │                   │               │ to parse...                                                  │
│              │                │          │        │                   │               │ https://avd.aquasec.com/nvd/cve-2021-36159                   │
├──────────────┼────────────────┼──────────┤        ├───────────────────┼───────────────┼──────────────────────────────────────────────────────────────┤
│ busybox      │ CVE-2021-42378 │ HIGH     │        │ 1.32.1-r6         │ 1.32.1-r7     │ busybox: use-after-free in awk applet leads to denial of     │
│              │                │          │        │                   │               │ service and possibly...                                      │
│              │                │          │        │                   │               │ https://avd.aquasec.com/nvd/cve-2021-42378                   │
│              ├────────────────┤          │        │                   │               ├──────────────────────────────────────────────────────────────┤
│              │ CVE-2021-42379 │          │        │                   │               │ busybox: use-after-free in awk applet leads to denial of     │
│              │                │          │        │                   │               │ service and possibly...                                      │
│              │                │          │        │                   │               │ https://avd.aquasec.com/nvd/cve-2021-42379                   │
│              ├────────────────┤          │        │                   │               ├──────────────────────────────────────────────────────────────┤
│              │ CVE-2021-42380 │          │        │                   │               │ busybox: use-after-free in awk applet leads to denial of     │
│              │                │          │        │                   │               │ service and possibly...                                      │
│              │                │          │        │                   │               │ https://avd.aquasec.com/nvd/cve-2021-42380                   │
│              ├────────────────┤          │        │                   │               ├──────────────────────────────────────────────────────────────┤
│              │ CVE-2021-42381 │          │        │                   │               │ busybox: use-after-free in awk applet leads to denial of     │
│              │                │          │        │                   │               │ service and possibly...                                      │
│              │                │          │        │                   │               │ https://avd.aquasec.com/nvd/cve-2021-42381                   │
│              ├────────────────┤          │        │                   │               ├──────────────────────────────────────────────────────────────┤
│              │ CVE-2021-42382 │          │        │                   │               │ busybox: use-after-free in awk applet leads to denial of     │
│              │                │          │        │                   │               │ service and possibly...                                      │
│              │                │          │        │                   │               │ https://avd.aquasec.com/nvd/cve-2021-42382                   │
│              ├────────────────┤          │        │                   │               ├──────────────────────────────────────────────────────────────┤
│              │ CVE-2021-42383 │          │        │                   │               │ busybox: use-after-free in awk applet leads to denial of     │
│              │                │          │        │                   │               │ service and possibly...                                      │
│              │                │          │        │                   │               │ https://avd.aquasec.com/nvd/cve-2021-42383                   │
│              ├────────────────┤          │        │                   │               ├──────────────────────────────────────────────────────────────┤
│              │ CVE-2021-42384 │          │        │                   │               │ busybox: use-after-free in awk applet leads to denial of     │
│              │                │          │        │                   │               │ service and possibly...                                      │
│              │                │          │        │                   │               │ https://avd.aquasec.com/nvd/cve-2021-42384                   │
│              ├────────────────┤          │        │                   │               ├──────────────────────────────────────────────────────────────┤
│              │ CVE-2021-42385 │          │        │                   │               │ busybox: use-after-free in awk applet leads to denial of     │
│              │                │          │        │                   │               │ service and possibly...                                      │
│              │                │          │        │                   │               │ https://avd.aquasec.com/nvd/cve-2021-42385                   │
│              ├────────────────┤          │        │                   │               ├──────────────────────────────────────────────────────────────┤
│              │ CVE-2021-42386 │          │        │                   │               │ busybox: use-after-free in awk applet leads to denial of     │
│              │                │          │        │                   │               │ service and possibly...                                      │
│              │                │          │        │                   │               │ https://avd.aquasec.com/nvd/cve-2021-42386                   │
│              ├────────────────┤          │        │                   ├───────────────┼──────────────────────────────────────────────────────────────┤
│              │ CVE-2022-28391 │          │        │                   │ 1.32.1-r8     │ busybox: remote attackers may execute arbitrary code if      │
│              │                │          │        │                   │               │ netstat is used                                              │
│              │                │          │        │                   │               │ https://avd.aquasec.com/nvd/cve-2022-28391                   │
...
│              ├────────────────┼──────────┤        │                   ├───────────────┼──────────────────────────────────────────────────────────────┤
│              │ CVE-2021-42374 │ MEDIUM   │        │                   │ 1.32.1-r7     │ busybox: out-of-bounds read in unlzma applet leads to        │
│              │                │          │        │                   │               │ information leak and denial...                               │
│              │                │          │        │                   │               │ https://avd.aquasec.com/nvd/cve-2021-42374                   │
│              ├────────────────┤          │        │                   │               ├──────────────────────────────────────────────────────────────┤
│              │ CVE-2021-42375 │          │        │                   │               │ busybox: incorrect handling of a special element in ash      │
│              │                │          │        │                   │               │ applet leads to...                                           │
│              │                │          │        │                   │               │ https://avd.aquasec.com/nvd/cve-2021-42375                   │
├──────────────┼────────────────┼──────────┤        ├───────────────────┼───────────────┼──────────────────────────────────────────────────────────────┤
│ zlib         │ CVE-2022-37434 │ CRITICAL │        │ 1.2.11-r3         │ 1.2.12-r2     │ zlib: heap-based buffer over-read and overflow in inflate()  │
│              │                │          │        │                   │               │ in inflate.c via a...                                        │
│              │                │          │        │                   │               │ https://avd.aquasec.com/nvd/cve-2022-37434                   │
│              ├────────────────┼──────────┤        │                   ├───────────────┼──────────────────────────────────────────────────────────────┤
│              │ CVE-2018-25032 │ HIGH     │        │                   │ 1.2.12-r0     │ zlib: A flaw found in zlib when compressing (not             │
│              │                │          │        │                   │               │ decompressing) certain inputs...                             │
│              │                │          │        │                   │               │ https://avd.aquasec.com/nvd/cve-2018-25032                   │
└──────────────┴────────────────┴──────────┴────────┴───────────────────┴───────────────┴──────────────────────────────────────────────────────────────┘
2024-07-07T15:10:46+02:00       INFO    Table result includes only package filenames. Use '--format json' option to get the full path to the package file.

Node.js (node-pkg)

Total: 21 (UNKNOWN: 0, LOW: 1, MEDIUM: 4, HIGH: 15, CRITICAL: 1)

┌─────────────────────────────────────┬────────────────┬──────────┬──────────┬───────────────────┬──────────────────────────────────────────────────────────┬──────────────────────────────────────────────────────────────┐
│               Library               │ Vulnerability  │ Severity │  Status  │ Installed Version │                      Fixed Version                       │                            Title                             │
├─────────────────────────────────────┼────────────────┼──────────┼──────────┼───────────────────┼──────────────────────────────────────────────────────────┼──────────────────────────────────────────────────────────────┤
│ @npmcli/arborist (package.json)     │ CVE-2021-39134 │ HIGH     │ fixed    │ 2.6.4             │ 2.8.2                                                    │ nodejs-arborist: symlink following vulnerability             │
│                                     │                │          │          │                   │                                                          │ https://avd.aquasec.com/nvd/cve-2021-39134                   │
│                                     ├────────────────┤          │          │                   │                                                          ├──────────────────────────────────────────────────────────────┤
│                                     │ CVE-2021-39135 │          │          │                   │                                                          │ nodejs-arborist: symlink following vulnerability             │
│                                     │                │          │          │                   │                                                          │ https://avd.aquasec.com/nvd/cve-2021-39135                   │
├─────────────────────────────────────┼────────────────┤          │          ├───────────────────┼──────────────────────────────────────────────────────────┼──────────────────────────────────────────────────────────────┤
│ ansi-regex (package.json)           │ CVE-2021-3807  │          │          │ 3.0.0             │ 6.0.1, 5.0.1, 4.1.1, 3.0.1                               │ nodejs-ansi-regex: Regular expression denial of service      │
│                                     │                │          │          │                   │                                                          │ (ReDoS) matching ANSI escape codes                           │
│                                     │                │          │          │                   │                                                          │ https://avd.aquasec.com/nvd/cve-2021-3807                    │
│                                     │                │          │          ├───────────────────┤                                                          │                                                              │
│                                     │                │          │          │ 5.0.0             │                                                          │                                                              │
│                                     │                │          │          │                   │                                                          │                                                              │
│                                     │                │          │          │                   │                                                          │                                                              │
├─────────────────────────────────────┼────────────────┤          │          ├───────────────────┼──────────────────────────────────────────────────────────┼──────────────────────────────────────────────────────────────┤
│ http-cache-semantics (package.json) │ CVE-2022-25881 │          │          │ 4.1.0             │ 4.1.1                                                    │ http-cache-semantics: Regular Expression Denial of Service   │
│                                     │                │          │          │                   │                                                          │ (ReDoS) vulnerability                                        │
│                                     │                │          │          │                   │                                                          │ https://avd.aquasec.com/nvd/cve-2022-25881                   │
├─────────────────────────────────────┼────────────────┤          ├──────────┼───────────────────┼──────────────────────────────────────────────────────────┼──────────────────────────────────────────────────────────────┤
│ ip (package.json)                   │ CVE-2024-29415 │          │ affected │ 1.1.5             │                                                          │ node-ip: Incomplete fix for CVE-2023-42282                   │
│                                     │                │          │          │                   │                                                          │ https://avd.aquasec.com/nvd/cve-2024-29415                   │
│                                     ├────────────────┼──────────┼──────────┤                   ├──────────────────────────────────────────────────────────┼──────────────────────────────────────────────────────────────┤
│                                     │ CVE-2023-42282 │ LOW      │ fixed    │                   │ 2.0.1, 1.1.9                                             │ nodejs-ip: arbitrary code execution via the isPublic()       │
│                                     │                │          │          │                   │                                                          │ function                                                     │
│                                     │                │          │          │                   │                                                          │ https://avd.aquasec.com/nvd/cve-2023-42282                   │
├─────────────────────────────────────┼────────────────┼──────────┤          ├───────────────────┼──────────────────────────────────────────────────────────┼──────────────────────────────────────────────────────────────┤
│ json-schema (package.json)          │ CVE-2021-3918  │ CRITICAL │          │ 0.2.3             │ 0.4.0                                                    │ nodejs-json-schema: Prototype pollution vulnerability        │
│                                     │                │          │          │                   │                                                          │ https://avd.aquasec.com/nvd/cve-2021-3918                    │
├─────────────────────────────────────┼────────────────┼──────────┤          ├───────────────────┼──────────────────────────────────────────────────────────┼──────────────────────────────────────────────────────────────┤
│ minimatch (package.json)            │ CVE-2022-3517  │ HIGH     │          │ 3.0.4             │ 3.0.5                                                    │ nodejs-minimatch: ReDoS via the braceExpand function         │
│                                     │                │          │          │                   │                                                          │ https://avd.aquasec.com/nvd/cve-2022-3517                    │
├─────────────────────────────────────┼────────────────┤          │          ├───────────────────┼──────────────────────────────────────────────────────────┼──────────────────────────────────────────────────────────────┤
│ npm (package.json)                  │ CVE-2022-29244 │          │          │ 7.19.1            │ 8.11.0                                                   │ nodejs: npm pack ignores root-level .gitignore and           │
│                                     │                │          │          │                   │                                                          │ .npmignore file exclusion directives when...                 │
│                                     │                │          │          │                   │                                                          │ https://avd.aquasec.com/nvd/cve-2022-29244                   │
├─────────────────────────────────────┼────────────────┤          │          ├───────────────────┼──────────────────────────────────────────────────────────┼──────────────────────────────────────────────────────────────┤
│ qs (package.json)                   │ CVE-2022-24999 │          │          │ 6.5.2             │ 6.10.3, 6.9.7, 6.8.3, 6.7.3, 6.6.1, 6.5.3, 6.4.1, 6.3.3, │ express: "qs" prototype poisoning causes the hang of the     │
│                                     │                │          │          │                   │ 6.2.4                                                    │ node process                                                 │
│                                     │                │          │          │                   │                                                          │ https://avd.aquasec.com/nvd/cve-2022-24999                   │
├─────────────────────────────────────┼────────────────┼──────────┼──────────┼───────────────────┼──────────────────────────────────────────────────────────┼──────────────────────────────────────────────────────────────┤
│ request (package.json)              │ CVE-2023-28155 │ MEDIUM   │ affected │ 2.88.2            │                                                          │ The Request package through 2.88.1 for Node.js allows a      │
│                                     │                │          │          │                   │                                                          │ bypass of SSRF...                                            │
│                                     │                │          │          │                   │                                                          │ https://avd.aquasec.com/nvd/cve-2023-28155                   │
├─────────────────────────────────────┼────────────────┤          ├──────────┼───────────────────┼──────────────────────────────────────────────────────────┼──────────────────────────────────────────────────────────────┤
│ semver (package.json)               │ CVE-2022-25883 │          │ fixed    │ 7.3.5             │ 7.5.2, 6.3.1, 5.7.2                                      │ nodejs-semver: Regular expression denial of service          │
│                                     │                │          │          │                   │                                                          │ https://avd.aquasec.com/nvd/cve-2022-25883                   │
├─────────────────────────────────────┼────────────────┼──────────┤          ├───────────────────┼──────────────────────────────────────────────────────────┼──────────────────────────────────────────────────────────────┤
│ tar (package.json)                  │ CVE-2021-32803 │ HIGH     │          │ 6.1.0             │ 3.2.3, 4.4.15, 5.0.7, 6.1.2                              │ nodejs-tar: Insufficient symlink protection allowing         │
│                                     │                │          │          │                   │                                                          │ arbitrary file creation and overwrite                        │
│                                     │                │          │          │                   │                                                          │ https://avd.aquasec.com/nvd/cve-2021-32803                   │
│                                     ├────────────────┤          │          │                   ├──────────────────────────────────────────────────────────┼──────────────────────────────────────────────────────────────┤
│                                     │ CVE-2021-32804 │          │          │                   │ 3.2.2, 4.4.14, 5.0.6, 6.1.1                              │ nodejs-tar: Insufficient absolute path sanitization allowing │
│                                     │                │          │          │                   │                                                          │ arbitrary file creation and overwrite                        │
│                                     │                │          │          │                   │                                                          │ https://avd.aquasec.com/nvd/cve-2021-32804                   │
│                                     ├────────────────┤          │          │                   ├──────────────────────────────────────────────────────────┼──────────────────────────────────────────────────────────────┤
│                                     │ CVE-2021-37701 │          │          │                   │ 4.4.16, 5.0.8, 6.1.7                                     │ nodejs-tar: Insufficient symlink protection due to directory │
│                                     │                │          │          │                   │                                                          │ cache poisoning using symbolic links...                      │
│                                     │                │          │          │                   │                                                          │ https://avd.aquasec.com/nvd/cve-2021-37701                   │
│                                     ├────────────────┤          │          │                   ├──────────────────────────────────────────────────────────┼──────────────────────────────────────────────────────────────┤
│                                     │ CVE-2021-37712 │          │          │                   │ 4.4.18, 5.0.10, 6.1.9                                    │ nodejs-tar: Insufficient symlink protection due to directory │
│                                     │                │          │          │                   │                                                          │ cache poisoning using symbolic links...                      │
│                                     │                │          │          │                   │                                                          │ https://avd.aquasec.com/nvd/cve-2021-37712                   │
│                                     ├────────────────┤          │          │                   │                                                          ├──────────────────────────────────────────────────────────────┤
│                                     │ CVE-2021-37713 │          │          │                   │                                                          │ nodejs-tar: Arbitrary File Creation/Overwrite on Windows via │
│                                     │                │          │          │                   │                                                          │ insufficient relative path sanitization                      │
│                                     │                │          │          │                   │                                                          │ https://avd.aquasec.com/nvd/cve-2021-37713                   │
│                                     ├────────────────┼──────────┤          │                   ├──────────────────────────────────────────────────────────┼──────────────────────────────────────────────────────────────┤
│                                     │ CVE-2024-28863 │ MEDIUM   │          │                   │ 6.2.1                                                    │ node-tar: denial of service while parsing a tar file due to  │
│                                     │                │          │          │                   │                                                          │ lack...                                                      │
│                                     │                │          │          │                   │                                                          │ https://avd.aquasec.com/nvd/cve-2024-28863                   │
├─────────────────────────────────────┼────────────────┤          │          ├───────────────────┼──────────────────────────────────────────────────────────┼──────────────────────────────────────────────────────────────┤
│ tough-cookie (package.json)         │ CVE-2023-26136 │          │          │ 2.5.0             │ 4.1.3                                                    │ tough-cookie: prototype pollution in cookie memstore         │
│                                     │                │          │          │                   │                                                          │ https://avd.aquasec.com/nvd/cve-2023-26136                   │
├─────────────────────────────────────┼────────────────┼──────────┤          ├───────────────────┼──────────────────────────────────────────────────────────┼──────────────────────────────────────────────────────────────┤
│ yarn (package.json)                 │ CVE-2021-4435  │ HIGH     │          │ 1.22.10           │ 1.22.13                                                  │ yarn: untrusted search path                                  │
│                                     │                │          │          │                   │                                                          │ https://avd.aquasec.com/nvd/cve-2021-4435                    │
└─────────────────────────────────────┴────────────────┴──────────┴──────────┴───────────────────┴──────────────────────────────────────────────────────────┴──────────────────────────────────────────────────────────────┘
```
trivy : Total: 37 (UNKNOWN: 0, LOW: 0, MEDIUM: 6, HIGH: 27, CRITICAL: 4)
npm : found 102 vulnerabilities (2 low, 58 moderate, 38 high, 4 critical)

### BACKEND
_npm audit_ :
```sh
[root@localhost back_student]# npm audit

                       === npm audit security report ===

# Run  npm install jest@29.7.0  to resolve 24 vulnerabilities
SEMVER WARNING: Recommended action is a potentially breaking change
┌───────────────┬──────────────────────────────────────────────────────────────┐
│ Moderate      │ OS Command Injection in node-notifier                        │
├───────────────┼──────────────────────────────────────────────────────────────┤
│ Package       │ node-notifier                                                │
├───────────────┼──────────────────────────────────────────────────────────────┤
│ Dependency of │ jest                                                         │
├───────────────┼──────────────────────────────────────────────────────────────┤
│ Path          │ jest > jest-cli > @jest/core > @jest/reporters >             │
│               │ node-notifier                                                │
├───────────────┼──────────────────────────────────────────────────────────────┤
│ More info     │ https://github.com/advisories/GHSA-5fw9-fq32-wv5p            │
└───────────────┴──────────────────────────────────────────────────────────────┘


┌───────────────┬──────────────────────────────────────────────────────────────┐
│ Moderate      │ Insufficient Granularity of Access Control in JSDom          │
├───────────────┼──────────────────────────────────────────────────────────────┤
│ Package       │ jsdom                                                        │
├───────────────┼──────────────────────────────────────────────────────────────┤
│ Dependency of │ jest                                                         │
├───────────────┼──────────────────────────────────────────────────────────────┤
│ Path          │ jest > jest-cli > jest-config > jest-environment-jsdom >     │
│               │ jsdom                                                        │
├───────────────┼──────────────────────────────────────────────────────────────┤
│ More info     │ https://github.com/advisories/GHSA-f4c9-cqv8-9v98            │
└───────────────┴──────────────────────────────────────────────────────────────┘
...
found 43 vulnerabilities (27 moderate, 13 high, 3 critical) in 884 scanned packages
  run `npm audit fix` to fix 8 of them.
  29 vulnerabilities require semver-major dependency updates.
  6 vulnerabilities require manual review. See the full report for details.
```
Trivy pour le back :
```sh
back (alpine 3.9.4)

Total: 26 (UNKNOWN: 0, LOW: 4, MEDIUM: 14, HIGH: 6, CRITICAL: 2)

┌──────────────┬────────────────┬──────────┬────────┬───────────────────┬───────────────┬──────────────────────────────────────────────────────────────┐
│   Library    │ Vulnerability  │ Severity │ Status │ Installed Version │ Fixed Version │                            Title                             │
├──────────────┼────────────────┼──────────┼────────┼───────────────────┼───────────────┼──────────────────────────────────────────────────────────────┤
│ libcrypto1.1 │ CVE-2020-1967  │ HIGH     │ fixed  │ 1.1.1b-r1         │ 1.1.1g-r0     │ openssl: Segmentation fault in SSL_check_chain causes denial │
│              │                │          │        │                   │               │ of service                                                   │
│              │                │          │        │                   │               │ https://avd.aquasec.com/nvd/cve-2020-1967                    │
│              ├────────────────┤          │        │                   ├───────────────┼──────────────────────────────────────────────────────────────┤
│              │ CVE-2021-23840 │          │        │                   │ 1.1.1j-r0     │ openssl: integer overflow in CipherUpdate                    │
│              │                │          │        │                   │               │ https://avd.aquasec.com/nvd/cve-2021-23840                   │
│              ├────────────────┤          │        │                   ├───────────────┼──────────────────────────────────────────────────────────────┤
│              │ CVE-2021-3450  │          │        │                   │ 1.1.1k-r0     │ openssl: CA certificate check bypass with                    │
│              │                │          │        │                   │               │ X509_V_FLAG_X509_STRICT                                      │
│              │                │          │        │                   │               │ https://avd.aquasec.com/nvd/cve-2021-3450                    │
│              ├────────────────┼──────────┤        │                   ├───────────────┼──────────────────────────────────────────────────────────────┤
│              │ CVE-2019-1547  │ MEDIUM   │        │                   │ 1.1.1d-r0     │ openssl: side-channel weak encryption vulnerability          │
│              │                │          │        │                   │               │ https://avd.aquasec.com/nvd/cve-2019-1547                    │
│              ├────────────────┤          │        │                   │               ├──────────────────────────────────────────────────────────────┤
│              │ CVE-2019-1549  │          │        │                   │               │ openssl: information disclosure in fork()                    │
│              │                │          │        │                   │               │ https://avd.aquasec.com/nvd/cve-2019-1549                    │
│              ├────────────────┤          │        │                   ├───────────────┼──────────────────────────────────────────────────────────────┤
│              │ CVE-2019-1551  │          │        │                   │ 1.1.1d-r2     │ openssl: Integer overflow in RSAZ modular exponentiation on  │
│              │                │          │        │                   │               │ x86_64                                                       │
│              │                │          │        │                   │               │ https://avd.aquasec.com/nvd/cve-2019-1551                    │
│              ├────────────────┤          │        │                   ├───────────────┼──────────────────────────────────────────────────────────────┤
│              │ CVE-2020-1971  │          │        │                   │ 1.1.1i-r0     │ openssl: EDIPARTYNAME NULL pointer de-reference              │
│              │                │          │        │                   │               │ https://avd.aquasec.com/nvd/cve-2020-1971                    │
│              ├────────────────┤          │        │                   ├───────────────┼──────────────────────────────────────────────────────────────┤
│              │ CVE-2021-23841 │          │        │                   │ 1.1.1j-r0     │ openssl: NULL pointer dereference in                         │
│              │                │          │        │                   │               │ X509_issuer_and_serial_hash()                                │
│              │                │          │        │                   │               │ https://avd.aquasec.com/nvd/cve-2021-23841                   │
│              ├────────────────┤          │        │                   ├───────────────┼──────────────────────────────────────────────────────────────┤
│              │ CVE-2021-3449  │          │        │                   │ 1.1.1k-r0     │ openssl: NULL pointer dereference in signature_algorithms    │
│              │                │          │        │                   │               │ processing                                                   │
│              │                │          │        │                   │               │ https://avd.aquasec.com/nvd/cve-2021-3449                    │
│              ├────────────────┼──────────┤        │                   ├───────────────┼──────────────────────────────────────────────────────────────┤
│              │ CVE-2019-1563  │ LOW      │        │                   │ 1.1.1d-r0     │ openssl: information disclosure in PKCS7_dataDecode and      │
│              │                │          │        │                   │               │ CMS_decrypt_set1_pkey                                        │
│              │                │          │        │                   │               │ https://avd.aquasec.com/nvd/cve-2019-1563                    │
│              ├────────────────┤          │        │                   ├───────────────┼──────────────────────────────────────────────────────────────┤
│              │ CVE-2021-23839 │          │        │                   │ 1.1.1j-r0     │ openssl: incorrect SSLv2 rollback protection                 │
│              │                │          │        │                   │               │ https://avd.aquasec.com/nvd/cve-2021-23839                   │
├──────────────┼────────────────┼──────────┤        │                   ├───────────────┼──────────────────────────────────────────────────────────────┤
...
```

On remarque que nous avons beaucoup de vulnérabilités hautes et critiques qu'il va être nécessaire de corriger, nous devons aussi trouver un moyen de palier à une des faiblesse de docker, le fait que les build soit faites avec root.

### Intervention sur les dockerfiles :
Pour commencer il sera nécessaire d'upgrader la version de node, nous avons donc optés pour node 20. Nous avons ensuite effectuer quelques ajustments sur les droits des users docker, et du debeug afin de pouvoir avoir des images front et back tournantes.
_FRONTEND_ :
```Dockerfile
# First stage: Build the application
FROM node:20-alpine AS builder
WORKDIR /app
COPY . .
RUN yarn install
# Set the environment variable for OpenSSL legacy support
ENV NODE_OPTIONS=--openssl-legacy-provider
RUN yarn build

# Second stage: Serve the application
FROM node:20-alpine
WORKDIR /app
COPY --from=builder /app/build .
RUN yarn global add serve
CMD ["serve", "-p", "80", "-s", "."]
```
_BACKEND_ :
```Dockerfile
# Use Node.js version 20 Alpine image
FROM node:20-alpine

# Install necessary packages
RUN apk add --no-cache python3 py3-pip make g++ \
    && ln -sf python3 /usr/bin/python

# Set the working directory in the container
WORKDIR /usr/src/app

# Copy package.json and yarn.lock files
COPY package.json yarn.lock ./

# Install dependencies with increased network timeout
RUN yarn install --network-timeout 1000000

# Copy the rest of your application code
COPY . .

# Copy and set permissions for the entrypoint script
COPY entrypoint.sh /usr/src/app/entrypoint.sh
RUN chmod +x /usr/src/app/entrypoint.sh

# Add a non-root user and switch to it
RUN addgroup -S appgroup && adduser -S appuser -G appgroup
USER appuser

# Expose port 3000 for external access
EXPOSE 3000

# Set the entrypoint to start your application
ENTRYPOINT ["/usr/src/app/entrypoint.sh"]
```
Ici nous avons donc utilisé une nouvelle version de node 20, nous avons créé et spécifié les droits un user pour le back `appuser` et nous avons spécifié un entrypoint.sh.

```yaml
services:
  db:
    image: mysql:5.7
    container_name: dev_db
    volumes:
      - db_data:/var/lib/mysql
    restart: always
    environment:
      MYSQL_ROOT_PASSWORD_FILE: /run/secrets/db_root_password
      MYSQL_DATABASE: dev_db
      MYSQL_USER: dev_user
      MYSQL_PASSWORD_FILE: /run/secrets/db_password
    secrets:
      - db_root_password
      - db_password
    ports:
      - "3306:3306"
    networks:
      - backend
    security_opt:
      - no-new-privileges:true
    cap_add:
      - SYS_NICE
      - SYS_RESOURCE
    mem_limit: 2g
    mem_reservation: 1g

  api:
    container_name: dev_api
    image: sample-express-app
    build: .
    restart: always
    environment:
      DB_HOST: db
      DB_USER: dev_user
      DB_PASSWORD_FILE: /run/secrets/db_password
    secrets:
      - db_password
    ports:
      - "3000:3000"
    networks:
      - backend
    depends_on:
      - db
    security_opt:
      - no-new-privileges:true
    cap_drop:
      - ALL
    read_only: true
    tmpfs:
      - /tmp

networks:
  backend:
    driver: bridge

volumes:
  db_data:

secrets:
  db_root_password:
    file: ./secrets/db_root_password.txt
  db_password:
    file: ./secrets/db_password.txt
```
Ici le dockercompose reprend beaucoup le premier sauf que celui présente quelques modifications, notamment des restrictions niveau mémoire pour la db, des variables d'environnement nouvelles pour cloisonner chaque services.

### Test final

Nous allons desormais tester la résilence de notre applicatif docker grâce à Trivy.
_FRONTEND_ :
```sh
[admin@localhost front_student]$ trivy image front_student-front
2024-07-07T13:16:44+02:00       INFO    Need to update DB
2024-07-07T13:16:44+02:00       INFO    Downloading DB...       repository="ghcr.io/aquasecurity/trivy-db:2"
49.62 MiB / 49.62 MiB [-----------------------------------------------------------------------------------------------------------] 100.00% 22.69 MiB p/s 2.4s
2024-07-07T13:16:47+02:00       INFO    Vulnerability scanning is enabled
2024-07-07T13:16:47+02:00       INFO    Secret scanning is enabled
2024-07-07T13:16:47+02:00       INFO    If your scanning is slow, please try '--scanners vuln' to disable secret scanning
2024-07-07T13:16:47+02:00       INFO    Please see also https://aquasecurity.github.io/trivy/v0.53/docs/scanner/secret#recommendation for faster secret detection
2024-07-07T13:16:51+02:00       INFO    Detected OS     family="alpine" version="3.20.0"
2024-07-07T13:16:51+02:00       INFO    [alpine] Detecting vulnerabilities...   os_version="3.20" repository="3.20" pkg_num=16
2024-07-07T13:16:51+02:00       INFO    Number of language-specific files       num=1
2024-07-07T13:16:51+02:00       INFO    [node-pkg] Detecting vulnerabilities...
2024-07-07T13:16:51+02:00       WARN    Using severities from other vendors for some vulnerabilities. Read https://aquasecurity.github.io/trivy/v0.53/docs/scanner/vulnerability#severity-selection for details.

front_student-front (alpine 3.20.0)

Total: 10 (UNKNOWN: 0, LOW: 0, MEDIUM: 10, HIGH: 0, CRITICAL: 0)

┌───────────────┬────────────────┬──────────┬────────┬───────────────────┬───────────────┬────────────────────────────────────────────────┐
│    Library    │ Vulnerability  │ Severity │ Status │ Installed Version │ Fixed Version │                     Title                      │
├───────────────┼────────────────┼──────────┼────────┼───────────────────┼───────────────┼────────────────────────────────────────────────┤
│ busybox       │ CVE-2023-42364 │ MEDIUM   │ fixed  │ 1.36.1-r28        │ 1.36.1-r29    │ busybox: use-after-free                        │
│               │                │          │        │                   │               │ https://avd.aquasec.com/nvd/cve-2023-42364     │
│               ├────────────────┤          │        │                   │               ├────────────────────────────────────────────────┤
│               │ CVE-2023-42365 │          │        │                   │               │ busybox: use-after-free                        │
│               │                │          │        │                   │               │ https://avd.aquasec.com/nvd/cve-2023-42365     │
├───────────────┼────────────────┤          │        │                   │               ├────────────────────────────────────────────────┤
│ busybox-binsh │ CVE-2023-42364 │          │        │                   │               │ busybox: use-after-free                        │
│               │                │          │        │                   │               │ https://avd.aquasec.com/nvd/cve-2023-42364     │
│               ├────────────────┤          │        │                   │               ├────────────────────────────────────────────────┤
│               │ CVE-2023-42365 │          │        │                   │               │ busybox: use-after-free                        │
│               │                │          │        │                   │               │ https://avd.aquasec.com/nvd/cve-2023-42365     │
├───────────────┼────────────────┤          │        ├───────────────────┼───────────────┼────────────────────────────────────────────────┤
│ libcrypto3    │ CVE-2024-4741  │          │        │ 3.3.0-r2          │ 3.3.0-r3      │ openssl: Use After Free with SSL_free_buffers  │
│               │                │          │        │                   │               │ https://avd.aquasec.com/nvd/cve-2024-4741      │
│               ├────────────────┤          │        │                   ├───────────────┼────────────────────────────────────────────────┤
│               │ CVE-2024-5535  │          │        │                   │ 3.3.1-r1      │ openssl: SSL_select_next_proto buffer overread │
│               │                │          │        │                   │               │ https://avd.aquasec.com/nvd/cve-2024-5535      │
├───────────────┼────────────────┤          │        │                   ├───────────────┼────────────────────────────────────────────────┤
│ libssl3       │ CVE-2024-4741  │          │        │                   │ 3.3.0-r3      │ openssl: Use After Free with SSL_free_buffers  │
│               │                │          │        │                   │               │ https://avd.aquasec.com/nvd/cve-2024-4741      │
│               ├────────────────┤          │        │                   ├───────────────┼────────────────────────────────────────────────┤
│               │ CVE-2024-5535  │          │        │                   │ 3.3.1-r1      │ openssl: SSL_select_next_proto buffer overread │
│               │                │          │        │                   │               │ https://avd.aquasec.com/nvd/cve-2024-5535      │
├───────────────┼────────────────┤          │        ├───────────────────┼───────────────┼────────────────────────────────────────────────┤
│ ssl_client    │ CVE-2023-42364 │          │        │ 1.36.1-r28        │ 1.36.1-r29    │ busybox: use-after-free                        │
│               │                │          │        │                   │               │ https://avd.aquasec.com/nvd/cve-2023-42364     │
│               ├────────────────┤          │        │                   │               ├────────────────────────────────────────────────┤
│               │ CVE-2023-42365 │          │        │                   │               │ busybox: use-after-free                        │
│               │                │          │        │                   │               │ https://avd.aquasec.com/nvd/cve-2023-42365     │
└───────────────┴────────────────┴──────────┴────────┴───────────────────┴───────────────┴────────────────────────────────────────────────┘
```
_BACKEND_
```sh
[admin@localhost back_student]$ trivy image back
2024-07-07T13:20:47+02:00       INFO    Vulnerability scanning is enabled
2024-07-07T13:20:47+02:00       INFO    Secret scanning is enabled
2024-07-07T13:20:47+02:00       INFO    If your scanning is slow, please try '--scanners vuln' to disable secret scanning
2024-07-07T13:20:47+02:00       INFO    Please see also https://aquasecurity.github.io/trivy/v0.53/docs/scanner/secret#recommendation for faster secret detection
2024-07-07T13:21:16+02:00       INFO    Detected OS     family="alpine" version="3.20.1"
2024-07-07T13:21:16+02:00       INFO    [alpine] Detecting vulnerabilities...   os_version="3.20" repository="3.20" pkg_num=53
2024-07-07T13:21:16+02:00       INFO    Number of language-specific files       num=1
2024-07-07T13:21:16+02:00       INFO    [node-pkg] Detecting vulnerabilities...
2024-07-07T13:21:16+02:00       WARN    Using severities from other vendors for some vulnerabilities. Read https://aquasecurity.github.io/trivy/v0.53/docs/scanner/vulnerability#severity-selection for details.

back (alpine 3.20.1)

Total: 2 (UNKNOWN: 0, LOW: 0, MEDIUM: 2, HIGH: 0, CRITICAL: 0)

┌────────────┬───────────────┬──────────┬────────┬───────────────────┬───────────────┬────────────────────────────────────────────────┐
│  Library   │ Vulnerability │ Severity │ Status │ Installed Version │ Fixed Version │                     Title                      │
├────────────┼───────────────┼──────────┼────────┼───────────────────┼───────────────┼────────────────────────────────────────────────┤
│ libcrypto3 │ CVE-2024-5535 │ MEDIUM   │ fixed  │ 3.3.1-r0          │ 3.3.1-r1      │ openssl: SSL_select_next_proto buffer overread │
│            │               │          │        │                   │               │ https://avd.aquasec.com/nvd/cve-2024-5535      │
├────────────┤               │          │        │                   │               │                                                │
│ libssl3    │               │          │        │                   │               │                                                │
│            │               │          │        │                   │               │                                                │
└────────────┴───────────────┴──────────┴────────┴───────────────────┴───────────────┴────────────────────────────────────────────────┘
2024-07-07T13:21:16+02:00       INFO    Table result includes only package filenames. Use '--format json' option to get the full path to the package file.

Node.js (node-pkg)

Total: 6 (UNKNOWN: 0, LOW: 0, MEDIUM: 6, HIGH: 0, CRITICAL: 0)

┌──────────────────────────┬─────────────────────┬──────────┬────────┬───────────────────┬───────────────┬───────────────────────────────────────────────────────────┐
│         Library          │    Vulnerability    │ Severity │ Status │ Installed Version │ Fixed Version │                           Title                           │
├──────────────────────────┼─────────────────────┼──────────┼────────┼───────────────────┼───────────────┼───────────────────────────────────────────────────────────┤
│ validator (package.json) │ CVE-2021-3765       │ MEDIUM   │ fixed  │ 11.1.0            │ 13.7.0        │ validator: Inefficient Regular Expression Complexity in   │
│                          │                     │          │        │                   │               │ Validator.js                                              │
│                          │                     │          │        │                   │               │ https://avd.aquasec.com/nvd/cve-2021-3765                 │
│                          │                     │          │        │                   │               │                                                           │
│                          │                     │          │        │                   │               │                                                           │
│                          │                     │          │        │                   │               │                                                           │
│                          │                     │          │        │                   │               │                                                           │
│                          │                     │          │        │                   │               │                                                           │
│                          │                     │          │        │                   │               │                                                           │
│                          │                     │          │        │                   │               │                                                           │
│                          │                     │          │        │                   │               │                                                           │
│                          ├─────────────────────┤          │        │                   │               ├───────────────────────────────────────────────────────────┤
│                          │ GHSA-xx4c-jj58-r7x6 │          │        │                   │               │ Inefficient Regular Expression Complexity in Validator.js │
│                          │                     │          │        │                   │               │ https://github.com/advisories/GHSA-xx4c-jj58-r7x6         │
│                          │                     │          │        │                   │               │                                                           │
│                          │                     │          │        │                   │               │                                                           │
│                          │                     │          │        │                   │               │                                                           │
│                          │                     │          │        │                   │               │                                                           │
│                          │                     │          │        │                   │               │                                                           │
│                          │                     │          │        │                   │               │                                                           │
└──────────────────────────┴─────────────────────┴──────────┴────────┴───────────────────┴───────────────┴───────────────────────────────────────────────────────────┘
```
Nous avons desormais, aucune faille haute, ni critique, quelques failles modérées sont tout de même à souligner.

## Conclusion

La migration vers AlmaLinux et la refonte complète de notre infrastructure ont permis de renforcer significativement la sécurité et la stabilité de notre système. Nous avons remplacé les services obsolètes par des alternatives modernes, mis à jour nos systèmes d'exploitation, et mis en place des configurations systemd pour une gestion plus cohérente des services. De plus, nous avons renforcé notre politique de sécurité en utilisant SELinux pour restreindre les actions des services et des utilisateurs.

Cependant, malgré ces améliorations, il est crucial de reconnaître qu'un système d'information (SI) ne peut jamais être sécurisé à 100%. Les menaces évoluent constamment, et de nouvelles vulnérabilités peuvent être découvertes à tout moment. C'est pourquoi il est essentiel de maintenir une vigilance constante, d'effectuer des audits réguliers, et de continuer à améliorer notre infrastructure de manière proactive.

### Pistes d'Amélioration Continues

- **Système :**
  - Poursuivre la mise en place de configurations systemd pour normaliser les services.
  - Utiliser SELinux de manière plus extensive pour renforcer les politiques de sécurité.

- **Réseau :**
  - Améliorer la segmentation réseau pour isoler les services critiques et limiter les mouvements latéraux.
  - Mettre en place des VLANs et des règles de pare-feu strictes.

- **Applicatif :**
  - Mettre en place un processus régulier de mise à jour des dépendances et des packages.
  - Utiliser des outils de sécurité pour identifier et corriger les vulnérabilités dès qu'elles sont découvertes.

En conclusion, la sécurité de notre infrastructure est un processus continu qui nécessite une attention constante et des améliorations régulières. Bien que nous ne puissions jamais atteindre une sécurité absolue, nous devons nous efforcer de minimiser les risques et de réagir rapidement aux nouvelles menaces pour protéger au mieux notre système d'information.
