import 'package:relax_orm/relax_orm.dart';

part 'models.g.dart';

// @RelaxSeed opts this model into seeder generation without needing the
// `dart run relax_orm --seed` flag.
@RelaxTable()
@RelaxSeed(count: 5)
class User {
  @PrimaryKey()
  final String id;
  final String name;
  final int age;
  final bool active;
  final DateTime createdAt;

  User({
    required this.id,
    required this.name,
    required this.age,
    required this.active,
    required this.createdAt,
  });
}

// order: 1 → posts are seeded after users.
@RelaxTable(name: 'blog_posts')
@RelaxSeed(count: 20, order: 1)
class Post {
  @PrimaryKey()
  final String id;
  final String title;
  final String body;
  final String authorId;
  final DateTime publishedAt;
  final bool isDraft;

  @Ignore()
  final String? localCacheKey;

  Post({
    required this.id,
    required this.title,
    required this.body,
    required this.authorId,
    required this.publishedAt,
    required this.isDraft,
    this.localCacheKey,
  });
}
