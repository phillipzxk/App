---
title: Datenmodell
tags: [datenstruktur]
aliases: [Datenstruktur]
aktualisiert: 2026-10-12
---

# Datenmodell (Grobkonzept)

Jeder [[Nutzer]] hat viele [[Check-ins]], jeder Check-in hat genau eine [[KI-Antworten|KI-Antwort]]. Der [[Fortschritts-Verlauf]] wird aus den Bewertungs-Kennzahlen aller KI-Antworten eines Nutzers gebildet und braucht keine eigene Tabelle.

```mermaid
erDiagram
    NUTZER ||--o{ CHECK_IN : "hat viele (1 pro Tag)"
    CHECK_IN ||--|| KI_ANTWORT : "hat genau eine"
    NUTZER ||--o{ GEWICHT : "hat viele"
    NUTZER ||--o| TRAININGSPLAN : "hat einen"
    NUTZER ||--o{ ABENDROUTINE : "Schritte"
    NUTZER ||--o| KCAL_PROFIL : "hat eins"
    NUTZER ||--o{ COACH_FRAGE : "hat viele"
    NUTZER ||--o{ SCHLAFDAUER : "1 pro Tag"
    NUTZER {
        id nutzer_id
        text name
        text email
        date registrierungsdatum
        enum abo_status
        text ziel
        text level
        text motivation
        text training
        text ernaehrung
        text schlaf_energie
        text zusammenfassung
    }
    CHECK_IN {
        id check_in_id
        id nutzer_id
        date datum
        text training
        text ernaehrung
        text schlaf
        text mindset
    }
    GEWICHT {
        id nutzer_id
        datetime datum
        float kilogramm
    }
    TRAININGSPLAN {
        id nutzer_id
        text montag_bis_sonntag
    }
    ABENDROUTINE {
        id nutzer_id
        text uhrzeit
        text was
    }
    KCAL_PROFIL {
        id nutzer_id
        int groesse_cm
        int alter
        enum geschlecht
        enum aktivitaet
    }
    SCHLAFDAUER {
        id nutzer_id
        date datum
        float stunden
    }
    COACH_FRAGE {
        id nutzer_id
        datetime datum
        enum bereich
        text text
        text antwort
    }
    KI_ANTWORT {
        id antwort_id
        id check_in_id
        text antworttext
        enum antwort_typ
        int kennzahl
    }
```

## Tabellen

1. [[Nutzer]]
2. [[Check-ins]]
3. [[KI-Antworten]]
4. [[Fortschritts-Verlauf]] (abgeleitet, keine Tabelle)
5. [[Gewicht]]
6. [[Trainingsplan]], [[Abendroutine]], [[kcal-Profil]], [[Coach-Fragen]], [[Schlafdauer]] (für den [[Main Feed]], 2026-10-12)

## Bewusst weggelassen

Keine Lebensmittel- oder Übungsdatenbank, keine Kalorien-/Makro-Felder. Das passt zum conversationellen, einfachen Ansatz statt detailliertem All-in-one-Tracking (siehe [[Technischer Ansatz]]).
