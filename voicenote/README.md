# 🎙️ Project Report: Voice Notes App with Speech-to-Text

## 📄 Executive Summary
The **Voice Notes App** is a high-performance Flutter application designed to bridge the gap between spoken thought and digital organization. The primary objective was to create a seamless, hands-free experience for users to capture notes, manage them efficiently with local persistence, and provide a premium user interface that supports both light and dark aesthetics.

---

## 📑 1. Documentation of Features

### 🎙️ 1.1 Advanced Speech-to-Text Integration
The core engine of the app utilizes real-time speech recognition. 
- **Real-time Processing**: Words appear on the screen as the user speaks, providing immediate visual feedback.
- **Duplication Logic**: Implemented a custom synchronization buffer to ensure that as the speech engine updates partial results, the existing note content is not duplicated or overwritten incorrectly.
- **Hands-Free Capability**: Designed with a "Press to Start/Stop" mic system that allows users to dictate long-form notes without holding down a physical key.

### 💾 1.2 Local Persistence with Hive
For data reliability, the app uses **Hive**, a lightweight and blazing-fast NoSQL database.
- **Offline First**: All notes are stored locally on the device, ensuring the app works perfectly without an internet connection (once the speech engine is initialized).
- **CRUD Operations**: Users can Create, Read, Update, and Delete notes. Changes are synced to the local disk in milliseconds.
- **Data Integrity**: Notes are stored with structured models including titles, content, and ISO-8601 timestamps.

### 🔍 1.3 Smart Organization & Search
As the number of notes grows, findability becomes crucial.
- **Live Search**: A real-time filter implemented in the Provider layer that narrows down the note list as the user types in the search bar.
- **Chronological Sorting**: Notes are automatically sorted by the most recent timestamp so that the latest thoughts are always at the top.

### 🎨 1.4 Premium UI/UX Design
- **Material 3 Standards**: Built using the latest Material Design 3 guidelines for a modern look.
- **Sliver Animations**: The Home Screen features a collapsing app bar that provides a professional "app-like" feel during scrolling.
- **Dual Theme Support**: Full support for Dark Mode, which reduces eye strain in low-light environments. The theme state is persisted across app restarts.

---

## 📦 2. Technical Stack & Dependencies

The application is built using the following industry-standard packages:

| Package | Purpose | Why it was chosen? |
| :--- | :--- | :--- |
| **`speech_to_text`** | Voice Recognition | Provides the most stable interface for native iOS and Android speech engines. |
| **`hive_flutter`** | Database | Significantly faster than SQLite and SharedPreferences for object storage. |
| **`provider`** | State Management | Recommended by the Flutter team for its simplicity and clean separation of concerns. |
| **`intl`** | Localization/Formatting | Essential for handling human-readable date and time formatting. |
| **`cupertino_icons`** | Icons | Provides high-quality system icons for a native feel. |

---

## 🛠 3. Implementation Details

### 🏗 Architecture (Provider Pattern)
The app follows a **Model-View-Provider** architecture:
- **Model**: Defines the `Note` object.
- **View**: Responsive UI screens (`HomeScreen`, `EditNoteScreen`).
- **Provider**: Acts as the "Brain". It manages the Hive box, handles the search logic, and notifies the UI when data changes.

### 🚀 Speech-to-Text Solution
A significant challenge addressed was the "duplication" of text during real-time listening. The solution involved:
1. Capturing the "Base Text" before recording starts.
2. Dynamically merging the "Recognized Words" with the base text.
3. Managing the cursor (TextSelection) to ensure it stays at the end of the text field during live updates.

---

## 📸 4. App Gallery

| Home Screen (Light) | Voice Editor | Dark Mode |
| :---: | :---: | :---: |
| ![Home](https://via.placeholder.com/200x400?text=Home+Screen) | ![Edit](https://via.placeholder.com/200x400?text=Voice+Editor) | ![Dark](https://via.placeholder.com/200x400?text=Dark+Mode) |

---

## 🚀 5. Getting Started

### Prerequisites
- Flutter SDK (v3.0.0+)
- Physical device (Mic does not work on most emulators)

### Installation
1. `flutter pub get`
2. Ensure permissions are granted in `AndroidManifest.xml` and `Info.plist`.
3. `flutter run`

---

## 📈 6. Future Roadmap
- [ ] Category-based folders for notes.
- [ ] Voice-to-Audio (saving the actual audio file alongside text).
- [ ] Export to PDF/Text functionality.
- [ ] Cloud Sync (Firebase/Supabase).

