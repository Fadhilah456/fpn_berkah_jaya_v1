class AppConfig {
  static const String version = "3.2.0";
  static const String namaToko = "FPN AUTO PARTS";
  static const String alamatToko = "BANDUNG";
  static const String kotaToko = "BANDUNG";
  static const String telpToko = "081382743463";
  static const List<String> footerToko = ["Terimakasih Sudah Berbelanja", "Di FPN AUTO PARTS"];
 
  static const int lebarKarakter = 32;
  static const String password = "CIMAHIENJOY";
  static const String passwordToko = "TOKO123";
  static const String secret = "MUHAMAD FADILAH GANTENG KALEM 029";

  // SPBU default (akan di-override oleh SharedPreferences jika ada)
  static const List<Map<String, String>> defaultDaftarSpbu = [
    {
      "kode": "3440520",
      "nama": "SPBU RAYA BARAT CIMAHI",
      "alamat": "JL. RAYA BARAT CIMAHI",
      "harga": "14874",
    }
  ];
}