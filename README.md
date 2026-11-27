# Helium-3

Helium-3 is a continued, modified build of [Helium](https://github.com/AsakuraFuuko/Helium), retaining the original status-bar HUD widgets and adding Apple Shortcuts controls.

## Features

- Original Helium HUD and widget-set functionality.
- Shortcuts actions for enabling, disabling, toggling, and checking the HUD global switch.
- List and inspect widget sets.
- Enable or disable an individual widget set independently of the HUD global switch.
- Update multiple widget-set layout fields in one action; omitted values remain unchanged.

## Compatibility

- Original project baseline: iOS 14+.
- Shortcuts/App Intents actions: iOS 16+.
- On iOS 16+, enable Developer Mode as required by the original project.

## Building

Theos and Xcode are required. Run:

```sh
./ipabuild.sh
```

The resulting `.tipa` is placed in the `build` directory.

The project includes GitHub Actions workflows to build a debug IPA on pushes and a release IPA on version tags.

## Upstream and licensing

This project is based on [AsakuraFuuko/Helium](https://github.com/AsakuraFuuko/Helium). The upstream source tree and GPL-3.0 license are retained. See [LICENSE](LICENSE) for the full license text.

Helium-3 changes should be clearly identified as modifications to the upstream project.
