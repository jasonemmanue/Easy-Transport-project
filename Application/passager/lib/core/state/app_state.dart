import 'package:carlinq_core/carlinq_core.dart';

/// Etat de l'app Passager : portefeuille et domicile (Retour maison).
class AppState extends BaseAppState {
  int _walletBalance = 2500;
  String _passengerHome = 'Douala, Akwa - Rue 12';

  int get walletBalance => _walletBalance;
  String get passengerHome => _passengerHome;

  void reloadWallet(int amount) {
    _walletBalance += amount;
    notifyListeners();
  }

  void setPassengerHome(String address) {
    _passengerHome = address;
    notifyListeners();
  }
}
