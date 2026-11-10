import 'package:flutter/material.dart';

import 'app/app.dart';
import 'app/dependencies.dart';
import 'core/config/env.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  const env = Env.fromEnvironment();
  final dependencies = AppDependencies.fromEnv(env);
  await dependencies.session.restore();
  runApp(AlertaApp(dependencies: dependencies));
}
