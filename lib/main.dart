import 'package:flutter/material.dart';

import 'app/app.dart';
import 'app/dependencies.dart';
import 'core/config/env.dart';

void main() {
  const env = Env.fromEnvironment();
  runApp(AlertaApp(dependencies: AppDependencies.fromEnv(env)));
}
