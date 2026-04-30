<div align="center">
  <img src="assets/logo.png" width="150" alt="Logo">
</div>

# 🎵 Music Catalog

A Flutter mobile app for browsing your music library and downloading albums directly to your [slskd](https://github.com/slskd/slskd) server via the Soulseek network.

---

## Screenshots

<div align="center">
  <img src="assets/1.jpg" width="150" alt="Screenshot 1">
  <img src="assets/2.jpg" width="150" alt="Screenshot 2">
  <img src="assets/3.jpg" width="150" alt="Screenshot 3">
  <img src="assets/4.jpg" width="150" alt="Screenshot 4">
  <img src="assets/5.jpg" width="150" alt="Screenshot 5">
</div>

---

## Features

- 🔍 **Search** any artist using the iTunes API
- 🎴 **Browse Albums & Singles** in a clean grid view with filter tabs
- 📋 **Album Details** — full tracklist with artwork
- ⬇️ **Soulseek Download** — search slskd, pick from top 10 results (FLAC → MP3 320 → MP3), tap **Get** to queue
- ⚙️ **Settings** — enter your slskd server URL, username, and password (stored securely on-device)

---

## Architecture

```
┌─────────────────────────────────────────────────────┐
│                    Flutter App                       │
│                                                     │
│  ┌──────────┐   ┌──────────────┐   ┌─────────────┐ │
│  │ HomePage │   │AlbumDetails  │   │SettingsPage │ │
│  │  (grid)  │   │  (tracklist) │   │ (URL/creds) │ │
│  └────┬─────┘   └──────┬───────┘   └──────┬──────┘ │
│       │                │                  │        │
│  ┌────▼──────────────────────────────────▼──────┐  │
│  │               Provider (State Layer)          │  │
│  │  ┌─────────────┐  ┌──────────────┐  ┌──────┐ │  │
│  │  │CatalogState │  │DownloadState │  │Setts │ │  │
│  │  └──────┬──────┘  └──────┬───────┘  │State │ │  │
│  │         │                │          └──┬───┘ │  │
│  └─────────┼────────────────┼─────────────┼─────┘  │
│            │                │             │        │
│  ┌─────────▼──────┐  ┌──────▼───────┐    │        │
│  │   iTunes API   │  │  Slskd API   │◄───┘        │
│  │  (metadata)    │  │  (download)  │             │
│  └─────────┬──────┘  └──────┬───────┘             │
└────────────┼────────────────┼─────────────────────┘
             │                │
    ┌────────▼──────┐  ┌──────▼──────────────────┐
    │  iTunes Store │  │     slskd Server         │
    │  (public API) │  │  POST /api/v0/searches   │
    └───────────────┘  │  GET  /api/v0/searches/  │
                       │       {id}/responses      │
                       │  POST /api/v0/transfers/  │
                       │       downloads/{user}    │
                       └─────────────────────────-┘
```

### Download Flow

```
User taps ⬇️
    │
    ▼
App sends search query ("Artist Album Year")
to slskd via POST /api/v0/searches
    │
    ▼
App polls GET /api/v0/searches/{id}
until state != "InProgress"
    │
    ▼
App fetches GET /api/v0/searches/{id}/responses
Parses peer file lists, groups by directory
Scores: FLAC > MP3 320kbps > MP3 > other
    │
    ▼
Shows top 10 results in a scrollable list
User taps "Get" on preferred result
    │
    ▼
App sends POST /api/v0/transfers/downloads/{username}
Body: [{filename, size}, ...] (QueueDownloadRequest)
    │
    ▼
slskd queues & downloads the files 🎉
```

---

## Prerequisites

| Requirement | Notes |
|---|---|
| Flutter ≥ 3.x | [Install Flutter](https://flutter.dev/docs/get-started/install) |
| Android device or emulator | Tested on Android; iOS should also work |
| [slskd](https://github.com/slskd/slskd) instance | Self-hosted Soulseek daemon |

---

## Getting Started

```bash
# Clone
git clone https://github.com/YOUR_USERNAME/music-catalog.git
cd music-catalog

# Install dependencies
flutter pub get

# Run on connected device
flutter run
```

On first launch, tap the **⚙️ Settings** icon and enter:
- **Server URL** — e.g. `http://192.168.1.x:5030`
- **Username** — your slskd username
- **Password** — your slskd password

Credentials are saved locally on the device using `SharedPreferences` and are **never sent anywhere except your own slskd server**.

---

## Project Structure

```
lib/
├── main.dart                 # App entry point & providers
├── api/
│   ├── itunes_api.dart       # iTunes Search API client
│   └── slskd_api.dart        # slskd REST API client
├── models/
│   ├── album.dart            # Album data model
│   └── track.dart            # Track data model
├── state/
│   ├── catalog_state.dart    # Album search & tracklist state
│   ├── download_state.dart   # Soulseek search & download state
│   └── settings_state.dart   # Persisted slskd credentials
└── ui/
    ├── home_page.dart         # Search bar + album grid
    ├── album_details_page.dart # Tracklist + download dialog
    └── settings_page.dart     # slskd configuration
```

---

## Dependencies

| Package | Purpose |
|---|---|
| `provider` | State management |
| `http` | HTTP requests (iTunes + slskd APIs) |
| `shared_preferences` | Persist slskd credentials on-device |

---

## Security Notes

- **No credentials are hardcoded** in this repository
- All slskd credentials are stored **locally on your device** only
- The app communicates only with the public iTunes Search API and your own self-hosted slskd instance
- For production use, consider running slskd behind a reverse proxy with HTTPS

---

## License

MIT
