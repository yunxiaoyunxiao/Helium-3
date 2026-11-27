# Helium-3 Development Status

Helium-3 is a personal continuation of the upstream Helium project.

## Project rules

- Keep the upstream Helium project intact; all changes belong in this repository.
- Preserve the upstream license and copyright notices when importing source files.
- Retain the original HUD and widget-set functionality.
- Add Shortcuts controls for the HUD global switch and individual widget sets.
- Keep the HUD global switch independent from each widget set's enabled state.
- Do not add image-floating functionality; that belongs to a separate project.

## Implementation plan

1. Import and verify the complete upstream source tree and license.
2. Inspect the Theos build scripts, deployment target, bridging layer, and app lifecycle.
3. Implement Shortcuts actions using APIs compatible with the actual build environment.
4. Verify configuration persistence, HUD reload notifications, and independent enable states.
5. Build and test the IPA; report only verified build results.

## Status

Repository write-access check and project initialization.
