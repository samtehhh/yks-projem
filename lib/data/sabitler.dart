import 'package:flutter/material.dart';

// YKS 2024 - RESMİ SORU DAĞILIMLARI VE SABİTLER

// KONU ÇIKMA SIKLIĞI (2018-2025 Analizi)
enum KonuSikligi { yuksek, orta, dusuk }

// Konu Sıklık Renk Kodları
const Map<KonuSikligi, Color> siklikRenkleri = {
  KonuSikligi.yuksek: Color(0xFFEF5350), // Kırmızı - Çok Sık
  KonuSikligi.orta: Color(0xFFFFA726), // Turuncu - Düzenli
  KonuSikligi.dusuk: Color(0xFF66BB6A), // Yeşil - Az
};

const Map<KonuSikligi, String> siklikEtiketleri = {
  KonuSikligi.yuksek: 'Çok Sık Çıkar',
  KonuSikligi.orta: 'Düzenli Çıkar',
  KonuSikligi.dusuk: 'Az Çıkar',
};

const Map<KonuSikligi, IconData> siklikIkonlari = {
  KonuSikligi.yuksek: Icons.local_fire_department_rounded,
  KonuSikligi.orta: Icons.trending_up_rounded,
  KonuSikligi.dusuk: Icons.circle_outlined,
};

// KONU ÇIKMA SIKLIĞI HARİTASI (2018-2025 YKS Analizi)
const Map<String, KonuSikligi> konuCikmaSikliklari = {
  // ===== TYT TÜRKÇE =====
  'Paragraf': KonuSikligi.yuksek,
  'Sözcükte Anlam': KonuSikligi.yuksek,
  'Cümlede Anlam': KonuSikligi.yuksek,
  'Yazım Kuralları': KonuSikligi.yuksek,
  'Noktalama İşaretleri': KonuSikligi.yuksek,
  'Sözcükte Yapı': KonuSikligi.orta,
  'Ses Bilgisi': KonuSikligi.dusuk,
  'İsimler (Adlar)': KonuSikligi.orta,
  'Sıfatlar (Ön Adlar)': KonuSikligi.orta,
  'Zamirler (Adıllar)': KonuSikligi.orta,
  'Zarflar (Belirteçler)': KonuSikligi.orta,
  'Edat - Bağlaç - Ünlem': KonuSikligi.orta,
  'Fiiller (Eylemler)': KonuSikligi.orta,
  'Ek Fiil': KonuSikligi.dusuk,
  'Fiilimsi': KonuSikligi.orta,
  'Cümlenin Öğeleri': KonuSikligi.orta,
  'Fiil Çatısı': KonuSikligi.orta,
  'Cümle Türleri': KonuSikligi.orta,
  'Anlatım Bozukluğu': KonuSikligi.orta,

  // ===== TYT MATEMATİK =====
  'Temel Kavramlar': KonuSikligi.yuksek,
  'Sayı Basamakları': KonuSikligi.yuksek,
  'Bölme ve Bölünebilme': KonuSikligi.orta,
  'EBOB - EKOK': KonuSikligi.orta,
  'Rasyonel Sayılar': KonuSikligi.yuksek,
  'Basit Eşitsizlikler': KonuSikligi.orta,
  'Mutlak Değer': KonuSikligi.yuksek,
  'Üslü Sayılar': KonuSikligi.yuksek,
  'Köklü Sayılar': KonuSikligi.yuksek,
  'Çarpanlara Ayırma': KonuSikligi.orta,
  'Oran - Orantı': KonuSikligi.yuksek,
  'Denklem Çözme': KonuSikligi.yuksek,
  'Sayı Kesir Problemleri': KonuSikligi.yuksek,
  'Yaş Problemleri': KonuSikligi.yuksek,
  'İşçi Emek Problemleri': KonuSikligi.yuksek,
  'Yüzde Kar Zarar Problemleri': KonuSikligi.yuksek,
  'Karışım Problemleri': KonuSikligi.yuksek,
  'Hareket Problemleri': KonuSikligi.yuksek,
  'Grafik Problemleri': KonuSikligi.yuksek,
  'Rutin Olmayan Problemler': KonuSikligi.yuksek,
  'Kümeler': KonuSikligi.orta,
  'Mantık': KonuSikligi.orta,
  'Fonksiyonlar': KonuSikligi.yuksek,
  'Polinomlar': KonuSikligi.orta,
  'İkinci Dereceden Denklemler': KonuSikligi.orta,
  'Karmaşık Sayılar': KonuSikligi.orta,
  'Permütasyon': KonuSikligi.orta,
  'Kombinasyon': KonuSikligi.orta,
  'Binom': KonuSikligi.dusuk,
  'Olasılık': KonuSikligi.orta,
  'Veri - İstatistik': KonuSikligi.orta,

  // ===== TYT GEOMETRİ =====
  'Doğruda ve Üçgende Açılar': KonuSikligi.yuksek,
  'Dik ve Özel Üçgenler': KonuSikligi.yuksek,
  'İkizkenar ve Eşkenar Üçgen': KonuSikligi.yuksek,
  'Açıortay ve Kenarortay': KonuSikligi.orta,
  'Üçgende Eşlik ve Benzerlik': KonuSikligi.yuksek,
  'Üçgende Alan': KonuSikligi.yuksek,
  'Açı Kenar Bağıntıları': KonuSikligi.orta,
  'Çokgenler': KonuSikligi.yuksek,
  'Dörtgenler': KonuSikligi.yuksek,
  'Yamuk': KonuSikligi.orta,
  'Paralelkenar': KonuSikligi.orta,
  'Eşkenar Dörtgen': KonuSikligi.orta,
  'Dikdörtgen': KonuSikligi.orta,
  'Kare': KonuSikligi.orta,
  'Deltoid': KonuSikligi.dusuk,
  'Çemberde Açı': KonuSikligi.yuksek,
  'Çemberde Uzunluk': KonuSikligi.yuksek,
  'Dairede Alan': KonuSikligi.yuksek,
  'Katı Cisimler (Prizma, Piramit)': KonuSikligi.yuksek,
  'Noktanın ve Doğrunun Analitiği': KonuSikligi.orta,

  // ===== TYT FİZİK =====
  'Fizik Bilimine Giriş': KonuSikligi.dusuk,
  'Madde ve Özellikleri': KonuSikligi.yuksek,
  'Hareket ve Kuvvet': KonuSikligi.yuksek,
  'İş, Güç ve Enerji': KonuSikligi.yuksek,
  'Isı, Sıcaklık ve Genleşme': KonuSikligi.yuksek,
  'Basınç': KonuSikligi.orta,
  'Kaldırma Kuvveti': KonuSikligi.orta,
  'Elektrik (Elektrostatik)': KonuSikligi.yuksek,
  'Elektrik Akımı ve Devreler': KonuSikligi.yuksek,
  'Mıknatıs ve Manyetizma': KonuSikligi.orta,
  'Dalgalar (Yay, Su, Ses, Deprem)': KonuSikligi.orta,
  'Optik (Aydınlanma, Gölgeler, Aynalar)': KonuSikligi.yuksek,
  'Optik (Kırılma, Mercekler, Renkler)': KonuSikligi.yuksek,

  // ===== TYT KİMYA =====
  'Kimya Bilimi': KonuSikligi.orta,
  'Atom ve Periyodik Sistem': KonuSikligi.yuksek,
  'Kimyasal Türler Arası Etkileşimler': KonuSikligi.yuksek,
  'Maddenin Halleri': KonuSikligi.yuksek,
  'Doğa ve Kimya': KonuSikligi.orta,
  'Kimyanın Temel Kanunları': KonuSikligi.orta,
  'Mol Kavramı': KonuSikligi.orta,
  'Kimyasal Hesaplamalar': KonuSikligi.orta,
  'Karışımlar': KonuSikligi.orta,
  'Asitler, Bazlar ve Tuzlar': KonuSikligi.yuksek,
  'Kimya Her Yerde': KonuSikligi.dusuk,

  // ===== TYT BİYOLOJİ =====
  'Canlıların Ortak Özellikleri': KonuSikligi.orta,
  'Canlıların Temel Bileşenleri': KonuSikligi.yuksek,
  'Hücre ve Organeller': KonuSikligi.yuksek,
  'Madde Geçişleri': KonuSikligi.orta,
  'Canlıların Sınıflandırılması': KonuSikligi.orta,
  'Hücre Bölünmeleri (Mitoz - Mayoz)': KonuSikligi.orta,
  'Kalıtım': KonuSikligi.yuksek,
  'Ekosistem Ekolojisi': KonuSikligi.yuksek,
  'Güncel Çevre Sorunları': KonuSikligi.orta,

  // ===== TYT TARİH =====
  'Tarih Bilimi': KonuSikligi.dusuk,
  'İlk Çağ Uygarlıkları': KonuSikligi.orta,
  'İlk Türk Devletleri': KonuSikligi.orta,
  'İslam Tarihi ve Uygarlığı': KonuSikligi.orta,
  'Türk İslam Devletleri': KonuSikligi.orta,
  'Türkiye Tarihi': KonuSikligi.orta,
  'Beylikten Devlete (Osmanlı)': KonuSikligi.orta,
  'Dünya Gücü Osmanlı': KonuSikligi.orta,
  'Osmanlı Kültür ve Medeniyeti': KonuSikligi.orta,
  'Değişim Çağında Avrupa ve Osmanlı': KonuSikligi.orta,
  'Uluslararası İlişkilerde Denge Stratejisi': KonuSikligi.orta,
  'XX. Yüzyıl Başlarında Osmanlı': KonuSikligi.orta,
  'Milli Mücadele Hazırlık Dönemi': KonuSikligi.orta,
  'Milli Mücadele Muharebeler Dönemi': KonuSikligi.orta,
  'Atatürkçülük ve Türk İnkılabı': KonuSikligi.yuksek,

  // ===== TYT COĞRAFYA =====
  'Doğa ve İnsan': KonuSikligi.orta,
  'Dünya\'nın Şekli ve Hareketleri': KonuSikligi.orta,
  'Coğrafi Konum': KonuSikligi.orta,
  'Harita Bilgisi': KonuSikligi.orta,
  'İklim Bilgisi': KonuSikligi.orta,
  'Yerin Şekillenmesi (İç ve Dış Kuvvetler)': KonuSikligi.orta,
  'Su, Toprak ve Bitki': KonuSikligi.orta,
  'Nüfus ve Yerleşme': KonuSikligi.orta,
  'Ekonomik Faaliyetler': KonuSikligi.orta,
  'Bölgeler ve Ülkeler': KonuSikligi.orta,
  'Doğal Afetler': KonuSikligi.yuksek,
  'Çevre ve Toplum': KonuSikligi.yuksek,

  // ===== TYT FELSEFE =====
  'Felsefeyi Tanıyalım': KonuSikligi.dusuk,
  'Felsefe ile Düşünme': KonuSikligi.orta,
  'Varlık Felsefesi': KonuSikligi.orta,
  'Bilgi Felsefesi': KonuSikligi.orta,
  'Bilim Felsefesi': KonuSikligi.orta,
  'Ahlak Felsefesi': KonuSikligi.orta,
  'Din Felsefesi': KonuSikligi.orta,
  'Siyaset Felsefesi': KonuSikligi.orta,
  'Sanat Felsefesi': KonuSikligi.dusuk,

  // ===== TYT DİN =====
  'Bilgi ve İnanç': KonuSikligi.orta,
  'Din ve İslam': KonuSikligi.orta,
  'İslam ve İbadet': KonuSikligi.orta,
  'Gençlik ve Değerler': KonuSikligi.orta,
  'Allah İnsan İlişkisi': KonuSikligi.orta,
  'Hz. Muhammed (S.A.V)': KonuSikligi.orta,
  'Vahiy ve Akıl': KonuSikligi.orta,
  'Ahlaki Tutum ve Davranışlar': KonuSikligi.orta,
  'İslam Düşüncesinde Yorumlar': KonuSikligi.orta,
  'Din, Kültür ve Medeniyet': KonuSikligi.orta,

  // ===== AYT MATEMATİK =====
  'Fonksiyonlar (II. Bölüm)': KonuSikligi.yuksek,
  // 'Polinomlar' ve 'İkinci Dereceden Denklemler' TYT'de mevcut
  'Karmaşık Sayılar (II. Bölüm)': KonuSikligi.orta,
  'İkinci Dereceden Eşitsizlikler': KonuSikligi.orta,
  'Parabol': KonuSikligi.orta,
  'Trigonometri': KonuSikligi.yuksek,
  'Logaritma': KonuSikligi.yuksek,
  'Diziler': KonuSikligi.orta,
  'Limit ve Süreklilik': KonuSikligi.yuksek,
  'Türev': KonuSikligi.yuksek,
  'İntegral': KonuSikligi.yuksek,
  'Sayma ve Olasılık (II. Bölüm)': KonuSikligi.orta,

  // ===== AYT FİZİK =====
  'Vektörler': KonuSikligi.orta,
  'Bağıl Hareket': KonuSikligi.orta,
  'Newton\'un Hareket Yasaları': KonuSikligi.yuksek,
  'Bir Boyutta Sabit İvmeli Hareket': KonuSikligi.yuksek,
  'İki Boyutta Hareket (Atışlar)': KonuSikligi.yuksek,
  'Enerji ve Hareket': KonuSikligi.yuksek,
  'İtme ve Momentum': KonuSikligi.yuksek,
  'Tork ve Denge': KonuSikligi.orta,
  'Kütle ve Ağırlık Merkezi': KonuSikligi.orta,
  'Basit Makineler': KonuSikligi.orta,
  'Elektriksel Kuvvet ve Alan': KonuSikligi.yuksek,
  'Elektriksel Potansiyel': KonuSikligi.yuksek,
  'Düzgün Elektrik Alan ve Sığa': KonuSikligi.orta,
  'Manyetizma ve Elektromanyetik İndüklenme': KonuSikligi.yuksek,
  'Alternatif Akım ve Transformatörler': KonuSikligi.orta,
  'Çembersel Hareket': KonuSikligi.orta,
  'Basit Harmonik Hareket': KonuSikligi.yuksek,
  'Dalga Mekaniği': KonuSikligi.orta,
  'Atom Fiziğine Giriş ve Radyoaktivite': KonuSikligi.yuksek,
  'Modern Fizik': KonuSikligi.yuksek,
  'Modern Fiziğin Teknolojideki Uygulamaları': KonuSikligi.orta,

  // ===== AYT KİMYA =====
  'Modern Atom Teorisi': KonuSikligi.orta,
  'Gazlar': KonuSikligi.yuksek,
  'Sıvı Çözeltiler ve Çözünürlük': KonuSikligi.yuksek,
  'Kimyasal Tepkimelerde Enerji': KonuSikligi.orta,
  'Kimyasal Tepkimelerde Hız': KonuSikligi.yuksek,
  'Kimyasal Tepkimelerde Denge': KonuSikligi.yuksek,
  'Asit ve Baz Dengeleri': KonuSikligi.yuksek,
  'Çözünürlük Dengesi (Kçç)': KonuSikligi.orta,
  'Kimya ve Elektrik': KonuSikligi.yuksek,
  'Karbon Kimyasına Giriş': KonuSikligi.orta,
  'Organik Bileşikler': KonuSikligi.yuksek,
  'Enerji Kaynakları ve Bilimsel Gelişmeler': KonuSikligi.orta,

  // ===== AYT BİYOLOJİ =====
  'Sinir Sistemi': KonuSikligi.yuksek,
  'Endokrin Sistem': KonuSikligi.yuksek,
  'Duyu Organları': KonuSikligi.orta,
  'Destek ve Hareket Sistemi': KonuSikligi.orta,
  'Sindirim Sistemi': KonuSikligi.orta,
  'Dolaşım Sistemi': KonuSikligi.yuksek,
  'Bağışıklık Sistemi': KonuSikligi.orta,
  'Solunum Sistemi': KonuSikligi.yuksek,
  'Üriner Sistem': KonuSikligi.orta,
  'Üreme Sistemi ve Embriyonik Gelişim': KonuSikligi.orta,
  'Komünite ve Popülasyon Ekolojisi': KonuSikligi.orta,
  'Nükleik Asitler (DNA-RNA)': KonuSikligi.orta,
  'Genden Proteine (Protein Sentezi)': KonuSikligi.yuksek,
  'Canlılık ve Enerji (ATP - Fotosentez - Kemosentez - Solunum)':
      KonuSikligi.yuksek,
  'Bitki Biyolojisi': KonuSikligi.yuksek,
  'Canlılar ve Çevre': KonuSikligi.orta,

  // ===== AYT EDEBİYAT =====
  'Güzel Sanatlar ve Edebiyat': KonuSikligi.orta,
  'Coşku ve Heyecanı Dile Getiren Metinler (Şiir)': KonuSikligi.yuksek,
  'Olay Çevresinde Oluşan Edebi Metinler': KonuSikligi.yuksek,
  'Öğretici Metinler': KonuSikligi.orta,
  'İslamiyet Öncesi Türk Edebiyatı': KonuSikligi.orta,
  'Geçiş Dönemi Türk Edebiyatı': KonuSikligi.orta,
  'Halk Edebiyatı': KonuSikligi.orta,
  'Divan Edebiyatı': KonuSikligi.yuksek,
  'Tanzimat Edebiyatı': KonuSikligi.yuksek,
  'Servet-i Fünun Edebiyatı': KonuSikligi.yuksek,
  'Fecr-i Ati Edebiyatı': KonuSikligi.orta,
  'Milli Edebiyat Dönemi': KonuSikligi.yuksek,
  'Cumhuriyet Dönemi Türk Edebiyatı': KonuSikligi.yuksek,
  'Batı Edebiyatı ve Akımlar': KonuSikligi.orta,

  // ===== AYT TARİH-1 =====
  // Ortak konular TYT Tarih'te mevcut, sadece AYT'ye özgü ekleniyor
  'Milli Mücadele': KonuSikligi.yuksek,
  'Atatürkçülük ve Türk İnkılabı (AYT)': KonuSikligi.yuksek,
  'Atatürk Dönemi Dış Politika': KonuSikligi.orta,

  // ===== AYT COĞRAFYA-1 =====
  'Biyoçeşitlilik': KonuSikligi.orta,
  'Ekosistemlerin İşleyişi': KonuSikligi.orta,
  'Madde Döngüleri ve Enerji Akışı': KonuSikligi.orta,
  'Ekstrem Doğa Olayları': KonuSikligi.yuksek,
  'Geleceğin Dünyası (Nüfus Politikaları)': KonuSikligi.orta,
  'Şehirlerin Fonksiyonları': KonuSikligi.orta,
  'Türkiye\'de Tarım ve Hayvancılık': KonuSikligi.orta,
  'Türkiye\'de Madenler ve Enerji Kaynakları': KonuSikligi.orta,
  'Türkiye\'de Sanayi, Ulaşım, Ticaret, Turizm': KonuSikligi.orta,
  'Bölgeler ve Ülkeler (Jeopolitik Konum)': KonuSikligi.orta,
  'Çevre ve Toplum (Küresel Isınma)': KonuSikligi.yuksek,

  // ===== AYT GEOMETRİ EKLEMELERİ (Unique Keys or Contextual) =====
  'Üçgende Benzerlik ve Eşlik': KonuSikligi.yuksek,
  'Çokgenler ve Dörtgenler': KonuSikligi.yuksek,
  'Yamuk ve Paralelkenar': KonuSikligi.orta,
  'Eşkenar Dörtgen, Dikdörtgen, Kare ve Deltoid': KonuSikligi.orta,
  'Çemberde Açılar ve Uzunluk': KonuSikligi.yuksek,
  'Noktanın Analitik İncelenmesi': KonuSikligi.yuksek,
  'Katı Cisimler (Prizma, Piramit, Silindir, Koni, Küre)': KonuSikligi.yuksek,
  'Doğrunun Analitik İncelenmesi': KonuSikligi.yuksek,
  'Çemberin Analitik İncelenmesi': KonuSikligi.orta,
  'Dönüşüm Geometrisi': KonuSikligi.orta,

  // ===== YDT İNGİLİZCE FREKANSLARI =====
  'Kelime Bilgisi (Vocabulary)': KonuSikligi.yuksek,
  'Dilbilgisi (Grammar)': KonuSikligi.yuksek,
  'Cloze Test': KonuSikligi.orta,
  'Cümle Tamamlama (Sentence Completion)': KonuSikligi.yuksek,
  'İngilizce-Türkçe Çeviri': KonuSikligi.yuksek,
  'Türkçe-İngilizce Çeviri': KonuSikligi.yuksek,
  'Paragraf (Okuma-Anlama)': KonuSikligi.yuksek,
  'Diyalog Tamamlama': KonuSikligi.orta,
  'Anlamca Yakın Cümle (Restatement)': KonuSikligi.orta,
  'Paragraf Tamamlama': KonuSikligi.orta,
  'Duruma Uygun İfade (Situational)': KonuSikligi.orta,
  'Anlam Akışını Bozan Cümle (Irrelevant)': KonuSikligi.orta,
};

const Map<String, int> maxSoruSayilari = {
  // TYT (Toplam 120)
  'TYT Türkçe': 40,
  'TYT Sosyal': 20,
  'TYT Matematik': 40, // Toplam 40 (30 Mat + 10 Geo)
  'TYT Geometri': 10,
  'TYT Fen': 20,

  // TYT Detayları (Breakdown Keys for UI)
  'Türkçe': 40,
  'Sosyal': 20,
  'Matematik': 40, // Aggregated Default
  'Sadece Matematik': 30, // Detailed Only
  'Geometri': 10, // Detailed Only
  'Fen': 20,

  // TYT Alt Dallar
  'Tarih': 5,
  'Coğrafya': 5,
  'Felsefe': 5,
  'Din': 5,
  'Fizik': 7,
  'Kimya': 7,
  'Biyoloji': 6,

  // AYT (Alan Bazlı 80)
  'AYT Matematik': 30,
  'AYT Geometri': 10,
  'AYT Fen': 40,
  'AYT Sosyal-1': 40,
  'AYT Sosyal-2': 40,
  'AYT YDT': 80,
  'YDT İngilizce': 80,

  // AYT Detayları (Breakdown Keys for UI)
  'Matematik (AYT)': 40, // Aggregated
  'Sadece Matematik (AYT)': 30, // Detailed
  'Geometri (AYT)': 10, // Detailed
  'Fen Bilimleri': 40,
  'Sosyal 1': 40,
  'Sosyal 2': 40,
  'Ed-Sos-1': 40,
  'Sosyal-2': 40,

  // AYT Alt Dallar
  'AYT Fizik': 14,
  'AYT Kimya': 13,
  'AYT Biyoloji': 13,

  'Edebiyat': 24,
  'Tarih-1': 10,
  'Coğrafya-1': 6,
  'Tarih-2': 11,
  'Coğrafya-2': 11,
  'Felsefe Grubu': 12,
  'Din (AYT)': 6,
};

// ALAN SEÇENEKLERİ
const List<String> kAlanSecenekleri = [
  'Sayısal (MF)',
  'Eşit Ağırlık (EA)',
  'Sözel (TS)',
  'Dil (YDT)'
];

// TYT Konuları (Full Listesi)
const Map<String, List<String>> tytKonulari = {
  'TYT Türkçe': [
    'Sözcükte Anlam',
    'Cümlede Anlam',
    'Paragraf',
    'Ses Bilgisi',
    'Yazım Kuralları',
    'Noktalama İşaretleri',
    'Sözcükte Yapı',
    'İsimler (Adlar)',
    'Sıfatlar (Ön Adlar)',
    'Zamirler (Adıllar)',
    'Zarflar (Belirteçler)',
    'Edat - Bağlaç - Ünlem',
    'Fiiller (Eylemler)',
    'Ek Fiil',
    'Fiilimsi',
    'Cümlenin Öğeleri',
    'Fiil Çatısı',
    'Cümle Türleri',
    'Anlatım Bozukluğu'
  ],
  'TYT Matematik': [
    'Temel Kavramlar',
    'Sayı Basamakları',
    'Bölme ve Bölünebilme',
    'EBOB - EKOK',
    'Rasyonel Sayılar',
    'Basit Eşitsizlikler',
    'Mutlak Değer',
    'Üslü Sayılar',
    'Köklü Sayılar',
    'Çarpanlara Ayırma',
    'Oran - Orantı',
    'Denklem Çözme',
    'Sayı Kesir Problemleri',
    'Yaş Problemleri',
    'İşçi Emek Problemleri',
    'Yüzde Kar Zarar Problemleri',
    'Karışım Problemleri',
    'Hareket Problemleri',
    'Grafik Problemleri',
    'Rutin Olmayan Problemler',
    'Kümeler',
    'Mantık',
    'Fonksiyonlar',
    'Polinomlar',
    'İkinci Dereceden Denklemler',
    'Karmaşık Sayılar',
    'Permütasyon',
    'Kombinasyon',
    'Binom',
    'Olasılık',
    'Veri - İstatistik'
  ],
  'TYT Geometri': [
    'Doğruda ve Üçgende Açılar',
    'Dik ve Özel Üçgenler',
    'İkizkenar ve Eşkenar Üçgen',
    'Açıortay ve Kenarortay',
    'Üçgende Eşlik ve Benzerlik',
    'Üçgende Alan',
    'Açı Kenar Bağıntıları',
    'Çokgenler',
    'Dörtgenler',
    'Yamuk',
    'Paralelkenar',
    'Eşkenar Dörtgen',
    'Dikdörtgen',
    'Kare',
    'Deltoid',
    'Çemberde Açı',
    'Çemberde Uzunluk',
    'Dairede Alan',
    'Katı Cisimler (Prizma, Piramit)',
    'Noktanın ve Doğrunun Analitiği'
  ],
  'TYT Fizik': [
    'Fizik Bilimine Giriş',
    'Madde ve Özellikleri',
    'Hareket ve Kuvvet',
    'İş, Güç ve Enerji',
    'Isı, Sıcaklık ve Genleşme',
    'Basınç',
    'Kaldırma Kuvveti',
    'Elektrik (Elektrostatik)',
    'Elektrik Akımı ve Devreler',
    'Mıknatıs ve Manyetizma',
    'Dalgalar (Yay, Su, Ses, Deprem)',
    'Optik (Aydınlanma, Gölgeler, Aynalar)',
    'Optik (Kırılma, Mercekler, Renkler)'
  ],
  'TYT Kimya': [
    'Kimya Bilimi',
    'Atom ve Periyodik Sistem',
    'Kimyasal Türler Arası Etkileşimler',
    'Maddenin Halleri',
    'Doğa ve Kimya',
    'Kimyanın Temel Kanunları',
    'Mol Kavramı',
    'Kimyasal Hesaplamalar',
    'Karışımlar',
    'Asitler, Bazlar ve Tuzlar',
    'Kimya Her Yerde'
  ],
  'TYT Biyoloji': [
    'Canlıların Ortak Özellikleri',
    'Canlıların Temel Bileşenleri',
    'Hücre ve Organeller',
    'Madde Geçişleri',
    'Canlıların Sınıflandırılması',
    'Hücre Bölünmeleri (Mitoz - Mayoz)',
    'Kalıtım',
    'Ekosistem Ekolojisi',
    'Güncel Çevre Sorunları'
  ],
  'TYT Tarih': [
    'Tarih Bilimi',
    'İlk Çağ Uygarlıkları',
    'İlk Türk Devletleri',
    'İslam Tarihi ve Uygarlığı',
    'Türk İslam Devletleri',
    'Türkiye Tarihi',
    'Beylikten Devlete (Osmanlı)',
    'Dünya Gücü Osmanlı',
    'Osmanlı Kültür ve Medeniyeti',
    'Değişim Çağında Avrupa ve Osmanlı',
    'Uluslararası İlişkilerde Denge Stratejisi',
    'XX. Yüzyıl Başlarında Osmanlı',
    'Milli Mücadele Hazırlık Dönemi',
    'Milli Mücadele Muharebeler Dönemi',
    'Atatürkçülük ve Türk İnkılabı'
  ],
  'TYT Coğrafya': [
    'Doğa ve İnsan',
    'Dünya\'nın Şekli ve Hareketleri',
    'Coğrafi Konum',
    'Harita Bilgisi',
    'İklim Bilgisi',
    'Yerin Şekillenmesi (İç ve Dış Kuvvetler)',
    'Su, Toprak ve Bitki',
    'Nüfus ve Yerleşme',
    'Ekonomik Faaliyetler',
    'Bölgeler ve Ülkeler',
    'Doğal Afetler',
    'Çevre ve Toplum'
  ],
  'TYT Felsefe': [
    'Felsefeyi Tanıyalım',
    'Felsefe ile Düşünme',
    'Varlık Felsefesi',
    'Bilgi Felsefesi',
    'Bilim Felsefesi',
    'Ahlak Felsefesi',
    'Din Felsefesi',
    'Siyaset Felsefesi',
    'Sanat Felsefesi'
  ],
  'TYT Din': [
    'Bilgi ve İnanç',
    'Din ve İslam',
    'İslam ve İbadet',
    'Gençlik ve Değerler',
    'Allah İnsan İlişkisi',
    'Hz. Muhammed (S.A.V)',
    'Vahiy ve Akıl',
    'Ahlaki Tutum ve Davranışlar',
    'İslam Düşüncesinde Yorumlar',
    'Din, Kültür ve Medeniyet'
  ]
};

// AYT Konuları (Full Listesi)
const Map<String, List<String>> aytMufredati = {
  'AYT Matematik': [
    'Fonksiyonlar (II. Bölüm)',
    'Polinomlar',
    'İkinci Dereceden Denklemler',
    'Karmaşık Sayılar (II. Bölüm)',
    'İkinci Dereceden Eşitsizlikler',
    'Parabol',
    'Trigonometri',
    'Logaritma',
    'Diziler',
    'Limit ve Süreklilik',
    'Türev',
    'İntegral',
    'Sayma ve Olasılık (II. Bölüm)'
  ],
  'AYT Geometri': [
    'Doğruda ve Üçgende Açılar',
    'Dik ve Özel Üçgenler',
    'Üçgende Benzerlik ve Eşlik',
    'Üçgende Alan',
    'Çokgenler ve Dörtgenler',
    'Yamuk ve Paralelkenar',
    'Eşkenar Dörtgen, Dikdörtgen, Kare ve Deltoid',
    'Çemberde Açılar ve Uzunluk',
    'Dairede Alan',
    'Noktanın Analitik İncelenmesi',
    'Doğrunun Analitik İncelenmesi',
    'Dönüşüm Geometrisi',
    'Katı Cisimler (Prizma, Piramit, Silindir, Koni, Küre)',
    'Çemberin Analitik İncelenmesi'
  ],
  'AYT Fizik': [
    'Vektörler',
    'Bağıl Hareket',
    'Newton\'un Hareket Yasaları',
    'Bir Boyutta Sabit İvmeli Hareket',
    'İki Boyutta Hareket (Atışlar)',
    'Enerji ve Hareket',
    'İtme ve Momentum',
    'Tork ve Denge',
    'Kütle ve Ağırlık Merkezi',
    'Basit Makineler',
    'Elektriksel Kuvvet ve Alan',
    'Elektriksel Potansiyel',
    'Düzgün Elektrik Alan ve Sığa',
    'Manyetizma ve Elektromanyetik İndüklenme',
    'Alternatif Akım ve Transformatörler',
    'Çembersel Hareket',
    'Basit Harmonik Hareket',
    'Dalga Mekaniği',
    'Atom Fiziğine Giriş ve Radyoaktivite',
    'Modern Fizik',
    'Modern Fiziğin Teknolojideki Uygulamaları'
  ],
  'AYT Kimya': [
    'Modern Atom Teorisi',
    'Gazlar',
    'Sıvı Çözeltiler ve Çözünürlük',
    'Kimyasal Tepkimelerde Enerji',
    'Kimyasal Tepkimelerde Hız',
    'Kimyasal Tepkimelerde Denge',
    'Asit ve Baz Dengeleri',
    'Çözünürlük Dengesi (Kçç)',
    'Kimya ve Elektrik',
    'Karbon Kimyasına Giriş',
    'Organik Bileşikler',
    'Enerji Kaynakları ve Bilimsel Gelişmeler'
  ],
  'AYT Biyoloji': [
    'Sinir Sistemi',
    'Endokrin Sistem',
    'Duyu Organları',
    'Destek ve Hareket Sistemi',
    'Sindirim Sistemi',
    'Dolaşım Sistemi',
    'Bağışıklık Sistemi',
    'Solunum Sistemi',
    'Üriner Sistem',
    'Üreme Sistemi ve Embriyonik Gelişim',
    'Komünite ve Popülasyon Ekolojisi',
    'Nükleik Asitler (DNA-RNA)',
    'Genden Proteine (Protein Sentezi)',
    'Canlılık ve Enerji (ATP - Fotosentez - Kemosentez - Solunum)',
    'Bitki Biyolojisi',
    'Canlılar ve Çevre'
  ],
  'AYT Edebiyat': [
    'Güzel Sanatlar ve Edebiyat',
    'Coşku ve Heyecanı Dile Getiren Metinler (Şiir)',
    'Olay Çevresinde Oluşan Edebi Metinler',
    'Öğretici Metinler',
    'İslamiyet Öncesi Türk Edebiyatı',
    'Geçiş Dönemi Türk Edebiyatı',
    'Halk Edebiyatı',
    'Divan Edebiyatı',
    'Tanzimat Edebiyatı',
    'Servet-i Fünun Edebiyatı',
    'Fecr-i Ati Edebiyatı',
    'Milli Edebiyat Dönemi',
    'Cumhuriyet Dönemi Türk Edebiyatı',
    'Batı Edebiyatı ve Akımlar'
  ],
  'AYT Tarih-1': [
    'Tarih Bilimi',
    'İlk Çağ Uygarlıkları',
    'İlk Türk Devletleri',
    'İslam Tarihi ve Uygarlığı',
    'Türk İslam Devletleri',
    'Türkiye Tarihi',
    'Beylikten Devlete (Osmanlı)',
    'Dünya Gücü Osmanlı',
    'Değişim Çağında Avrupa ve Osmanlı',
    'XX. Yüzyıl Başlarında Osmanlı',
    'Milli Mücadele',
    'Atatürkçülük ve Türk İnkılabı',
    'Atatürk Dönemi Dış Politika'
  ],
  'AYT Coğrafya-1': [
    'Biyoçeşitlilik',
    'Ekosistemlerin İşleyişi',
    'Madde Döngüleri ve Enerji Akışı',
    'Ekstrem Doğa Olayları',
    'Geleceğin Dünyası (Nüfus Politikaları)',
    'Şehirlerin Fonksiyonları',
    'Türkiye\'de Tarım ve Hayvancılık',
    'Türkiye\'de Madenler ve Enerji Kaynakları',
    'Türkiye\'de Sanayi, Ulaşım, Ticaret, Turizm',
    'Bölgeler ve Ülkeler (Jeopolitik Konum)',
    'Çevre ve Toplum (Küresel Isınma)'
  ],
  'AYT Tarih-2': [
    'Tarih Bilimi',
    'İlk Çağ Uygarlıkları',
    'İlk Türk Devletleri',
    'İslam Tarihi ve Uygarlığı',
    'Türk İslam Devletleri',
    'Türkiye Tarihi',
    'Beylikten Devlete (Osmanlı)',
    'Dünya Gücü Osmanlı',
    'Değişim Çağında Avrupa ve Osmanlı',
    'XX. Yüzyıl Başlarında Osmanlı',
    'Milli Mücadele',
    'Atatürkçülük ve Türk İnkılabı',
    'Atatürk Dönemi Dış Politika',
    'Çağdaş Türk ve Dünya Tarihi',
    'Yumuşama Dönemi ve Sonrası',
    'Küreselleşen Dünya'
  ],
  'AYT Coğrafya-2': [
    'Biyoçeşitlilik',
    'Ekosistem',
    'Madde Döngüleri',
    'Nüfus Politikaları',
    'Türkiye\'de Nüfus ve Yerleşme',
    'Türkiye\'nin Ekonomik Coğrafyası',
    'Türkiye\'de Tarım, Hayvancılık, Orman',
    'Türkiye\'de Madenler ve Enerji',
    'Türkiye\'de Sanayi ve Ticaret',
    'Türkiye\'de Ulaşım',
    'Türkiye\'de Turizm',
    'Uluslararası Örgütler',
    'Çevre ve Toplum',
    'Ülkeler Arası Etkileşim'
  ],
  'AYT Felsefe Grubu': [
    'Psikoloji Bilimini Tanıyalım',
    'Psikolojinin Temel Süreçleri',
    'Öğrenme, Bellek, Düşünme',
    'Ruh Sağlığı',
    'Sosyolojiye Giriş',
    'Birey ve Toplum',
    'Toplumsal Yapı ve Değişme',
    'Toplumsal Kurumlar',
    'Kültür ve Toplum',
    'Mantığa Giriş',
    'Klasik Mantık',
    'Mantık ve Dil',
    'Sembolik Mantık'
  ],
  'AYT Din': [
    'Dünya ve Ahiret',
    'Kur\'an\'a Göre Hz. Muhammed',
    'Kur\'an\'da Bazı Kavramlar',
    'İnançla İlgili Meseleler',
    'Yahudilik ve Hristiyanlık',
    'İslam ve Bilim',
    'Anadolu\'da İslam',
    'İslam Düşüncesinde Tasavvufi Yorumlar',
    'Güncel Dini Meseleler',
    'Hint ve Çin Dinleri'
  ],
  'YDT İngilizce': [
    'Kelime Bilgisi (Vocabulary)',
    'Dilbilgisi (Grammar)',
    'Cloze Test',
    'Cümle Tamamlama (Sentence Completion)',
    'İngilizce-Türkçe Çeviri',
    'Türkçe-İngilizce Çeviri',
    'Paragraf (Okuma-Anlama)',
    'Diyalog Tamamlama',
    'Anlamca Yakın Cümle (Restatement)',
    'Paragraf Tamamlama',
    'Duruma Uygun İfade (Situational)',
    'Anlam Akışını Bozan Cümle (Irrelevant)'
  ],

  // ALIASES (Eşleşme garantisi için)
  'Din (AYT)': [
    'Dünya ve Ahiret',
    'Kur\'an\'a Göre Hz. Muhammed',
    'Kur\'an\'da Bazı Kavramlar',
    'İnançla İlgili Meseleler',
    'Yahudilik ve Hristiyanlık',
    'İslam ve Bilim',
    'Anadolu\'da İslam',
    'İslam Düşüncesinde Tasavvufi Yorumlar',
    'Güncel Dini Meseleler',
    'Hint ve Çin Dinleri'
  ],
  'Felsefe Grubu': [
    'Psikoloji Bilimini Tanıyalım',
    'Psikolojinin Temel Süreçleri',
    'Öğrenme, Bellek, Düşünme',
    'Ruh Sağlığı',
    'Sosyolojiye Giriş',
    'Birey ve Toplum',
    'Toplumsal Yapı ve Değişme',
    'Toplumsal Kurumlar',
    'Kültür ve Toplum',
    'Mantığa Giriş',
    'Klasik Mantık',
    'Mantık ve Dil',
    'Sembolik Mantık'
  ],
  'Tarih-2': [
    'Tarih Bilimi',
    'İlk Çağ Uygarlıkları',
    'İlk Türk Devletleri',
    'İslam Tarihi ve Uygarlığı',
    'Türk İslam Devletleri',
    'Türkiye Tarihi',
    'Beylikten Devlete (Osmanlı)',
    'Dünya Gücü Osmanlı',
    'Değişim Çağında Avrupa ve Osmanlı',
    'XX. Yüzyıl Başlarında Osmanlı',
    'Milli Mücadele',
    'Atatürkçülük ve Türk İnkılabı',
    'Atatürk Dönemi Dış Politika',
    ' Çağdaş Türk ve Dünya Tarihi', // Fixed space
    'Yumuşama Dönemi ve Sonrası',
    'Küreselleşen Dünya'
  ],
  'Coğrafya-2': [
    'Biyoçeşitlilik',
    'Ekosistem',
    'Madde Döngüleri',
    'Nüfus Politikaları',
    'Türkiye\'de Nüfus ve Yerleşme',
    'Türkiye\'nin Ekonomik Coğrafyası',
    'Türkiye\'de Tarım, Hayvancılık, Orman',
    'Türkiye\'de Madenler ve Enerji',
    'Türkiye\'de Sanayi ve Ticaret',
    'Türkiye\'de Ulaşım',
    'Türkiye\'de Turizm',
    'Uluslararası Örgütler',
    'Çevre ve Toplum',
    'Ülkeler Arası Etkileşim'
  ]
};

// Renkler ve Durumlar
const durumRenkleri = {
  "Yapılacak": Color(0xFFEF5350), // Red 400
  "Çalışılıyor": Color(0xFF42A5F5), // Blue 400
  "Tekrar": Color(0xFFFFCA28), // Amber 400
  "Bitti": Color(0xFF66BB6A), // Green 400
};

const durumYazilari = {
  "Yapılacak": "Başlanmadı",
  "Çalışılıyor": "Devam Ediyor",
  "Tekrar": "Tekrar Lazım",
  "Bitti": "Tamamlandı"
};

// KAYNAK ÖNERİLERİ
const Map<String, List<String>> dersBazliKaynaklar = {
  // TYT
  'TYT Türkçe': [
    '345 Yayınları',
    'Bilgi Sarmal',
    'Limit Yayınları',
    'Paraf Yayınları',
    'Rüştü Hoca',
    'Kadir Gümüş (Benim Hocam)',
    'Hız ve Renk',
    'Aker Kartal',
    'Öznur Saat Yıldırım',
    'Yayın Denizi'
  ],
  'TYT Matematik': [
    '345 Yayınları',
    'Acil Matematik',
    'Orijinal Yayınları',
    'Bilgi Sarmal',
    'Karekök Yayınları',
    'Mert Hoca',
    'Rehber Matematik',
    'Bıyıklı Matematik',
    'Eyüp B.',
    'Barış Çelenk',
    '3D Yayınları',
    'Metin Yayınları',
    'Toprak Yayınları',
    'Çap Yayınları'
  ],
  'TYT Geometri': [
    'Kenan Kara ile Geometri',
    'Orijinal Geometri',
    'Acil Geometri',
    'Birey B Geometri',
    '345 Geometri',
    'Bilgi Sarmal Geometri',
    'Karekök',
    'Mert Hoca',
    'Nurtaç Hoca',
    'Eyüp B Geometri',
    '3D Geometri'
  ],
  'TYT Fizik': [
    '345 Yayınları',
    'Nihat Bilgin',
    'VIP Fizik',
    'Ertan Sinan Şahin',
    'Altuğ Güneş',
    'Özcan Aykın',
    'Hız ve Renk',
    'Palme',
    'Karaağaç',
    'Bilgi Sarmal'
  ],
  'TYT Kimya': [
    'Görkem Şahin (Benim Hocam)',
    'Aydın Yayınları',
    'Palme Yayınları',
    'Orbital Yayınları',
    'Kimya Adası',
    'Ferrum',
    'Miray Yayınları',
    '345 Kimya',
    'Bilgi Sarmal'
  ],
  'TYT Biyoloji': [
    'Dr. Biyoloji',
    'Selin Hoca',
    'Palme Yayınları',
    'Biyotik Yayınları',
    'Senin Biyolojin (Aras Hoca)',
    'Biosem',
    'Betül Biyoloji',
    'Fundamentals Biyoloji',
    'Hız ve Renk',
    '345 Biyoloji'
  ],
  'TYT Tarih': [
    'Ramazan Yetgin (Benim Hocam)',
    'Saadettin Akyayla',
    'Hız ve Renk',
    'Limit El Kitabı',
    'Selami Yalçın',
    'Aydın Yüce',
    'Karekök'
  ],
  'TYT Coğrafya': [
    'Coğrafyanın Kodları (Yunus Hoca)',
    'Yavuz Tuna',
    'Bayram Meral',
    'Limit El Kitabı',
    'Hız ve Renk',
    'Bilgi Sarmal'
  ],
  'TYT Felsefe': ['Semih Hoca', 'Felsefe Atölyesi', 'Limit El Kitabı'],
  'TYT Din': ['Caner Taslaman (Ref)', 'Benim Hocam', 'Özet Kitapçık'],

  // AYT
  'AYT Matematik': [
    'Orijinal Fasiküller',
    'Apotemi Fasiküller',
    'Eyüp B.',
    'Barış Çelenk',
    'Mert Hoca',
    'Rehber Matematik',
    '3D AYT',
    '345 AYT',
    'Acil AYT',
    'Bilgi Sarmal',
    'Karekök Zoru Bankası'
  ],
  'AYT Geometri': [
    'Kenan Kara',
    'Mert Hoca Geometri',
    'Eyüp B. Geometri',
    'Orijinal AYT Geometri',
    'Apotemi Maraton',
    '3D AYT Geometri',
    'Acil Geometri'
  ],
  'AYT Fizik': [
    'Özcan Aykın',
    'VIP Fizik',
    'Ertan Sinan Şahin (ESŞ)',
    'Aydın Fasikül',
    'Nihat Bilgin',
    'Karaağaç',
    '345 AYT Fizik',
    'Palme'
  ],
  'AYT Kimya': [
    'Görkem Şahin',
    'Aydın Yayınları',
    'Orbital',
    'Miray',
    'Palme',
    '345 AYT Kimya',
    'Kimya Adası'
  ],
  'AYT Biyoloji': [
    'Dr. Biyoloji',
    'Selin Hoca',
    'Biosem',
    'Betül Biyoloji',
    'Senin Biyolojin',
    'Biyotik',
    'Palme',
    'Apotemi Sistemler'
  ],
  'AYT Edebiyat': [
    'Kadir Gümüş',
    'Rüştü Hoca',
    'Limit Edebiyat',
    'Yayın Denizi',
    'Bilgi Sarmal',
    'Hız ve Renk'
  ],
  'AYT Tarih': ['Ramazan Yetgin', 'Tarih Sepeti', 'Aydın Yüce'],
  'AYT Coğrafya': ['Coğrafyanın Kodları', 'Yavuz Tuna', 'Bayram Meral'],
  'AYT Felsefe Grubu': ['Felsefe Atölyesi', 'Limit El Kitabı', 'Eis Yayınları'],
  'AYT Din': ['Benim Hocam', 'Limit', 'Diyanet Meali (Ref)'],
  'YDT İngilizce': [
    'Dilko',
    'Akın Dil',
    'Modadil',
    'PELTM',
    'Suat Gürcan',
    'Rıdvan Gürbüz',
    'Hız ve Renk YDT',
    'Yargı',
    'İrem Yayınları'
  ],

  'Genel': [
    '3D Türkiye Geneli',
    'Özdebir',
    'Töder',
    'Limit',
    'Bilgi Sarmal',
    'Toprak Yayınları',
    'Paraf',
    'Kraker',
    'Altın Karma',
    'Endemik'
  ]
};

// ÖNEMLİ KONULAR SÖZLÜĞÜ - KIRMIZI (ÇOK SIK) / MAVİ (DÜZENLİ)
const Map<String, List<String>> onemliKonular = {
  'Kirmizi': [
    // TYT Türkçe
    'Paragraf', 'Sözcükte Anlam', 'Cümlede Anlam', 'Yazım Kuralları',
    'Noktalama İşaretleri',

    // TYT Mat
    'Problemler', 'Temel Kavramlar', 'Üslü Sayılar', 'Köklü Sayılar',
    'Mutlak Değer',
    'Fonksiyonlar', 'Sayı Basamakları',

    // TYT Geo
    'Üçgenler', 'Dik ve Özel Üçgenler', 'Çokgenler', 'Katı Cisimler',

    // TYT Fen
    'Madde ve Özellikleri', 'Hareket ve Kuvvet', 'Isı, Sıcaklık ve Genleşme',
    'Elektrik', 'Optik',
    'Atom ve Periyodik Sistem', 'Kimyasal Türler Arası Etkileşimler',
    'Maddenin Halleri',
    'Hücre', 'Canlıların Sınıflandırılması', 'Ekosistem Ekolojisi', 'Kalıtım',

    // AYT Mat
    'Limit ve Süreklilik', 'Türev', 'İntegral', 'Trigonometri', 'Logaritma',
    'Diziler',
    'Fonksiyonlar (II. Bölüm)', 'Parabol',

    // AYT Geo
    'Çemberin Analitik İncelenmesi', 'Doğrunun Analitik İncelenmesi',
    'Dönüşüm Geometrisi',

    // AYT Fen
    'Newton\'un Hareket Yasaları', 'Atışlar', 'İtme ve Momentum',
    'Elektriksel Kuvvet ve Alan',
    'Manyetizma ve Elektromanyetik İndüklenme', 'Basit Harmonik Hareket',
    'Modern Fizik',
    'Gazlar', 'Sıvı Çözeltiler ve Çözünürlük', 'Kimyasal Tepkimelerde Hız',
    'Kimyasal Tepkimelerde Denge',
    'Asit ve Baz Dengeleri', 'Elektroliz', 'Organik Bileşikler',
    'Sinir Sistemi', 'Endokrin Sistem', 'Dolaşım Sistemi', 'Solunum Sistemi',
    'Fotosentez - Kemosentez - Solunum', 'Protein Sentezi', 'Bitki Biyolojisi'
  ],
  'Mavi': [
    // TYT Mat
    'Kümeler', 'Mantık', 'Polinomlar', 'Veri - İstatistik', 'Permütasyon',
    'Kombinasyon', 'Olasılık',

    // TYT Fen
    'Basınç', 'Kaldırma Kuvveti', 'Dalgalar',
    'Mol Kavramı', 'Karışımlar', 'Asitler, Bazlar ve Tuzlar',
    'Canlıların Temel Bileşenleri', 'Hücre Bölünmeleri (Mitoz - Mayoz)',

    // AYT Mat
    'İkinci Dereceden Eşitsizlikler', 'Karmaşık Sayılar',

    // AYT Fen
    'Vektörler', 'Bağıl Hareket', 'Tork ve Denge', 'Kütle ve Ağırlık Merkezi',
    'Basit Makineler', 'Alternatif Akım ve Transformatörler',
    'Modern Atom Teorisi', 'Çözünürlük Dengesi (Kçç)', 'Enerji Kaynakları',
    'Duyu Organları', 'Destek ve Hareket Sistemi', 'Sindirim Sistemi',
    'Üriner Sistem', 'Üreme Sistemi', 'Komünite ve Popülasyon Ekolojisi'
  ]
};

// UI Yardımcıları
const Map<String, List<String>> anaBasliklar = {
  'Matematik': ['Sayılar', 'Cebir', 'Geometri'],
  'Fizik': ['Mekanik', 'Elektrik', 'Optik', 'Modern Fizik'],
  'Türkçe': ['Anlam Bilgisi', 'Dil Bilgisi'],
  'Kimya': ['Genel Kimya', 'Organik Kimya'],
  'Biyoloji': ['Hücre ve Organizma', 'Sistemler', 'Ekoloji', 'Genetik'],
  'YDT İngilizce': ['English Skills', 'Grammar', 'Vocabulary']
};

const Map<String, List<String>> konuSinifListesi = {
  // Mat
  'Fonksiyonlar (II. Bölüm)': ['11. Sınıf'],
  'Polinomlar': ['10. Sınıf'],
  'İkinci Dereceden Denklemler': ['10. Sınıf'],
  'Trigonometri': ['11. Sınıf', '12. Sınıf'],
  'Logaritma': ['12. Sınıf'],
  'Diziler': ['12. Sınıf'],
  'Limit ve Süreklilik': ['12. Sınıf'],
  'Türev': ['12. Sınıf'],
  'İntegral': ['12. Sınıf'],
  'Çemberin Analitiği': ['12. Sınıf'],

  // Fizik
  'Vektörler': ['11. Sınıf'],
  'Bağıl Hareket': ['11. Sınıf'],
  'Newton\'un Hareket Yasaları': ['11. Sınıf'],
  'Atışlar': ['11. Sınıf'],
  'İtme ve Momentum': ['11. Sınıf'],
  'Elektriksel Kuvvet ve Alan': ['11. Sınıf'],
  'Manyetizma': ['11. Sınıf'],
  'Çembersel Hareket': ['12. Sınıf'],
  'Basit Harmonik Hareket': ['12. Sınıf'],
  'Dalga Mekaniği': ['12. Sınıf'],
  'Modern Fizik': ['12. Sınıf'],

  // Kimya
  'Modern Atom Teorisi': ['11. Sınıf'],
  'Gazlar': ['11. Sınıf'],
  'Sıvı Çözeltiler': ['11. Sınıf'],
  'Hız ve Denge': ['11. Sınıf'],
  'Kimya ve Elektrik': ['12. Sınıf'],
  'Karbon Kimyası': ['12. Sınıf'],
  'Organik Bileşikler': ['12. Sınıf'],

  // Biyoloji
  'Sinir Sistemi': ['11. Sınıf'],
  'Endokrin Sistem': ['11. Sınıf'],
  'Duyu Organları': ['11. Sınıf'],
  'Destek ve Hareket': ['11. Sınıf'],
  'Sindirim Sistemi': ['11. Sınıf'],
  'Dolaşım Sistemi': ['11. Sınıf'],
  'Solunum Sistemi': ['11. Sınıf'],
  'Üriner Sistem': ['11. Sınıf'],
  'Üreme Sistemi': ['11. Sınıf'],
  'Komünite Ekolojisi': ['11. Sınıf'],
  'Protein Sentezi': ['12. Sınıf'],
  'Canlılık ve Enerji': ['12. Sınıf'],
  'Bitki Biyolojisi': ['12. Sınıf'],
};
