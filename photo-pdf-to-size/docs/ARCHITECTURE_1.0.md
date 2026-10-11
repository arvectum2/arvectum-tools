# Photo & PDF Size: iOS 1.0 modular architecture

## Goals

Keep a compact local-first file tool whose components can be changed and tested independently. Runtime feature set must match current 0.6.x behavior (photo and PDF by maximum bytes, pixel resize, document photo presets, before/after, file exporter, sharing, advertising consent). The 1.0 refactor separates responsibilities; it is not a redesign.

## Code map

```text
PhotoPodRazmerApp
   ├── AppModel (@MainActor, observable state)
   │   ├── Model/AppModel+Navigation       mode/input selection
   │   ├── Model/AppModel+Import           PhotosUI + Files + security-scoped read
   │   ├── Model/AppModel+Settings         target bytes/dimensions/options
   │   ├── Model/AppModel+Processing       image & PDF orchestration
   │   ├── Model/AppModel+Lifecycle        reset/save result
   │   ├── Model/AppModel+Internals        completion token, shared helpers
   │   └── Model/InputConstraints         pure numeric validation
   ├── ImageEngine.swift                   local photo processing
   ├── PDFEngine.swift                     local PDF processing
   ├── Models.swift                        immutable photo/PDF contracts
   ├── ContentView.swift                   navigation, overlays and save/share
   │   ├── Views/PhotoTaskCard             file size, pixels, document presets
   │   ├── Views/PDFTaskCard               PDF input/target
   │   ├── Views/ResultViews               previews, results
   │   ├── Views/SharedControls            header, selector, chips
   │   ├── Views/FileExport                FileDocument + system ShareSheet
   │   └── Views/ArvectumColors            dark/light adaptive palette
   └── Advertising/
       ├── AdService                       Yandex SDK bootstrap, consent, loading
       ├── AdConsentView                   GDPR/ATT consent UI
       ├── AdPlacements                    main/result slot boundaries
       ├── AdBannerView                    adaptive result banner
       └── AdNativeView                    main native ad rendering
```

The `Views` layer observes `AppModel`. It does not modify JPEG/PDF bytes. `AppModel` performs main-actor state changes only and delegates heavy file processing to detached operations. `ImageEngine` and `PDFEngine` remain independent of SwiftUI views. Numeric parsing is pure in `InputConstraints`.

## Async invariants

- Each new input selection or processing operation receives a unique completion token.
- Switching modes/input type, resetting, or returning home invalidates previous tokens and clears working UI.
- A result/failure from an older task is ignored, even if the detached operation finishes later.
- Selected options (output format, EXIF stripping, document preset) are captured before leaving the main actor.
- File imports hold security-scoped access only while reading file data.
- The app **never** deletes user originals; exports are explicit.
- Expensive transformations remain on-device. Ad loading may use the network. Strong PDF compression can rasterize pages.

## Debug/QA fixtures

`Model/QAFixtures.swift` exists only under `#if DEBUG`. The test suite can launch with `--qa-photo-fixture`, `--qa-pdf-fixture`, or `--qa-pdf-result` to verify actual workflows without relying on a mutable Files Recents list. Fixtures contain synthetic images and a synthetic 3-page PDF. Production builds cannot compile or enter the QA fixture logic.

## QA layers

1. **Unit:** `ImageEngineTests`, `PDFEngineTests`, `AppModelTests` — bytes, formats, EXIF, orientation, dimension checks, async invalidation, reset and local import.
2. **Simulator UI:** `WorkflowUITests` — photo/PDF flow, modes, save exporter, Files sheet; `LayoutRegressionUITests` — RU/EN, light/dark, no home ad clipping.
3. **Physical device:** original `FilesImportUITests` — only when a real sample file is present in Files Recents. The tests explicitly skip on simulator rather than reporting false failures.
4. **Release:** device save/share smoke, SDK privacy disclosures, ad consent, App Store screenshots, country metadata before submission.

## Next modularization (after 1.0)

Only if test data reveals a need: inject engine protocols for fault-injection tests; extract document preset catalog into a versioned package; add low-memory PDF cancellation. Avoid gratuitous network dependencies, class hierarchies and over-generalized abstractions.
