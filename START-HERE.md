# Standalone Stremio Personal for iPhone and iPad

This is a personal build foundation based on GPL-3.0 StremioX, not the official
Stremio iOS source. Upstream: https://github.com/yvdjee/stremiox
Upstream snapshot: `341c87520f8c011b6a995557a1008bb6e123314b`.

## What is already implemented upstream

- Embedded NodeMobile torrent streaming server: the phone fetches peers and
  feeds the integrated libmpv player over `http://127.0.0.1:11470`.
- Stremio account sign-in, installed addon synchronization, catalog browsing,
  metadata, stream sources, and subtitle addons through the real stremio-core.
- Library type/sort filters; Discover type/catalog/genre filters; watched state
  and Continue Watching. Category availability depends on addon manifests.
- Native SwiftUI iPhone/iPad interface and an integrated player.

The UI is StremioX's interface. It does not reproduce the official app exactly.
Addon protocol support does not guarantee every third-party addon works.
The installed addon screen currently removes addons; install/configure them
through Stremio Web and sign in here to sync them. A full in-app addon directory
and install/configure flow is still a follow-up task.

## Changes in this starter

- `app/project-ios.yml`: one personal iOS target, separate bundle identifier
  `com.hegezolee.stremiopersonal`, retaining all native torrent dependencies.
- `scripts/build-personal-ios.sh`: prepares only iOS device and Apple Silicon
  simulator core slices; avoids the upstream tvOS/macOS build requirements.
- `.github/workflows/personal-ios.yml`: manually run an unsigned iOS build and
  download its IPA/checksum as an Actions artifact, without publishing a release.

App playback, account sync, and UI code are inherited unchanged. libmpv is
already integrated; replacing it with VLC is not part of this initial setup.

## Build on your Mac

Install full Xcode, open it once, and complete its requested component setup.
Use an Apple Silicon Mac. Install Homebrew and Rust via their official installers
if absent. Then run:

```bash
brew install xcodegen
rustup toolchain install nightly --profile minimal
chmod +x scripts/build-personal-ios.sh
./scripts/build-personal-ios.sh prepare
open app/StremioPersonal.xcodeproj
```

In Xcode, select the **StremioPersonal** scheme. Under Signing & Capabilities,
choose your Apple team, enable automatic signing, and change the bundle ID if
your team cannot register the default. Connect your iPhone, enable Developer
Mode if prompted, choose the phone as the destination, and press Run.

For a re-signable unsigned package:

```bash
./scripts/build-personal-ios.sh ipa
```

The result is `build/personal-ios/StremioPersonal-unsigned.ipa`. It must be
signed before installation. No Apple credentials belong in this repository.

## GitHub setup

Personal fork: https://github.com/hegezolee/stremiox
The personal build files are maintained on `personal/standalone-ios`.
Open START-HERE.md from that branch when following these instructions.

The workflow runs for pull requests that change the iOS build inputs. After
merging it to the default branch, you can also use Actions → Personal iPhone
and iPad build → Run workflow. Download the artifact when it succeeds.
A workflow definition alone is not proof of a successful native build.

## First device checks

1. Sign in to Stremio; compare installed addons, saved titles, and library
   categories against your existing Stremio app.
2. In Settings, turn Direct Links Only off and use the embedded server rather
   than a remote server. Confirm it is reachable.
3. Play a legal, well-seeded sample through a magnet or addon torrent source.
   No Pi, debrid service, or external player should be required.
4. Seek forward/backward; test pause/resume, subtitles, audio tracks, a long
   playback session, and return from the background.
5. Relaunch and verify saved positions, watched state, and addon persistence.
6. Test a weak swarm and a network interruption for useful buffering/errors.

## Known limits and dependencies

- iOS can suspend the app in the background. Standalone playback does not mean
  unrestricted background torrent downloading.
- Tracker and peer discovery reliability must be tested on your actual phone
  and network; upstream uses HTTP/HTTPS trackers to improve peer discovery.
- The torrent engine depends on Stremio's proprietary `server.js`, fetched at
  build time. The app source is GPL-3.0; the server retains its own terms.
  Its availability and redistribution rights require separate consideration
  before public distribution. Nothing here replaces it with libtorrent.
- Vendor downloads are checksum-verified by the upstream fetch script for its
  default versions. Downloads need GitHub release assets and Stremio's CDN.
- Upstream uses moving Rust nightly and stremio-core development dependencies.
  After a successful Mac build, capture a tested nightly date and Cargo.lock
  before treating repeatable builds as established.
- No native compilation or device playback was possible in this Linux session.

## Next development milestone

First establish a successful device build and legal sample playback. Then add
an in-app addon manifest preview/install flow and directory, check category
parity with your actual addons, and align the UI with the official Stremio
layout. Preserve upstream LICENSE and THIRD-PARTY-NOTICES.md.
