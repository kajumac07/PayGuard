# PayGuard 🛡️

PayGuard is an iOS app that helps users track subscriptions and auto-debits so they don’t lose money on forgotten renewals.

This is an **early access version** focused on real-world usage, feedback, and stability before monetization.

---

## ✨ Features

- 📌 **Manual Subscription Tracking**
  - Add subscriptions with amount, billing cycle, and renewal date
  - Edit or delete anytime

- 🔔 **Smart Renewal Reminders**
  - Get notified 2–3 days before a subscription renews
  - Never miss a cancellation window

- 📅 **Calendar Sync (Optional)**
  - Add renewal dates directly to Apple Calendar
  - Custom reminder days before renewal

- 📧 **Gmail Sync (Optional)**
  - Connect Gmail using read-only access
  - Scan subscription-related emails
  - User reviews and confirms before saving anything

- 🔒 **Privacy First**
  - No mandatory login
  - Data stored locally on the device
  - Gmail access is optional and read-only
  - App works fully without Gmail or Calendar access

---

## 🚀 Early Access Mode

PayGuard is currently in **early access**.

During early access:
- All core features are available
- Limits and pricing may change in the future
- Feedback is highly appreciated

Early access helps improve:
- Email parsing accuracy
- Reminder reliability
- Overall user experience

---

## 🛠 Tech Stack

- **SwiftUI** – UI framework
- **Swift Concurrency (async/await)**
- **EventKit** – Calendar integration
- **Google Sign-In** – Gmail OAuth
- **Gmail API (read-only)** – Email scanning
- **UserNotifications** – Alerts & reminders
- **Local Storage** – UserDefaults / local persistence

_No backend or account system in early access._

---

## 🔐 Permissions Used

| Permission | Reason |
|----------|-------|
| Notifications | To alert users before renewals |
| Calendar (Optional) | To add subscription reminders |
| Gmail (Optional) | To detect subscription emails |

Permissions are requested **only when needed**, never on app launch.

---

## 📲 Installation & Testing

### Requirements
- Xcode 15+
- iOS 17+
- Apple Developer Account (for device testing)

### Run Locally
1. Clone the repository
2. Open `PayGuard.xcodeproj`
3. Select a real device or simulator
4. Build & Run

---

## 🧪 Testing Notes

- Gmail scanning is user-initiated
- Emails are scanned in batches (not background)
- Manual email entry is available for testing parsers
- Calendar sync can be toggled per subscription

---

## 🗺 Roadmap

Planned improvements:
- Resume Gmail scanning
- Better email parsing & deduplication
- Subscription analytics
- Optional cloud sync
- Paid plans after early access

---

## 🤝 Feedback

Feedback from early users is extremely valuable.

If you find bugs or have suggestions:
- Open an issue
- Or share feedback directly through the app

---

## 🙌 Author

Built with ❤️ as a privacy-first utility app to help people save money by staying in control of subscriptions.
