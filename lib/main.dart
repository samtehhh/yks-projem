import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter/services.dart';
import 'theme.dart';

// Klasörlerden gerekli ekranları çekiyoruz
import 'package:firebase_database/firebase_database.dart';
import 'screens/giris_screen.dart';
import 'screens/ana_panel.dart';
import 'data/sabitler.dart'; // Ensure access to tytKonulari/aytMufredati

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp();
    await initializeDateFormatting('tr_TR', null);

    // Seed Database if Empty
    await _checkMufredatAndSeed();

    runApp(const YksTakipApp());
  } catch (e, stackTrace) {
    print('❌ Initialization Error: $e');
    print('Stack Trace: $stackTrace');
    runApp(ErrorApp(error: e, stackTrace: stackTrace));
  }
}

class YksTakipApp extends StatelessWidget {
  const YksTakipApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'YKS Koçum',
      theme: AppTheme.darkTheme,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('tr', 'TR'),
      ],
      locale: const Locale('tr', 'TR'),
      builder: (context, child) {
        return Shortcuts(
          shortcuts: <LogicalKeySet, Intent>{
            LogicalKeySet(LogicalKeyboardKey.goBack): const DismissIntent(),
            LogicalKeySet(LogicalKeyboardKey.escape): const DismissIntent(),
          },
          child: Actions(
            actions: <Type, Action<Intent>>{
              DismissIntent: CallbackAction<DismissIntent>(
                onInvoke: (DismissIntent intent) {
                  final NavigatorState? navigator = Navigator.maybeOf(context);
                  if (navigator != null && navigator.canPop()) {
                    navigator.pop();
                  }
                  return null;
                },
              ),
            },
            child: child!,
          ),
        );
      },
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(
                child: CircularProgressIndicator(color: AppTheme.primaryColor),
              ),
            );
          }
          if (snapshot.hasData) return const AnaPanel();
          return const GirisEkrani();
        },
      ),
    );
  }
}

// Temporary error app to display initialization errors
class ErrorApp extends StatelessWidget {
  final Object error;
  final StackTrace stackTrace;

  const ErrorApp({super.key, required this.error, required this.stackTrace});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 20),
                const Text('Başlatma Hatası',
                    style:
                        TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                Text(error.toString(), textAlign: TextAlign.center),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    print('Full Stack Trace:');
                    print(stackTrace.toString());
                  },
                  child: const Text('Stack Trace\'i Göster'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Database Seeder
Future<void> _checkMufredatAndSeed() async {
  final ref = FirebaseDatabase.instance.ref('mufredat');
  final snapshot = await ref.get();

  if (!snapshot.exists || snapshot.value == null) {
    debugPrint("⚠️ Mufredat verisi bulunamadı. Veritabanı oluşturuluyor...");
    List<Map<String, dynamic>> mufredatData = [];

    // 1. TYT Dersleri Ekle (Alan: TYT)
    tytKonulari.forEach((dersAdi, konuListesi) {
      List<Map<String, dynamic>> konular = konuListesi
          .map((k) => {"isim": k, "durum": "baslanmadi", "bitisTarihi": null})
          .toList();

      mufredatData.add({"isim": dersAdi, "alan": "TYT", "konular": konular});
    });

    // 2. AYT Dersleri Ekle (Alan: AYT)
    aytMufredati.forEach((dersAdi, konuListesi) {
      List<Map<String, dynamic>> konular = konuListesi
          .map((k) => {"isim": k, "durum": "baslanmadi", "bitisTarihi": null})
          .toList();

      mufredatData.add({"isim": dersAdi, "alan": "AYT", "konular": konular});
    });

    await ref.set(mufredatData);
    debugPrint("✅ Veritabanı başarıyla oluşturuldu!");
  } else {
    debugPrint("✅ Mufredat verisi mevcut, atlanıyor.");
  }
}
