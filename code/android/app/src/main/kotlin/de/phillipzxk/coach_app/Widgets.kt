package de.phillipzxk.coach_app

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.graphics.Paint
import android.net.Uri
import android.view.View
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetPlugin
import es.antonborri.home_widget.HomeWidgetProvider
import java.text.SimpleDateFormat
import java.util.Calendar
import java.util.Date
import java.util.Locale
import org.json.JSONArray
import org.json.JSONObject

// The widgets on Android (vault Umsetzung/Widgets.md): A "Jetzt dran",
// B "Fokus der Woche" with "Heute geschafft", C "Coach und Tag". The app
// writes one JSON text (lib/startwidget/widget_daten.dart); the widgets
// work out by themselves what is next. Android has no widgets on the lock
// screen, so D, E and F exist on the iPhone only.

private const val DATEN = "groundset_widget"
private const val OFFEN = "groundset_fokus_offen"
private const val GESCHAFFT = "de.phillipzxk.coach_app.widget.GESCHAFFT"

private fun tagKey(d: Date): String = SimpleDateFormat("yyyy-MM-dd", Locale.US).format(d)

private fun uhrzeit(d: Date): String = SimpleDateFormat("HH:mm", Locale.US).format(d)

private class Punkt(val zeit: Date, val titel: String, val ziel: String, val erledigt: Boolean)

/** The state of the day at one moment. */
private class Lage(prefs: SharedPreferences, val jetzt: Date = Date()) {
  val daten: JSONObject? =
      prefs.getString(DATEN, null)?.let { runCatching { JSONObject(it) }.getOrNull() }

  val aktuell: Boolean = daten?.optString("tag") == tagKey(jetzt)

  val punkte: List<Punkt> =
      if (!aktuell) emptyList()
      else {
        val a = daten?.optJSONArray("punkte") ?: JSONArray()
        (0 until a.length()).mapNotNull { i ->
          val p = a.optJSONObject(i) ?: return@mapNotNull null
          Punkt(
              Date(p.optLong("t") * 1000),
              p.optString("titel"),
              p.optString("ziel", "tag"),
              p.optBoolean("erledigt"),
          )
        }
      }

  val checkin: Boolean = aktuell && daten?.optBoolean("checkin") == true
  val naechster: Punkt? = punkte.firstOrNull { !it.erledigt && it.zeit.after(jetzt) }
  val gesamt: Int = punkte.size + 1
  val geschafft: Int =
      punkte.count { it.erledigt || !it.zeit.after(jetzt) } + (if (checkin) 1 else 0)
  val prozent: Int = if (aktuell) geschafft * 100 / gesamt else 0

  // Fokus der Woche: 7 days from its start day.
  private val f: JSONObject? = daten?.optJSONObject("fokus")
  private val start: Date? =
      f?.optString("start")?.let {
        runCatching { SimpleDateFormat("yyyy-MM-dd", Locale.US).parse(it) }.getOrNull()
      }
  private val fertig: Set<String> =
      f?.optJSONArray("geschafft")?.let { a -> (0 until a.length()).map { a.optString(it) }.toSet() }
          ?: emptySet()

  private fun tagAb(i: Int): Date =
      Calendar.getInstance().apply {
            time = start ?: jetzt
            add(Calendar.DAY_OF_YEAR, i)
          }
          .time

  val fokusTag: Int =
      if (start == null) 99
      else (0..7).firstOrNull { tagKey(tagAb(it)) == tagKey(jetzt) }?.plus(1) ?: 99
  val fokusText: String? = if (fokusTag <= 7) f?.optString("text") else null
  val striche: List<Boolean> = (0 until 7).map { fertig.contains(tagKey(tagAb(it))) }
  val heuteGeschafft: Boolean = fertig.contains(tagKey(jetzt))
}

private fun oeffnen(context: Context, ziel: String): PendingIntent =
    HomeWidgetLaunchIntent.getActivity(
        context,
        MainActivity::class.java,
        Uri.parse("groundset://oeffnen?ziel=$ziel"),
    )

/** Lets all three widgets draw again. */
private fun alleNeu(context: Context) {
  val m = AppWidgetManager.getInstance(context)
  for (k in listOf(JetztWidget::class.java, FokusWidget::class.java, TagWidget::class.java)) {
    val ids = m.getAppWidgetIds(ComponentName(context, k))
    if (ids.isEmpty()) continue
    context.sendBroadcast(
        Intent(context, k).apply {
          action = AppWidgetManager.ACTION_APPWIDGET_UPDATE
          putExtra(AppWidgetManager.EXTRA_APPWIDGET_IDS, ids)
        })
  }
}

/** A: the next thing of the day and how much of today is done. */
class JetztWidget : HomeWidgetProvider() {
  override fun onUpdate(
      context: Context,
      appWidgetManager: AppWidgetManager,
      appWidgetIds: IntArray,
      widgetData: SharedPreferences,
  ) {
    val l = Lage(widgetData)
    val n = l.naechster
    val (titel, unter, knopf, ziel) =
        when {
          !l.aktuell -> listOf("Dein Tag", "Öffne Groundset für heute.", "Öffnen", "heute")
          !l.checkin -> listOf("Check-in", "30 Sekunden für deinen Coach.", "Starten", "heute")
          n != null ->
              listOf(
                  n.titel,
                  "um ${uhrzeit(n.zeit)}",
                  if (n.ziel == "training") "Starten" else "Öffnen",
                  n.ziel,
              )
          else -> listOf("Alles geschafft", "Für heute ist nichts mehr offen.", "Ansehen", "tag")
        }
    for (id in appWidgetIds) {
      val v = RemoteViews(context.packageName, R.layout.widget_jetzt)
      v.setTextViewText(R.id.titel, titel)
      v.setTextViewText(R.id.unter, unter)
      v.setTextViewText(R.id.knopf, knopf)
      v.setProgressBar(R.id.ring, 100, l.prozent, false)
      v.setTextViewText(R.id.ring_text, if (l.aktuell) "${l.geschafft}/${l.gesamt}" else "–")
      v.setOnClickPendingIntent(R.id.wurzel, oeffnen(context, ziel))
      appWidgetManager.updateAppWidget(id, v)
    }
  }
}

/** B: the week's focus; "Heute geschafft" works right in the widget. */
class FokusWidget : HomeWidgetProvider() {
  override fun onReceive(context: Context, intent: Intent) {
    if (intent.action == GESCHAFFT) {
      val prefs = HomeWidgetPlugin.getData(context)
      val heute = tagKey(Date())
      val e = prefs.edit()
      // Shown at once, and noted for the app, which takes it over the
      // next time it opens.
      prefs.getString(DATEN, null)
          ?.let { runCatching { JSONObject(it) }.getOrNull() }
          ?.let { d ->
            d.optJSONObject("fokus")?.let { f ->
              val a = f.optJSONArray("geschafft") ?: JSONArray()
              if ((0 until a.length()).none { a.optString(it) == heute }) a.put(heute)
              f.put("geschafft", a)
              e.putString(DATEN, d.toString())
            }
          }
      val offen = (prefs.getString(OFFEN, "") ?: "").split(",").filter { it.isNotBlank() }
      e.putString(OFFEN, (offen + heute).distinct().joinToString(","))
      e.apply()
      alleNeu(context)
      return
    }
    super.onReceive(context, intent)
  }

  override fun onUpdate(
      context: Context,
      appWidgetManager: AppWidgetManager,
      appWidgetIds: IntArray,
      widgetData: SharedPreferences,
  ) {
    val l = Lage(widgetData)
    val striche =
        listOf(
            R.id.strich1,
            R.id.strich2,
            R.id.strich3,
            R.id.strich4,
            R.id.strich5,
            R.id.strich6,
            R.id.strich7,
        )
    for (id in appWidgetIds) {
      val v = RemoteViews(context.packageName, R.layout.widget_fokus)
      val text = l.fokusText
      v.setOnClickPendingIntent(R.id.wurzel, oeffnen(context, "fokus"))
      if (text == null) {
        v.setTextViewText(R.id.kicker, "Fokus der Woche")
        v.setTextViewText(R.id.titel, "Kein Fokus gewählt")
        v.setViewVisibility(R.id.striche, View.INVISIBLE)
        v.setTextViewText(R.id.knopf, "Öffnen")
        v.setOnClickPendingIntent(R.id.knopf, oeffnen(context, "fokus"))
      } else {
        v.setTextViewText(R.id.kicker, "Fokus · Tag ${l.fokusTag} von 7")
        v.setTextViewText(R.id.titel, text)
        v.setViewVisibility(R.id.striche, View.VISIBLE)
        striche.forEachIndexed { i, s ->
          v.setImageViewResource(
              s,
              if (l.striche[i]) R.drawable.widget_strich_an else R.drawable.widget_strich_aus,
          )
        }
        if (l.heuteGeschafft) {
          v.setTextViewText(R.id.knopf, "Geschafft")
          v.setInt(R.id.knopf, "setBackgroundResource", R.drawable.widget_pille_dunkel)
          v.setTextColor(R.id.knopf, 0xFFF3E2BD.toInt())
          v.setOnClickPendingIntent(R.id.knopf, oeffnen(context, "fokus"))
        } else {
          v.setTextViewText(R.id.knopf, "Heute geschafft")
          v.setInt(R.id.knopf, "setBackgroundResource", R.drawable.widget_pille_hell)
          v.setTextColor(R.id.knopf, 0xFF2A1F14.toInt())
          v.setOnClickPendingIntent(
              R.id.knopf,
              PendingIntent.getBroadcast(
                  context,
                  0,
                  Intent(context, FokusWidget::class.java).apply { action = GESCHAFFT },
                  PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
              ),
          )
        }
      }
      appWidgetManager.updateAppWidget(id, v)
    }
  }
}

/** C: the coach's sentence, the mean score and today's list. */
class TagWidget : HomeWidgetProvider() {
  override fun onUpdate(
      context: Context,
      appWidgetManager: AppWidgetManager,
      appWidgetIds: IntArray,
      widgetData: SharedPreferences,
  ) {
    val l = Lage(widgetData)
    val d = l.daten
    val coach =
        d?.optString("coach")?.takeIf { l.aktuell && it.isNotEmpty() }
            ?: if (l.checkin) "Dein Coach meldet sich gleich."
            else "Mach deinen Check-in, dann sage ich dir, worauf es heute ankommt."
    val schnitt = if (d != null && !d.isNull("schnitt")) d.optDouble("schnitt") else null
    val trend = if (l.aktuell && d != null && !d.isNull("trend")) d.optDouble("trend") else null
    fun komma(x: Double) = String.format(Locale.GERMANY, "%.1f", x)
    val trendText =
        when {
          trend == null -> ""
          Math.round(trend * 10) == 0L -> "\nwie gestern"
          trend > 0 -> "\n+${komma(trend)}"
          else -> "\n−${komma(-trend)}"
        }
    // The check-in, then what comes next; when little is left, the last
    // things of the day.
    val platz = 4
    val start =
        l.punkte
            .indexOfFirst { !it.erledigt && it.zeit.after(l.jetzt) }
            .let { if (it < 0) l.punkte.size else it }
            .coerceAtMost((l.punkte.size - platz).coerceAtLeast(0))
    val zeilen =
        listOf(Triple("Check-in", if (l.checkin) "erledigt" else "offen", l.checkin)) +
            l.punkte.drop(start).take(platz).map {
              Triple(it.titel, uhrzeit(it.zeit), it.erledigt || !it.zeit.after(l.jetzt))
            }
    val ids =
        listOf(
            Triple(R.id.zeile1, R.id.zeile1_titel, R.id.zeile1_wert),
            Triple(R.id.zeile2, R.id.zeile2_titel, R.id.zeile2_wert),
            Triple(R.id.zeile3, R.id.zeile3_titel, R.id.zeile3_wert),
            Triple(R.id.zeile4, R.id.zeile4_titel, R.id.zeile4_wert),
            Triple(R.id.zeile5, R.id.zeile5_titel, R.id.zeile5_wert),
        )
    for (id in appWidgetIds) {
      val v = RemoteViews(context.packageName, R.layout.widget_tag)
      v.setTextViewText(R.id.coach, coach)
      v.setProgressBar(R.id.ring, 100, ((schnitt ?: 0.0) * 10).toInt().coerceIn(0, 100), false)
      v.setTextViewText(R.id.ring_text, schnitt?.let { komma(it) } ?: "–")
      v.setTextViewText(R.id.schnitt, "Dein Schnitt$trendText")
      v.setViewVisibility(R.id.leer, if (l.aktuell) View.GONE else View.VISIBLE)
      ids.forEachIndexed { i, (zeile, titel, wert) ->
        val z = if (l.aktuell) zeilen.getOrNull(i) else null
        v.setViewVisibility(zeile, if (z == null) View.GONE else View.VISIBLE)
        if (z != null) {
          val flags =
              Paint.ANTI_ALIAS_FLAG or (if (z.third) Paint.STRIKE_THRU_TEXT_FLAG else 0)
          v.setTextViewText(titel, z.first)
          v.setTextViewText(wert, z.second)
          v.setInt(titel, "setPaintFlags", flags)
          v.setTextColor(titel, if (z.third) 0x73F6ECDB else 0xFFF6ECDB.toInt())
          v.setTextColor(wert, if (z.third) 0x73E6C98F else 0xFFE6C98F.toInt())
        }
      }
      v.setOnClickPendingIntent(R.id.wurzel, oeffnen(context, "tag"))
      appWidgetManager.updateAppWidget(id, v)
    }
  }
}
