import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'core/constants/app_constants.dart';
import 'core/di/injection.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'desktop_bootstrap.dart';
import 'features/progress/progress_cubit.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (!kIsWeb) {
    await DesktopBootstrap.init();
  }

  await AppServices.instance.init();

  runApp(CloudamnedApp(router: createRouter()));
}

class CloudamnedApp extends StatelessWidget {
  const CloudamnedApp({super.key, required this.router});

  final GoRouter router;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<ProgressCubit>.value(
      value: AppServices.instance.progressCubit,
      child: MaterialApp.router(
        title: AppConstants.appName,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.dark,
        routerConfig: router,
      ),
    );
  }
}
