import 'package:flutter_aes_ecb_pkcs5/flutter_aes_ecb_pkcs5.dart';

extension Crypto on String? {
  Future<String> hash() async {
    if (this == null && this!.isEmpty) return '';

    var encryptText =
        await FlutterAesEcbPkcs5.encryptString(this!, '6FA0314D0B3F3E8DEA5B8C77E475AB0F');
    return encryptText ?? '';
  }

  Future<String> unHash() async {
    if (this == null && this!.isEmpty) return '';
    var decryptText =
        await FlutterAesEcbPkcs5.decryptString(this!, '6FA0314D0B3F3E8DEA5B8C77E475AB0F');
    return decryptText ?? '';
  }
}
