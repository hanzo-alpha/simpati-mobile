# 📱 SIMPATI Mobile - Aplikasi Presensi ASN Kabupaten Soppeng

[![Flutter CI](https://github.com/hanzo-alpha/simpati-mobile/actions/workflows/flutter_ci.yml/badge.svg)](https://github.com/hanzo-alpha/simpati-mobile/actions/workflows/flutter_ci.yml)
[![Flutter Version](https://img.shields.io/badge/Flutter-%5E3.11.0-02569B?style=flat&logo=flutter)](https://flutter.dev)
[![Platform](https://img.shields.io/badge/Platform-Android%20%7C%20iOS-green?style=flat&logo=android)](https://flutter.dev)
[![Web Repo](https://img.shields.io/badge/Laravel_Backend-simpati-FF2D20?style=flat&logo=laravel)](https://github.com/hanzo-alpha/simpati)

**SIMPATI Mobile** adalah aplikasi Android & iOS resmi untuk Aparatur Sipil Negara (ASN) Pemerintah Daerah Kabupaten Soppeng untuk melakukan presensi kehadiran digital berbasis **Geofencing GPS**, **Verifikasi Biometrik Selfie Kamera Depan**, **Single Device Binding (Penguncian Perangkat)**, dan **Deteksi Anti-Fake GPS**.

---

## 🌟 Fitur Utama Aplikasi Mobile

- 📍 **Presensi Geofencing GPS Radius 200m**: Validasi koordinat GPS realtime terhadap titik polygon lokasi kantor OPD Soppeng.
- 🛡️ **Anti-Fake GPS Protection**: Pendeteksian otomatis aplikasi lokasi palsu (Mock Location / Spoofer).
- 📷 **Kamera Biometrik Live**: Verifikasi foto kehadiran selfie kamera depan langsung dari aplikasi.
- 📱 **Single Device Binding Hardware Lock**: Penguncian NIP pegawai pada 1 Hardware ID (IMEI) smartphone resmi.
- 📊 **Monitoring Kinerja & TPP**: Ringkasan persentase kehadiran bulanan & estimasi akumulasi potongan TPP.
- 📢 **Broadcast Edaran Kepegawaian**: Penerimaan pengumuman resmi instansi via Push Notification & In-App Notice.

---

## 🛠️ Stack & Paket Dependensi

- **Framework**: Flutter SDK (`^3.11.0`)
- **HTTP REST API Client**: `dio` (`^5.7.0`)
- **Location Services**: `geolocator` (`^13.0.2`), `geocoding` (`^3.0.0`)
- **Maps Rendering**: `flutter_map` (`^8.2.2`), `latlong2` (`^0.9.1`)
- **Kamera Selfie**: `camera` (`^0.11.1`), `image_picker` (`^1.1.2`)
- **Keamanan Penyimpanan**: `flutter_secure_storage` (`^9.2.4`)
- **State Management**: `provider` (`^6.1.2`)

---

## 🚀 Panduan Memulai Development

### Prasyarat:
- Flutter SDK >= 3.22.x
- Dart SDK >= 3.4.x
- Android Studio / VS Code dengan plugin Flutter & Dart
- Android SDK (API Level 34 / Android 14)

### Langkah Jalankan Aplikasi:

1. **Clone Repositori**:
   ```bash
   git clone https://github.com/hanzo-alpha/simpati-mobile.git
   cd simpati-mobile
   ```

2. **Dapatkan Dependensi Flutter**:
   ```bash
   flutter pub get
   ```

3. **Jalankan Aplikasi pada Perangkat/Emulator**:
   ```bash
   flutter run
   ```

4. **Build APK Android Release**:
   ```bash
   flutter build apk --release
   ```

---

## 📄 Repositori Web Backend

Aplikasi mobile ini terhubung dengan backend REST API Laravel 13:
👉 **[hanzo-alpha/simpati](https://github.com/hanzo-alpha/simpati)**

---

## 📄 Lisensi & Hak Cipta

&copy; {{ new Date().getFullYear() }} Pemerintah Kabupaten Soppeng. Seluruh Hak Cipta Dilindungi.
