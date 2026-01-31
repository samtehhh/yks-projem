import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import '../data/sabitler.dart'; // Ders ve Kaynak listeleri için

class TakvimEkrani extends StatefulWidget {
  const TakvimEkrani({super.key});
  @override
  State<TakvimEkrani> createState() => _TakvimEkraniState();
}

class _TakvimEkraniState extends State<TakvimEkrani> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  Map<DateTime, List<dynamic>> _events = {};

  // Aktivite Ekleme Değişkenleri
  String _secilenAlan = "TYT";
  String? _secilenDers;
  String? _secilenKonu;
  String _aktiviteTuru = "Konu Çalıştım"; // veya "Soru Çözdüm"
  String? _secilenKaynak;
  final TextEditingController _detayController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay; // Açılışta bugünü seçili yap
    _verileriCekVeTakvimeIsle();
  }

  // --- VERİLERİ ÇEKME FONKSİYONU ---
  Future<void> _verileriCekVeTakvimeIsle() async {
    final User? user = FirebaseAuth.instance.currentUser;
    final ref = FirebaseDatabase.instanceFor(
      app: Firebase.app(),
      databaseURL: 'https://yks-takip-2025-default-rtdb.europe-west1.firebasedatabase.app'
    ).ref("users/${user!.uid}"); 

    ref.onValue.listen((event) {
      if (!mounted) return;
      if (event.snapshot.value == null) {
        setState(() => _events = {});
        return;
      }
      
      final data = event.snapshot.value as Map<dynamic, dynamic>;
      Map<DateTime, List<dynamic>> yeniEventler = {};

      // 1. Serbest Çalışma (Pomodoro) Verileri
      if (data['SerbestCalisma'] != null) {
        final Map<dynamic, dynamic> calismalar = data['SerbestCalisma'];
        calismalar.forEach((key, value) {
          if (value['tarih'] != null) {
            DateTime tarih = DateTime.parse(value['tarih']);
            DateTime gun = DateTime.utc(tarih.year, tarih.month, tarih.day);
            if (yeniEventler[gun] == null) yeniEventler[gun] = [];
            
            yeniEventler[gun]!.add({
              'isim': "${value['sure']} dk Çalışma",
              'tip': 'serbest_calisma',
              'detay': "${value['tur']} (${value['sure']} dk)",
              'sure': value['sure']
            });
          }
        });
      }

      // 2. Günlük Manuel Aktiviteler
      if (data['GunlukAktiviteler'] != null) {
        final Map<dynamic, dynamic> aktiviteler = data['GunlukAktiviteler'];
        aktiviteler.forEach((key, value) {
          if (value['tarih'] != null) {
            DateTime tarih = DateTime.parse(value['tarih']);
            DateTime gun = DateTime.utc(tarih.year, tarih.month, tarih.day);
            if (yeniEventler[gun] == null) yeniEventler[gun] = [];

            yeniEventler[gun]!.add({
              'isim': "${value['ders']} - ${value['konu']}",
              'tip': value['tur'] == 'Soru Çözdüm' ? 'soru_cozdum' : 'konu_calistim',
              'detay': value['tur'] == 'Soru Çözdüm' 
                  ? "Kaynak: ${value['kaynak']} \n${value['detay']}" 
                  : "Konu Çalışması Yapıldı.",
              'dbKey': key // Silmek isterse diye
            });
          }
        });
      }

      // 3. Mevcut TYT/AYT Durumları
      void isleyici(String alan) {
        if (data[alan] != null) {
          final List<dynamic> dersler = data[alan] as List<dynamic>;
          for (int dIndex = 0; dIndex < dersler.length; dIndex++) {
            var ders = dersler[dIndex];
            if (ders['konular'] != null) {
              final List<dynamic> konular = ders['konular'];
              for (int kIndex = 0; kIndex < konular.length; kIndex++) {
                var konu = konular[kIndex];
                
                // Tekrarlar (Mevcut mantık)
                if (konu['planlananTarihler'] != null) {
                  List<dynamic> tarihler = konu['planlananTarihler'];
                  for (var tarihStr in tarihler) {
                    DateTime tarih = DateTime.parse(tarihStr);
                    DateTime gun = DateTime.utc(tarih.year, tarih.month, tarih.day);
                    if (yeniEventler[gun] == null) yeniEventler[gun] = [];
                    yeniEventler[gun]!.add({'isim': konu['isim'], 'tip': 'tekrar_hatirlatma', 'alan': alan, 'dIndex': dIndex, 'kIndex': kIndex, 'hedefTarih': tarihStr});
                  }
                }
              }
            }
          }
        }
      }
      isleyici('TYT');
      isleyici('AYT');

      if (mounted) setState(() => _events = yeniEventler);
    });
  }

  // --- YENİ AKTİVİTE EKLEME ---
  void _aktiviteEkleDialogGoster() {
    _secilenAlan = "TYT";
    _secilenDers = null;
    _secilenKonu = null;
    _aktiviteTuru = "Konu Çalıştım";
    _secilenKaynak = null;
    _detayController.clear();

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            List<String> dersListesi = [];
            if (_secilenAlan == 'TYT') {
              dersListesi = tytKonulari.keys.toList();
            } else {
              dersListesi = aytMufredati.keys.toList();
            }

            List<String> konuListesi = [];
            if (_secilenDers != null) {
              if (_secilenAlan == 'TYT') {
                konuListesi = tytKonulari[_secilenDers] ?? [];
              } else {
                konuListesi = aytMufredati[_secilenDers] ?? [];
              }
            }

            List<String> kaynakListesi = [];
            if (_secilenDers != null) {
               String anahtarKelime = 'Genel';
               dersBazliKaynaklar.forEach((k, v) {
                 if (_secilenDers!.contains(k)) anahtarKelime = k;
               });
               kaynakListesi = dersBazliKaynaklar[anahtarKelime] ?? [];
            }

            return AlertDialog(
              title: const Text("Bugün Ne Yaptın? 📝"),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Expanded(child: RadioListTile(title: const Text("TYT"), value: "TYT", groupValue: _secilenAlan, onChanged: (v) => setStateDialog(() { _secilenAlan = v.toString(); _secilenDers = null; _secilenKonu = null; }))),
                        Expanded(child: RadioListTile(title: const Text("AYT"), value: "AYT", groupValue: _secilenAlan, onChanged: (v) => setStateDialog(() { _secilenAlan = v.toString(); _secilenDers = null; _secilenKonu = null; }))),
                      ],
                    ),
                    DropdownButton<String>(
                      isExpanded: true,
                      hint: const Text("Ders Seçiniz"),
                      value: _secilenDers,
                      items: dersListesi.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                      onChanged: (v) => setStateDialog(() { _secilenDers = v; _secilenKonu = null; }),
                    ),
                    const SizedBox(height: 10),
                    DropdownButton<String>(
                      isExpanded: true,
                      hint: const Text("Konu Seçiniz"),
                      value: _secilenKonu,
                      items: konuListesi.map((e) => DropdownMenuItem(value: e, child: Text(e, overflow: TextOverflow.ellipsis))).toList(),
                      onChanged: (v) => setStateDialog(() => _secilenKonu = v),
                    ),
                    const Divider(),
                    Row(
                      children: [
                        Expanded(child: RadioListTile(contentPadding: EdgeInsets.zero, title: const Text("Çalıştım", style: TextStyle(fontSize: 14)), value: "Konu Çalıştım", groupValue: _aktiviteTuru, onChanged: (v) => setStateDialog(() => _aktiviteTuru = v.toString()))),
                        Expanded(child: RadioListTile(contentPadding: EdgeInsets.zero, title: const Text("Çözdüm", style: TextStyle(fontSize: 14)), value: "Soru Çözdüm", groupValue: _aktiviteTuru, onChanged: (v) => setStateDialog(() => _aktiviteTuru = v.toString()))),
                      ],
                    ),
                    if (_aktiviteTuru == 'Soru Çözdüm') ...[
                      DropdownButton<String>(
                        isExpanded: true,
                        hint: const Text("Kaynak Seçiniz"),
                        value: _secilenKaynak,
                        items: kaynakListesi.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                        onChanged: (v) => setStateDialog(() => _secilenKaynak = v),
                      ),
                      TextField(
                        controller: _detayController,
                        decoration: const InputDecoration(hintText: "Kaç soru? Hangi sayfa?", labelText: "Detaylar"),
                      )
                    ]
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text("İptal")),
                ElevatedButton(
                  onPressed: () {
                    if (_secilenDers == null || _secilenKonu == null) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Lütfen ders ve konu seçin.")));
                      return;
                    }
                    if (_aktiviteTuru == 'Soru Çözdüm' && _secilenKaynak == null) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Lütfen kaynak belirtin.")));
                      return;
                    }
                    _aktiviteyiKaydet();
                    Navigator.pop(context);
                  }, 
                  child: const Text("Kaydet")
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _aktiviteyiKaydet() async {
    final User? user = FirebaseAuth.instance.currentUser;
    final ref = FirebaseDatabase.instanceFor(
      app: Firebase.app(),
      databaseURL: 'https://yks-takip-2025-default-rtdb.europe-west1.firebasedatabase.app'
    ).ref("users/${user!.uid}/GunlukAktiviteler");

    DateTime kayitTarihi = _selectedDay ?? DateTime.now();

    await ref.push().set({
      'tarih': kayitTarihi.toIso8601String(),
      'alan': _secilenAlan,
      'ders': _secilenDers,
      'konu': _secilenKonu,
      'tur': _aktiviteTuru,
      'kaynak': _secilenKaynak ?? "",
      'detay': _detayController.text
    });

    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Aktivite takvime işlendi! ✅"), backgroundColor: Colors.green));
  }

  Future<void> _aktiviteSil(String? dbKey) async {
    if (dbKey == null) return;
    final User? user = FirebaseAuth.instance.currentUser;
    await FirebaseDatabase.instanceFor(
      app: Firebase.app(),
      databaseURL: 'https://yks-takip-2025-default-rtdb.europe-west1.firebasedatabase.app'
    ).ref("users/${user!.uid}/GunlukAktiviteler/$dbKey").remove();
    
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Kayıt silindi.")));
  }

  List<dynamic> _getEventsForDay(DateTime day) {
    return _events[DateTime.utc(day.year, day.month, day.day)] ?? [];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Takvim & Günlük"),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _aktiviteEkleDialogGoster,
        label: const Text("Ekle"),
        icon: const Icon(Icons.add),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          TableCalendar(
            locale: 'tr_TR', 
            firstDay: DateTime.utc(2024, 1, 1),
            lastDay: DateTime.utc(2030, 12, 31),
            focusedDay: _focusedDay,
            calendarFormat: _calendarFormat,
            headerStyle: const HeaderStyle(formatButtonVisible: false, titleCentered: true),
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
              });
            },
            onPageChanged: (focusedDay) => _focusedDay = focusedDay,
            eventLoader: _getEventsForDay,
            calendarBuilders: CalendarBuilders(
              singleMarkerBuilder: (context, date, event) {
                final map = event as Map<dynamic, dynamic>;
                Color dotColor = Colors.grey;
                if (map['tip'] == 'serbest_calisma') dotColor = Colors.purple;
                else if (map['tip'] == 'soru_cozdum') dotColor = Colors.blue;
                else if (map['tip'] == 'konu_calistim') dotColor = Colors.green;
                else if (map['tip'] == 'tekrar_hatirlatma') dotColor = Colors.orange;
                
                return Container(
                  decoration: BoxDecoration(shape: BoxShape.circle, color: dotColor),
                  width: 7.0, height: 7.0, margin: const EdgeInsets.symmetric(horizontal: 1.5),
                );
              },
            ),
          ),
          const Divider(),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            width: double.infinity,
            color: Colors.grey.shade100,
            child: Center(child: Text(
              _selectedDay == null ? "Bir gün seçin" : "${DateFormat('d MMMM yyyy', 'tr_TR').format(_selectedDay!)} Kayıtları",
              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)
            )),
          ),
          Expanded(
            child: _selectedDay == null 
              ? const Center(child: Text("Bir gün seçin."))
              : ListView(
                  children: _getEventsForDay(_selectedDay!).map((event) {
                    
                    if (event['tip'] == 'serbest_calisma') {
                      return Card(
                        color: Colors.purple.shade50,
                        margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        child: ListTile(
                          leading: const Icon(Icons.timer, color: Colors.purple),
                          title: Text(event['isim'], style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text(event['detay']),
                        ),
                      );
                    }

                    if (event['tip'] == 'soru_cozdum') {
                      return Dismissible(
                        key: Key(event['dbKey'] ?? DateTime.now().toString()),
                        direction: DismissDirection.endToStart,
                        onDismissed: (_) => _aktiviteSil(event['dbKey']),
                        background: Container(color: Colors.red, alignment: Alignment.centerRight, padding: const EdgeInsets.only(right: 20), child: const Icon(Icons.delete, color: Colors.white)),
                        child: Card(
                          color: Colors.blue.shade50,
                          margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          child: ListTile(
                            leading: const Icon(Icons.quiz, color: Colors.blue),
                            title: Text(event['isim'], style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text(event['detay']),
                            trailing: const Icon(Icons.check_circle, color: Colors.blue),
                          ),
                        ),
                      );
                    }

                    if (event['tip'] == 'konu_calistim') {
                       return Dismissible(
                        key: Key(event['dbKey'] ?? DateTime.now().toString()),
                        direction: DismissDirection.endToStart,
                        onDismissed: (_) => _aktiviteSil(event['dbKey']),
                        background: Container(color: Colors.red, alignment: Alignment.centerRight, padding: const EdgeInsets.only(right: 20), child: const Icon(Icons.delete, color: Colors.white)),
                        child: Card(
                          color: Colors.green.shade50,
                          margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          child: ListTile(
                            leading: const Icon(Icons.book, color: Colors.green),
                            title: Text(event['isim'], style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text(event['detay']),
                            trailing: const Icon(Icons.check, color: Colors.green),
                          ),
                        ),
                       );
                    }

                    if (event['tip'] == 'tekrar_hatirlatma') {
                       return Card(
                        color: Colors.orange.shade50,
                        margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        child: ListTile(
                          leading: const Icon(Icons.notifications_active, color: Colors.orange),
                          title: Text(event['isim'], style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: const Text("Bugün tekrar etmen gereken konu."),
                          trailing: ElevatedButton(
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 10)),
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Konular sekmesinden detaylara bakabilirsin.")));
                            }, 
                            child: const Text("Git")
                          ),
                        ),
                      );
                    }

                    return const SizedBox();
                  }).toList(),
                ),
          ),
        ],
      ),
    );
  }
}