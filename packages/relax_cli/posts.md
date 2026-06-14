---
## Carrousel LinkedIn — 5 slides

---

### Slide 1/5 — ACCROCHE

**Tag :** `>_ DART CLI · FLUTTER`

**Titre :**
Starting a new Flutter project
shouldn't mean repeating
the **same boring setup** again.

**Sous-titre :**
I built `relax_cli` to generate a production-ready Flutter project in seconds.

**Boutons :**
`>_ Dart CLI`   `⚡ Clean Architecture`   `🗄 RelaxORM`

**Terminal :**
```
$ dart pub global activate relax_cli
$ relax --help
```

---

### Slide 2/5 — LE PROBLÈME

**Tag :** `⚠ THE PROBLEM`

**Titre :** The usual problem

**Sous-titre :** Starting from scratch or copy-pasting old projects wastes time.

**Checklist :**
- ✅ Setup project folders
- ✅ Configure Material 3 theme
- ✅ Add state management (Bloc / Riverpod / Provider / GetX)
- ✅ Setup multi-flavor (dev, staging, prod)
- ✅ Wire dependency injection (GetIt)
- ✅ Add local persistence / ORM
- ✅ Fix imports and barrel files

**Note :** `⚠ It works, but it's repetitive and messy.`

---

### Slide 3/5 — LA SOLUTION

**Tag :** `</> THE SOLUTION`

**Titre :**
So I built
`relax_cli`

**Sous-titre :** A Dart CLI to generate Flutter Clean Architecture projects faster.

**Boutons :**
`📁 Project`   `🧩 Feature`   `📄 Page`   `📦 Module`

**Terminal :**
```
$ relax create my_app
$ relax generate feature auth
$ relax generate page auth login
$ relax generate module product
```

**Note :** Generate a consistent, production-ready structure in seconds.

---

### Slide 4/5 — CE QUE ÇA GÉNÈRE

**Tag :** `</> WHAT IT GENERATES`

**Titre :**
Generate the
**boring setup**
in seconds.

**Checklist :**
- ✅ Complete project structure (Clean Architecture)
- ✅ State management — Bloc, Provider, Riverpod, GetX
- ✅ Material 3 theme (light/dark + custom color)
- ✅ Multi-flavor — dev, staging, production
- ✅ Dependency injection (GetIt)
- ✅ RelaxORM module — Repository + Collection\<T\> + reactive streams
- ✅ Internationalization via slang
- ✅ Auto `build_runner` on module/model creation

**Note :** `More consistent, less repetitive.`

---

### Slide 5/5 — ESSAIE-LE

**Tag :** `</> TRY IT`

**Titre :** Ready **to try it?**

**Sous-titre :** Install it, explore it, and let me know your feedback.

**Terminal :**
```
$ dart pub global activate relax_cli
$ relax --help
```

**Lien :** `pub.dev/packages/relax_cli`

**Note :** `💬 Feedback and ideas are welcome.`

---

Post 1 — Lancement / Annonce
🚀 J'ai créé Relax CLI — un outil en ligne de commande pour scaffolder des projets Flutter en quelques secondes.

En tant que développeur Flutter, j'en avais marre de passer 30 minutes à configurer chaque nouveau projet : architecture, thème Material 3, state management, fichiers de base…

Relax CLI fait tout ça pour vous :

✅ relax create my_app → projet complet avec clean architecture
✅ Choix du state management : Bloc, Provider, Riverpod ou GetX
✅ Thème Material 3 (light/dark) personnalisable
✅ Flavors Android (dev, staging, prod) préconfigurés
✅ RelaxORM intégré pour la persistance locale

Une seule commande. Zéro boilerplate.

Le projet est open source et disponible sur pub.dev.

Si vous êtes développeur Flutter, testez-le et dites-moi ce que vous en pensez 👇

dart pub global activate relax

#Flutter #Dart #OpenSource #DevTools #MobileApp #CleanArchitecture

Post 2 — Focus technique (génération de features)
💡 Vous ajoutez une nouvelle feature à votre app Flutter ?

Ne recréez pas tout à la main.

Avec Relax CLI, une seule commande :


relax generate feature auth
Et vous obtenez :
→ Le dossier features/auth/ complet
→ Le Bloc (ou Provider/Riverpod/GetX) avec events + states en sealed classes
→ Les vues avec barrel files

Le meilleur ? Relax détecte automatiquement l'architecture de votre projet depuis le pubspec.yaml. Pas besoin de préciser si vous utilisez Bloc ou Riverpod.

Ça marche aussi pour les modules de données :


relax generate module product
→ Repository pattern + RelaxORM intégré + build_runner lancé automatiquement.

Moins de config, plus de code métier.

#Flutter #Dart #Productivity #DeveloperExperience #CodeGeneration

Post 3 — Storytelling / Problème-Solution
🤔 Combien de temps perdez-vous à configurer un projet Flutter avant d'écrire la première ligne de code métier ?

Moi, c'était entre 30 et 45 minutes. À chaque fois.

Créer l'arborescence. Configurer le thème. Mettre en place le state management. Ajouter les flavors. Copier-coller depuis un ancien projet…

J'ai décidé d'automatiser tout ça.

Relax CLI génère un projet Flutter production-ready en une commande :

• Clean architecture feature-based
• Material 3 avec palette de couleurs personnalisée
• Sealed classes Dart 3+
• Environnements dev/staging/prod avec fichiers .env
• ORM local intégré avec CRUD typé et streams réactifs

Ce qui me prenait 45 minutes prend maintenant 10 secondes.

L'outil est open source (licence MIT) et disponible dès maintenant.

Si ça peut vous faire gagner du temps aussi, le lien est en commentaire 👇

#Flutter #Dart #OpenSource #Productivity #DeveloperTools

Post 4 — Focus sur RelaxORM / différenciation
📦 La plupart des CLI Flutter génèrent la structure. Relax CLI va plus loin.

Ce qui différencie Relax des autres outils de scaffolding :

RelaxORM — un ORM local-first intégré directement dans les modules générés.

Quand vous faites :


relax generate module product
Vous obtenez un modèle annoté @RelaxTable(), un repository avec Collection<Product> pour du CRUD typé, des streams réactifs pour l'UI, et le build_runner se lance automatiquement.

Pas de configuration supplémentaire. Pas de dépendances à installer manuellement.

Ajoutez à ça :
→ Support Bloc, Provider, Riverpod, GetX
→ Détection automatique de l'architecture existante
→ Commande relax doctor pour vérifier votre environnement

Relax CLI, c'est l'outil que j'aurais voulu avoir quand j'ai commencé Flutter.

Disponible en open source → lien en commentaire.

#Flutter #Dart #ORM #LocalFirst #OpenSource #DevTools #CleanArchitecture
