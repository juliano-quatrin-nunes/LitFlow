## Project Purpose
This application supports Catholic music ministry teams during Mass celebrations.

Its primary goals are:
- manage reusable musical repertoire
- assemble celebration-specific repertoires
- generate slide decks for projection
- generate formatted chord sheets for musicians
- support parish scheduling and local configuration
- remain extensible for future liturgy workflows

The frontend UI is currently written in Brazilian Portuguese.
All source code, classes, methods, documentation, and domain names MUST remain in English.

This document should stay intentionally small and evolve with the codebase.

---

## Architecture
This project is a **Rails full-stack monolith**.

The goal is to keep complexity low while exercising strong domain modeling and modern Rails frontend workflows.

Frontend developer experience should leverage modern Rails tooling:
- Action View
- Hotwire
- Tailwind CSS
- JR UI (https://ui.jetrockets.com/ui) as the primary component library
- Herb / ReActionView
- Stimulus where needed

Prefer Rails-native patterns and JR UI components before introducing new abstractions.

---

## Domain-Driven Design
The system uses **DDD strategic modeling with bounded contexts**.

When implementing features, first identify the correct bounded context and keep responsibilities isolated.

### Liturgy
Reference context responsible for:
- Mass structure
- liturgical seasons
- liturgical calendar
- celebration moments
- fixed and optional parts
- liturgical rules

### Musical Repertoire
Global reusable content catalog responsible for:
- songs
- lyrics
- chords
- musical keys
- composers and artists
- reusable prayers and spoken texts used in projection

This catalog is shared and not parish-owned.

### Celebration Assembly
Core domain responsible for:
- building the repertoire for a specific Mass
- ordering songs, prayers, and fixed parts
- connecting content to the liturgical structure
- generating projection artifacts
- generating formatted chord sheets
- supporting celebration flow

### Parish
Local organizational context responsible for:
- parish and community structure
- parishioners and ministry members
- Mass schedules and assignments
- local preferences
- local projection defaults
- agenda and coordination

This is local customization, not strict multitenancy.

---

## Workflow Guidance
Before implementing any feature:
1. identify the bounded context
2. define the business responsibility
3. choose the simplest Rails-native implementation
4. only introduce abstractions after repeated use

Prefer evolving this file as the real architecture emerges from the code.
Avoid speculative design.