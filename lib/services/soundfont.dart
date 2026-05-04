import 'dart:io';
import 'package:dio/dio.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

class SoundfontService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Check if the soundfont exists in assets
  Future<bool> isSoundfontInAssets(String filename) async {
    try {
      await rootBundle.load('assets/sounds/soundfonts/$filename');
      return true;
    } catch (e) {
      return false;
    }
  }
  // Checks if the soundfont file is downloaded locally
  Future<bool> isSoundfontDownloaded(String filename) async {
    final directory = await getApplicationDocumentsDirectory();
    final filePath = '${directory.path}/$filename';
    return File(filePath).exists();
  }
  // Get the list of downloaded soundfonts from App Storage
  Future<List<String>> getListOfLocalSoundfonts() async {
    final directory = await getApplicationDocumentsDirectory();
    final files = await directory.list().toList();
    return files.map((file) => file.path.split('/').last).where((name)=>name.toLowerCase().endsWith('.sf2')).toList();
  }

  // Downloads the soundfont from Firebase Storage
  Future<void> downloadSoundfont(String filename) async {
    final directory = await getApplicationDocumentsDirectory();
    final filePath = '${directory.path}/$filename';

    final ref = _storage.ref().child('soundfonts/$filename');
    try {
      final downloadUrl = await ref.getDownloadURL();

      // Use Dio for downloading the soundfont
      final dio = Dio();
      await dio.download(downloadUrl, filePath);
    } catch (e) {
      if (kDebugMode) {
        print('Error downloading soundfont: $e');
      }
      throw Exception('Failed to download soundfont');
    }
  }

  // Get the local path of the soundfont file
  Future<String> getSoundfontPath(String filename) async {
    if (await isSoundfontInAssets(filename)){
      String localPath = 'assets/sounds/soundfonts/$filename';
      final ByteData data = await rootBundle.load(localPath);
      final List<int> bytes = data.buffer.asUint8List();

      final Directory tempDir = await getTemporaryDirectory();
      final String fileName = localPath.split('/').last;
      final File tempFile = File('${tempDir.path}/$fileName');

      await tempFile.writeAsBytes(bytes);
      return tempFile.path; // assets folder path
    }

    // if not in assets, check temp storage
    final directory = await getApplicationDocumentsDirectory();
    return '${directory.path}/$filename';
  }

  // Main function to handle loading soundfont (checks and downloads if needed)
  Future<void> loadSoundfont(String filename) async {
    if (!(await isSoundfontInAssets(filename)) && !(await isSoundfontDownloaded(filename))) {
      await downloadSoundfont(filename);
    }
  }
}
