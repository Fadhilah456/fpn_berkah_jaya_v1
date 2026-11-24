import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config.dart';

class UpdateService {
  static const String repoOwner = 'Fadhilah456';
  static const String repoName = 'fpn_berkah_jaya_v1';
  static const String apiUrl = 'https://api.github.com/repos/$repoOwner/$repoName/releases/latest';

  static Future<Map<String, dynamic>> checkForUpdate() async {
    try {
      final response = await http.get(Uri.parse(apiUrl)).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final latestVersion = (data['tag_name'] as String).replaceAll('v', '').replaceAll('V', '');
        final downloadUrl = (data['assets'] as List).isNotEmpty
            ? data['assets'][0]['browser_download_url'] as String
            : 'https://github.com/$repoOwner/$repoName/releases';
       
        return {
          'has_update': _isNewerVersion(latestVersion, AppConfig.version),
          'latest_version': latestVersion,
          'download_url': downloadUrl,
          'error': null,
        };
      } else {
        return {'has_update': false, 'error': 'Gagal mengambil data dari GitHub'};
      }
    } catch (e) {
      return {'has_update': false, 'error': 'Koneksi internet bermasalah'};
    }
  }

  static bool _isNewerVersion(String latest, String current) {
    List<int> parseVersion(String v) {
      return v.split('.').map((e) => int.tryParse(e) ?? 0).toList();
    }
    final v1 = parseVersion(latest);
    final v2 = parseVersion(current);
   
    for (int i = 0; i < 3; i++) {
      if (v1[i] > v2[i]) return true;
      if (v1[i] < v2[i]) return false;
    }
    return false;
  }

  static Future<int> getSkipCount() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('update_skip_count') ?? 0;
  }

  static Future<void> incrementSkipCount() async {
    final prefs = await SharedPreferences.getInstance();
    int count = (prefs.getInt('update_skip_count') ?? 0) + 1;
    await prefs.setInt('update_skip_count', count);
  }

  static Future<void> resetSkipCount() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('update_skip_count', 0);
  }
}