import 'package:build/build.dart';
import 'package:build_test/build_test.dart';
import 'package:relax_orm_generator/builder.dart';
import 'package:test/test.dart';

/// Stub of `package:relax_orm/relax_orm_annotations.dart` — the generator only
/// needs the annotation shapes to resolve.
const _annotations = r'''
library;

class RelaxTable {
  final String? name;
  const RelaxTable({this.name});
}

class PrimaryKey {
  const PrimaryKey();
}

class Ignore {
  const Ignore();
}

class Column {
  final String? name;
  final bool? nullable;
  final String? defaultValue;

  const Column({this.name, this.nullable, this.defaultValue});
}

class RelaxSeed {
  final int count;
  final int order;
  final bool enabled;

  const RelaxSeed({this.count = 10, this.order = 0, this.enabled = true});
}
''';

const _userModel = r'''
import 'package:relax_orm/relax_orm_annotations.dart';

part 'user.g.dart';

@RelaxTable()
class User {
  User({
    required this.id,
    required this.email,
    required this.age,
    required this.createdAt,
    this.bio,
  });

  @PrimaryKey()
  final String id;
  final String email;
  final int age;
  final DateTime createdAt;
  final String? bio;
}
''';

/// Runs the builder over [sources] and returns the generated part file.
Future<String> generate(
  Map<String, String> sources, {
  Map<String, Object?> config = const {},
}) async {
  final readerWriter = TestReaderWriter();
  await testBuilder(
    relaxOrmBuilder(BuilderOptions(config)),
    {'relax_orm|lib/relax_orm_annotations.dart': _annotations, ...sources},
    readerWriter: readerWriter,
    // Without this the part file lands under `.dart_tool/build/generated/`,
    // which `testing.readString` can't address.
    flattenOutput: true,
  );

  final parts = readerWriter.testing.assets.where(
    (id) => id.path.endsWith('.relax_orm.g.part'),
  );
  expect(parts, hasLength(1), reason: 'expected exactly one generated part');
  return readerWriter.testing.readString(parts.single);
}

void main() {
  group('seeder generation', () {
    test('is off by default', () async {
      final output = await generate({
        'relax_orm_generator|lib/user.dart': _userModel,
      });

      expect(output, contains('final userSchema = TableSchema<User>('));
      expect(output, isNot(contains('class UserSeeder')));
    });

    test('the seed builder option turns it on for every model', () async {
      final output = await generate(
        {'relax_orm_generator|lib/user.dart': _userModel},
        config: {'seed': 'true'},
      );

      expect(output, contains('class UserSeeder extends TableSeeder<User> {'));
      expect(output, contains("String get tableName => 'users';"));
      expect(output, contains('int get defaultCount => 10;'));
      expect(output, contains('User buildOne(int index, SeedFaker faker)'));
      expect(output, contains('id: faker.uuid()'));
      expect(output, contains('email: faker.email()'));
      expect(output, contains('age: faker.integer(min: 18, max: 80)'));
      expect(output, contains('createdAt: faker.pastDateTime()'));
      // Nullable, non-primary-key columns are sometimes left empty.
      expect(output, contains('bio: faker.maybe(faker.paragraph())'));
    });

    test('seed_count sets the default row count', () async {
      final output = await generate(
        {'relax_orm_generator|lib/user.dart': _userModel},
        config: {'seed': 'true', 'seed_count': '25'},
      );

      expect(output, contains('int get defaultCount => 25;'));
    });

    test('@RelaxSeed generates a seeder without the flag', () async {
      final output = await generate({
        'relax_orm_generator|lib/user.dart': r'''
import 'package:relax_orm/relax_orm_annotations.dart';

part 'user.g.dart';

@RelaxTable()
@RelaxSeed(count: 42, order: 3)
class User {
  User({required this.id, required this.name});

  @PrimaryKey()
  final String id;
  final String name;
}
''',
      });

      expect(output, contains('class UserSeeder extends TableSeeder<User> {'));
      expect(output, contains('int get defaultCount => 42;'));
      expect(output, contains('int get defaultOrder => 3;'));
    });

    test(
      '@RelaxSeed(enabled: false) opts a model out despite the flag',
      () async {
        final output = await generate(
          {
            'relax_orm_generator|lib/user.dart': r'''
import 'package:relax_orm/relax_orm_annotations.dart';

part 'user.g.dart';

@RelaxTable()
@RelaxSeed(enabled: false)
class User {
  User({required this.id, required this.name});

  @PrimaryKey()
  final String id;
  final String name;
}
''',
          },
          config: {'seed': 'true'},
        );

        expect(output, contains('final userSchema = TableSchema<User>('));
        expect(output, isNot(contains('class UserSeeder')));
      },
    );

    test('walks nested models and lists', () async {
      final output = await generate(
        {
          'relax_orm_generator|lib/profile.dart': r'''
import 'package:relax_orm/relax_orm_annotations.dart';

part 'profile.g.dart';

class Address {
  Address({required this.city, required this.country});

  final String city;
  final String country;
}

@RelaxTable()
class Profile {
  Profile({required this.id, required this.address, required this.tags});

  @PrimaryKey()
  final String id;
  final Address address;
  final List<String> tags;
}
''',
        },
        config: {'seed': 'true'},
      );

      expect(output, contains('address: Address('));
      expect(output, contains('city: faker.city()'));
      expect(output, contains('country: faker.country()'));
      expect(output, contains('tags: faker.listOf(2, (_) => faker.word())'));
    });

    test('honours a custom table name', () async {
      final output = await generate(
        {
          'relax_orm_generator|lib/post.dart': r'''
import 'package:relax_orm/relax_orm_annotations.dart';

part 'post.g.dart';

@RelaxTable(name: 'blog_posts')
class Post {
  Post({required this.id, required this.title});

  @PrimaryKey()
  final String id;
  final String title;
}
''',
        },
        config: {'seed': 'true'},
      );

      expect(output, contains("String get tableName => 'blog_posts';"));
      expect(output, contains('title: faker.sentence(words: 4)'));
    });
  });
}
