import 'dart:typed_data';

import 'package:image/image.dart' as img;

/// 64-bit difference hash as 16 hex chars, or null if the bytes aren't an image.
/// Robust to resizing and recompression, so re-saved screenshots still match.
String? perceptualHash(Uint8List bytes) {
  try {
    final decoded = img.decodeImage(bytes);
    if (decoded == null) return null;
    final small = img.copyResize(
      img.grayscale(decoded),
      width: 9,
      height: 8,
      interpolation: img.Interpolation.average,
    );
    var bits = BigInt.zero;
    for (var y = 0; y < 8; y++) {
      for (var x = 0; x < 8; x++) {
        final left = small.getPixel(x, y).luminance;
        final right = small.getPixel(x + 1, y).luminance;
        bits = (bits << 1) | (left > right ? BigInt.one : BigInt.zero);
      }
    }
    return bits.toRadixString(16).padLeft(16, '0');
  } on Object {
    return null;
  }
}

/// Number of differing bits between two equal-length hex hashes.
int hammingDistance(String a, String b) {
  if (a.length != b.length) return 1 << 20;
  var d = 0;
  for (var i = 0; i < a.length; i++) {
    var x = int.parse(a[i], radix: 16) ^ int.parse(b[i], radix: 16);
    while (x != 0) {
      d += x & 1;
      x >>= 1;
    }
  }
  return d;
}

/// Hashes within this distance count as "the same image".
const phashDuplicateDistance = 4;

bool isNearDuplicate(String hash, Iterable<String> known) => known.any(
  (k) =>
      k == hash ||
      (k.length == 16 &&
          hash.length == 16 &&
          hammingDistance(k, hash) <= phashDuplicateDistance),
);
