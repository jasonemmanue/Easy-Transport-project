import 'package:carlinq_core/carlinq_core.dart';

/// Etat de l'app Chauffeur (Drivers et Copilote) : role, points, objectifs,
/// fenetre de refus, Pack Premium et domicile (Retour maison).
class AppState extends BaseAppState {
  UserRole _role = UserRole.drivers;
  int _driverPoints = 82;
  final int _weeklyGoal = 50;
  int _weeklyProgress = 32;
  int _refusalSecondsLeft = 380; // fenetre de refus quotidienne (5-10 min)
  bool _premiumActive = true;
  String _driverHome = 'Bonaberi, Quartier Deido - Rue 45';

  /// `drivers` (affilie, commission 8%) ou `copilote` (Pack Premium).
  UserRole get role => _role;
  int get driverPoints => _driverPoints;
  int get weeklyGoal => _weeklyGoal;
  int get weeklyProgress => _weeklyProgress;
  int get refusalSecondsLeft => _refusalSecondsLeft;
  bool get premiumActive => _premiumActive;
  String get driverHome => _driverHome;

  void setRole(UserRole role) {
    assert(role != UserRole.passenger, 'App chauffeur : Drivers ou Copilote');
    _role = role;
    notifyListeners();
  }

  /// Refus d'une commande : consomme 60 s de la fenetre quotidienne,
  /// au-dela la penalite de -5 points s'applique.
  void refuseOrder() {
    if (_refusalSecondsLeft >= 60) {
      _refusalSecondsLeft -= 60;
    } else {
      _refusalSecondsLeft = 0;
      _driverPoints = (_driverPoints - 5).clamp(0, 100);
    }
    notifyListeners();
  }

  void completeRide() {
    _driverPoints = (_driverPoints + 2).clamp(0, 100);
    _weeklyProgress += 1;
    notifyListeners();
  }

  void setPremium(bool active) {
    _premiumActive = active;
    notifyListeners();
  }

  void setDriverHome(String address) {
    _driverHome = address;
    notifyListeners();
  }
}
