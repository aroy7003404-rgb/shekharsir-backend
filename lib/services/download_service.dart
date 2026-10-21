import 'dart:io';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DownloadService {
  final Dio _dio = Dio();
  static const String _downloadRegistryKey = 'shekhar_sir_downloaded_materials';

  /// Download file from URL with real-time progress callback
  Future<String?> downloadFile({
    required String fileUrl,
    required String fileName,
    required void Function(int count, int total) onProgress,
  }) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final savePath = '${dir.path}/$fileName';

      await _dio.download(
        fileUrl,
        savePath,
        onReceiveProgress: onProgress,
      );

      await _registerDownloadedFile(fileUrl, savePath);
      return savePath;
    } catch (e) {
      debugPrint('Error downloading material file: $e');
      return null;
    }
  }

  /// Get local file path if material is already cached
  static Future<String?> getLocalFilePath(String fileUrl) async {
    final registry = await _getRegistry();
    final path = registry[fileUrl];
    if (path != null && File(path).existsSync()) {
      return path;
    }
    return null;
  }

  /// Check if material is downloaded locally
  static Future<bool> isFileDownloaded(String fileUrl) async {
    final path = await getLocalFilePath(fileUrl);
    return path != null;
  }

  static Future<void> _registerDownloadedFile(String url, String localPath) async {
    final prefs = await SharedPreferences.getInstance();
    final registry = await _getRegistry();
    registry[url] = localPath;
    await prefs.setString(_downloadRegistryKey, json.encode(registry));
  }

  static Future<Map<String, String>> _getRegistry() async {
    final prefs = await SharedPreferences.getInstance();
    final str = prefs.getString(_downloadRegistryKey);
    if (str != null && str.isNotEmpty) {
      try {
        final decoded = json.decode(str) as Map<String, dynamic>;
        return decoded.map((key, value) => MapEntry(key, value.toString()));
      } catch (_) {}
    }
    return {};
  }
}
