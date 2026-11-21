package de.phillipzxk.coach_app

import android.Manifest
import android.content.ContentValues
import android.content.Intent
import android.content.pm.PackageManager
import android.hardware.Sensor
import android.hardware.SensorEvent
import android.hardware.SensorEventListener
import android.hardware.SensorManager
import android.os.Build
import android.os.Bundle
import android.provider.CalendarContract
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel
import java.util.Calendar
import java.util.TimeZone

/// FlutterFragmentActivity, because Health Connect (package health) asks
/// for permission through it. Steps and calendar use the same channels as
/// AppDelegate.swift (vault Umsetzung/Android nachziehen.md).
class MainActivity : FlutterFragmentActivity() {
    private val warten = mutableMapOf<Int, (Boolean) -> Unit>()
    private var naechste = 4100

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        ueberSperre(vomWecker(intent))
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        if (vomWecker(intent)) ueberSperre(true)
    }

    /// Opened by the ringing alarm (flutter_local_notifications puts the
    /// payload into the intent): only then over the lock screen.
    private fun vomWecker(i: Intent?) =
        i?.getStringExtra("payload")?.startsWith("wecker|") == true

    /// The ringing alarm shows over the lock screen and turns the screen on
    /// (vault Umsetzung/Echter Wecker). Off again once it is answered, so
    /// the app never opens without unlocking otherwise.
    private fun ueberSperre(an: Boolean) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O_MR1) {
            setShowWhenLocked(an)
            setTurnScreenOn(an)
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val bote = flutterEngine.dartExecutor.binaryMessenger
        EventChannel(bote, "groundset/schritte").setStreamHandler(Schritte())
        MethodChannel(bote, "groundset/wecker").setMethodCallHandler { call, result ->
            when (call.method) {
                "sperre" -> {
                    ueberSperre(call.arguments == true)
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
        MethodChannel(bote, "groundset/kalender").setMethodCallHandler { call, result ->
            when (call.method) {
                "verbinden" -> erlauben(
                    arrayOf(Manifest.permission.READ_CALENDAR, Manifest.permission.WRITE_CALENDAR)
                ) { result.success(it) }
                "kalender" -> result.success(if (kalenderErlaubt()) kalender() else emptyList<Any>())
                "termine" -> {
                    val von = (call.argument<Number>("von"))?.toLong()
                    val bis = (call.argument<Number>("bis"))?.toLong()
                    val aus = call.argument<List<String>>("aus")?.toSet() ?: emptySet()
                    if (!kalenderErlaubt() || von == null || bis == null) {
                        result.success(emptyList<Any>())
                    } else {
                        result.success(termine(von, bis, aus))
                    }
                }
                "anlegen" -> result.success(anlegen(call.arguments as? Map<*, *> ?: emptyMap<Any, Any>()))
                else -> result.notImplemented()
            }
        }
    }

    // MARK: permissions

    private fun hat(recht: String) =
        checkSelfPermission(recht) == PackageManager.PERMISSION_GRANTED

    /// Asks Android once; true when all [rechte] are allowed.
    private fun erlauben(rechte: Array<String>, fertig: (Boolean) -> Unit) {
        val fehlt = rechte.filter { !hat(it) }
        if (fehlt.isEmpty()) {
            fertig(true)
            return
        }
        val code = naechste++
        warten[code] = fertig
        requestPermissions(fehlt.toTypedArray(), code)
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray,
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        val fertig = warten.remove(requestCode) ?: return
        fertig(grantResults.isNotEmpty() && grantResults.all { it == PackageManager.PERMISSION_GRANTED })
    }

    // MARK: steps for the alarm task

    /// Counts steps with the phone's step sensor while the task is open.
    /// Sends only the number of steps since the start.
    private inner class Schritte : EventChannel.StreamHandler, SensorEventListener {
        private var senke: EventChannel.EventSink? = null
        private var start: Float? = null
        private val manager get() = getSystemService(SENSOR_SERVICE) as SensorManager

        override fun onListen(arguments: Any?, events: EventChannel.EventSink) {
            val sensor = manager.getDefaultSensor(Sensor.TYPE_STEP_COUNTER)
            if (sensor == null) {
                events.error("kein_zaehler", "Kein Schrittzähler", null)
                return
            }
            val los = {
                senke = events
                start = null
                events.success(0)
                manager.registerListener(this, sensor, SensorManager.SENSOR_DELAY_UI)
            }
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                erlauben(arrayOf(Manifest.permission.ACTIVITY_RECOGNITION)) { ok ->
                    if (ok) los() else events.error("nicht_erlaubt", "Nicht erlaubt", null)
                }
            } else {
                los()
            }
        }

        override fun onCancel(arguments: Any?) {
            manager.unregisterListener(this)
            senke = null
            start = null
        }

        override fun onSensorChanged(event: SensorEvent) {
            val gesamt = event.values.firstOrNull() ?: return
            val s = start ?: gesamt.also { start = it }
            senke?.success((gesamt - s).toInt())
        }

        override fun onAccuracyChanged(sensor: Sensor?, accuracy: Int) {}
    }

    // MARK: calendar (vault Umsetzung/Kalender verbinden)

    private fun kalenderErlaubt() =
        hat(Manifest.permission.READ_CALENDAR) && hat(Manifest.permission.WRITE_CALENDAR)

    /// All visible calendars, the primary one first.
    private fun kalender(): List<Map<String, Any>> {
        val aus = mutableListOf<Triple<Boolean, String, Map<String, Any>>>()
        val spalten = arrayOf(
            CalendarContract.Calendars._ID,
            CalendarContract.Calendars.CALENDAR_DISPLAY_NAME,
            CalendarContract.Calendars.CALENDAR_COLOR,
            CalendarContract.Calendars.CALENDAR_ACCESS_LEVEL,
            CalendarContract.Calendars.IS_PRIMARY,
        )
        try {
            contentResolver.query(
                CalendarContract.Calendars.CONTENT_URI, spalten,
                "${CalendarContract.Calendars.VISIBLE} = 1", null, null,
            )?.use { c ->
                while (c.moveToNext()) {
                    val name = c.getString(1) ?: "Kalender"
                    val schreibbar = c.getInt(3) >= CalendarContract.Calendars.CAL_ACCESS_CONTRIBUTOR
                    aus.add(
                        Triple(
                            c.getInt(4) == 1 && schreibbar, name,
                            mapOf(
                                "id" to c.getLong(0).toString(),
                                "name" to name,
                                "farbe" to (c.getInt(2) or (0xFF shl 24)),
                                "schreibbar" to schreibbar,
                            ),
                        ),
                    )
                }
            }
        } catch (_: Exception) {
        }
        return aus.sortedWith(compareBy({ !it.first }, { it.second.lowercase() })).map { it.third }
    }

    /// All-day appointments are stored at midnight UTC: moved to the same
    /// day at local midnight, as on the iPhone.
    private fun lokalerTag(utc: Long): Long {
        val u = Calendar.getInstance(TimeZone.getTimeZone("UTC")).apply { timeInMillis = utc }
        return Calendar.getInstance().apply {
            clear()
            set(u.get(Calendar.YEAR), u.get(Calendar.MONTH), u.get(Calendar.DAY_OF_MONTH))
        }.timeInMillis
    }

    private fun termine(von: Long, bis: Long, aus: Set<String>): List<Map<String, Any>> {
        val liste = mutableListOf<Map<String, Any>>()
        val uri = CalendarContract.Instances.CONTENT_URI.buildUpon().also {
            android.content.ContentUris.appendId(it, von)
            android.content.ContentUris.appendId(it, bis)
        }.build()
        val spalten = arrayOf(
            CalendarContract.Instances.BEGIN,
            CalendarContract.Instances.TITLE,
            CalendarContract.Instances.ALL_DAY,
            CalendarContract.Instances.CALENDAR_ID,
            CalendarContract.Instances.CALENDAR_DISPLAY_NAME,
        )
        try {
            contentResolver.query(uri, spalten, null, null, "${CalendarContract.Instances.BEGIN} ASC")?.use { c ->
                while (c.moveToNext()) {
                    if (aus.contains(c.getLong(3).toString())) continue
                    val ganztags = c.getInt(2) == 1
                    val start = if (ganztags) lokalerTag(c.getLong(0)) else c.getLong(0)
                    liste.add(
                        mapOf(
                            "start" to start.toDouble(),
                            "titel" to (c.getString(1) ?: ""),
                            "ganztags" to ganztags,
                            "kalender" to (c.getString(4) ?: "Kalender"),
                        ),
                    )
                }
            }
        } catch (_: Exception) {
        }
        return liste.sortedBy { it["start"] as Double }
    }

    private fun anlegen(args: Map<*, *>): Boolean {
        if (!kalenderErlaubt()) return false
        val start = (args["start"] as? Number)?.toLong() ?: return false
        val titel = args["titel"] as? String ?: return false
        val ganztags = args["ganztags"] as? Boolean ?: false
        val alle = kalender().filter { it["schreibbar"] == true }
        val ziel = (args["kalender"] as? String)?.let { id -> alle.firstOrNull { it["id"] == id } }
            ?: alle.firstOrNull() ?: return false
        val werte = ContentValues().apply {
            put(CalendarContract.Events.CALENDAR_ID, (ziel["id"] as String).toLong())
            put(CalendarContract.Events.TITLE, titel)
            if (ganztags) {
                val lokal = Calendar.getInstance().apply { timeInMillis = start }
                val utc = Calendar.getInstance(TimeZone.getTimeZone("UTC")).apply {
                    clear()
                    set(lokal.get(Calendar.YEAR), lokal.get(Calendar.MONTH), lokal.get(Calendar.DAY_OF_MONTH))
                }.timeInMillis
                put(CalendarContract.Events.DTSTART, utc)
                put(CalendarContract.Events.DTEND, utc + 86_400_000L)
                put(CalendarContract.Events.ALL_DAY, 1)
                put(CalendarContract.Events.EVENT_TIMEZONE, "UTC")
            } else {
                put(CalendarContract.Events.DTSTART, start)
                put(CalendarContract.Events.DTEND, start + 3_600_000L)
                put(CalendarContract.Events.EVENT_TIMEZONE, TimeZone.getDefault().id)
            }
        }
        return try {
            contentResolver.insert(CalendarContract.Events.CONTENT_URI, werte) != null
        } catch (_: Exception) {
            false
        }
    }
}
