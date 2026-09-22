import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_in_app_messaging/firebase_in_app_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:shared_preferences/shared_preferences.dart';

class FirebaseEconomy {
  static const catalogTtl = Duration(minutes: 15);
  static const maxImageSide = 1280;
  static const maxImageBytes = 180 * 1024;

  static bool _configured = false;

  static void configure() {
    if (_configured || Firebase.apps.isEmpty) {
      return;
    }
    _configured = true;
    FirebaseFirestore.instance.settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes: 40 * 1024 * 1024,
    );
    try {
      FirebaseInAppMessaging.instance.setAutomaticDataCollectionEnabled(false);
      FirebaseInAppMessaging.instance.setMessagesSuppressed(true);
    } catch (error) {
      debugPrint('No se pudo silenciar In-App Messaging: $error');
    }
  }

  static String catalogKey({
    required String collection,
    required bool includeUnpublished,
  }) {
    return 'fe_${collection}_${includeUnpublished ? 'all' : 'pub'}';
  }

  static Future<bool> isCatalogFresh(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final millis = prefs.getInt(key);
    if (millis == null) {
      return false;
    }
    return DateTime.now().difference(
          DateTime.fromMillisecondsSinceEpoch(millis),
        ) <
        catalogTtl;
  }

  static Future<void> markCatalogFresh(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(key, DateTime.now().millisecondsSinceEpoch);
  }

  static Future<QuerySnapshot<Map<String, dynamic>>?> cachedQuery(
    Query<Map<String, dynamic>> query,
  ) async {
    try {
      final cached = await query.get(const GetOptions(source: Source.cache));
      if (cached.docs.isNotEmpty) {
        return cached;
      }
    } catch (_) {}
    return null;
  }

  static Future<QuerySnapshot<Map<String, dynamic>>> serverQuery(
    Query<Map<String, dynamic>> query,
  ) {
    return query.get(const GetOptions(source: Source.server));
  }

  static Future<DocumentSnapshot<Map<String, dynamic>>> getDocument(
    DocumentReference<Map<String, dynamic>> ref, {
    bool preferCache = true,
  }) async {
    if (preferCache) {
      try {
        final cached = await ref.get(const GetOptions(source: Source.cache));
        if (cached.exists) {
          return cached;
        }
      } catch (_) {}
    }
    return ref.get(const GetOptions(source: Source.server));
  }

  static Future<List<int>> compactJpeg(List<int> bytes) async {
    if (bytes.length <= maxImageBytes) {
      return bytes;
    }
    try {
      return await compute(_compactJpegIsolate, Uint8List.fromList(bytes));
    } catch (error) {
      debugPrint('No se pudo compactar la imagen: $error');
      return bytes;
    }
  }
}

Uint8List _compactJpegIsolate(Uint8List bytes) {
  final decoded = img.decodeImage(bytes);
  if (decoded == null) {
    return bytes;
  }
  var image = decoded;
  if (image.width > FirebaseEconomy.maxImageSide ||
      image.height > FirebaseEconomy.maxImageSide) {
    image = img.copyResize(
      image,
      width: image.width >= image.height ? FirebaseEconomy.maxImageSide : null,
      height: image.height > image.width ? FirebaseEconomy.maxImageSide : null,
    );
  }
  var quality = 82;
  var encoded = img.encodeJpg(image, quality: quality);
  while (encoded.length > FirebaseEconomy.maxImageBytes && quality > 45) {
    quality -= 10;
    encoded = img.encodeJpg(image, quality: quality);
  }
  return encoded.length < bytes.length ? Uint8List.fromList(encoded) : bytes;
}
