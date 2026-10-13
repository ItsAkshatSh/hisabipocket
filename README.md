<div align="center">


# Hisabi Pocket

**Your budgeting companion. Making money tracking actually fun.**

Say it, snap it, see it. Log expenses by voice, scan receipts, and let an AI companion help you make sense of where your money goes.

<br />

![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-3.4+-0175C2?logo=dart&logoColor=white)
![Firebase](https://img.shields.io/badge/Firebase-Auth%20%2B%20Firestore-FFCA28?logo=firebase&logoColor=black)
![Riverpod](https://img.shields.io/badge/State-Riverpod-00B8D4)
![Platforms](https://img.shields.io/badge/Platforms-Android%20%7C%20iOS%20%7C%20Web%20%7C%20Desktop-3DDC84)
![Status](https://img.shields.io/badge/Status-In%20Development-orange)

</div>

---

## What is Hisabi?

Most budgeting apps feel like homework. Hisabi is built the other way around: it should take a few seconds to log something, and the stuff you get back should be something you actually want to look at.

*Hisabi* (حسابي) means "my account" in Arabic, and that's the idea. It's a personal money companion that lives on your phone and your home screen.

## Features

| Feature | Status |
|---|---|
| **Voice quick add**: just say what you spent and it gets logged | Done |
| **Visualized expenses**: charts and breakdowns so your spending makes sense at a glance | Done |
| **Receipt upload**: snap a receipt and let OCR do the typing | Done |
| **Hisabi AI companion**: ask questions about your spending | Done |
| **Notifications**: a notification provider for reminders and nudges | Done |
| **Home screen widgets**: functional widgets for budget progress, top categories, trends, quick actions and savings goals | In progress |
| **Built-in OCR**: on-device receipt scanning | Planned |

## Tech Stack

- **Framework:** Flutter (Dart `>=3.4.1 <4.0.0`)
- **State management:** [Riverpod](https://riverpod.dev)
- **Routing:** [go_router](https://pub.dev/packages/go_router)
- **Backend:** Firebase Auth, Cloud Firestore, Google Sign-In
- **Local storage:** Hive, shared_preferences
- **UI and motion:** Material 3, `dynamic_color` (Material You theming), `flutter_animate`, `google_fonts`, `flutter_svg`
- **Home screen widgets:** `home_widget`
- **Extras:** `image_picker` for receipts, `share_plus`, `intl`, `flutter_dotenv`

## Getting Started

### Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) (stable channel, Dart 3.4.1 or newer)
- A Firebase project with Authentication and Firestore enabled
- Android Studio or Xcode if you're targeting mobile

### Setup

```bash
# 1. Clone the repo
git clone https://github.com/ItsAkshatSh/hisabipocket.git
cd hisabipocket

# 2. Install dependencies
flutter pub get

# 3. Create your environment file (see below)
touch .env

# 4. Run it
flutter run
```


### Firebase

1. Create a project in the [Firebase console](https://console.firebase.google.com).
2. Enable **Authentication** (with Google as a provider) and **Cloud Firestore**.
3. Add your platform apps and generate the config with the FlutterFire CLI:

```bash
dart pub global activate flutterfire_cli
flutterfire configure
```

## Project Structure

```
hisabipocket/
├── lib/            # App source (providers, models, screens, widgets)
├── android/        # Android runner
├── ios/            # iOS runner
├── web/            # Web runner
├── macos/          # macOS runner
├── windows/        # Windows runner
├── linux/          # Linux runner
├── test/           # Tests
├── pubspec.yaml    # Dependencies and assets
└── TODO.md         # Widget enhancement plan
```

## Roadmap

The next big thing is home screen widgets, following Material Design 3 expressive styling:

- [ ] Budget progress widget (spending vs monthly budget)
- [ ] Top categories widget
- [ ] Expense trend widget (up/down indicators with percentages)
- [ ] Quick actions widget
- [ ] Savings goal widget with progress rings
- [ ] Settings toggles for enabling and disabling widgets
- [ ] Micro-animations and haptic feedback
- [ ] Built-in OCR for receipts

The full plan lives in [`TODO.md`](./TODO.md).

## Contributing

Found a bug or have an idea? Open an [issue](https://github.com/ItsAkshatSh/hisabipocket/issues) or send a pull request. For anything big, open an issue first so we can talk it through.

## Author

Built by [Akshat](https://github.com/ItsAkshatSh).

---

<div align="center">

If Hisabi helps you, drop a star on the repo. It genuinely helps.

</div>
