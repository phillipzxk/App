package de.phillipzxk.coach_app

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.BitmapShader
import android.graphics.Canvas
import android.graphics.Paint
import android.graphics.Path
import android.graphics.Shader
import android.net.Uri
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider
import java.text.SimpleDateFormat
import java.util.Calendar
import java.util.Date
import java.util.Locale
import org.json.JSONArray
import org.json.JSONObject

// The widgets on Android (vault Umsetzung/Widgets.md), the five confirmed
// 2026-11-15: "Dein Baum", "Jetzt dran" with praise, "Dafür", "Dein Coach
// spricht" and "Deine Woche". The app writes one JSON text
// (lib/startwidget/widget_daten.dart); the widgets work out by themselves
// what is next.

private const val DATEN = "groundset_widget"
private const val GOLD = 0xFFE6C98F.toInt()
private const val TINTE = 0xFF2A1F14.toInt()
private const val CREME = 0xFFF6ECDB.toInt()

private fun tagKey(d: Date): String = SimpleDateFormat("yyyy-MM-dd", Locale.US).format(d)

private fun uhrzeit(d: Date): String = SimpleDateFormat("HH:mm", Locale.US).format(d)

private fun datum(key: String?): Date? =
    key?.let { runCatching { SimpleDateFormat("yyyy-MM-dd", Locale.US).parse(it) }.getOrNull() }

private fun tageZwischen(a: Date, b: Date): Int {
  fun mitternacht(d: Date) =
      Calendar.getInstance().apply {
        time = d
        set(Calendar.HOUR_OF_DAY, 12)
        set(Calendar.MINUTE, 0)
        set(Calendar.SECOND, 0)
        set(Calendar.MILLISECOND, 0)
      }
  return Math.round((mitternacht(b).timeInMillis - mitternacht(a).timeInMillis) / 86400000.0)
      .toInt()
}

private class Punkt(val zeit: Date, val titel: String, val ziel: String, val erledigt: Boolean)

/** The state of the day at one moment. */
private class Lage(prefs: SharedPreferences, val jetzt: Date = Date()) {
  val daten: JSONObject? =
      prefs.getString(DATEN, null)?.let { runCatching { JSONObject(it) }.getOrNull() }

  private fun text(key: String): String =
      daten?.takeIf { !it.isNull(key) }?.optString(key) ?: ""

  val aktuell: Boolean = daten?.optString("tag") == tagKey(jetzt)
  val name: String = text("name")

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
  val komplett: Boolean = aktuell && checkin && geschafft >= gesamt

  /** What was just done, while its praise lasts. */
  val lob: String? =
      daten?.optJSONObject("lob")?.let {
        if (aktuell && Date(it.optLong("bis") * 1000).after(jetzt)) it.optString("titel") else null
      }

  /** From 17:00 the coach looks back instead of ahead. */
  val abend: Boolean =
      Calendar.getInstance().apply { time = jetzt }.get(Calendar.HOUR_OF_DAY) >= 17

  private val alter: Int = datum(daten?.optString("tag"))?.let { tageZwischen(it, jetzt) } ?: 9

  // The streak only holds while the data is at most a day old.
  val serie: Int =
      when {
        alter <= 0 -> daten?.optInt("serie") ?: 0
        alter == 1 && daten?.optBoolean("checkin") == true -> daten?.optInt("serie") ?: 0
        else -> 0
      }
  val rekord: Int = daten?.optInt("rekord") ?: 0
  val wurzeln: Int = daten?.optInt("wurzeln") ?: 0
  val marke: Int = listOf(3, 7, 14, 30).firstOrNull { serie < it } ?: ((serie / 30 + 1) * 30)
  val markeErreicht: Boolean = serie > 0 && (serie in listOf(3, 7, 14) || serie % 30 == 0)

  val ziel: String = text("ziel")
  val grund: String = text("grund")
  val coach: String = if (aktuell) text("coach") else ""
  val abendSatz: String = text("abend")

  private val fokus: JSONObject? = daten?.optJSONObject("fokus")
  val fokusText: String = fokus?.optString("text") ?: ""
  val fokusTag: Int? =
      datum(fokus?.optString("start"))?.let { tageZwischen(it, jetzt) + 1 }?.takeIf { it in 1..7 }

  /** Monday = 0 … Sunday = 6. */
  val wochentag: Int =
      (Calendar.getInstance().apply { time = jetzt }.get(Calendar.DAY_OF_WEEK) + 5) % 7

  /** The circles only count while the data is from this week. */
  val woche: List<Boolean> =
      daten?.optJSONArray("woche")
          ?.takeIf { it.length() == 7 && alter in 0..wochentag }
          ?.let { a -> (0 until 7).map { a.optBoolean(it) } } ?: List(7) { false }
  val letzteWoche: Int = daten?.optInt("letzteWoche") ?: 0
}

private fun oeffnen(context: Context, ziel: String): PendingIntent =
    HomeWidgetLaunchIntent.getActivity(
        context,
        MainActivity::class.java,
        Uri.parse("groundset://oeffnen?ziel=$ziel"),
    )

/**
 * The sprout from the app: a leaf for every day in a row (up to eight are drawn), a root for
 * every ticked day of the week's focus.
 */
private fun baumBild(blaetter: Int, wurzeln: Int, farbe: Int, mitBoden: Boolean = true): Bitmap {
  val gr = 360
  val b = Bitmap.createBitmap(gr, gr, Bitmap.Config.ARGB_8888)
  val c = Canvas(b)
  val e = gr / 150f
  val mitte = gr / 2f
  val boden = gr * 0.60f
  val strich =
      Paint(Paint.ANTI_ALIAS_FLAG).apply {
        color = farbe
        style = Paint.Style.STROKE
        strokeCap = Paint.Cap.ROUND
      }
  val flaeche =
      Paint(Paint.ANTI_ALIAS_FLAG).apply {
        color = farbe
        style = Paint.Style.FILL
      }
  if (mitBoden) {
    strich.strokeWidth = 1.5f
    strich.alpha = 76
    c.drawLine(0f, boden, gr.toFloat(), boden, strich)
    strich.alpha = 255
  }
  if (blaetter <= 0) {
    c.drawCircle(mitte, boden, 4 * e, flaeche)
    return b
  }
  val n = minOf(blaetter, 8)
  val abstand = 8.5f * e
  strich.strokeWidth = 3 * e
  c.drawLine(mitte, boden, mitte, boden - (16 * e + n * abstand), strich)
  for (i in 0 until n) {
    val s = if (i % 2 == 0) 1f else -1f
    val y = boden - 8 * e - i * abstand
    val g = (20 - i) * e
    val blatt =
        Path().apply {
          moveTo(mitte, y)
          quadTo(mitte + s * g * 0.95f, y - g * 0.1f, mitte + s * g, y - g * 0.9f)
          quadTo(mitte + s * g * 0.1f, y - g * 0.85f, mitte, y)
          close()
        }
    flaeche.alpha = (255 * (1 - i * 0.05f)).toInt()
    c.drawPath(blatt, flaeche)
  }
  if (mitBoden) {
    strich.alpha = 190
    for (i in 0 until minOf(maxOf(wurzeln, 1), 7)) {
      val s = if (i % 2 == 0) 1f else -1f
      val weit = (14 + (i / 2) * 11) * e
      val tief = (20 + (i / 2) * 6 + (i % 2) * 4) * e
      strich.strokeWidth = maxOf(1f, (2.4f - i * 0.2f) * e)
      c.drawPath(
          Path().apply {
            moveTo(mitte, boden + 1)
            quadTo(mitte + s * weit * 0.35f, boden + tief * 0.75f, mitte + s * weit, boden + tief)
          },
          strich,
      )
    }
  }
  return b
}

/** The coach's face as a circle with a gold ring. */
private fun kopfBild(context: Context): Bitmap {
  val gr = 184
  val quelle = BitmapFactory.decodeResource(context.resources, R.drawable.widget_coach)
  val b = Bitmap.createBitmap(gr, gr, Bitmap.Config.ARGB_8888)
  val c = Canvas(b)
  if (quelle != null) {
    val skaliert = Bitmap.createScaledBitmap(quelle, gr, gr, true)
    val bild =
        Paint(Paint.ANTI_ALIAS_FLAG).apply {
          shader = BitmapShader(skaliert, Shader.TileMode.CLAMP, Shader.TileMode.CLAMP)
        }
    c.drawCircle(gr / 2f, gr / 2f, gr / 2f - 4, bild)
  }
  val ring =
      Paint(Paint.ANTI_ALIAS_FLAG).apply {
        color = GOLD
        style = Paint.Style.STROKE
        strokeWidth = 7f
      }
  c.drawCircle(gr / 2f, gr / 2f, gr / 2f - 4, ring)
  return b
}

private fun anrede(l: Lage, vor: String = ", "): String = if (l.name.isEmpty()) "" else "$vor${l.name}"

/** 1: the tree that grows with the streak. */
class BaumWidget : HomeWidgetProvider() {
  override fun onUpdate(
      context: Context,
      appWidgetManager: AppWidgetManager,
      appWidgetIds: IntArray,
      widgetData: SharedPreferences,
  ) {
    val l = Lage(widgetData)
    val n = l.serie
    val gold = l.markeErreicht
    val oben =
        when (n) {
          0 -> "Dein Baum"
          1 -> "Tag 1"
          else -> "$n Tage am Stück"
        }
    val unten =
        when {
          n == 0 -> "Startet mit deinem nächsten Check-in"
          gold -> "Marke $n erreicht. Stark${anrede(l)}."
          n >= 3 && n >= l.rekord -> "Dein Rekord"
          else -> "Noch ${l.marke - n} bis zur Marke ${l.marke}"
        }
    for (id in appWidgetIds) {
      val v = RemoteViews(context.packageName, R.layout.widget_baum)
      v.setInt(
          R.id.wurzel,
          "setBackgroundResource",
          if (gold) R.drawable.widget_hell else R.drawable.widget_dunkel,
      )
      v.setImageViewBitmap(R.id.baum, baumBild(n, l.wurzeln, if (gold) TINTE else GOLD))
      v.setTextViewText(R.id.kicker, oben)
      v.setTextColor(R.id.kicker, if (gold) TINTE else GOLD)
      v.setTextViewText(R.id.unter, unten)
      v.setTextColor(R.id.unter, if (gold) TINTE else CREME)
      v.setOnClickPendingIntent(R.id.wurzel, oeffnen(context, "heute"))
      appWidgetManager.updateAppWidget(id, v)
    }
  }
}

/** 2: the next thing of the day; praises what was just done. */
class JetztWidget : HomeWidgetProvider() {
  override fun onUpdate(
      context: Context,
      appWidgetManager: AppWidgetManager,
      appWidgetIds: IntArray,
      widgetData: SharedPreferences,
  ) {
    val l = Lage(widgetData)
    val n = l.naechster
    val lob = l.lob
    val rest = l.gesamt - l.geschafft
    for (id in appWidgetIds) {
      if (l.komplett) {
        val v = RemoteViews(context.packageName, R.layout.widget_komplett)
        v.setImageViewBitmap(R.id.baum, baumBild(2, 0, TINTE, mitBoden = false))
        v.setTextViewText(
            R.id.unter,
            "${l.geschafft} von ${l.gesamt}. Dein Fundament ist heute gewachsen.",
        )
        v.setOnClickPendingIntent(R.id.wurzel, oeffnen(context, "tag"))
        appWidgetManager.updateAppWidget(id, v)
        continue
      }
      val (kicker, titel, unter, knopf, ziel) =
          when {
            lob != null ->
                listOf(
                    "Geschafft",
                    "$lob ist im Kasten",
                    if (rest > 0) "Noch $rest heute. Weiter so${anrede(l)}."
                    else "Stark${anrede(l)}.",
                    "Was kommt",
                    "tag",
                )
            !l.aktuell ->
                listOf("Jetzt dran", "Dein Tag", "Öffne Groundset für heute.", "Öffnen", "heute")
            !l.checkin ->
                listOf(
                    "Jetzt dran",
                    "Check-in",
                    "30 Sekunden für deinen Coach.",
                    "Starten",
                    "heute",
                )
            n != null ->
                listOf(
                    "Jetzt dran",
                    n.titel,
                    "um ${uhrzeit(n.zeit)}",
                    if (n.ziel == "training") "Starten" else "Öffnen",
                    n.ziel,
                )
            else ->
                listOf(
                    "Jetzt dran",
                    "Alles geschafft",
                    "Für heute ist nichts mehr offen.",
                    "Ansehen",
                    "tag",
                )
          }
      val v = RemoteViews(context.packageName, R.layout.widget_jetzt)
      v.setTextViewText(R.id.kicker, kicker)
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

/** 3: the user's own goal and reason, taking turns from day to day. */
class DafuerWidget : HomeWidgetProvider() {
  override fun onUpdate(
      context: Context,
      appWidgetManager: AppWidgetManager,
      appWidgetIds: IntArray,
      widgetData: SharedPreferences,
  ) {
    val l = Lage(widgetData)
    val tag = Calendar.getInstance().apply { time = l.jetzt }.get(Calendar.DAY_OF_YEAR)
    val zeigeGrund = l.grund.isNotEmpty() && (l.ziel.isEmpty() || tag % 2 == 1)
    val satz = if (zeigeGrund) l.grund else l.ziel
    val n = l.naechster
    val zahltEin =
        when {
          n != null -> "${n.titel} um ${uhrzeit(n.zeit)}"
          l.fokusTag != null && l.fokusText.isNotEmpty() -> l.fokusText
          l.checkin -> "Dein Abend und dein Schlaf"
          else -> "Dein Check-in"
        }
    for (id in appWidgetIds) {
      val v = RemoteViews(context.packageName, R.layout.widget_dafuer)
      v.setTextViewText(R.id.kicker, if (zeigeGrund) "Darum jetzt" else "Dafür")
      v.setTextViewText(R.id.titel, if (satz.isEmpty()) "Dein Ziel fehlt noch" else "„$satz“")
      v.setTextViewText(R.id.unter, zahltEin)
      v.setOnClickPendingIntent(R.id.wurzel, oeffnen(context, "mindset"))
      appWidgetManager.updateAppWidget(id, v)
    }
  }
}

/** 4: the coach, in the morning a task, in the evening an honest look back. */
class CoachWidget : HomeWidgetProvider() {
  override fun onUpdate(
      context: Context,
      appWidgetManager: AppWidgetManager,
      appWidgetIds: IntArray,
      widgetData: SharedPreferences,
  ) {
    val l = Lage(widgetData)
    val abend = l.abend && l.aktuell && l.checkin
    val stand = "${l.geschafft} von ${l.gesamt} geschafft."
    val wer = if (l.name.isEmpty()) "" else "${l.name}, "
    val satz =
        when {
          abend && l.abendSatz.isNotEmpty() -> "$stand ${l.abendSatz}"
          abend && l.komplett -> "$stand Heute hast du alles durchgezogen."
          abend -> stand
          l.coach.isNotEmpty() -> l.coach
          l.checkin -> "${wer}ich melde mich gleich bei dir."
          else -> "${wer}mach deinen Check-in. Dann sage ich dir, worauf es heute ankommt."
        }
    val n = l.naechster
    val unten =
        when {
          abend && n != null -> "Nur noch: ${n.titel} ${uhrzeit(n.zeit)}"
          abend -> "Für heute ist nichts mehr offen."
          l.fokusTag != null -> "Fokus: Tag ${l.fokusTag} von 7"
          else -> "Noch kein Fokus gewählt"
        }
    val kopf = kopfBild(context)
    for (id in appWidgetIds) {
      val v = RemoteViews(context.packageName, R.layout.widget_coach)
      v.setTextViewText(R.id.kicker, if (abend) "Dein Coach · Abend" else "Dein Coach · Morgen")
      v.setImageViewBitmap(R.id.kopf, kopf)
      v.setTextViewText(R.id.titel, satz)
      v.setTextViewText(R.id.unter, unten)
      v.setTextViewText(
          R.id.knopf,
          if (abend) "Abend starten" else if (l.checkin) "Öffnen" else "Check-in",
      )
      v.setOnClickPendingIntent(R.id.wurzel, oeffnen(context, if (abend) "schlaf" else "heute"))
      appWidgetManager.updateAppWidget(id, v)
    }
  }
}

/** 5: seven circles for the week, against last week. */
class WocheWidget : HomeWidgetProvider() {
  override fun onUpdate(
      context: Context,
      appWidgetManager: AppWidgetManager,
      appWidgetIds: IntArray,
      widgetData: SharedPreferences,
  ) {
    val l = Lage(widgetData)
    val n = l.woche.count { it }
    val davor = l.letzteWoche
    val vergleich =
        when {
          n > davor -> "Letzte Woche $davor. Du bist vorn."
          n == davor -> if (n == 0) "Der erste Kreis wartet." else "Gleichstand mit letzter Woche."
          else -> "Letzte Woche $davor. Noch ${davor - n + 1} bis du vorn bist."
        }
    val kreise =
        listOf(
            R.id.kreis1,
            R.id.kreis2,
            R.id.kreis3,
            R.id.kreis4,
            R.id.kreis5,
            R.id.kreis6,
            R.id.kreis7,
        )
    for (id in appWidgetIds) {
      val v = RemoteViews(context.packageName, R.layout.widget_woche)
      v.setTextViewText(R.id.titel, "$n")
      kreise.forEachIndexed { i, k ->
        val an = l.woche[i]
        val heute = i == l.wochentag
        v.setInt(
            k,
            "setBackgroundResource",
            when {
              an -> R.drawable.widget_kreis_an
              heute -> R.drawable.widget_kreis_heute
              else -> R.drawable.widget_kreis_aus
            },
        )
        v.setTextColor(k, if (an) TINTE else if (heute) GOLD else 0x99F6ECDB.toInt())
      }
      v.setTextViewText(R.id.unter, vergleich)
      v.setOnClickPendingIntent(R.id.wurzel, oeffnen(context, "heute"))
      appWidgetManager.updateAppWidget(id, v)
    }
  }
}
