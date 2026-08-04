/// Picks a `SeedFaker` call for a column, based on its SQL type and its name.
///
/// Seeded data is much more useful when it looks like real data, so the name is
/// used as a hint: an `email` text column gets `faker.email()` rather than a
/// random word, a `price` real column gets a money-shaped range, and so on.
/// The type always wins — a column named `email` typed `int` still gets an int.
library;

/// Returns the `faker.…()` expression to use for a column.
///
/// - [columnName]: the database column name (snake_case).
/// - [columnConstructor]: the `ColumnDef` constructor name, i.e. one of
///   `text`, `integer`, `real`, `boolean`, `dateTime`, `blob`.
/// - [isPrimaryKey]: primary keys always get a unique-looking value.
String fakerCallFor({
  required String columnName,
  required String columnConstructor,
  bool isPrimaryKey = false,
}) {
  final name = columnName.toLowerCase();

  switch (columnConstructor) {
    case 'text':
      return _textCall(name, isPrimaryKey: isPrimaryKey);
    case 'integer':
      return _integerCall(name);
    case 'real':
      return _realCall(name);
    case 'boolean':
      return _booleanCall(name);
    case 'dateTime':
      return _dateTimeCall(name);
    case 'blob':
      return 'faker.bytes()';
    default:
      return 'faker.word()';
  }
}

String _textCall(String name, {required bool isPrimaryKey}) {
  if (isPrimaryKey) return 'faker.uuid()';
  if (name == 'id' || name.endsWith('_id') || name.endsWith('_uuid')) {
    return 'faker.uuid()';
  }
  if (_contains(name, const ['email', 'mail'])) return 'faker.email()';
  if (_contains(name, const ['username', 'login', 'handle', 'nickname'])) {
    return 'faker.username()';
  }
  if (_contains(name, const ['first_name', 'firstname', 'given_name'])) {
    return 'faker.firstName()';
  }
  if (_contains(name, const ['last_name', 'lastname', 'surname'])) {
    return 'faker.lastName()';
  }
  if (_contains(name, const ['name', 'author', 'owner'])) {
    return 'faker.fullName()';
  }
  if (_contains(name, const ['phone', 'mobile']) ||
      _isOneOf(name, const ['tel'])) {
    return 'faker.phone()';
  }
  if (_contains(name, const ['password', 'token', 'secret', 'hash']) ||
      _isOneOf(name, const ['key', 'api_key'])) {
    return 'faker.token()';
  }
  if (_contains(name, const [
    'avatar',
    'image',
    'photo',
    'picture',
    'url',
    'link',
    'website',
    'thumbnail',
  ])) {
    return 'faker.url()';
  }
  if (_contains(name, const ['slug'])) return 'faker.slug()';
  if (_contains(name, const ['color', 'colour'])) return 'faker.color()';
  if (_contains(name, const ['city'])) return 'faker.city()';
  if (_contains(name, const ['country'])) return 'faker.country()';
  if (_contains(name, const ['address', 'street'])) {
    return "'\${faker.integer(min: 1, max: 300)} \${faker.word()} street'";
  }
  if (_contains(name, const ['title', 'subject', 'headline', 'label'])) {
    return 'faker.sentence(words: 4)';
  }
  if (_contains(name, const [
    'description',
    'body',
    'content',
    'bio',
    'comment',
    'message',
    'summary',
    'note',
    'text',
  ])) {
    return 'faker.paragraph()';
  }
  return 'faker.word()';
}

String _integerCall(String name) {
  if (_isOneOf(name, const ['age'])) {
    return 'faker.integer(min: 18, max: 80)';
  }
  if (_isOneOf(name, const ['year'])) {
    return 'faker.integer(min: 1990, max: 2030)';
  }
  if (_isOneOf(name, const ['month'])) return 'faker.integer(min: 1, max: 12)';
  if (_isOneOf(name, const ['day'])) return 'faker.integer(min: 1, max: 28)';
  if (_contains(name, const ['percent', 'progress', 'rate'])) {
    return 'faker.integer(min: 0, max: 100)';
  }
  if (_contains(name, const ['rating', 'score', 'stars'])) {
    return 'faker.integer(min: 1, max: 5)';
  }
  if (_contains(name, const ['price', 'amount', 'total', 'cost', 'balance'])) {
    return 'faker.integer(min: 100, max: 100000)';
  }
  if (_contains(name, const [
    'count',
    'quantity',
    'qty',
    'stock',
    'views',
    'likes',
    'position',
    'index',
    'order',
    'version',
  ])) {
    return 'faker.integer(min: 0, max: 100)';
  }
  return 'faker.integer()';
}

String _realCall(String name) {
  if (_contains(name, const ['latitude']) || _isOneOf(name, const ['lat'])) {
    return 'faker.decimal(min: -90, max: 90, fractionDigits: 6)';
  }
  if (_contains(name, const ['longitude']) ||
      _isOneOf(name, const ['lng', 'lon'])) {
    return 'faker.decimal(min: -180, max: 180, fractionDigits: 6)';
  }
  if (_contains(name, const ['rating', 'score'])) {
    return 'faker.decimal(min: 0, max: 5, fractionDigits: 1)';
  }
  if (_contains(name, const ['percent', 'progress', 'rate'])) {
    return 'faker.decimal(min: 0, max: 100)';
  }
  if (_contains(name, const ['price', 'amount', 'total', 'cost', 'balance'])) {
    return 'faker.decimal(min: 1, max: 5000)';
  }
  return 'faker.decimal()';
}

String _booleanCall(String name) {
  // Flags that are the exception rather than the rule read better when the
  // seeded data mostly leaves them off.
  if (_contains(name, const [
    'deleted',
    'archived',
    'banned',
    'blocked',
    'draft',
    'hidden',
    'locked',
  ])) {
    return 'faker.boolean(trueProbability: 0.1)';
  }
  if (_contains(name, const [
    'active',
    'enabled',
    'visible',
    'published',
    'verified',
    'confirmed',
  ])) {
    return 'faker.boolean(trueProbability: 0.8)';
  }
  return 'faker.boolean()';
}

String _dateTimeCall(String name) {
  if (_contains(name, const ['birth', 'born', 'dob'])) {
    return 'faker.birthDate()';
  }
  if (_contains(name, const [
    'expire',
    'expires',
    'expiry',
    'due',
    'scheduled',
    'starts',
    'ends',
    'next',
  ])) {
    return 'faker.futureDateTime()';
  }
  return 'faker.pastDateTime()';
}

bool _contains(String name, List<String> needles) {
  return needles.any(name.contains);
}

/// Exact match, used for short tokens where a substring match would misfire
/// (`lat` inside `plate`, `key` inside `monkey`, …).
bool _isOneOf(String name, List<String> candidates) {
  return candidates.contains(name);
}
