import 'dart:math';
import 'dart:typed_data';

/// Deterministic fake-data generator used by seeders.
///
/// Every value is derived from a seeded [Random], so the same `seed` always
/// produces the same sequence of values. That makes seeded databases
/// reproducible across machines and CI runs.
///
/// ```dart
/// final faker = SeedFaker(seed: 42);
/// faker.fullName(); // always the same for seed 42
/// faker.email();
/// faker.integer(min: 18, max: 80);
/// ```
///
/// Generated `TableSeeder`s receive a [SeedFaker] in `buildOne`, but you can
/// also use it directly when writing a seeder by hand.
class SeedFaker {
  /// Creates a faker.
  ///
  /// - [seed]: the random seed. Same seed → same data.
  /// - [now]: reference point for date generation. Defaults to
  ///   `DateTime.now()`; pass a fixed value when you need dates to be
  ///   reproducible too.
  SeedFaker({int seed = 0, DateTime? now})
    : _random = Random(seed),
      _now = now ?? DateTime.now();

  final Random _random;
  final DateTime _now;

  /// The reference "now" used by [dateTime], [pastDateTime] and
  /// [futureDateTime].
  DateTime get now => _now;

  /// Derives a stable 32-bit seed from [value] (FNV-1a).
  ///
  /// Unlike `String.hashCode`, this is guaranteed identical across Dart
  /// versions and platforms — seeders rely on it to stay reproducible.
  static int seedFromString(String value) {
    var hash = 0x811c9dc5;
    for (final unit in value.codeUnits) {
      hash ^= unit;
      hash = (hash * 0x01000193) & 0xffffffff;
    }
    return hash;
  }

  // -- Primitives --

  /// A random integer in `[min, max]` (both inclusive).
  int integer({int min = 0, int max = 1000}) {
    if (max <= min) return min;
    return min + _random.nextInt(max - min + 1);
  }

  /// A random double in `[min, max)`, rounded to [fractionDigits] decimals.
  double decimal({double min = 0, double max = 1000, int fractionDigits = 2}) {
    final value = min + _random.nextDouble() * (max - min);
    final factor = pow(10, fractionDigits);
    return (value * factor).round() / factor;
  }

  /// A random boolean, `true` with probability [trueProbability].
  bool boolean({double trueProbability = 0.5}) {
    return _random.nextDouble() < trueProbability;
  }

  /// Random bytes, useful for `blob` columns.
  Uint8List bytes({int length = 16}) {
    return Uint8List.fromList(
      List<int>.generate(length, (_) => _random.nextInt(256)),
    );
  }

  /// A random element of [items].
  T oneOf<T>(List<T> items) {
    if (items.isEmpty) {
      throw ArgumentError.value(items, 'items', 'must not be empty');
    }
    return items[_random.nextInt(items.length)];
  }

  /// Builds a list of [count] items via [build].
  List<T> listOf<T>(int count, T Function(int index) build) {
    return List<T>.generate(count, build);
  }

  /// Returns [value], or `null` with probability [nullProbability].
  ///
  /// Used by generated seeders for nullable columns so seeded data exercises
  /// both the "present" and "absent" branches of your code.
  T? maybe<T>(T value, {double nullProbability = 0.2}) {
    return _random.nextDouble() < nullProbability ? null : value;
  }

  // -- Identifiers --

  /// A UUID-v4-shaped identifier, derived from the seeded random.
  ///
  /// Not cryptographically random — it exists purely to give seeded rows
  /// stable, realistic-looking primary keys.
  String uuid() {
    final buffer = StringBuffer();
    for (var i = 0; i < 32; i++) {
      if (i == 8 || i == 12 || i == 16 || i == 20) buffer.write('-');
      if (i == 12) {
        buffer.write('4');
        continue;
      }
      if (i == 16) {
        buffer.write(_hexDigits[8 + _random.nextInt(4)]);
        continue;
      }
      buffer.write(_hexDigits[_random.nextInt(16)]);
    }
    return buffer.toString();
  }

  /// A random hex token of [length] characters (api keys, hashes, …).
  String token({int length = 32}) {
    return String.fromCharCodes(
      List<int>.generate(
        length,
        (_) => _hexDigits[_random.nextInt(16)].codeUnitAt(0),
      ),
    );
  }

  // -- Text --

  /// A single lowercase word.
  String word() => oneOf(_words);

  /// [count] words joined by spaces.
  String words(int count) =>
      List<String>.generate(count, (_) => word()).join(' ');

  /// A capitalized sentence of roughly [words] words, ending with a period.
  String sentence({int words = 8}) {
    final text = this.words(words < 1 ? 1 : words);
    return '${text[0].toUpperCase()}${text.substring(1)}.';
  }

  /// A paragraph made of [sentences] sentences.
  String paragraph({int sentences = 3}) {
    return List<String>.generate(
      sentences < 1 ? 1 : sentences,
      (_) => sentence(words: integer(min: 6, max: 14)),
    ).join(' ');
  }

  /// A URL-friendly slug of [words] words.
  String slug({int words = 3}) => this.words(words).replaceAll(' ', '-');

  // -- People --

  /// A first name.
  String firstName() => oneOf(_firstNames);

  /// A last name.
  String lastName() => oneOf(_lastNames);

  /// A `First Last` name.
  String fullName() => '${firstName()} ${lastName()}';

  /// A lowercase username, e.g. `amina.traore42`.
  String username() {
    return '${firstName().toLowerCase()}.${lastName().toLowerCase()}'
        '${integer(min: 1, max: 99)}';
  }

  /// An email address built from a random name.
  String email() => '${username()}@${oneOf(_domains)}';

  /// An international-looking phone number.
  String phone() {
    return '+${integer(min: 1, max: 99)} '
        '${integer(min: 100, max: 999)} '
        '${integer(min: 100, max: 999)} '
        '${integer(min: 100, max: 999)}';
  }

  // -- Places & misc --

  /// A city name.
  String city() => oneOf(_cities);

  /// A country name.
  String country() => oneOf(_countries);

  /// An `https://` URL.
  String url() => 'https://${oneOf(_domains)}/${slug()}';

  /// A hex color, e.g. `#3fa9c2`.
  String color() => '#${token(length: 6)}';

  // -- Dates --

  /// A date within [days] days around [now] (past by default).
  DateTime dateTime({int days = 365, bool future = false}) {
    final offset = Duration(
      days: integer(min: 0, max: days),
      hours: integer(min: 0, max: 23),
      minutes: integer(min: 0, max: 59),
      seconds: integer(min: 0, max: 59),
    );
    return future ? _now.add(offset) : _now.subtract(offset);
  }

  /// A date in the past (within [days] days).
  DateTime pastDateTime({int days = 365}) => dateTime(days: days);

  /// A date in the future (within [days] days).
  DateTime futureDateTime({int days = 365}) =>
      dateTime(days: days, future: true);

  /// A birth date for someone between [minAge] and [maxAge] years old.
  DateTime birthDate({int minAge = 18, int maxAge = 80}) {
    final age = integer(min: minAge, max: maxAge);
    return DateTime(
      _now.year - age,
      integer(min: 1, max: 12),
      integer(min: 1, max: 28),
    );
  }
}

const _hexDigits = '0123456789abcdef';

const _words = <String>[
  'alpha',
  'amber',
  'anchor',
  'aurora',
  'beacon',
  'bloom',
  'branch',
  'breeze',
  'canvas',
  'cedar',
  'cipher',
  'clover',
  'coral',
  'delta',
  'dune',
  'ember',
  'fable',
  'falcon',
  'fern',
  'forge',
  'garden',
  'glacier',
  'harbor',
  'haven',
  'indigo',
  'ivory',
  'jade',
  'kite',
  'lagoon',
  'lantern',
  'lumen',
  'maple',
  'meadow',
  'nimbus',
  'oasis',
  'onyx',
  'orbit',
  'pebble',
  'pine',
  'prism',
  'quartz',
  'quill',
  'ridge',
  'river',
  'saffron',
  'sierra',
  'slate',
  'solstice',
  'summit',
  'thistle',
  'timber',
  'tundra',
  'umbra',
  'valley',
  'velvet',
  'vertex',
  'willow',
  'zenith',
  'zephyr',
];

const _firstNames = <String>[
  'Amina',
  'Bruno',
  'Chloé',
  'Diego',
  'Elena',
  'Farid',
  'Grace',
  'Hugo',
  'Ines',
  'Jonas',
  'Kadija',
  'Liam',
  'Maya',
  'Noah',
  'Olivia',
  'Pierre',
  'Quentin',
  'Rania',
  'Samir',
  'Théo',
  'Uma',
  'Victor',
  'Wendy',
  'Yasmine',
];

const _lastNames = <String>[
  'Adjei',
  'Bernard',
  'Costa',
  'Diallo',
  'Evans',
  'Fontaine',
  'Garcia',
  'Haddad',
  'Ibrahim',
  'Jansen',
  'Kouassi',
  'Lopez',
  'Mensah',
  'Novak',
  'Owusu',
  'Petrov',
  'Quintero',
  'Rossi',
  'Silva',
  'Traoré',
  'Ndiaye',
  'Verma',
  'Weber',
  'Zhang',
];

const _domains = <String>[
  'example.com',
  'mail.dev',
  'relax.app',
  'testmail.io',
  'sample.org',
];

const _cities = <String>[
  'Abidjan',
  'Accra',
  'Barcelona',
  'Casablanca',
  'Dakar',
  'Douala',
  'Lagos',
  'Lisbon',
  'Lomé',
  'Lyon',
  'Montreal',
  'Nairobi',
  'Porto',
  'Toronto',
];

const _countries = <String>[
  'Benin',
  'Canada',
  'France',
  'Germany',
  'Ghana',
  'Ivory Coast',
  'Kenya',
  'Morocco',
  'Nigeria',
  'Portugal',
  'Senegal',
  'Spain',
  'Togo',
];
