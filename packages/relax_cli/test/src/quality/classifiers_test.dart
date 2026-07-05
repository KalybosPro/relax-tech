import 'package:relax_cli/src/quality/analyzer/business_function_detector.dart';
import 'package:relax_cli/src/quality/analyzer/dart_parser.dart';
import 'package:relax_cli/src/quality/analyzer/layer_classifier.dart';
import 'package:relax_cli/src/quality/analyzer/state_management_detector.dart';
import 'package:relax_cli/src/quality/config/quality_config.dart';
import 'package:relax_cli/src/quality/models/quality_models.dart';
import 'package:test/test.dart';

void main() {
  final parser = DartParser();

  group('LayerClassifier', () {
    final classifier = LayerClassifier();

    test('classifies by path segment', () {
      final parsed = parser.parse('class Foo {}');
      expect(
        classifier.classify(
          'lib/features/auth/repository/auth_repo.dart',
          parsed,
        ),
        ArchLayer.repository,
      );
      expect(
        classifier.classify('lib/features/auth/view/login_page.dart', parsed),
        ArchLayer.widget,
      );
    });

    test('falls back to superclass heuristics', () {
      final parsed = parser.parse(
        'class HomeCubit extends Cubit<HomeState> {}',
      );
      expect(
        classifier.classify('lib/home/home_cubit.dart', parsed),
        ArchLayer.controller,
      );
    });
  });

  group('StateManagementDetector', () {
    final detector = StateManagementDetector();

    test('detects bloc, cubit, riverpod, getx, provider', () {
      expect(
        detector.detect(parser.parse('class B extends Bloc<E, S> {}')),
        StateManagementKind.bloc,
      );
      expect(
        detector.detect(parser.parse('class C extends Cubit<S> {}')),
        StateManagementKind.cubit,
      );
      expect(
        detector.detect(parser.parse('class N extends StateNotifier<S> {}')),
        StateManagementKind.riverpod,
      );
      expect(
        detector.detect(parser.parse('class G extends GetxController {}')),
        StateManagementKind.getx,
      );
      expect(
        detector.detect(parser.parse('class P extends ChangeNotifier {}')),
        StateManagementKind.provider,
      );
      expect(
        detector.detect(parser.parse('class X {}')),
        StateManagementKind.none,
      );
    });
  });

  group('BusinessFunctionDetector', () {
    final detector = BusinessFunctionDetector(const QualityConfig());

    test('detects async business verbs, ignores plain helpers', () {
      final parsed = parser.parse('''
class OrderController {
  Future<void> createOrder(Cart cart) async {
    await repository.save(cart);
  }
  int helper() => 42;
}
''');
      final fns = detector.detect(
        filePath: 'lib/order_controller.dart',
        layer: ArchLayer.controller,
        parsed: parsed,
      );
      expect(fns, hasLength(1));
      expect(fns.single.name, 'createOrder');
      expect(fns.single.className, 'OrderController');
    });
  });
}
