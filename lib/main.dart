import 'package:flutter/widgets.dart';
import 'package:mosaic_ui/mosaic_ui.dart';

import 'src/wallet_data.dart';
import 'src/wallet_home.dart';

void main() {
  final data = WalletData()..start();
  runApp(
    MosaicApp(
      title: 'Mosaic Wallet',
      builder: (context) => WalletHome(data: data),
    ),
  );
}
