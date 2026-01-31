const Map<String, Map<String, String>> errorCategories = {
  'Dikkat ve Okuma Hataları': {
    'İşlem Hatası':
        "Kalemini kullan, zihnini değil! Basit toplama çıkarmaları bile zihinden yapmaya çalışmak sınav stresinde seni yanıltır. Her adımı kağıda dökersen hatayı gözünle yakalarsın.",
    'Soru Kökünü Yanlış Okuma':
        "Sorunun son kelimesi kaderini belirler. 'Değildir', 'Kesinlikle', 'Sadece' gibi ifadelerin altını mutlaka çiz. Beynin olumsuzu olumlu okumaya meyillidir, buna izin verme.",
    'Veriyi Görmeme':
        "Soru sadece metinden ibaret değildir. Grafiğin eksenlerine, tablonun dipnotlarına veya parantez içi bilgilere dikkat et. Cevap bazen o küçük detayda saklıdır.",
    'Şıkları Yanlış Okuma':
        "Acele edip A şıkkına atlama. ÖSYM güçlü çeldiricileri genelde ilk şıklara koyar. Cevap A gibi görünse bile E şıkkına kadar hepsini okumadan işaretleme yapma.",
    'Optik/İşaretleme Hatası':
        "Bu en acı verici hata. Soruyu kitapçıkta çözdükten sonra optiğe geçirirken numarasını kontrol et. Toplu işaretleme yapma, '1 Soru - 1 İşaretleme' kuralını uygula.",
  },
  'Bilgi ve Kavrama Eksikliği': {
    'Konu Eksiği':
        "Bu soruyu çözmek için gereken temel bilgiye henüz sahip değilsin. Üzülme, eksiği bulmak da bir kazançtır. Bu konuyu 'Acil Çalışılacaklar' listene ekle ve konu anlatımına dön.",
    'Formül/Kural Hatırlayamama':
        "Bilgi hafızanda var ama geri çağıramadın. Bu formülü hemen küçük bir not kağıdına yaz ve masana yapıştır. Bir hafta boyunca gözünün önünde dursun.",
    'Kavram Yanılgısı':
        "Bir şeyi biliyorsun ama yanlış biliyorsun. Bu, bilmemekten daha tehlikelidir. Konu özetine dön ve bu kavramın tam tanımını MEB kitabından teyit et.",
    'Yorum Hatası':
        "Bilgiyi bilsen de soruya uyarlarken mantık hatası yaptın. Daha fazla 'Yeni Nesil' soru tipi görmen lazım. Soru çözüm videoları izleyerek hocaların bakış açısını kapmaya çalış.",
  },
  'Strateji ve Psikoloji': {
    'Süre Yetmedi':
        "Zaman yönetimi de bir derstir. Bir soruyla 2 dakikadan fazla inatlaşma. Yapamadıysan yanına işaret koy ve geç (Turlama Taktiği).",
    'İki Şık Arasında Kalma':
        "Genellikle ilk hissettiğin cevap doğrudur. Eğer somut bir kanıtın yoksa, son saniyede şıkkını değiştirme. İki şıkka indirdiysen konuyu biliyorsundur, kendine güven.",
    'Emin Olmadan İşaretleme':
        "Unutma: 4 yanlış 1 doğruyu götürür ama boş soru hiçbir şeyi götürmez. Emin değilsen boş bırakmak, yanlış yapmaktan daha büyük bir stratejik hamledir.",
    'Odaklanma Sorunu':
        "Zihnin yorulmuş. Uzun paragraf soruları aslında en kolayıdır çünkü cevap içindedir. Derin bir nefes al, duruşunu dikleştir ve soruya tekrar odaklan.",
    'İnatlaşma':
        "Soruyla kavga edilmez. O an çözemiyorsan beynin o soruya körleşmiş demektir. Soruyu geç, döndüğünde daha kolay çözeceksin.",
  }
};
