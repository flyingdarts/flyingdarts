import 'package:flutter/material.dart';
import 'package:flyingdarts_authress_login/flyingdarts_authress_login.dart';
import 'package:ui/ui.dart';

import 'routes/app_router.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return AuthressProvider(
      config: const AuthressConfiguration(applicationId: 'app_2YKyhM6M31XVtuCeuDsSJ2', authressApiUrl: 'https://authress.flyingdarts.net'),
      deepLinkConfig: const DeepLinkConfig(scheme: 'flyingdarts', host: 'auth'),
      child: MaterialApp(
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
          useMaterial3: true,
          appBarTheme: const AppBarTheme(centerTitle: true, elevation: 0),
        ),
        home: AuthressPageGuard(
          authenticatedChild: MaterialApp.router(
            theme: ThemeData(
              colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
              useMaterial3: true,
              appBarTheme: const AppBarTheme(centerTitle: true, elevation: 0),
            ),
            routerConfig: AppRouter.router,
          ),
          unauthenticatedChild: _buildUnauthenticatedApp(),
          loadingChild: _buildLoadingApp(),
          errorChild: _buildErrorApp(),
        ),
      ),
    );
  }

  Widget _buildUnauthenticatedApp() {
    return FlyingdartsScaffold(
      showAppBar: false,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Center(child: _buildLoginButton()),
      ),
    );
  }

  Widget _buildLoadingApp() {
    return const FlyingdartsScaffold(
      showAppBar: false,
      child: Center(child: LottieWidget(assetPath: 'assets/animations/flyingdarts_icon.json', width: 100, height: 100)),
    );
  }

  Widget _buildErrorApp() {
    return FlyingdartsScaffold(
      showAppBar: false,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [const Text('Authentication error. Please try again.'), _buildLoginButton()],
        ),
      ),
    );
  }

  Widget _buildLoginButton() {
    return Builder(
      builder: (context) => ElevatedButton(
        onPressed: () => context.authenticate(),
        style: ElevatedButton.styleFrom(
          backgroundColor: MyTheme.secondaryColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: const Text('Please login to continue', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
      ),
    );
  }
}
