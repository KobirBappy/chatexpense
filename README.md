# ChatExpense — AI-Powered Personal Finance Manager

A cross-platform Flutter application that lets you track income and expenses using voice, images (receipt scanning), or manual entry — powered by Google Gemini AI.

---

## Features

### Transaction Entry
- **Manual** — Form-based entry with category selection
- **Voice** — Speak your transaction; AI extracts the details
- **Receipt Scanning** — Photograph a receipt; AI parses it into structured data
- **AI Chat** — Natural language financial input processed by Gemini

### AI Capabilities
- Google Gemini integration for receipt OCR, voice command processing, and financial insight generation
- Smart category suggestion with fallback pattern matching
- Spending trend analysis (increasing / decreasing / stable)

### Analytics Dashboard
- Income vs. expense summary with charts (fl_chart + Syncfusion)
- Category-wise spending breakdown
- Savings rate calculation
- AI-generated financial recommendations
- Configurable date range filtering (default: last 30 days)

### Authentication & Accounts
- Firebase email/password authentication
- Persistent sessions with remember-me support
- User profile management

### Subscription Tiers
| Feature | Free | Pro | PowerUser |
|---|---|---|---|
| Chat messages | 60 | Unlimited | Unlimited |
| Image entries | 10 | Unlimited | Unlimited |
| Voice entries | 10 | Unlimited | Unlimited |
| AI queries | 10 | Unlimited | Unlimited |
| Custom categories | 3 | Unlimited | Unlimited |

### Other
- Daily reminder notifications (configurable time)
- Budget alerts and transaction notifications
- Excel export and share functionality
- Light / dark theme support
- Windows MSIX packaging ready

---

## Tech Stack

| Layer | Technology |
|---|---|
| Framework | Flutter ^3.4.3 / Dart ^3.4.3 |
| State management | Provider |
| Backend | Firebase (Auth, Firestore, Cloud Storage) |
| AI | Google Gemini (gemini-2.5-flash / pro) |
| Charts | fl_chart, Syncfusion Flutter Charts |
| Voice | speech_to_text |
| Notifications | flutter_local_notifications, workmanager |
| Environment | flutter_dotenv |

---

## Supported Platforms

- Android
- iOS
- Web
- Windows (MSIX)
- macOS
- Linux

---

## Project Structure

```
lib/
├── main.dart                           # App entry, Provider setup
├── home_screen.dart                    # Main navigation (3 tabs)
├── firebase_options.dart               # Firebase configuration
│
├── # Services
├── firebase_service.dart               # Auth, Firestore, Storage
├── gemini_service.dart                 # Google Gemini AI
├── image_processing_service.dart       # Image picking & processing
├── voice_service.dart                  # Speech-to-text
├── notification_service.dart           # Local notifications & reminders
│
├── # Screens
├── login_screen.dart
├── register_screen.dart
├── onboarding_screen.dart
├── transaction_screen_corrected.dart   # Add / view transactions
├── dashboard_screen_corrected.dart     # Analytics & insights
├── account_screen_corrected.dart       # Profile & settings
│
├── # Models
├── user_model.dart
├── transaction_model.dart              # Types: income, expense, loanGiven, loanReceived
├── subscription_model.dart
│
├── # Providers
├── user_provider.dart
├── transaction_provider.dart
├── subscription_provider.dart
│
└── voiceprocessingdialog.dart          # Voice input UI
```

---

## Getting Started

### Prerequisites

- Flutter SDK >= 3.4.3
- A Firebase project with Auth, Firestore, and Cloud Storage enabled
- A Google Gemini API key

### 1. Clone the repository

```bash
git clone <repo-url>
cd chatapp
```

### 2. Configure environment variables

Create a `.env` file in the project root:

```env
GEMINI_API_KEY=your_gemini_api_key_here
```

### 3. Configure Firebase

Replace `lib/firebase_options.dart` with your own Firebase project configuration, or run:

```bash
flutterfire configure
```

### 4. Install dependencies

```bash
flutter pub get
```

### 5. Run the app

```bash
flutter run
```

---

## Required Permissions

| Permission | Purpose |
|---|---|
| Microphone | Voice transaction entry |
| Camera | Receipt photo capture |
| Storage / Files | Image and file picker |
| Notifications | Daily reminders and budget alerts |

---

## Transaction Types

- `income` — Money received
- `expense` — Money spent
- `loanGiven` — Money lent to someone
- `loanReceived` — Money borrowed

## Default Categories

Food, Transport, Shopping, Bills, Entertainment, Salary, Healthcare, Education, Other

---

## Environment Variables

| Variable | Description |
|---|---|
| `GEMINI_API_KEY` | Google Gemini API key for AI features |

> Never commit `.env` to version control.

---

## License

This project is proprietary. All rights reserved.
