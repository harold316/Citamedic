import 'dart:typed_data';

import 'package:image_picker/image_picker.dart';

class ClinicPhotoDraft {
  const ClinicPhotoDraft({this.file, this.bytes, this.url});

  final XFile? file;
  final Uint8List? bytes;
  final String? url;

  bool get hasImage =>
      bytes != null || (url != null && url!.trim().isNotEmpty);
}
