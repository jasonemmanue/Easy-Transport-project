/// Lieux de Douala -> coordonnees, en attendant l'autocompletion Google Places
/// (Phase MVP). Toute adresse inconnue recoit une position stable proche du
/// centre (Akwa), derivee du texte : le devis reste coherent d'un appel a l'autre.
class Place {
  const Place(this.label, this.lat, this.lng);
  final String label;
  final double lat;
  final double lng;

  Map<String, dynamic> toJson() => {'label': label, 'lat': lat, 'lng': lng};
}

const _known = <String, (double, double)>{
  'akwa': (4.0511, 9.7043),
  'bonanjo': (4.0435, 9.6890),
  'bonapriso': (4.0330, 9.6920),
  'deido': (4.0660, 9.7090),
  'bali': (4.0440, 9.7020),
  'bonaberi': (4.0720, 9.6600),
  'bonamoussadi': (4.0900, 9.7400),
  'ndokoti': (4.0450, 9.7420),
  'makepe': (4.0800, 9.7550),
  'logbaba': (4.0350, 9.7700),
  'aeroport': (4.0061, 9.7195),
  'marche central': (4.0490, 9.7000),
  'laquintinie': (4.0440, 9.7020),
  'pharmacie': (4.0580, 9.7120),
  'ecole': (4.0630, 9.7200),
};

Place placeFor(String text) {
  final label = text.trim().isEmpty ? 'Douala' : text.trim();
  final lower = label.toLowerCase();
  for (final entry in _known.entries) {
    if (lower.contains(entry.key)) {
      return Place(label, entry.value.$1, entry.value.$2);
    }
  }
  // Position stable derivee du texte, dans un rayon d'environ 3 km.
  final h = label.codeUnits.fold<int>(7, (a, c) => (a * 31 + c) & 0xFFFF);
  return Place(label, 4.0511 + ((h % 61) - 30) / 1000,
      9.7043 + (((h ~/ 61) % 61) - 30) / 1000);
}
