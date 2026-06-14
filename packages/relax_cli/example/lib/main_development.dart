import 'package:example/app/app.dart';
import 'package:example/bootstrap.dart';
import 'package:env/env.dart';

void main() {
  bootstrap(() => const App(), env: AppFlavor.development().getEnv);
}
