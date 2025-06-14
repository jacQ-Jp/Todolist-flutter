
---

<h1 align="center">📝 Todos App</h1>
<p align="center">Flutter + Laravel | Simple. Fast. Offline-ready.</p>

---

## ✨ Fitur

* 🔐 Auth (Login & Register)
* 📝 CRUD Tugas + Prioritas
* ✅ Checklist Selesai
* 📅 Date Picker & Reminder
* 📡 Sync Otomatis
* 📴 Mode Offline (Mock Data)
* 🌈 UI Responsive (Material Design)

---

## ⚙️ Quick Setup

### 🚀 Flutter

```bash
git clone https://github.com/RamaPoke/Todos.git
cd Todos/mobile
flutter pub get
flutter run
```

> 📌 Edit `AppConfig` di `main.dart`:

```dart
static const baseUrl = "http://10.0.2.2:8000/api";
```

### 🛠️ Laravel (Backend)

* Laravel + Sanctum Auth
* Endpoint:

  * `POST /login`
  * `GET/POST/PUT/DELETE /tasks`
  * `GET /user`, `/health`
* Contoh data:

```json
{
  "title": "Contoh Tugas",
  "priority": "high",
  "due_date": "2025-06-20T10:00:00Z",
  "is_done": false
}
```

---

## 📦 Dependencies

```yaml
http: ^0.13.5
shared_preferences: ^2.0.15
intl: ^0.17.0
```


> 📲 Ringan, responsif, dan tetap jalan meski offline.
> 🎯 Fokus pada produktivitas, bukan kerumitan.

---
