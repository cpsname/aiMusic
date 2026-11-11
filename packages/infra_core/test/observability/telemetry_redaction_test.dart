import 'package:flutter_test/flutter_test.dart';
import 'package:infra_core/infra_core.dart';

/// Captures what a wrapped sink actually receives, to prove redaction happened
/// before delegation.
class _CapturingSink implements TelemetrySink {
  final List<(String, Map<String, Object?>?)> events = [];
  final List<(String, Map<String, Object?>?)> breadcrumbs = [];
  Object? lastError;
  Map<String, Object?>? lastContext;
  bool lastFatal = false;
  String? user;

  @override
  void logEvent(String name, {Map<String, Object?>? properties}) =>
      events.add((name, properties));

  @override
  void recordError(
    Object error,
    StackTrace? stackTrace, {
    Map<String, Object?>? context,
    bool fatal = false,
  }) {
    lastError = error;
    lastContext = context;
    lastFatal = fatal;
  }

  @override
  void breadcrumb(String message, {Map<String, Object?>? data}) =>
      breadcrumbs.add((message, data));

  @override
  void setUser(String? anonymousId) => user = anonymousId;
}

const _hex64 =
    'a1b2c3d4e5f6a7b8c9d0e1f2a3b4c5d6a1b2c3d4e5f6a7b8c9d0e1f2a3b4c5d6';

void main() {
  group('PiiRedactor.redactString', () {
    const r = PiiRedactor();

    test('masks JWTs, bearer tokens, emails, hex secrets and E.164 phones', () {
      expect(
        r.redactString('access=eyJhbG.eyJzdWIi.SflKxwRJ'),
        isNot(contains('eyJ')),
      );
      expect(
        r.redactString('Authorization: Bearer abc.def-456'),
        isNot(contains('abc.def')),
      );
      expect(r.redactString('reach me at a.b@example.com'),
          isNot(contains('@example.com')));
      expect(r.redactString('sig=$_hex64'), isNot(contains(_hex64)));
      expect(r.redactString('phone +12025550123'),
          isNot(contains('+12025550123')));
    });

    test('preserves dashed UUID request ids (must stay correlatable)', () {
      const id = '550e8400-e29b-41d4-a716-446655440000';
      expect(r.redactString('request_id=$id'), contains(id));
    });

    test('preserves short digit runs like order numbers', () {
      expect(r.redactString('order O12345'), contains('O12345'));
    });
  });

  group('PiiRedactor.redactMap', () {
    const r = PiiRedactor();

    test('masks values under sensitive keys wholesale, leaves others', () {
      final out = r.redactMap({
        'access_token': 'whatever-plain',
        'order_no': 'O123',
        'note': 'hello',
      });
      expect(out['access_token'], isNot('whatever-plain'));
      expect(out['order_no'], 'O123');
      expect(out['note'], 'hello');
    });

    test('recurses into nested maps and lists', () {
      final out = r.redactMap({
        'headers': {'authorization': 'Bearer xyztoken'},
        'list': ['a@b.com'],
      });
      expect((out['headers'] as Map)['authorization'], isNot(contains('xyz')));
      expect((out['list'] as List).first, isNot(contains('@')));
    });
  });

  group('RedactingTelemetrySink', () {
    test('scrubs token from event properties before delegating', () {
      final inner = _CapturingSink();
      RedactingTelemetrySink(inner).logEvent(
        'purchase_start',
        properties: {'access_token': 'eyJh.eyJz.SflK', 'product': 'pro'},
      );
      final (name, props) = inner.events.single;
      expect(name, 'purchase_start');
      expect(props!['access_token'], isNot(contains('eyJ')));
      expect(props['product'], 'pro');
    });

    test('scrubs breadcrumb message and data', () {
      final inner = _CapturingSink();
      RedactingTelemetrySink(inner).breadcrumb(
        'Authorization: Bearer supersecretvalue',
        data: {'email': 'a@b.com'},
      );
      final (msg, data) = inner.breadcrumbs.single;
      expect(msg, isNot(contains('supersecret')));
      expect(data!['email'], isNot(contains('@')));
    });

    test('redacts error context and forwards the fatal flag', () {
      final inner = _CapturingSink();
      RedactingTelemetrySink(inner).recordError(
        StateError('boom'),
        StackTrace.current,
        context: {'token': 'eyJh.eyJz.SflK'},
        fatal: true,
      );
      expect(inner.lastFatal, isTrue);
      expect(inner.lastContext!['token'], isNot(contains('eyJ')));
    });

    test('forwards the anonymous user id unchanged', () {
      final inner = _CapturingSink();
      RedactingTelemetrySink(inner).setUser('anon-123');
      expect(inner.user, 'anon-123');
    });
  });
}
