# viA ✨

A premium, hyper-gamified path drawing and live GPS tracker built natively with Flutter. **viA** re-imagines local navigation and fitness tracking with striking neon visuals, glassmorphism aesthetics, and satisfying micro-interactions.

## 🌟 Flagship Features

- **Live "Tron" Path Drawing**: Hand-draw routes directly onto the OSM mapping engine or automatically track your live path. The route renders as a 3-stage vivid gradient stroke that mimics a glowing light-trail.
- **Sonar Pulse Tracking**: Your live GPS marker isn't just a static dot. We've implemented an infinite 3D-effect sonar ring that satisfyingly pulses while your path maps dynamically.
- **Glassmorphic Stats Hub**: An ultra-frosted action bar calculates live distance (Haversine geodesic), estimated steps, burned calories, and active km/h speed. 
- **Open-Meteo Global Integration**: Features a sleek, absolutely-positioned glass bead that automatically pulls your accurate localized weather temperature & day/night status without requiring an API Key.
- **Achievement Gamification**: Over on the Profile, viA tracks total mileage and route milestones through a persistent Hive local database. Locked achievements feature a dark frosted padlock overlay, while unlocked milestones bloom with a perpetual primary glow.

## 💡 Tech Stack

- **Framework**: Flutter (Dart)
- **Map Engine**: `flutter_map` with CartoDB Dark Matter / OpenStreetMap tiles.
- **Local Database**: `hive` & `hive_flutter` for ultra-fast, offline NoSQL storage.
- **Routing & Networking**: `latlong2`, `geolocator`, `http`.
- **APIs**:
  - **Nominatim** OpenStreetMap for lightning-fast localized location searching.
  - **Open-Meteo** for seamless, free live temperature and weather state forecasting.
- **UI/UX**: `animate_do` + Glassmorphism (`BackdropFilter`) + premium custom typographies (`google_fonts`).

## 🚀 Getting Started

### Prerequisites
- Flutter SDK installed on your machine.
- iOS Simulator, Android Emulator, or a Physical Device.

### Installation & Run

1. Clone the repository:
   ```bash
   git clone https://github.com/NilakanthaPradhan/viA.git
   cd viA
   ```
2. Fetch tracking and UI dependencies:
   ```bash
   flutter pub get
   ```
3. Run the application:
   ```bash
   flutter run
   ```

## 📸 Interface Philosophy
The entire app avoids traditional rigid material banners and boxes entirely. Instead, viA utilizes massive gaussian blurs, gradient shader masks, and fluid gesture intersections (double-taps to complete paths, triple-taps to wipe the board) to create an interface that feels incredibly expensive and delightful to manipulate.

---
_Designed and engineered with an intense attention to detail and a passion for pushing UI bounds._
