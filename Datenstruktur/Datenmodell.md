---
title: Datenmodell
tags: [datenstruktur]
aliases: [Datenstruktur]
aktualisiert: 2026-10-09
---

# Datenmodell (Grobkonzept)

Jeder [[Nutzer]] hat viele [[Check-ins]], jeder Check-in hat genau eine [[KI-Antworten|KI-Antwort]]. Der [[Fortschritts-Verlauf]] wird aus den Bewertungs-Kennzahlen aller KI-Antworten eines Nutzers gebildet und braucht keine eigene Tabelle.

```mermaid
erDiagram
    NUTZER ||--o{ CHECK_IN : "hat viele (1 pro Tag)"
    CHECK_IN ||--|| KI_ANTWORT : "hat genau eine"
    NUTZER {
        id nutzer_id
        text name
        text email
        date registrierungsdatum
        enum abo_status
        text ziel
        text level
    }
    CHECK_IN {
        id check_in_id
        id nutzer_id
        date datum
        text training
        text ernaehrung_gefuehl
        text schlaf_energie
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

## Bewusst weggelassen

Keine Lebensmittel- oder Übungsdatenbank, keine Kalorien-/Makro-Felder. Das passt zum conversationellen, einfachen Ansatz statt detailliertem All-in-one-Tracking (siehe [[Technischer Ansatz]]).
