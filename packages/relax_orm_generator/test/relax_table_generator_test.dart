import 'dart:convert';

import 'package:build/build.dart';
import 'package:build_test/build_test.dart';
import 'package:relax_orm_generator/builder.dart';
import 'package:test/test.dart';

void main() {
  test('generates JSON-backed mappings for nested models and lists', () async {
    await testBuilder(
      relaxOrmBuilder(BuilderOptions.empty),
      {
        'relax_orm|lib/relax_orm_annotations.dart': r'''
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
''',
        'relax_orm_generator|lib/auth_user.dart': r'''
import 'package:relax_orm/relax_orm_annotations.dart';

part 'auth_user.g.dart';

class User {
  User({
    this.id,
    this.name,
    this.createdAt,
  });

  String? id;
  String? name;
  DateTime? createdAt;
}

@RelaxTable()
class AuthUser {
  AuthUser({
    this.id,
    this.user,
    this.tags,
    this.friends,
  });

  @PrimaryKey()
  String? id;
  User? user;
  List<String>? tags;
  List<User>? friends;
}
''',
      },
      outputs: {
        'relax_orm_generator|lib/auth_user.relax_orm.g.part':
            predicate<Object?>((output) {
              final content = output is List<int>
                  ? utf8.decode(output)
                  : '$output';
              return content.contains(
                    "ColumnDef.text('user', isNullable: true)",
                  ) &&
                  content.contains(
                    "ColumnDef.text('tags', isNullable: true)",
                  ) &&
                  content.contains(
                    "ColumnDef.text('friends', isNullable: true)",
                  ) &&
                  content.contains("'user': RelaxOrmJson.encode(") &&
                  content.contains("'tags': RelaxOrmJson.encode(") &&
                  content.contains("'friends': RelaxOrmJson.encode(") &&
                  content.contains('User(') &&
                  content.contains('RelaxOrmJson.asList(') &&
                  content.contains('DateTime.parse(');
            }),
      },
    );
  });

  test(
    'encodes nullable JSON fields without relying on type promotion',
    () async {
      await testBuilder(
        relaxOrmBuilder(BuilderOptions.empty),
        {
          'relax_orm|lib/relax_orm_annotations.dart': _annotations,
          'relax_orm_generator|lib/story.dart': r'''
import 'package:relax_orm/relax_orm_annotations.dart';

part 'story.g.dart';

class Quote {
  Quote({this.author, this.url, this.postedAt});

  String? author;
  String? url;
  DateTime? postedAt;
}

@RelaxTable()
class Story {
  Story({this.id, this.replyToStory, this.waveform, this.aliases});

  @PrimaryKey()
  String? id;
  Quote? replyToStory;
  List<double>? waveform;
  List<String?>? aliases;
}
''',
        },
        outputs: {
          'relax_orm_generator|lib/story.relax_orm.g.part': predicate<Object?>((
            output,
          ) {
            final raw = output is List<int> ? utf8.decode(output) : '$output';
            // The generated source is formatted, so compare on a single line.
            final content = raw.replaceAll(RegExp(r'\s+'), ' ');

            // Property accesses are never promoted by Dart, so every read inside
            // the `else` branch must carry a `!`.
            expect(content, contains("'author': entity.replyToStory!.author"));
            expect(
              content,
              contains(
                "'postedAt': entity.replyToStory!.postedAt == null "
                '? null '
                ': entity.replyToStory!.postedAt!.toIso8601String()',
              ),
            );
            expect(
              content,
              contains(
                'entity.waveform == null ? null : entity.waveform!.map(',
              ),
            );

            // Lambda parameters *are* promoted — a `!` there would be flagged as
            // an unnecessary non-null assertion.
            expect(content, isNot(contains('item!')));
            expect(content, contains('entity.aliases!.map((item) => item)'));
            return true;
          }),
        },
      );
    },
  );
}

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
''';
