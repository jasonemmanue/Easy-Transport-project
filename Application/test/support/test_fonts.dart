import 'dart:io';

import 'package:flutter/services.dart';

/// Charge les vraies polices Roboto et MaterialIcons fournies avec le SDK
/// Flutter, a la place de la police de test a glyphes carres (~2x plus
/// large). Les debordements detectes et les captures correspondent ainsi au
/// rendu d'un vrai telephone.
///
/// Retourne false si le SDK n'est pas trouve (les tests restent executables).
Future<bool> loadRealFonts() async {
  final root = Platform.environment['FLUTTER_ROOT'];
  if (root == null) return false;
  final dir = '$root/bin/cache/artifacts/material_fonts';
  if (!File('$dir/roboto-regular.ttf').existsSync()) return false;

  Future<ByteData> read(String name) async {
    final bytes = File('$dir/$name').readAsBytesSync();
    return ByteData.view(bytes.buffer);
  }

  final roboto = FontLoader('Roboto');
  for (final w in ['regular', 'medium', 'bold', 'black', 'light']) {
    roboto.addFont(read('roboto-$w.ttf'));
  }
  await roboto.load();

  final icons = FontLoader('MaterialIcons')
    ..addFont(read('materialicons-regular.otf'));
  await icons.load();
  return true;
}
