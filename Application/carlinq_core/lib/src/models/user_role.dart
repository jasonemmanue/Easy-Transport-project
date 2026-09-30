enum UserRole {
  passenger,
  drivers,   // Chauffeur mode Yango-like (recoit des commandes)
  copilote,  // Chauffeur independant ou societe qui paie un cota
}

extension UserRoleX on UserRole {
  String get label {
    switch (this) {
      case UserRole.passenger:
        return 'Passager';
      case UserRole.drivers:
        return 'Drivers';
      case UserRole.copilote:
        return 'Copilote';
    }
  }

  String get description {
    switch (this) {
      case UserRole.passenger:
        return 'Reservez une course en un tap, suivez le chauffeur en temps reel.';
      case UserRole.drivers:
        return 'Recevez des commandes et gagnez de l\'argent avec Carlinq.';
      case UserRole.copilote:
        return 'Chauffeurs independants et societes de transport - payez le cota et travaillez.';
    }
  }
}

enum CarlinqMode {
  flexible,  // Entre dans les quartiers (3 classes)
  taxi,      // Points fixes en bordure de route
}

enum ServiceClass { eco, serenity, prestige }

extension ServiceClassX on ServiceClass {
  String get label => switch (this) {
        ServiceClass.eco => 'Eco',
        ServiceClass.serenity => 'Serenity',
        ServiceClass.prestige => 'Prestige',
      };
  double get coefficient => switch (this) {
        ServiceClass.eco => 1.0,
        ServiceClass.serenity => 1.3,
        ServiceClass.prestige => 1.7,
      };
  String get vehicle => switch (this) {
        ServiceClass.eco => 'Corolla, Logan, Lancer',
        ServiceClass.serenity => 'Camry, Accent, Yaris',
        ServiceClass.prestige => 'Prado, Fortuner, RAV4',
      };
}
