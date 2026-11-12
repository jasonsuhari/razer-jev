# razer-jev

Colours a Razer Cobra mouse by what the pointer is resting on, judged by [Jev](https://docs.typesafe.ai).

1. The app screenshots what's under your pointer.
2. Jev looks at it and picks an answer (cat, dog or neither; right answer, wrong answer or neither).
3. The app colours the mouse to match.

No Razer software is involved. The app sends the mouse's USB commands directly, as worked out by [OpenRazer](https://github.com/openrazer/openrazer).

## Build and run

Needs macOS 14 or later and the Xcode command line tools.

```sh
./build.sh                                   # builds ~/Applications/Razer Jev.app
security add-generic-password -s razer-jev -a typesafe-api-key \
  -T ~/Applications/Razer\ Jev.app -w        # paste your TypeSafe API key when asked
open ~/Applications/Razer\ Jev.app
```

The app reads the key from `TYPESAFE_API_KEY` first, then from that Keychain item.

macOS asks for two permissions under System Settings > Privacy & Security: **Input Monitoring** (to talk to the mouse) and **Screen & System Audio Recording** (to see the screen). The first build makes a local signing certificate in `signing/`, so macOS keeps those permissions when you rebuild.

## Layout

| Folder | What it does |
|---|---|
| `Sources/RazerJev/Modes/` | One file per mode: what to look at, the question for Jev, and a colour per answer |
| `Sources/RazerJev/Watch/` | The mode type, and the loop that waits for the pointer to settle, asks Jev and sets the light |
| `Sources/RazerJev/Screen/` | Screenshots around the pointer or of the window under it, with a ring marking the pointer |
| `Sources/RazerJev/Jev/` | The TypeSafe API call and the API key lookup |
| `Sources/RazerJev/Light/` | The `Light` interface and the Razer Cobra driver |
| `Sources/RazerJev/App/` | The window and the command line |

## Add a mode

Add a file to `Sources/RazerJev/Modes/`:

```swift
extension WatchMode {
    static let spoilers = WatchMode(
        id: "spoilers",
        title: "Spoiler → red",
        scope: .aroundPointer(points: 400),
        question: "`screen` is part of a computer screen. The mouse pointer is at the centre of the magenta ring. Does the text under the pointer give away the ending of a film, show or book?",
        answers: [
            Answer(id: "spoiler", meaning: "It reveals a plot twist or ending.", light: .red),
            Answer(id: "safe", meaning: "It reveals nothing important.", light: .off),
        ])
}
```

Then list it in `Modes/AllModes.swift`. It appears in the window's menu and on the command line.

## Test a mode on a screenshot

```sh
RazerJev --judge quiz screenshot.png 1420 890 --save-marked marked.png
```

`x` and `y` are pixels in the screenshot. `try-it/` has pages to open, hover over or screenshot.

## Command line

```
RazerJev                                     open the window
RazerJev --set red|green|off
RazerJev --judge <mode> <screenshot> <x> <y> [--pixels-per-point 2] [--save-marked out.png]
```

The binary is at `~/Applications/Razer Jev.app/Contents/MacOS/RazerJev`.
