# cloudamned

**Cloud Engineering Flight Simulator** — not a quiz app. A desktop career simulator for Cloud Technical Engineers (IaaS).

> Product name is always **cloudamned** (not CloudForge Academy or other aliases).

You join a consulting company, gather requirements from customers, make tradeoff-driven architecture decisions, deploy offline-simulated infrastructure, survive failures, run forensics, and get promoted. Everything is local. No cloud accounts. No API keys.

## Platforms

- Windows
- macOS
- Linux

## Stack

| Layer | Choice |
|--------|--------|
| UI | Flutter Stable Desktop, shadcn-inspired design system |
| State | BLoC / Cubit |
| Routing | go_router |
| Storage | Hive (progress) + SQLite (attempts/logs) |
| Charts | fl_chart |
| Fonts | google_fonts (Inter + JetBrains Mono) |
| Window | window_manager |
| Terminal UX | Custom shell + monospaced terminal panels |

## Features

### Career core (v2)
- **Career Simulation** — customer projects (ABC Manufacturing Sdn Bhd, bank, hospital, retail, university, government), **20-step** consulting lifecycle with validation
- **Daily Engineer Mode** — stand-up → tickets → Terraform → meetings → deploy → incident → docs
- **Ticket Management** — INC queue, SLA, customer updates, RCA, postmortem
- **Landing Zone Builder** — Organizations → KMS; Well-Architected pillar scores
- **Migration Lab** — discovery through post-migration review
- **Architecture Review / Cost Lab / Security Audit / Documentation / Meetings & Comms**
- **Skill Analytics** — 100+ skills + interview readiness report

### Simulators
- **AWS Console clone**, **Linux VM**, **Terraform**, **Incident Lab**, **Interview design mode**
- Docker, Kubernetes, networking, CI/CD, monitoring, Windows Server
- 20 learning modules · 120+ labs · exams · XP/badges

## Run

```bash
cd C:\IdeaProjects\cloudamned
flutter pub get
flutter run -d windows
```

macOS / Linux:

```bash
flutter run -d macos
flutter run -d linux
```

## Tests

```bash
flutter test
```

## Architecture

```
lib/
  core/           # theme, router, DI, widgets (shadcn system)
  domain/         # entities
  data/content/   # roadmap + question bank
  features/       # feature-first UI + cubits
  simulation/     # offline engines (linux, aws, docker, k8s, terraform, network)
```

Clean Architecture boundaries:

- **Presentation** — feature pages + BLoC
- **Domain** — entities (Lab, Progress, Question)
- **Data** — content catalogs, Hive/SQLite
- **Simulation** — pure Dart engines with realistic outputs

## Design

Dark IDE aesthetic inspired by VS Code, Azure Portal, AWS Console, JetBrains.

- No gradients
- No flashy animation chrome
- Resizable multi-pane layouts
- Keyboard shortcuts: `Ctrl+1..5`, `Ctrl+T` terminal, `Ctrl+[` sidebar

## License

Private / training use unless otherwise specified.
