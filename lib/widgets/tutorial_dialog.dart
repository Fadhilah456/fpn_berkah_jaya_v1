import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TutorialDialog extends StatefulWidget {
  const TutorialDialog({super.key});

  @override
  State<TutorialDialog> createState() => _TutorialDialogState();
}

class _TutorialDialogState extends State<TutorialDialog> {
  int _currentPage = 0;
  final PageController _pageController = PageController();

  final List<Map<String, String>> _tutorialSteps = [
    {
      'icon': '🔒',
      'title': '1. Aktivasi & Login',
      'desc': 'Salin ID Perangkat dan kirim ke admin untuk mendapatkan kode aktivasi. Setelah aktif, masukkan password utama untuk masuk.'
    },
    {
      'icon': '⛽',
      'title': '2. Bon BBM',
      'desc': 'Pilih SPBU, isi volume dan nominal. Aplikasi akan otomatis menghitung subsidi. Klik "Simpan & Cetak" untuk melihat preview.'
    },
    {
      'icon': '🛒',
      'title': '3. Struk Toko',
      'desc': 'Masukkan nama barang, harga, dan jumlah. Klik tombol "+" untuk menambah. Total akan dihitung otomatis. Masukkan password khusus untuk mengakses menu ini.'
    },
    {
      'icon': '⚙️',
      'title': '4. Pengaturan',
      'desc': 'Atur printer Bluetooth, aktifkan/nonaktifkan logo, ubah harga non-subsidi, dan lihat riwayat file bon/struk yang pernah dibuat.'
    }
  ];

  Future<void> _markAsSeen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('has_seen_tutorial', true);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('👋 Selamat Datang!', textAlign: TextAlign.center),
      content: SizedBox(
        width: double.maxFinite,
        height: 250,
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) => setState(() => _currentPage = index),
                itemCount: _tutorialSteps.length,
                itemBuilder: (context, index) {
                  final step = _tutorialSteps[index];
                  return Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(step['icon']!, style: const TextStyle(fontSize: 48)),
                      const SizedBox(height: 16),
                      Text(step['title']!, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Text(step['desc']!, textAlign: TextAlign.center, style: const TextStyle(fontSize: 14, color: Colors.black87)),
                    ],
                  );
                },
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _tutorialSteps.length,
                (index) => Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _currentPage == index ? Colors.blue : Colors.grey,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            _markAsSeen();
            Navigator.of(context).pop();
          },
          child: const Text('Lewati'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_currentPage < _tutorialSteps.length - 1) {
              _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
            } else {
              _markAsSeen();
              Navigator.of(context).pop();
            }
          },
          child: Text(_currentPage == _tutorialSteps.length - 1 ? 'Mengerti!' : 'Lanjut'),
        ),
      ],
    );
  }
}