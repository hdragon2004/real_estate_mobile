import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'core/theme/app_theme.dart';
import 'core/network/api_client.dart';
import 'presentation/screens/splash/splash_screen.dart';
import 'presentation/screens/splash/welcome_screen.dart';
import 'presentation/screens/auth/login_screen.dart';
import 'presentation/layout/main_layout.dart';

Future<void> main() async {
  // Bắt buộc cho mọi async init trước runApp
  WidgetsFlutterBinding.ensureInitialized();

  // Load file .env
  await dotenv.load(fileName: '.env');

  // Khởi tạo định dạng ngày cho locale tiếng Việt
  await initializeDateFormatting('vi_VN', null);
  Intl.defaultLocale = 'vi_VN';

  // Khởi tạo ApiClient, load token, v.v.
  await ApiClient.initialize();

  // Cấu hình thanh trạng thái & thanh điều hướng hệ thống
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Real Estate Hub',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,

      // Có thể dùng home hoặc initialRoute, ở đây giữ home như bạn
      home: const SplashScreen(),

      routes: {
        '/splash': (context) => const SplashScreen(),
        '/welcome': (context) => const WelcomeScreen(),
        '/login': (context) => const LoginScreen(),
        '/home': (context) => const MainLayout(),
      },
    );
  }
}
