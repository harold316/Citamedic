import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:http/http.dart' as http;

import 'firebase_economy.dart';

class StorageUpload {
  static Future<String> jpeg({
    required String path,
    required List<int> bytes,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw StateError('Debes iniciar sesión para subir archivos.');
    }
    final compact = await FirebaseEconomy.compactJpeg(bytes);
    final token = await user.getIdToken();
    if (token == null || token.isEmpty) {
      throw StateError('No se pudo obtener el token de Firebase.');
    }

    final configured = Firebase.app().options.storageBucket;
    if (configured == null || configured.isEmpty) {
      throw StateError('Firebase Storage no está configurado.');
    }

    final buckets = <String>{
      configured,
      if (configured.endsWith('.firebasestorage.app'))
        configured.replaceAll('.firebasestorage.app', '.appspot.com'),
      if (configured.endsWith('.appspot.com'))
        configured.replaceAll('.appspot.com', '.firebasestorage.app'),
    };

    Object? lastError;
    for (final bucket in buckets) {
      try {
        return await _uploadToBucket(
          bucket: bucket,
          path: path,
          bytes: compact,
          token: token,
        );
      } catch (error) {
        lastError = error;
        final retryAnotherBucket =
            error is StateError && error.message.contains('bucket');
        if (!retryAnotherBucket) {
          rethrow;
        }
      }
    }
    throw lastError ?? StateError('No se pudo subir la imagen.');
  }

  static Future<String> _uploadToBucket({
    required String bucket,
    required String path,
    required List<int> bytes,
    required String token,
  }) async {
    final uri = Uri.https('firebasestorage.googleapis.com', '/v0/b/$bucket/o', {
      'name': path,
      'uploadType': 'media',
    });
    final response = await http.post(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'image/jpeg',
      },
      body: bytes,
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw StateError(_messageFor(response.statusCode, response.body));
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final downloadToken =
        data['downloadTokens'] as String? ?? data['downloadToken'] as String?;
    final encodedPath = Uri.encodeComponent(path);
    if (downloadToken == null || downloadToken.isEmpty) {
      return 'https://firebasestorage.googleapis.com/v0/b/$bucket/o/$encodedPath?alt=media';
    }
    return 'https://firebasestorage.googleapis.com/v0/b/$bucket/o/$encodedPath?alt=media&token=$downloadToken';
  }

  static String _messageFor(int statusCode, String body) {
    if (statusCode == 403) {
      return 'Storage rechazó la subida. En Firebase Console → Storage → Reglas, publica las reglas de storage.rules.';
    }
    if (statusCode == 404) {
      return 'No se encontró el bucket de Storage. Revisa que el producto Storage esté creado en el proyecto agendamedic-c36df.';
    }
    return 'No se pudo subir la imagen ($statusCode). $body';
  }
}
