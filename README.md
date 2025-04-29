# Flutter Screen Generator 🛠️

A powerful CLI tool to help Flutter developers **automatically generate screens**, **set up Dio & SharedPreferences**, and **integrate API methods** into BLoC/Cubit architecture—all with one command!

---

## ✨ Features

- 🔄 Generates screen folders with Cubit/BLoC structure.
- ⚙️ Auto-configures `DioHelper` with a base URL via interactive prompts.
- 💾 Sets up `CachedHelper` for using `SharedPreferences`.
- 🔌 Optionally adds boilerplate API methods (GET, POST, PUT, DELETE) directly to generated Cubits.
- ✅ Checks and adds required dependencies (`dio`, `flutter_bloc`, etc.) to `pubspec.yaml`.
- 🚀 Saves development time and enforces consistency across your codebase.

---

## 📦 Installation

Add the package as a dev dependency to your Flutter project:

```bash
dart pub add flutter_screen_generator --dev



## 🚀 Usage

Run the command with `flutter_screen_generator` as the executable name

```bash
    dart run flutter_screen_generator:flutter_screen_generator <screen_name>
```

---

## 🚀 Example

```bash
dart run flutter_screen_generator:flutter_screen_generator settings
```

---


<img width="777" alt="Screenshot 2025-04-29 at 2 10 36 PM" src="https://github.com/user-attachments/assets/ffeb66ac-fb0d-43e6-bf72-e79c012499ba" />

