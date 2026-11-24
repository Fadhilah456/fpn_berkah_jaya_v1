import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'dart:convert';
import 'config.dart';
import 'utils.dart';
import 'services/printer_service.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FPN BERKAH JAYA',
      theme: ThemeData(primarySwatch: Colors.blue, useMaterial3: true),
      home: const StartupScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

// ==================== STARTUP SCREEN ====================
class StartupScreen extends StatefulWidget {
  const StartupScreen({super.key});

  @override
  State<StartupScreen> createState() => _StartupScreenState();
}

class _StartupScreenState extends State<StartupScreen> {
  @override
  void initState() {
    super.initState();
    _checkActivation();
  }

  Future<void> _checkActivation() async {
    final prefs = await SharedPreferences.getInstance();
    final isActivated = prefs.getBool('is_activated') ?? false;
    if (!isActivated) {
      if (mounted) {
        final result = await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (context) => const ActivationDialog(),
        );
        if (result == true) {
          _showLogin();
        } else {
          SystemNavigator.pop();
        }
      }
    } else {
      _showLogin();
    }
  }

  Future<void> _showLogin() async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => const LoginDialog(),
    );
    if (result == true && mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const MainScreen()),
      );
    } else {
      SystemNavigator.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}

// ==================== ACTIVATION DIALOG ====================
class ActivationDialog extends StatefulWidget {
  const ActivationDialog({super.key});

  @override
  State<ActivationDialog> createState() => _ActivationDialogState();
}

class _ActivationDialogState extends State<ActivationDialog> {
  final TextEditingController _codeController = TextEditingController();
  String _machineId = "Memuat...";
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMachineId();
  }

  Future<void> _loadMachineId() async {
    final id = await getMachineId();
    if (mounted) {
      setState(() {
        _machineId = id;
        _isLoading = false;
      });
    }
  }

  Future<void> _verify() async {
    final correctCode = generateActivationCode(_machineId).replaceAll('-', '');
    final inputCode = _codeController.text.trim().replaceAll('-', '').toUpperCase();
   
    if (inputCode == correctCode) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('is_activated', true);
      if (mounted) Navigator.of(context).pop(true);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Kode aktivasi salah!')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('🔒 AKTIVASI APLIKASI', textAlign: TextAlign.center),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Aplikasi ini perlu diaktivasi sekali saja di perangkat ini.'),
            const SizedBox(height: 16),
            Row(
              children: [
                const Text('ID Perangkat: '),
                Expanded(
                  child: Text(_isLoading ? "Memuat..." : _machineId, style: const TextStyle(fontWeight: FontWeight.bold)),
                ),
                IconButton(
                  icon: const Icon(Icons.copy),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: _machineId));
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('ID Perangkat disalin!')));
                  },
                )
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _codeController,
              decoration: const InputDecoration(labelText: 'Kode Aktivasi', border: OutlineInputBorder()),
              textCapitalization: TextCapitalization.characters,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Batal')),
        ElevatedButton(onPressed: _verify, child: const Text('Verifikasi & Aktifkan')),
      ],
    );
  }
}

// ==================== LOGIN DIALOG ====================
class LoginDialog extends StatefulWidget {
  const LoginDialog({super.key});

  @override
  State<LoginDialog> createState() => _LoginDialogState();
}

class _LoginDialogState extends State<LoginDialog> {
  final TextEditingController _passwordController = TextEditingController();

  void _checkPassword() {
    if (_passwordController.text == AppConfig.password) {
      Navigator.of(context).pop(true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password salah!')));
      _passwordController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('LOGIN APLIKASI', textAlign: TextAlign.center),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Masukkan password untuk masuk'),
          const SizedBox(height: 16),
          TextField(
            controller: _passwordController,
            obscureText: true,
            decoration: const InputDecoration(labelText: 'Password', border: OutlineInputBorder()),
            onSubmitted: (_) => _checkPassword(),
          ),
        ],
      ),
      actions: [ElevatedButton(onPressed: _checkPassword, child: const Text('Masuk'))],
    );
  }
}

// ==================== MAIN SCREEN ====================
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  final List<Widget> _pages = const [BbmScreen(), TokoScreen(), SettingsScreen()];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          if (index == 1) {
            _showTokoPassword(index);
          } else {
            setState(() => _currentIndex = index);
          }
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.local_gas_station), label: 'Bon BBM'),
          BottomNavigationBarItem(icon: Icon(Icons.shopping_cart), label: 'Struk Toko'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Pengaturan'),
        ],
      ),
    );
  }

  Future<void> _showTokoPassword(int targetIndex) async {
    final controller = TextEditingController();
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Password Struk Toko'),
        content: TextField(
          controller: controller,
          obscureText: true,
          decoration: const InputDecoration(labelText: 'Password'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () {
              if (controller.text == AppConfig.passwordToko) {
                Navigator.pop(context, true);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password salah!')));
              }
            },
            child: const Text('Masuk'),
          ),
        ],
      ),
    );
    if (result == true && mounted) {
      setState(() => _currentIndex = targetIndex);
    }
  }
}

// ==================== BBM SCREEN ====================
class BbmScreen extends StatefulWidget {
  const BbmScreen({super.key});

  @override
  State<BbmScreen> createState() => _BbmScreenState();
}

class _BbmScreenState extends State<BbmScreen> {
  final _noTransController = TextEditingController(text: "0000000");
  final _tanggalController = TextEditingController();
  final _jamController = TextEditingController();
  final _shiftController = TextEditingController(text: "1");
  final _pompaController = TextEditingController(text: "18");
  final _operatorController = TextEditingController(text: "LUTHFI");
  final _jenisController = TextEditingController(text: "PERTALITE");
  final _volController = TextEditingController();
  final _nomController = TextEditingController();
  String _selectedSpbuKode = "";
  List<Map<String, String>> _daftarSpbu = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tanggalController.text = nowDateStr();
    _jamController.text = nowTimeStr();
    _loadSpbu();
  }

  Future<void> _loadSpbu() async {
    final prefs = await SharedPreferences.getInstance();
    final savedSpbu = prefs.getStringList('daftar_spbu');
   
    setState(() {
      if (savedSpbu != null && savedSpbu.isNotEmpty) {
        _daftarSpbu = savedSpbu.map((s) {
          final parts = s.split('|');
          return {'kode': parts[0], 'nama': parts[1], 'alamat': parts[2], 'harga': parts[3]};
        }).toList();
      } else {
        _daftarSpbu = List<Map<String, String>>.from(AppConfig.defaultDaftarSpbu);
      }
     
      if (_daftarSpbu.isNotEmpty) {
        _selectedSpbuKode = _daftarSpbu.first['kode']!;
      }
      _isLoading = false;
    });
  }

  Future<void> _saveSpbu() async {
    final prefs = await SharedPreferences.getInstance();
    final spbuList = _daftarSpbu.map((s) => '${s['kode']}|${s['nama']}|${s['alamat']}|${s['harga']}').toList();
    await prefs.setStringList('daftar_spbu', spbuList);
    await prefs.setString('spbu_terpilih', _selectedSpbuKode);
  }

  Map<String, String> get _currentSpbu {
    if (_daftarSpbu.isEmpty) return AppConfig.defaultDaftarSpbu.first;
    return _daftarSpbu.firstWhere((s) => s['kode'] == _selectedSpbuKode, orElse: () => _daftarSpbu.first);
  }

  void _isiWaktuSekarang() {
    setState(() {
      _tanggalController.text = nowDateStr();
      _jamController.text = nowTimeStr();
    });
  }

  void _tambahSpbu() {
    final kodeCtrl = TextEditingController();
    final namaCtrl = TextEditingController();
    final alamatCtrl = TextEditingController();
    final hargaCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('➕ Tambah SPBU Baru'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: kodeCtrl, decoration: const InputDecoration(labelText: 'Kode SPBU', border: OutlineInputBorder())),
              const SizedBox(height: 8),
              TextField(controller: namaCtrl, decoration: const InputDecoration(labelText: 'Nama SPBU', border: OutlineInputBorder())),
              const SizedBox(height: 8),
              TextField(controller: alamatCtrl, decoration: const InputDecoration(labelText: 'Alamat', border: OutlineInputBorder())),
              const SizedBox(height: 8),
              TextField(controller: hargaCtrl, decoration: const InputDecoration(labelText: 'Harga Non-Subsidi', border: OutlineInputBorder()), keyboardType: TextInputType.number),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () {
              if (kodeCtrl.text.isEmpty || namaCtrl.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Kode dan Nama wajib diisi!')));
                return;
              }
              setState(() {
                _daftarSpbu.add({
                  'kode': kodeCtrl.text.trim(),
                  'nama': namaCtrl.text.trim(),
                  'alamat': alamatCtrl.text.trim(),
                  'harga': hargaCtrl.text.trim().replaceAll(RegExp(r'[^0-9]'), ''),
                });
                _selectedSpbuKode = kodeCtrl.text.trim();
              });
              _saveSpbu();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('SPBU berhasil ditambahkan!')));
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  void _hapusSpbu() {
    if (_daftarSpbu.length <= 1) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Minimal harus ada 1 SPBU!')));
      return;
    }
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus SPBU?'),
        content: Text('Yakin ingin menghapus SPBU "${_currentSpbu['nama']}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              setState(() {
                _daftarSpbu.removeWhere((s) => s['kode'] == _selectedSpbuKode);
                _selectedSpbuKode = _daftarSpbu.first['kode']!;
              });
              _saveSpbu();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('SPBU dihapus!')));
            },
            child: const Text('Hapus', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _prosesDanPreview() {
    if (_volController.text.isEmpty || _nomController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Volume dan Nominal wajib diisi!')));
      return;
    }
   
    double vol = double.tryParse(_volController.text.replaceAll(',', '.')) ?? 0;
    int nom = int.tryParse(_nomController.text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
    int hargaNonSub = int.tryParse(_currentSpbu['harga'] ?? '0') ?? 0;

    if (vol == 0 || hargaNonSub == 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Data tidak valid!')));
      return;
    }

    int hargaJual = (nom / vol).round();
    int subLiter = hargaNonSub - hargaJual;
    int tanpaSub = (vol * hargaNonSub).round();
    int totSub = tanpaSub - nom;
    String g = "-" * AppConfig.lebarKarakter;

    String cashLine = "${"CASH".padRight(24)}${fmt(nom).padLeft(8)}";

    String teks = [
      centerText(_selectedSpbuKode, AppConfig.lebarKarakter),
      centerText(_currentSpbu['nama']!, AppConfig.lebarKarakter),
      centerText(_currentSpbu['alamat']!, AppConfig.lebarKarakter),
      "Shift: ${_shiftController.text}   No. Trans: ${_noTransController.text}",
      "Waktu: ${_tanggalController.text} ${_jamController.text}",
      g,
      padRight("Pulau/Pompa  : ${_pompaController.text}", AppConfig.lebarKarakter),
      padRight("Operator     : ${_operatorController.text}", AppConfig.lebarKarakter),
      padRight("Jenis BBM    : ${_jenisController.text}", AppConfig.lebarKarakter),
      padRight("Volume       : ${vol.toStringAsFixed(2)} liter", AppConfig.lebarKarakter),
      g,
      "Informasi Harga BBM (Rp/Liter)",
      padRight("Harga Non Subsidi  : ${fmt(hargaNonSub)}", AppConfig.lebarKarakter),
      padRight("Subsidi Pemerintah : ${fmt(subLiter)}", AppConfig.lebarKarakter),
      padRight("Harga Jual         : ${fmt(hargaJual)}", AppConfig.lebarKarakter),
      g,
      "Total Penjualan (Rp)",
      padRight("Tanpa Subsidi      : ${fmt(tanpaSub)}", AppConfig.lebarKarakter),
      padRight("Subsidi Pemerintah : ${fmt(totSub)}", AppConfig.lebarKarakter),
      padRight("Dibayar Konsumen   : ${fmt(nom)}", AppConfig.lebarKarakter),
      g,
      cashLine,
      g,
      "Anda mendapat subsidi dari",
      "Pemerintah sebesar Rp ${fmt(totSub)}",
      "(Perhitungan Subsidi Unaudited",
      "atau Estimasi). Gunakan BBM",
      "Subsidi secara bijak.",
    ].join('\n');

    showDialog(
      context: context,
      builder: (context) => PreviewDialog(teks: teks, namaFile: "bon_${_noTransController.text}.txt", pakaiLogo: true),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(appBar: AppBar(title: const Text('Input Data Bon BBM')), body: const Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Input Data Bon BBM')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedSpbuKode,
                    decoration: const InputDecoration(labelText: 'Pilih SPBU', border: OutlineInputBorder()),
                    items: _daftarSpbu.map((s) => DropdownMenuItem(value: s['kode'], child: Text("${s['kode']} - ${s['nama']}", overflow: TextOverflow.ellipsis))).toList(),
                    onChanged: (val) => setState(() => _selectedSpbuKode = val!),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(icon: const Icon(Icons.access_time), onPressed: _isiWaktuSekarang, tooltip: 'Isi Waktu Sekarang'),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(onPressed: _tambahSpbu, icon: const Icon(Icons.add), label: const Text('Tambah SPBU'), style: ElevatedButton.styleFrom(backgroundColor: Colors.blue)),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(onPressed: _hapusSpbu, icon: const Icon(Icons.delete), label: const Text('Hapus SPBU'), style: ElevatedButton.styleFrom(backgroundColor: Colors.red)),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(controller: _noTransController, decoration: const InputDecoration(labelText: 'No. Transaksi', border: OutlineInputBorder())),
            const SizedBox(height: 8),
            TextField(controller: _tanggalController, decoration: const InputDecoration(labelText: 'Tanggal', border: OutlineInputBorder())),
            const SizedBox(height: 8),
            TextField(controller: _jamController, decoration: const InputDecoration(labelText: 'Jam', border: OutlineInputBorder())),
            const SizedBox(height: 8),
            TextField(controller: _shiftController, decoration: const InputDecoration(labelText: 'Shift', border: OutlineInputBorder())),
            const SizedBox(height: 8),
            TextField(controller: _pompaController, decoration: const InputDecoration(labelText: 'Pulau/Pompa', border: OutlineInputBorder())),
            const SizedBox(height: 8),
            TextField(controller: _operatorController, decoration: const InputDecoration(labelText: 'Operator', border: OutlineInputBorder())),
            const SizedBox(height: 8),
            TextField(controller: _jenisController, decoration: const InputDecoration(labelText: 'Jenis BBM', border: OutlineInputBorder())),
            const SizedBox(height: 8),
            TextField(controller: _volController, decoration: const InputDecoration(labelText: 'Volume (Liter)', border: OutlineInputBorder()), keyboardType: const TextInputType.numberWithOptions(decimal: true)),
            const SizedBox(height: 8),
            TextField(controller: _nomController, decoration: const InputDecoration(labelText: 'Nominal (Rp)', border: OutlineInputBorder()), keyboardType: TextInputType.number),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _prosesDanPreview,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green, padding: const EdgeInsets.all(16)),
              child: const Text('💾 Simpan & Cetak Bon', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }
}

// ==================== TOKO SCREEN ====================
class TokoScreen extends StatefulWidget {
  const TokoScreen({super.key});

  @override
  State<TokoScreen> createState() => _TokoScreenState();
}

class _TokoScreenState extends State<TokoScreen> {
  final _noStrukController = TextEditingController(text: DateTime.now().millisecondsSinceEpoch.toString());
  final _kasirController = TextEditingController(text: "Admin");
  final _pelangganController = TextEditingController(text: "Umum");
  final _tanggalController = TextEditingController();
  final _jamController = TextEditingController();

  final _namaItemController = TextEditingController();
  final _hargaItemController = TextEditingController();
  final _qtyItemController = TextEditingController();
  final FocusNode _namaItemFocusNode = FocusNode(); // PERBAIKAN: Gunakan FocusNode

  List<Map<String, dynamic>> _items = [];

  @override
  void initState() {
    super.initState();
    _tanggalController.text = nowDateStr();
    _jamController.text = nowTimeStr();
  }

  void _tambahItem() {
    if (_namaItemController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Nama barang wajib diisi!')));
      return;
    }
    int harga = int.tryParse(_hargaItemController.text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
    int qty = int.tryParse(_qtyItemController.text) ?? 0;
    if (harga <= 0 || qty <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Harga atau Qty tidak valid!')));
      return;
    }

    setState(() {
      _items.add({'nama': _namaItemController.text, 'harga': harga, 'qty': qty, 'subtotal': harga * qty});
      _namaItemController.clear();
      _hargaItemController.clear();
      _qtyItemController.clear();
      _namaItemFocusNode.requestFocus(); // PERBAIKAN: requestFocus pada FocusNode
    });
  }

  void _hapusItem(int index) {
    setState(() => _items.removeAt(index));
  }

  int get _total => _items.fold(0, (sum, item) => sum + (item['subtotal'] as int));

  void _cetakStruk() {
    if (_items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Tidak ada item untuk dicetak!')));
      return;
    }

    String g = "-" * AppConfig.lebarKarakter;
    List<String> lines = [
      centerText(AppConfig.namaToko, AppConfig.lebarKarakter),
      centerText(AppConfig.alamatToko, AppConfig.lebarKarakter),
      centerText(AppConfig.kotaToko, AppConfig.lebarKarakter),
      centerText(AppConfig.telpToko, AppConfig.lebarKarakter),
      "",
      "No.: ${_noStrukController.text}",
      "Ksr : ${_kasirController.text}",
      "Pel: ${_pelangganController.text}",
      "${_tanggalController.text} ${_jamController.text}",
      g,
    ];

    for (var it in _items) {
      lines.add(it['nama']);
      String hargaStr = "Rp${fmt(it['harga'])} x ${it['qty']}";
      String subStr = "Rp${fmt(it['subtotal'])}";
      lines.add(hargaStr.padRight(16) + subStr.padLeft(16));
      lines.add("");
    }

    String totalLine = "${"Total".padRight(18)}${("Rp${fmt(_total)}").padLeft(14)}";
   
    lines.addAll([g, totalLine, g, centerText(AppConfig.footerToko[0], AppConfig.lebarKarakter), centerText(AppConfig.footerToko[1], AppConfig.lebarKarakter)]);

    String teks = lines.join('\n');
    showDialog(
      context: context,
      builder: (context) => PreviewDialog(teks: teks, namaFile: "struk_${_noStrukController.text}.txt", pakaiLogo: false),
    );
   
    setState(() {
      _items.clear();
      _noStrukController.text = DateTime.now().millisecondsSinceEpoch.toString();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Input Struk Toko')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(flex: 3, child: TextField(controller: _namaItemController, focusNode: _namaItemFocusNode, decoration: const InputDecoration(labelText: 'Nama Barang', isDense: true, border: OutlineInputBorder()))),
                const SizedBox(width: 8),
                Expanded(flex: 2, child: TextField(controller: _hargaItemController, decoration: const InputDecoration(labelText: 'Harga', isDense: true, border: OutlineInputBorder()), keyboardType: TextInputType.number)),
                const SizedBox(width: 8),
                Expanded(flex: 1, child: TextField(controller: _qtyItemController, decoration: const InputDecoration(labelText: 'Qty', isDense: true, border: OutlineInputBorder()), keyboardType: TextInputType.number)),
                IconButton(icon: const Icon(Icons.add_circle, color: Colors.green, size: 32), onPressed: _tambahItem),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _items.length,
              itemBuilder: (context, index) {
                final item = _items[index];
                return ListTile(
                  title: Text(item['nama'], style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text("Rp${fmt(item['harga'])} x ${item['qty']} = Rp${fmt(item['subtotal'])}"),
                  trailing: IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => _hapusItem(index)),
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.grey[200], border: Border(top: BorderSide(color: Colors.grey[400]!))),
            child: Row(
              children: [
                Text("Total: Rp${fmt(_total)}", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const Spacer(),
                ElevatedButton.icon(onPressed: _cetakStruk, icon: const Icon(Icons.print), label: const Text('Cetak Struk'), style: ElevatedButton.styleFrom(backgroundColor: Colors.green)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ==================== SETTINGS SCREEN ====================
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  List<BluetoothInfo> _printers = [];
  String? _selectedPrinter;
  bool _isScanning = false;
  bool _enableLogo = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _selectedPrinter = prefs.getString('selected_printer');
      _enableLogo = prefs.getBool('enable_logo') ?? true;
    });
    _scanPrinters();
  }

  Future<void> _scanPrinters() async {
    setState(() => _isScanning = true);
    try {
      final devices = await PrinterService.getPairedPrinters();
      if (mounted) {
        setState(() {
          _printers = devices;
          _isScanning = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isScanning = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal scan: $e')));
      }
    }
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selected_printer', _selectedPrinter ?? '');
    await prefs.setBool('enable_logo', _enableLogo);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pengaturan disimpan!')));
    }
  }

  Future<void> _testPrint() async {
    if (_selectedPrinter == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pilih printer terlebih dahulu!')));
      return;
    }

    try {
      bool connected = await PrinterService.connect(_selectedPrinter!);
      if (!connected) throw Exception("Gagal terhubung ke printer. Pastikan printer menyala.");

      String testText = "TEST PRINT\n" + "=" * 32 + "\n" +
          "Jika Anda melihat ini,\nprinter berfungsi normal!\n" + "=" * 32 + "\n" +
          "Printer: $_selectedPrinter\n" +
          "Waktu: ${nowDateStr()} ${nowTimeStr()}\n";
     
      bool result = await PrinterService.printText(testText);
      await PrinterService.disconnect();

      if (mounted) {
        if (result) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Test Print Berhasil!')));
        } else {
          throw Exception("Gagal mengirim data ke printer");
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Test Print Gagal: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pengaturan')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('🖨️ Printer Bluetooth', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            if (_isScanning)
              const Center(child: CircularProgressIndicator())
            else
              DropdownButtonFormField<String>(
                value: _selectedPrinter,
                decoration: const InputDecoration(border: OutlineInputBorder(), hintText: 'Pilih Printer'),
                // PERBAIKAN: Gunakan p.macAdress (dengan 1 'd') sesuai bug bawaan package
                items: _printers.map((p) => DropdownMenuItem(value: p.macAdress, child: Text("${p.name} (${p.macAdress})"))).toList(),
                onChanged: (val) => setState(() => _selectedPrinter = val),
              ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: ElevatedButton.icon(onPressed: _scanPrinters, icon: const Icon(Icons.refresh), label: const Text('Scan Ulang'))),
                const SizedBox(width: 16),
                Expanded(child: ElevatedButton.icon(onPressed: _testPrint, icon: const Icon(Icons.print), label: const Text('Test Print'), style: ElevatedButton.styleFrom(backgroundColor: Colors.orange))),
              ],
            ),
            const Divider(height: 32),
            const Text('🖼️ Logo di Struk', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            SwitchListTile(
              title: const Text('Tampilkan Logo'),
              subtitle: const Text('Logo akan dicetak di bagian atas struk'),
              value: _enableLogo,
              onChanged: (val) => setState(() => _enableLogo = val),
            ),
            const Spacer(),
            ElevatedButton(
              onPressed: _saveSettings,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, padding: const EdgeInsets.all(16)),
              child: const Text('💾 Simpan Pengaturan', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }
}

// ==================== PREVIEW DIALOG ====================
class PreviewDialog extends StatefulWidget {
  final String teks;
  final String namaFile;
  final bool pakaiLogo;

  const PreviewDialog({super.key, required this.teks, required this.namaFile, required this.pakaiLogo});

  @override
  State<PreviewDialog> createState() => _PreviewDialogState();
}

class _PreviewDialogState extends State<PreviewDialog> {
  bool _isPrinting = false;
  bool _enableLogo = true;
  static const String _logoAsset = 'assets/logo_pertamina.jpg'; // Pastikan nama file sesuai

  @override
  void initState() {
    super.initState();
    _loadLogoSetting();
  }

  Future<void> _loadLogoSetting() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _enableLogo = prefs.getBool('enable_logo') ?? true;
      });
    }
  }

  Future<void> _simpanTxt() async {
    try {
      final path = await saveTextToFile(widget.teks, widget.namaFile);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('✓ File disimpan di:\n$path')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal menyimpan: $e')));
      }
    }
  }

  Future<void> _cetak() async {
    final prefs = await SharedPreferences.getInstance();
    final printerMac = prefs.getString('selected_printer');

    if (printerMac == null || printerMac.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Printer belum diatur di menu Pengaturan!')));
      }
      return;
    }

    setState(() => _isPrinting = true);
    try {
      final connected = await PrinterService.connect(printerMac);
      if (!connected) throw Exception('Gagal terhubung. Pastikan printer menyala & sudah di-pairing di Bluetooth Android.');

      if (widget.pakaiLogo && _enableLogo) {
        try {
          final byteData = await rootBundle.load(_logoAsset);
          final logoBytes = await logoBytesToEscPos(byteData.buffer.asUint8List(), maxWidth: 384);
          if (logoBytes.isNotEmpty) {
            await PrinterService.printBytes(logoBytes);
            await Future.delayed(const Duration(milliseconds: 300));
          }
        } catch (_) {
          // Jika logo gagal, lanjut cetak teks saja
        }
      }

      final result = await PrinterService.printText(widget.teks);
      await PrinterService.disconnect();

      if (mounted) {
        if (result) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✓ Berhasil dicetak ke printer!')));
          Navigator.of(context).pop();
        } else {
          throw Exception('Gagal mengirim data ke printer');
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal Cetak: $e')));
      }
    } finally {
      if (mounted) setState(() => _isPrinting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Preview: ${widget.namaFile}'),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            children: [
              if (widget.pakaiLogo && _enableLogo)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Image.asset(_logoAsset, height: 70),
                ),
              Container(
                width: double.maxFinite,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.grey[200], border: Border.all(color: Colors.grey), borderRadius: BorderRadius.circular(4)),
                child: Text(widget.teks, style: const TextStyle(fontFamily: 'monospace', fontSize: 11, height: 1.2)),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: _simpanTxt, child: const Text('💾 Simpan TXT')),
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Tutup')),
        ElevatedButton(
          onPressed: _isPrinting ? null : _cetak,
          style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
          child: _isPrinting
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : const Text('🖨️ Cetak', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}