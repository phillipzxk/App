import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:coach_app/checkin/checkin.dart';
import 'package:coach_app/coach/remote_coach.dart';
import 'package:coach_app/data/user_profile.dart';
import 'package:coach_app/feed/feed_data.dart';

const _max = UserProfile(name: 'Max', ziel: 'Stolz sein');

void main() {
  test('check-in reply goes to /checkin with token and answers', () async {
    late http.Request sent;
    final coach = RemoteCoach(
      baseUrl: 'https://coach.test',
      token: 'abc',
      client: MockClient((r) async {
        sent = r;
        return http.Response.bytes(
          utf8.encode(jsonEncode({'text': ' Max, guter Tag. '})),
          200,
        );
      }),
    );
    final today = CheckIn(
      datum: DateTime(2026, 10, 14),
      training: 'Beine',
      ernaehrung: 'ok',
      schlaf: 'gut',
      mindset: 'nichts',
    );

    final reply = await coach.reply(_max, today, [today]);

    expect(reply, 'Max, guter Tag.');
    expect(sent.url.toString(), 'https://coach.test/checkin');
    expect(sent.headers['x-app-token'], 'abc');
    final body = jsonDecode(sent.body) as Map;
    expect(body['profile']['name'], 'Max');
    expect(body['today']['training'], 'Beine');
  });

  test('feed answer sends area and context', () async {
    late Map body;
    final coach = RemoteCoach(
      baseUrl: 'https://coach.test',
      token: 'abc',
      client: MockClient((r) async {
        body = jsonDecode(r.body) as Map;
        return http.Response(jsonEncode({'text': 'Antwort'}), 200);
      }),
    );

    final a = await coach.answer(
      _max,
      Bereich.training,
      'Kraft fehlte',
      context: 'Mo: Oberkörper',
    );

    expect(a, 'Antwort');
    expect(body['bereich'], 'training');
    expect(body['context'], 'Mo: Oberkörper');
  });

  test(
    'errors and empty answers give null, so the app shows its fallback',
    () async {
      final failing = RemoteCoach(
        baseUrl: 'https://coach.test',
        token: 'abc',
        client: MockClient((_) async => http.Response('{"error":"x"}', 502)),
      );
      expect(await failing.summarize(_max), isNull);

      final empty = RemoteCoach(
        baseUrl: 'https://coach.test',
        token: 'abc',
        client: MockClient((_) async => http.Response('{"text":""}', 200)),
      );
      expect(await empty.summarize(_max), isNull);

      final offline = RemoteCoach(
        baseUrl: 'https://coach.test',
        token: 'abc',
        client: MockClient((_) async => throw http.ClientException('offline')),
      );
      expect(await offline.summarize(_max), isNull);
    },
  );
}
