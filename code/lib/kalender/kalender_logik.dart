import '../checkin/checkin.dart';
import '../feed/feed_store.dart';
import 'kalender_dienst.dart';

/// Connects the calendar (vault Umsetzung/Kalender verbinden.md): asks the
/// phone, moves the app's own appointments from today on into the
/// calendar so nothing gets lost, and saves it. False when not allowed.
Future<bool> kalenderVerbinden(
  KalenderDienst dienst,
  FeedStore feed,
  DateTime jetzt,
) async {
  if (!await dienst.verbinden()) return false;
  final heute = dayKey(jetzt);
  for (final t in await feed.loadTermine()) {
    if (dayKey(t.datum).compareTo(heute) < 0) continue;
    if (await dienst.anlegen(t, null)) await feed.removeTermin(t);
  }
  final e = await feed.loadKalender();
  await feed.saveKalender(e.copyWith(verbunden: true));
  return true;
}

/// Back to the app's own list; the choices are forgotten.
Future<void> kalenderTrennen(FeedStore feed) =>
    feed.saveKalender(const KalenderEinstellung());
