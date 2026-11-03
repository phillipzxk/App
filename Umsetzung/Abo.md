---
thema: Abo
stand: 2026-11-02
status: Entwurf beschlossen, gebaut (Bezahlung über Apple folgt mit dem Entwicklerkonto)
---

# Abo

Zusammen mit Phillip Schritt für Schritt festgelegt (2026-11-02). Gehört zur Vorbereitung auf die Beta, siehe [[Release-Plan]] und [[Konto und Sicherung]].

## Beschlüsse

1. **Gratis-Woche:** 7 Tage ist alles offen, ohne Zahlung vorab. Am 7. Tag kommt der Abo-Bildschirm mit dem, was der Coach in der Woche über einen gelernt hat.
2. **Abo-Bildschirm:** oben das gewachsene Wurzelwerk der Woche, darunter die Wochen-Zusammenfassung vom Coach, dann Preis und Knopf.
3. **Preise:** Monat 9,99 € und Jahr 59,99 € (5 € im Monat, 50 % gespart). Das Jahr ist vorausgewählt. Beide Preise stehen gleich groß nebeneinander in einem Feld (Phillip: sonst wirkt 59,99 € zu viel).
4. **Ohne Abo:** Eintragen und Check-in bleiben frei, der Coach schweigt. Keine täglichen Antworten und keine übrigen KI-Funktionen.
5. **Zähler:** die ganze Woche ein kleiner Zähler oben rechts auf Heute.
6. **Für Nutzer ohne Abo (Phillip: „die sind auch wichtig“):** sonntags ein Wochen-Satz vom Coach, und erkannte [[Deine Muster]] bleiben sichtbar.
7. **Keine Werbung.** Gesundheitsdaten, Apple verbietet HealthKit-Daten für Werbung, und Werbung bringt bei kleiner Nutzerzahl kaum etwas.

## Entwurf 7 (Phillip „ja“ 2026-11-02)

https://claude.ai/artifact/3KtBLmbGYxgoQegBrC1vZ6

Farbe **Bernstein**: dunkles, warmes Braun mit leisen, langsam treibenden Lichtflecken. Passt zum Rest der App und hebt sich nur leicht ab (Phillip: „muss zum Rest passen, nur ganz leicht abheben und clean sein“). Nicht mehr schwarz, nicht zu voll.

- **Tag 1 bis 7, Heute:** Zähler als kleiner Ring aus 7 Teilen, in der Mitte wächst ein Trieb. Beim ersten Öffnen und bei jedem Tippen sagt eine Sprechblase: „7 Tage ist alles offen. Am 7. Tag zeige ich dir, was in deiner ersten Woche gewachsen ist.“
- **Tag 6:** Der Coach hängt an seine Antwort an: „Morgen zeige ich dir, was ich in deinen ersten 7 Tagen über dich gelernt habe.“ Darunter eine Karte mit pulsierendem Samenkorn: „Morgen: Deine erste Woche geht auf.“
- **Tag 7, Abo-Bildschirm „Sieh, was gewachsen ist“:**
  - Sonne geht hinter einem goldenen Baum auf, Strahlen drehen sich langsam, Blätter wiegen sich.
  - Darunter die 7 Tage als Punkte, jeder mit dem, was an dem Tag war. Ein Tag ohne Check-in bleibt hohl.
  - Lichtpunkte fliegen in eine Karte mit 3 goldenen Ringen (Check-ins, Fokus-Tage, durchgezogen). In derselben Karte stehen „Was ich über dich gelernt habe“, das stärkste Muster und „Nächste Woche: dein erster Reality Check und ein neuer Fokus“.
  - „Mit dem Abo wächst weiter“ als ruhige Liste: Coach jeden Tag, Fokus und Reality Check, Teller-Foto und Form-Check, Muster und Tagesplan.
  - Preisfeld mit gleitendem goldenem Knauf, Knopf „Weiter wachsen“ (Gold bis Bernstein, Lichtschimmer), klein „Jederzeit kündbar, bezahlt wird über Apple.“, Link „Ohne Abo weiter eintragen“.
- **Danach mit Abo:** goldener Ring zeichnet sich, Trieb wächst, Funken. „Phillip, wir wachsen weiter.“, Coach-Satz, „Abo aktiv“ und „Deine nächste Woche“ (Mo, Mi, So).
- **Danach ohne Abo:** Montag bis Samstag ist die Coach-Karte grau („Dein Check-in ist gespeichert. Ich melde mich am Sonntag mit deiner Woche.“), darunter „Coach wieder einschalten ab 5 € im Monat ›“. Sonntags schreibt der Coach den Wochen-Satz.

Animationen: Felder gleiten federnd herein, Baum zieht beim Scrollen langsamer mit, Felder geben beim Tippen leicht nach.

## Stand im Code (2026-11-02)

- Ordner `code/lib/abo/`.
- Die Gratis-Woche beginnt mit dem ersten Tag in der App nach dem Update.
- Der Abo-Bildschirm kommt an Tag 7 nach dem Check-in.
- Ohne Abo sperrt die App alle KI-Anfragen außer Bereichs-Werten, Mustern und dem Wochen-Satz. Die Bereichs-Werte bleiben, damit Heute und das Wurzelwerk nicht leer sind, samt dem kurzen Satz „Warum gerade hier“. Von Phillip bestätigt am 2026-11-03 („passt“).
- Neue Worker-Route `/woche` für die Wochen-Zusammenfassung und den Sonntags-Satz.
- Kaufen ist in der Vorschau nur gespielt. Echte Bezahlung über Apple (StoreKit) kommt, sobald Phillip das Apple-Entwicklerkonto hat. In den Einstellungen unter „Abo“ kann man den Abo-Bildschirm zum Ansehen öffnen und das Abo in der Vorschau wieder zurücksetzen.
