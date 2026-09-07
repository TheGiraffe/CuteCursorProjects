import 'package:flutter/material.dart';

import 'persist/zine_store.dart';
import 'screens/project_list_screen.dart';
import 'theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final store = await ZineStore.open();
  runApp(PetalPressApp(store: store));
}

class PetalPressApp extends StatelessWidget {
  const PetalPressApp({super.key, required this.store});

  final ZineStore store;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppDisplay.name,
      debugShowCheckedModeBanner: false,
      theme: buildPetalTheme(),
      home: ProjectListScreen(store: store),
    );
  }
}
