const Map<String, List<String>> breakdownMap = {
  // TYT
  'TYT Sosyal': ['Tarih', 'Coğrafya', 'Felsefe', 'Din'],
  'TYT Matematik': ['Sadece Matematik', 'Geometri'], // Updated: Split logic
  'TYT Fen': ['Fizik', 'Kimya', 'Biyoloji'],

  // AYT
  'AYT Matematik': ['Sadece Matematik (AYT)', 'Geometri (AYT)'],
  'AYT Sosyal 1': ['Edebiyat', 'Tarih-1', 'Coğrafya-1'],
  'AYT Sosyal 2': ['Tarih-2', 'Coğrafya-2', 'Felsefe Grubu', 'Din (AYT)'],
  'AYT Fen Bilimleri': ['AYT Fizik', 'AYT Kimya', 'AYT Biyoloji'],

  // Handling naming variance for AYT Fen:
  'AYT Fen': ['AYT Fizik', 'AYT Kimya', 'AYT Biyoloji'],
};
