# Wallet Demo

Reference app showing how Mosaic redesigns a normal deep wallet app
into a state-first surface. Built on `packages/mosaic_ui`.

## Surface

A single home surface, no nested pages:

```text
┌──────── Balance (wide) ────────┐
│ Send (m) │ Pay  (m)            │
│  Recent transactions (wide)    │
│ Cards(m) │ Insight (m)         │
└────────────────────────────────┘
```

Live data drives the balance and transactions: a fake `WalletData`
object posts a new transaction every five seconds via
`ValueNotifier`, which `MosaicLiveSource.fromListenable` turns into
the `DataState` timeline the tiles consume.

The header has a `metro ↔ modern` toggle to switch token sets at
runtime.

## Run

```bash
cd examples/wallet_demo
flutter pub get
flutter run -d chrome      # web
flutter run -d windows     # native windows
```
