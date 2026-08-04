import 'package:relax_orm_generator/src/seed_value_mapper.dart';
import 'package:test/test.dart';

String call(String name, String type, {bool isPrimaryKey = false}) =>
    fakerCallFor(
      columnName: name,
      columnConstructor: type,
      isPrimaryKey: isPrimaryKey,
    );

void main() {
  group('text columns', () {
    test('primary keys and id-shaped columns get a uuid', () {
      expect(call('id', 'text', isPrimaryKey: true), 'faker.uuid()');
      expect(call('slug', 'text', isPrimaryKey: true), 'faker.uuid()');
      expect(call('id', 'text'), 'faker.uuid()');
      expect(call('author_id', 'text'), 'faker.uuid()');
      expect(call('session_uuid', 'text'), 'faker.uuid()');
    });

    test('recognises common person fields', () {
      expect(call('email', 'text'), 'faker.email()');
      expect(call('contact_email', 'text'), 'faker.email()');
      expect(call('username', 'text'), 'faker.username()');
      expect(call('first_name', 'text'), 'faker.firstName()');
      expect(call('last_name', 'text'), 'faker.lastName()');
      expect(call('name', 'text'), 'faker.fullName()');
      expect(call('phone', 'text'), 'faker.phone()');
    });

    test('recognises long-text and link fields', () {
      expect(call('title', 'text'), 'faker.sentence(words: 4)');
      expect(call('description', 'text'), 'faker.paragraph()');
      expect(call('body', 'text'), 'faker.paragraph()');
      expect(call('avatar_url', 'text'), 'faker.url()');
      expect(call('slug', 'text'), 'faker.slug()');
    });

    test('falls back to a word', () {
      expect(call('foo', 'text'), 'faker.word()');
    });

    test('short tokens only match exactly', () {
      // "lat" inside "plate", "key" inside "monkey" must not misfire.
      expect(call('plate', 'text'), 'faker.word()');
      expect(call('monkey', 'text'), 'faker.word()');
      expect(call('key', 'text'), 'faker.token()');
    });
  });

  group('typed columns', () {
    test('type wins over the name hint', () {
      // A column named `email` typed int is still an int.
      expect(call('email', 'integer'), 'faker.integer()');
      expect(call('name', 'boolean'), 'faker.boolean()');
    });

    test('integer ranges follow the name', () {
      expect(call('age', 'integer'), 'faker.integer(min: 18, max: 80)');
      expect(call('rating', 'integer'), 'faker.integer(min: 1, max: 5)');
      expect(call('view_count', 'integer'), 'faker.integer(min: 0, max: 100)');
      expect(call('anything', 'integer'), 'faker.integer()');
    });

    test('real ranges follow the name', () {
      expect(
        call('latitude', 'real'),
        'faker.decimal(min: -90, max: 90, fractionDigits: 6)',
      );
      expect(
        call('longitude', 'real'),
        'faker.decimal(min: -180, max: 180, fractionDigits: 6)',
      );
      expect(call('price', 'real'), 'faker.decimal(min: 1, max: 5000)');
      expect(call('whatever', 'real'), 'faker.decimal()');
    });

    test('boolean probability follows the name', () {
      expect(
        call('is_deleted', 'boolean'),
        'faker.boolean(trueProbability: 0.1)',
      );
      expect(call('active', 'boolean'), 'faker.boolean(trueProbability: 0.8)');
      expect(call('flag', 'boolean'), 'faker.boolean()');
    });

    test('dates lean past, future or birth date', () {
      expect(call('created_at', 'dateTime'), 'faker.pastDateTime()');
      expect(call('expires_at', 'dateTime'), 'faker.futureDateTime()');
      expect(call('birth_date', 'dateTime'), 'faker.birthDate()');
    });

    test('blobs get bytes', () {
      expect(call('payload', 'blob'), 'faker.bytes()');
    });
  });
}
