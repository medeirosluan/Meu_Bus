class AppFares {
  static const int metroCents = 520;

  static String formatReais(int cents) {
    final reais = cents ~/ 100;
    final centavos = (cents % 100).toString().padLeft(2, '0');
    return 'R\$ $reais,$centavos';
  }
}
