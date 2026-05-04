import 'package:flutter/widgets.dart';
import 'package:mosaic_ui/mosaic_ui.dart';

import 'src/wallet_data.dart';
import 'src/wallet_home.dart';
import 'src/walkthrough_gate.dart';

void main() {
  final data = WalletData()..start();
  runApp(
    MosaicApp(
      title: 'Mosaic Wallet',
      builder: (context) => WalkthroughGate(
        prefsKey: 'wallet_demo.walkthrough.seen',
        steps: const [
          MosaicWalkthroughStep(
            title: 'Welcome to Mosaic Wallet',
            body:
                'A reference app for the Mosaic design system. '
                'Tiles, surfaces, and shallow journeys.',
            glyph: '◫',
          ),
          MosaicWalkthroughStep(
            title: 'Send and Pay',
            body:
                'Tap a tile on the Overview to slide a panel up — '
                'no full-screen routes, no nested back stacks.',
            glyph: '↗',
          ),
          MosaicWalkthroughStep(
            title: 'Activity and Cards',
            body:
                'Browse transactions, freeze cards, and inspect '
                'each in a stacked surface.',
            glyph: '◧',
          ),
          MosaicWalkthroughStep(
            title: 'Tune your style',
            body:
                'Use the command bar at the bottom to switch '
                'Metro / Modern modes and Dark / Light themes.',
            glyph: '◐',
          ),
        ],
        child: WalletHome(data: data),
      ),
    ),
  );
}
