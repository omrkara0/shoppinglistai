class Urun {
  final String isim;
  final double miktar;
  final String miktarTuru;

  Urun({
    required this.isim,
    required this.miktar,
    required this.miktarTuru,
  });

  factory Urun.fromMap(Map<String, dynamic> map) {
    return Urun(
      isim: map['isim'] as String,
      miktar: (map['miktar'] as num).toDouble(),
      miktarTuru: map['miktarTuru'] as String,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'isim': isim,
      'miktar': miktar,
      'miktarTuru': miktarTuru,
    };
  }
}
