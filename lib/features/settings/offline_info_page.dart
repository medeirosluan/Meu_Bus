import 'package:flutter/material.dart';

class OfflineInfoPage extends StatelessWidget {
  const OfflineInfoPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Recursos offline')),
      body: ListView(
        padding: EdgeInsets.all(16),
        children: [
          Text('O que funciona sem internet:',
              style: TextStyle(fontWeight: FontWeight.w700)),
          SizedBox(height: 8),
          Text('• Estações e linhas do metrô e CPTM'),
          Text('• Horários tabelados'),
          Text('• Favoritos'),
          SizedBox(height: 16),
          Text('O que precisa de internet:',
              style: TextStyle(fontWeight: FontWeight.w700)),
          SizedBox(height: 8),
          Text('• Status ao vivo das linhas'),
          Text('• Histórico de ocorrências'),
        ],
      ),
    );
  }
}
