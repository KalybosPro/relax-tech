# Spécification Technique — Module `relax quality`

## Sommaire
1. Vue d'ensemble et principes directeurs
2. Architecture du module
3. Structure des dossiers
4. Interfaces TypeScript centrales
5. Pipeline d'analyse AST Dart
6. Moteur de détection et génération des UseCases
7. Moteur de génération de tests
8. Mocks et fakes
9. Exécution des tests et couverture
10. Moteur de règles qualité
11. Dashboard web
12. Format des données échangées
13. Persistance de l'historique
14. Stratégie CI/CD
15. Performances attendues
16. Risques techniques et mitigations
17. Plan d'implémentation par phases

---

## 1. Vue d'ensemble et principes directeurs

`relax quality` est un sous-système ajouté à Relax CLI qui transforme un générateur de code en **plateforme d'analyse et d'amélioration continue de la qualité** pour des projets Flutter, quel que soit le state management utilisé (GetX, Bloc/Cubit, Riverpod, Provider, MobX, ou aucun).

Principes non négociables :

- **Non-destructif par défaut.** Toute modification de code est un diff proposé, jamais appliqué silencieusement (sauf `--fix` sur une liste blanche de transformations sûres).
- **Idempotence.** Relancer l'analyse sur un projet déjà traité ne doit produire aucun changement.
- **Agnostique à l'architecture.** Le système doit fonctionner même si le projet n'a ni UseCase, ni Repository, ni couche testée.
- **Scalable.** Cible : projets de 100k+ lignes Dart, analyse incrémentale (cache basé sur hash de fichier).
- **Séparation stricte** entre *analyse* (lecture seule), *génération* (écriture proposée), *exécution* (flutter test), et *présentation* (dashboard).

---

## 2. Architecture du module

```
                         ┌─────────────────────┐
                         │   relax quality CLI  │
                         │   (orchestrateur)     │
                         └──────────┬───────────┘
                                    │
        ┌───────────────┬──────────┼───────────────┬───────────────┐
        ▼               ▼          ▼               ▼               ▼
 ┌─────────────┐ ┌─────────────┐ ┌───────────┐ ┌───────────┐ ┌─────────────┐
 │ Analyzer     │ │ UseCase Gen │ │ Test Gen  │ │ Runner    │ │ Dashboard    │
 │ (AST + Graph)│ │ Engine      │ │ Engine    │ │ (test+cov)│ │ Server       │
 └──────┬───────┘ └──────┬──────┘ └─────┬─────┘ └─────┬─────┘ └──────┬──────┘
        │                │              │             │              │
        └────────────────┴──────┬───────┴─────────────┴──────────────┘
                                 ▼
                        ┌─────────────────┐
                        │  Quality Store   │
                        │ (JSON/SQLite)    │
                        └─────────────────┘
```

Chaque bloc est un module TypeScript indépendant communiquant via des interfaces typées et un bus d'événements interne (`EventEmitter` ou équivalent léger), ce qui permet de lancer chaque étape isolément (`--generate-usecases`, `--test`, `--dashboard`, etc.).

---

## 3. Structure des dossiers

```
relax-cli/
└── src/
    └── quality/
        ├── index.ts                     # point d'entrée, parsing des flags
        ├── config/
        │   ├── quality.config.ts        # schéma de config (.relaxrc quality section)
        │   └── defaults.ts
        ├── analyzer/
        │   ├── dart-parser.ts           # wrapper autour d'un parseur AST Dart
        │   ├── ast-visitor.ts           # visiteur générique
        │   ├── dependency-graph.ts      # construction du graphe UI→...→API
        │   ├── layer-classifier.ts      # classification widget/controller/usecase/...
        │   ├── state-management/
        │   │   ├── getx.ts
        │   │   ├── bloc.ts
        │   │   ├── riverpod.ts
        │   │   ├── provider.ts
        │   │   └── mobx.ts
        │   └── business-function-detector.ts
        ├── architecture/
        │   ├── flow-validator.ts        # UI→Controller→UseCase→Repo→Datasource→API
        │   ├── violation-rules.ts
        │   └── violation-reporter.ts
        ├── usecase-engine/
        │   ├── usecase-detector.ts
        │   ├── usecase-generator.ts
        │   ├── code-transformer.ts      # déplace la logique métier, garde les appels
        │   └── templates/
        │       └── usecase.template.ts
        ├── test-engine/
        │   ├── test-gap-detector.ts
        │   ├── test-case-synthesizer.ts # génère groups/it à partir de la signature
        │   ├── scenario-library.ts      # succès, erreurs réseau, timeout, etc.
        │   └── templates/
        │       └── test.template.ts
        ├── mock-engine/
        │   ├── mock-generator.ts
        │   ├── fake-generator.ts
        │   └── templates/
        ├── runner/
        │   ├── test-runner.ts           # flutter test
        │   ├── coverage-runner.ts       # flutter test --coverage
        │   └── lcov-parser.ts
        ├── quality-rules/
        │   ├── rule-engine.ts
        │   ├── rules/
        │   │   ├── file-length.rule.ts
        │   │   ├── function-length.rule.ts
        │   │   ├── cyclomatic-complexity.rule.ts
        │   │   ├── duplication.rule.ts
        │   │   ├── dead-code.rule.ts
        │   │   ├── unused-imports.rule.ts
        │   │   ├── unused-vars.rule.ts
        │   │   ├── widget-rebuild.rule.ts
        │   │   ├── futurebuilder-misuse.rule.ts
        │   │   └── build-method-size.rule.ts
        │   └── suggestion-formatter.ts
        ├── ai-advisor/
        │   ├── provider.ts               # interface commune OpenAI/Gemini/Claude/local
        │   └── prompt-builder.ts
        ├── dashboard/
        │   ├── server.ts                 # serveur HTTP léger embarqué
        │   ├── static/                   # bundle front (SPA légère)
        │   └── api/
        │       ├── score.controller.ts
        │       ├── coverage.controller.ts
        │       ├── violations.controller.ts
        │       └── graph.controller.ts
        ├── store/
        │   ├── quality-store.ts          # persistance historique
        │   └── schema.ts
        ├── diff/
        │   ├── patch-builder.ts
        │   └── safe-fix-catalog.ts       # liste blanche des correctifs auto
        └── report/
            ├── ci-reporter.ts            # sortie JSON/JUnit pour CI
            └── console-reporter.ts
```

---

## 4. Interfaces TypeScript centrales

```typescript
// --- Modèle de projet ---
interface DartFile {
  path: string;
  hash: string;
  ast: DartAstNode;
  layer: ArchLayer | 'unknown';
  stateManagement?: StateManagementKind;
}

type ArchLayer =
  | 'widget' | 'controller' | 'usecase'
  | 'repository' | 'datasource' | 'api_service' | 'model';

type StateManagementKind = 'getx' | 'bloc' | 'cubit' | 'riverpod' | 'provider' | 'mobx' | 'none';

interface BusinessFunction {
  name: string;               // login, logout, createOrder...
  filePath: string;
  className?: string;
  signature: FunctionSignature;
  layer: ArchLayer;
  calls: FunctionCallRef[];   // appels sortants (pour tracer UI→...→API)
  bodyRange: [number, number];
}

interface FunctionSignature {
  name: string;
  isAsync: boolean;
  returnType: string;         // ex: 'Future<User>'
  params: { name: string; type: string }[];
}

// --- Graphe de dépendances ---
interface DependencyGraph {
  nodes: Map<string, GraphNode>;
  edges: GraphEdge[];
}
interface GraphNode {
  id: string;
  layer: ArchLayer;
  filePath: string;
  label: string;
}
interface GraphEdge {
  from: string;
  to: string;
  kind: 'calls' | 'imports' | 'injects';
}

// --- Violations d'architecture ---
interface ArchitectureViolation {
  type: 'controller_to_api' | 'missing_repository' | 'missing_usecase' | 'layer_skip';
  filePath: string;
  functionName: string;
  message: string;
  occurrences: number;
  severity: 'info' | 'warning' | 'error';
}

// --- UseCase ---
interface UseCaseCandidate {
  businessFunction: BusinessFunction;
  existingUseCaseFound: boolean;
  matchedClassNames: string[];  // LoginUseCase, LoginUsecase, abstract LoginUseCase...
  suggestedFileName: string;    // login_usecase.dart
  suggestedClassName: string;   // LoginUseCase
}

interface GeneratedUseCase {
  filePath: string;
  content: string;
  callSitesToUpdate: CallSiteRewrite[];
}
interface CallSiteRewrite {
  filePath: string;
  originalCall: string;
  newCall: string;
  range: [number, number];
}

// --- Tests ---
interface TestGap {
  businessFunction: BusinessFunction;
  expectedTestFile: string;   // login_test.dart
  exists: boolean;
}
interface TestScenario {
  name: string;                // 'returns user', 'invalid password', ...
  kind: 'success' | 'invalid_input' | 'network_error' | 'server_error' | 'timeout' | 'null_response';
  setup: string;               // code de mock
  assertion: string;
}
interface GeneratedTestFile {
  filePath: string;
  content: string;
  scenarios: TestScenario[];
}

// --- Mocks/Fakes ---
interface MockSpec {
  targetClassName: string;     // Repository, ApiService...
  mockClassName: string;       // MockRepository
  methods: FunctionSignature[];
}
interface FakeSpec {
  targetTypeName: string;      // User, Response
  fakeClassName: string;       // FakeUser
  fields: { name: string; type: string; sampleValue: string }[];
}

// --- Couverture ---
interface CoverageReport {
  overall: number; // 0-100
  byLayer: Record<ArchLayer, number>;
  byFeature: Record<string, number>;
  byFile: Record<string, { covered: number; total: number }>;
}

// --- Résultats de tests ---
interface TestRunResult {
  total: number;
  passed: number;
  failed: number;
  skipped: number;
  durationMs: number;
  failures: { testName: string; filePath: string; message: string }[];
}

// --- Règles qualité ---
interface QualityIssue {
  rule: string;
  filePath: string;
  line: number;
  message: string;
  score: number;              // ex: complexité 18
  suggestion: string;
  severity: 'info' | 'warning' | 'error';
}

// --- Rapport global ---
interface QualityReport {
  generatedAt: string;
  projectScore: number;       // 0-100
  previousScore?: number;
  coverage: CoverageReport;
  testRun: TestRunResult;
  violations: ArchitectureViolation[];
  issues: QualityIssue[];
  heatmap: Record<string, number>;  // module -> % coverage
  graph: DependencyGraph;
  aiSuggestions?: string[];
}
```

---

## 5. Pipeline d'analyse AST Dart

Relax CLI est en TypeScript ; le parsing AST Dart se fait via l'une de ces stratégies (à trancher en phase MVP) :

1. **`dart analyze --format=json` + `package:analyzer`** exposé via un petit binaire Dart appelé en sous-processus, qui sérialise l'AST en JSON consommé côté TypeScript. *(Recommandé — s'appuie sur le compilateur officiel, robuste face aux évolutions du langage.)*
2. Parseur Dart custom en TypeScript (grammaire simplifiée) — plus rapide à itérer mais fragile sur les cas complexes (extensions, mixins, generics imbriqués).

**Décision recommandée : option 1**, avec un petit "sidecar" Dart (`tools/ast_dumper.dart`) fourni avec la CLI, appelé une fois par fichier (ou en batch) et dont la sortie JSON est mise en cache par hash de fichier.

### Étapes du pipeline

```
1. Scan récursif de lib/ (respect de .relaxignore)
2. Pour chaque fichier modifié depuis le dernier run (hash diff) :
     a. Extraire l'AST via ast_dumper
     b. Visiter l'AST → extraire classes, méthodes, imports, annotations
3. Classification de couche (layer-classifier.ts) :
     - Heuristiques : nom de dossier (controllers/, repositories/, datasources/, usecases/)
     - Héritage / implémentation (extends GetxController, extends Bloc<...>, extends StateNotifier...)
     - Annotations/mixins caractéristiques (ChangeNotifier, Observable de MobX)
4. Détection state management (state-management/*.ts) :
     - GetX: extends GetxController / Get.find / Get.put
     - Bloc/Cubit: extends Bloc<Event, State> / extends Cubit<State>
     - Riverpod: StateNotifierProvider / @riverpod
     - Provider: ChangeNotifierProvider / context.watch
     - MobX: @observable / @action
5. business-function-detector.ts :
     - Repère les méthodes dont le nom matche un dictionnaire de verbes métier
       (login, logout, register, create*, cancel*, update*, delete*, fetch*, submit*)
       combiné à une heuristique de forme (async, retourne Future<T>, appelle un repository/api)
6. Construction du dependency-graph.ts :
     - Un nœud par (fichier, classe)
     - Une arête 'calls' par appel de méthode résolu statiquement
     - Une arête 'injects' pour les injections DI détectées (constructeur, get_it, Provider)
```

### Exemple de visiteur (pseudo-code)

```typescript
class BusinessFunctionVisitor implements AstVisitor {
  private results: BusinessFunction[] = [];

  visitMethodDeclaration(node: MethodNode, ctx: VisitContext) {
    if (isBusinessVerb(node.name) && this.looksLikeBusinessLogic(node)) {
      this.results.push({
        name: node.name,
        filePath: ctx.filePath,
        className: ctx.enclosingClass?.name,
        signature: extractSignature(node),
        layer: ctx.layer,
        calls: extractCalls(node),
        bodyRange: node.range,
      });
    }
  }

  private looksLikeBusinessLogic(node: MethodNode): boolean {
    return node.isAsync
      || callsAny(node, ['repository', 'api', 'datasource'])
      || node.returnType.startsWith('Future<');
  }
}
```

---

## 6. Moteur de détection et génération des UseCases

### 6.1 Détection

```typescript
function detectUseCase(fn: BusinessFunction, allFiles: DartFile[]): UseCaseCandidate {
  const namePatterns = [
    `${capitalize(fn.name)}UseCase`,
    `${capitalize(fn.name)}Usecase`,
    `Abstract${capitalize(fn.name)}UseCase`,
  ];
  const matched = allFiles
    .flatMap(f => f.ast.classes)
    .filter(c => namePatterns.some(p => normalize(c.name) === normalize(p)));

  return {
    businessFunction: fn,
    existingUseCaseFound: matched.length > 0,
    matchedClassNames: matched.map(c => c.name),
    suggestedFileName: `${toSnakeCase(fn.name)}_usecase.dart`,
    suggestedClassName: `${capitalize(fn.name)}UseCase`,
  };
}
```

La normalisation des noms de classe gère la casse (`UseCase` vs `Usecase`) et le préfixe `abstract`.

### 6.2 Génération

Quand `existingUseCaseFound === false` :

1. Générer le fichier UseCase avec une méthode `execute()` dont la signature reprend celle de la fonction métier détectée.
2. **Déplacer** (et non dupliquer) le corps de la logique métier vers `execute()`.
3. **Réécrire l'appelant** pour qu'il appelle le UseCase (le call-site original est transformé en appel au UseCase, injecté via constructeur ou service locator existant du projet).
4. Le tout produit un **diff Git-like**, jamais appliqué sans confirmation (sauf `--fix` si la transformation est dans la liste blanche des transformations sûres — voir §16).

### Template généré

```dart
// login_usecase.dart
class LoginUseCase {
  final AuthRepository repository;
  LoginUseCase(this.repository);

  Future<User> execute(String email, String password) async {
    // Logique métier déplacée depuis AuthController.login()
    final result = await repository.login(email, password);
    return result;
  }
}
```

### Réécriture du call-site (avant/après)

```dart
// Avant
Future<void> login(String email, String password) async {
  final user = await _repository.login(email, password);
  state = state.copyWith(user: user);
}

// Après
Future<void> login(String email, String password) async {
  final user = await _loginUseCase.execute(email, password);
  state = state.copyWith(user: user);
}
```

---

## 7. Moteur de génération de tests

### 7.1 Détection des manques (`test-gap-detector.ts`)

```typescript
function findTestGaps(functions: BusinessFunction[], testFiles: DartFile[]): TestGap[] {
  return functions.map(fn => {
    const expected = `${toSnakeCase(fn.name)}_test.dart`;
    return {
      businessFunction: fn,
      expectedTestFile: expected,
      exists: testFiles.some(t => t.path.endsWith(expected)),
    };
  }).filter(gap => !gap.exists);
}
```

### 7.2 Synthèse des scénarios (`scenario-library.ts`)

Une bibliothèque de scénarios est associée au **type de retour** et aux **paramètres** de la fonction :

| Type de retour            | Scénarios générés par défaut                                  |
|---------------------------|-----------------------------------------------------------------|
| `Future<User>` (auth)      | success, invalid_input, network_error, server_error, timeout, null_response |
| `Future<void>`             | success, network_error, server_error, timeout                  |
| `Future<List<T>>`          | success (liste pleine), success (liste vide), network_error, server_error, timeout |
| `Future<bool>`              | success (true), success (false), network_error, server_error   |

```typescript
function synthesizeScenarios(fn: BusinessFunction): TestScenario[] {
  const base = scenarioLibrary.forReturnType(fn.signature.returnType);
  return base.map(s => ({
    ...s,
    setup: buildMockSetup(fn, s.kind),
    assertion: buildAssertion(fn, s.kind),
  }));
}
```

### 7.3 Exemple de test généré

```dart
group('Login', () {
  late MockAuthRepository mockRepository;
  late LoginUseCase useCase;

  setUp(() {
    mockRepository = MockAuthRepository();
    useCase = LoginUseCase(mockRepository);
  });

  test('returns user', () async {
    when(() => mockRepository.login(any(), any()))
        .thenAnswer((_) async => FakeUser());
    final result = await useCase.execute('a@b.com', 'pw');
    expect(result, isA<User>());
  });

  test('invalid password', () async {
    when(() => mockRepository.login(any(), any()))
        .thenThrow(InvalidCredentialsException());
    expect(() => useCase.execute('a@b.com', 'wrong'),
        throwsA(isA<InvalidCredentialsException>()));
  });

  test('network error', () async {
    when(() => mockRepository.login(any(), any()))
        .thenThrow(SocketException('no network'));
    expect(() => useCase.execute('a@b.com', 'pw'),
        throwsA(isA<SocketException>()));
  });

  test('server error', () async {
    when(() => mockRepository.login(any(), any()))
        .thenThrow(ServerException(500));
    expect(() => useCase.execute('a@b.com', 'pw'),
        throwsA(isA<ServerException>()));
  });

  test('timeout', () async {
    when(() => mockRepository.login(any(), any()))
        .thenThrow(TimeoutException('timeout'));
    expect(() => useCase.execute('a@b.com', 'pw'),
        throwsA(isA<TimeoutException>()));
  });

  test('null response', () async {
    when(() => mockRepository.login(any(), any()))
        .thenAnswer((_) async => null);
    expect(() => useCase.execute('a@b.com', 'pw'), throwsException);
  });
});
```

---

## 8. Mocks et fakes

`mock-engine` inspecte l'interface/classe cible (Repository, ApiService) et génère un mock basé sur **mocktail** (recommandé, sans code-gen requis, contrairement à mockito qui nécessite `build_runner`).

```typescript
function generateMock(spec: MockSpec): string {
  const methods = spec.methods.map(m =>
    `  ${m.returnType} ${m.name}(${paramsToDart(m.params)}) => super.noSuchMethod(...);`
  ).join('\n');
  return `
class ${spec.mockClassName} extends Mock implements ${spec.targetClassName} {}
`;
}
```

`fake-generator.ts` produit des objets de données minimalistes (`FakeUser`, `FakeResponse`) avec des valeurs d'exemple déterministes (pas de `Random`, pour la reproductibilité des tests).

---

## 9. Exécution des tests et couverture

### 9.1 Runner

```typescript
async function runTests(options: { ci: boolean }): Promise<TestRunResult> {
  const proc = spawn('flutter', ['test', '--machine'], { cwd: projectRoot });
  return parseMachineOutput(proc); // format JSON ligne-par-ligne de flutter test --machine
}
```

`--machine` (format JSON structuré de `flutter test`) est préféré à un parsing de sortie texte : plus robuste, donne accès aux noms de tests, durées, et messages d'échec structurés.

### 9.2 Couverture

```typescript
async function runCoverage(): Promise<CoverageReport> {
  await exec('flutter test --coverage');
  const lcov = await fs.readFile('coverage/lcov.info', 'utf-8');
  const parsed = parseLcov(lcov);
  return aggregateByLayerAndFeature(parsed, dependencyGraph);
}
```

`lcov-parser.ts` parse le format LCOV standard (`SF:`, `DA:`, `LH:`, `LF:`), puis `aggregateByLayerAndFeature` croise chaque fichier avec sa couche (`layer-classifier`) et sa feature (dossier de premier niveau sous `lib/features/<feature>/` ou équivalent) pour produire les agrégations demandées (par couche, par feature).

---

## 10. Moteur de règles qualité

Architecture en **règles indépendantes** (plugin-like), chacune implémentant :

```typescript
interface QualityRule {
  id: string;
  evaluate(file: DartFile, ctx: RuleContext): QualityIssue[];
}
```

Exemples de règles :

- `function-length.rule.ts` : seuil configurable (défaut 50 lignes), suggestion "Split into multiple methods" au-delà.
- `cyclomatic-complexity.rule.ts` : calcul classique (nombre de branches +1 : `if`, `else if`, `for`, `while`, `case`, `&&`, `||`, `catch`), score exposé tel quel (ex: `Score 18`).
- `duplication.rule.ts` : hashing de blocs normalisés (type-2 clone detection, tokens normalisés sur noms de variables) avec seuil de similarité (Jaccard/N-gram).
- `dead-code.rule.ts` : croisement avec le dependency-graph — fonctions/classes jamais référencées.
- `widget-rebuild.rule.ts` : détection de `build()` sans `const`, sans `Selector`/`Consumer` ciblé, provoquant des rebuilds larges.
- `futurebuilder-misuse.rule.ts` : détecte un `Future` recréé directement dans `build()` (anti-pattern classique provoquant des re-fetch à chaque rebuild).
- `build-method-size.rule.ts` : combine longueur + profondeur d'arbre de widgets.

Le moteur agrège en `QualityReport.issues`, chaque `QualityIssue` étant formatée avec un message et une suggestion actionnable, exactement au format attendu :

```
Complexité élevée
Score 18
login() — 230 lignes
Too complex
Suggestion : Split into multiple methods
```

### Score global du projet

```typescript
function computeProjectScore(report: Partial<QualityReport>): number {
  const weights = { coverage: 0.35, violations: 0.25, issues: 0.25, testHealth: 0.15 };
  const coverageScore = report.coverage!.overall;
  const violationsScore = 100 - Math.min(100, report.violations!.length * 5);
  const issuesScore = 100 - Math.min(100, report.issues!.reduce((s, i) => s + severityWeight(i.severity), 0));
  const testHealthScore = (report.testRun!.passed / report.testRun!.total) * 100;

  return Math.round(
    coverageScore * weights.coverage +
    violationsScore * weights.violations +
    issuesScore * weights.issues +
    testHealthScore * weights.testHealth
  );
}
```

Pondérations exposées dans `.relaxrc` pour permettre l'ajustement par équipe.

---

## 11. Dashboard web

### 11.1 Contraintes
- **Léger et embarqué** : pas de build front séparé à installer chez l'utilisateur — bundle statique pré-buildé livré avec la CLI (HTML/CSS/JS vanilla ou petit bundle Preact, pas de dépendance Node runtime côté client).
- Lancement local uniquement (`http://localhost:8080`), pas d'exposition réseau par défaut.

### 11.2 Architecture serveur

```typescript
// dashboard/server.ts
function startDashboard(report: QualityReport, port = 8080) {
  const app = createHttpServer();
  app.get('/api/score', scoreController(report));
  app.get('/api/coverage', coverageController(report));
  app.get('/api/violations', violationsController(report));
  app.get('/api/graph', graphController(report));
  app.get('/api/history', historyController(store));
  app.use('/', serveStatic('./static'));
  app.listen(port, () => openBrowser(`http://localhost:${port}`));
}
```

Le serveur est un simple serveur HTTP (Node `http` natif ou `polka`/`fastify` minimal — à éviter Express pour rester léger) qui sert :
- des données JSON via `/api/*`
- le bundle front statique

### 11.3 Composants du dashboard (calés sur les maquettes du besoin)

- **Project Score** : gros indicateur circulaire (93/100, delta +5, libellé qualitatif "Excellent").
- **Coverage** : barre/segments empilés (Controller/Repository/UseCase/Widget), pourcentage global.
- **Architecture** : badges (Clean / Repository / UseCases / DI) — état vert/orange/rouge selon détection.
- **Tests** : total / passed / failed, avec liste dépliable des échecs.
- **Violations** : liste groupée par type avec compteur d'occurrences.
- **Heatmap des modules** : grille colorée (rouge <40%, orange 40-70%, vert >70%) par feature/module.
- **Coverage par Feature** : tableau trié.
- **Historique des exécutions** : line chart (score dans le temps), alimenté par le Quality Store.
- **Graph interactif** : rendu SVG/Canvas du dependency-graph, nœuds cliquables → filtrent la liste de violations/couverture associée, navigation UI→Controller→UseCase→Repository→Datasource→API.

### 11.4 Suggestions IA (optionnelles)

```typescript
interface AiAdvisorProvider {
  name: 'openai' | 'gemini' | 'claude' | 'local';
  generateSuggestion(context: AiSuggestionContext): Promise<string>;
}
```

Activé uniquement si une clé API est présente dans la config (`.relaxrc` ou variable d'environnement). Le prompt envoyé inclut uniquement la signature de fonction + un résumé structurel (jamais tout le fichier), pour limiter coût et exposition de code sensible. Aucune suggestion n'est appliquée automatiquement — affichage seul dans le dashboard, avec bouton "Créer le UseCase" qui déclenche le flux de génération standard (avec validation utilisateur).

---

## 12. Format des données échangées

Toutes les communications interne-module et CLI↔dashboard utilisent un JSON versionné :

```json
{
  "schemaVersion": "1.0",
  "generatedAt": "2026-07-04T10:00:00Z",
  "projectScore": 93,
  "previousScore": 88,
  "coverage": {
    "overall": 91,
    "byLayer": { "controller": 84, "repository": 92, "usecase": 100, "widget": 45 },
    "byFeature": { "Authentication": 95, "Orders": 87, "Payment": 43, "Notification": 100 }
  },
  "testRun": { "total": 215, "passed": 213, "failed": 2, "skipped": 0, "durationMs": 48213 },
  "violations": [
    { "type": "controller_to_api", "occurrences": 4, "severity": "error", "message": "Controller → API" },
    { "type": "missing_repository", "occurrences": 2, "severity": "warning", "message": "Repository missing" }
  ],
  "heatmap": { "Authentication": 30, "Orders": 100, "Payment": 10, "Profile": 60 }
}
```

Ce JSON constitue aussi le format d'export pour la CI (`--ci` produit ce fichier sous `relax-quality-report.json`, plus un export JUnit pour intégration dans les outils CI classiques).

---

## 13. Persistance de l'historique

- **Stockage local** : SQLite embarqué (`better-sqlite3` ou équivalent WASM pur-JS pour éviter les binaires natifs à compiler selon plateforme) dans `.relax/quality/history.db`, ou repli JSON append-only (`.relax/quality/history.jsonl`) si SQLite indisponible sur l'environnement.
- **Schéma** :

```typescript
interface HistoryEntry {
  runId: string;
  timestamp: string;
  projectScore: number;
  coverageOverall: number;
  testsTotal: number;
  testsPassed: number;
  testsFailed: number;
  violationsCount: number;
  gitCommitSha?: string;   // corrélation avec l'historique Git si dispo
}
```

- Rétention configurable (par défaut : 90 derniers runs), avec agrégation par jour au-delà pour garder un historique long sans explosion de taille.
- Le fichier `.relax/quality/` est ajouté au `.gitignore` par défaut (option pour le committer si l'équipe veut suivre le score dans le repo).

---

## 14. Stratégie CI/CD

`relax quality --ci` :

1. Désactive tout prompt interactif.
2. Exécute : analyse → détection UseCases/tests manquants (rapport seul, **pas de génération** sauf flag explicite) → `flutter test --coverage` → règles qualité.
3. Produit :
   - `relax-quality-report.json` (schéma ci-dessus)
   - `relax-quality-junit.xml` (compatible GitLab CI / GitHub Actions / Jenkins)
   - Code de sortie non-zéro si seuils configurés non atteints (`minCoverage`, `maxViolations`, `maxFailedTests` dans `.relaxrc`).
4. Option de commentaire automatique sur PR (GitHub/GitLab API) avec résumé du score et delta — implémentable en phase avancée via un petit reporter dédié, hors périmètre MVP.

Exemple de config seuils :

```jsonc
{
  "quality": {
    "ci": {
      "minCoverage": 80,
      "maxViolations": 5,
      "failOnRegression": true
    }
  }
}
```

---

## 15. Performances attendues

Cibles pour un projet de 100k+ lignes Dart :

| Étape                              | Cible                          | Stratégie |
|-------------------------------------|--------------------------------|-----------|
| Analyse AST complète (1er run)      | < 60 s                         | Parsing parallélisé (worker pool), un process `ast_dumper` par cœur disponible |
| Analyse incrémentale (run suivant)  | < 5 s pour <5% de fichiers modifiés | Cache par hash de fichier (`.relax/quality/cache/`) |
| Détection UseCase/tests manquants   | < 2 s                          | Opère sur l'index déjà construit, pas de re-parse |
| `flutter test --coverage`           | dépendant du projet (non maîtrisé par Relax) | Option `--test-shard` pour paralléliser par répertoire de test si le projet le permet |
| Dashboard (chargement initial)      | < 1 s                          | JSON pré-calculé et servi statiquement, pas de recalcul à la volée |
| Mémoire pic                         | < 1.5 GB                       | Streaming du parsing fichier par fichier, pas de chargement de tout l'AST en mémoire simultanément |

---

## 16. Risques techniques et mitigations

| Risque | Impact | Mitigation |
|---|---|---|
| Parsing AST Dart incomplet sur syntaxes récentes (patterns, records, sealed classes) | Faux négatifs dans la détection de couches/UseCases | S'appuyer sur `package:analyzer` officiel (via sidecar Dart) plutôt qu'un parseur maison |
| Faux positifs dans la détection de "fonction métier" | Génération de UseCases non pertinents | Seuil de confiance + mode `--check` par défaut, jamais d'écriture sans confirmation ; whitelist de verbes configurable |
| Réécriture de call-sites cassant la compilation | Projet ne compile plus après `--fix` | Génération de diff + validation `dart analyze` sur le résultat avant application ; rollback automatique si erreur de compilation détectée |
| Diversité des state managements | Détection incomplète pour projets hybrides (ex: Bloc + Provider mélangés) | Détecteurs indépendants par state management, résultats fusionnés, pas de dépendance à un seul modèle mental |
| Coût des appels IA (suggestions) | Coût financier, latence, fuite de code | Envoi de signatures/résumés uniquement, jamais du code source complet ; désactivé par défaut, opt-in explicite |
| Performance sur mono-repos géants | Timeout / usage mémoire excessif | Analyse incrémentale obligatoire + option de scope (`--path lib/features/orders`) |
| Divergence entre lcov.info et structure logique (fichiers non mappés à une feature) | Agrégation par feature incorrecte | Fallback : classification "unknown" affichée explicitement plutôt que faussement attribuée |
| Instabilité de `flutter test --machine` selon versions du SDK Flutter | Parsing des résultats cassé | Détection de version Flutter, parseurs versionnés, tests de compatibilité dans la CI de Relax CLI elle-même |

---

## 17. Plan d'implémentation par phases

### Phase 1 — MVP (analyse en lecture seule)
- Scan `lib/` + parsing AST via sidecar Dart.
- Classification de couches + détection state management.
- Construction du dependency-graph basique.
- Détection des violations `Controller → API` et `Repository missing`.
- `relax quality --check` : rapport console uniquement, aucune écriture.

### Phase 2 — Génération de tests et mocks
- `test-gap-detector` + `scenario-library` (scénarios standards).
- `mock-engine` (mocktail) + `fake-generator`.
- `relax quality --generate-tests`.
- `runner` : exécution `flutter test --machine` + parsing résultats.

### Phase 3 — Couverture et règles qualité
- `coverage-runner` + `lcov-parser` + agrégation par couche/feature.
- `quality-rules` (longueur, complexité, duplication, dead code, imports/vars inutilisés).
- Calcul du score global.
- `relax quality --test` et rapport de couverture en console.

### Phase 4 — Génération des UseCases (le plus sensible)
- `usecase-detector` + `usecase-generator`.
- `code-transformer` (déplacement de logique + réécriture des call-sites) avec diff et confirmation obligatoire.
- `relax quality --generate-usecases`.
- Introduction de `--fix` limité à la liste blanche de transformations sûres (uniquement génération de fichiers nouveaux, jamais de réécriture de call-sites en mode `--fix` initialement).

### Phase 5 — Dashboard web interactif
- Bundle front statique (score, coverage, architecture, tests, violations, heatmap, historique).
- Serveur HTTP embarqué + endpoints `/api/*`.
- Graphe interactif cliquable.
- `relax quality --dashboard`.

### Phase 6 — CI/CD et historique
- `ci-reporter` (JSON + JUnit), seuils configurables, code de sortie CI.
- `quality-store` (SQLite/JSONL) + graphique d'historique dans le dashboard.
- `relax quality --ci`.

### Phase 7 — Avancé
- Suggestions IA optionnelles (OpenAI/Gemini/Claude/local), opt-in.
- Détection de widgets reconstruits inutilement et misuse de `FutureBuilder` (règles avancées nécessitant une analyse de flux de données plus fine).
- Commentaires automatiques sur PR (GitHub/GitLab).
- Mode `--path` pour analyse ciblée sur mono-repos.

---

## Notes finales d'implémentation

- Toutes les commandes (`--check`, `--generate-usecases`, `--generate-tests`, `--test`, `--dashboard`, `--ci`, `--fix`) partagent le même orchestrateur (`index.ts`) qui active/désactive les étapes du pipeline selon les flags, pour éviter la duplication de logique entre modes.
- Le `Quality Store` sert de source de vérité unique pour tout ce qui est historique/tendance ; ni le dashboard ni le reporter CI ne doivent recalculer indépendamment un score déjà persisté pour un run donné.
- Toute transformation de code (UseCase, fix automatique) doit systématiquement produire un diff textuel réversible avant écriture, journalisé dans `.relax/quality/patches/<timestamp>/` pour permettre un rollback manuel même après application.
