# bcp_app

Applicazione mobile Flutter per sistema di telemetria MTB con ESP32-C6.

## Requisiti

- Flutter SDK >=3.5.0
- Android SDK (minSdk 21)
- Dispositivo ESP32-C6 con firmware BLE

## Setup

1. Clona il repository
2. Installa le dipendenze: `flutter pub get`

text
3. Configura gli UUID BLE in `lib/services/ble_service.dart`
4. Esegui l'app: `flutter run`

text

## Funzionalità

- Connessione BLE con ESP32-C6
- Gestione file su SD Card
- Configurazione hardware (1-4 sensori)
- Configurazione bici (tipo, ruote, sospensioni)
- Preview dati real-time (Accel/Gyro)
- Upload dati a server Flask
