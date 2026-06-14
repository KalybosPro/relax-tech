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
