import 'package:findme/features/pins/data/client_files.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('targetShort: the short edge to ask the encoder for', () {
    test('a photo larger than the limit lands its long edge on it', () {
      expect(targetShort(4000, 3000, 2048), 1536);
      expect(targetShort(3000, 4000, 2048), 1536); // tall: the same
      expect(targetShort(4032, 3024, 2048), 1536);
      expect(targetShort(2048, 1536, 400), 300);
    });

    test('a photo within the limit keeps its own size (never enlarged)', () {
      expect(targetShort(300, 200, 2048), 200);
      expect(targetShort(2048, 100, 2048), 100);
    });

    test('never below one pixel', () {
      expect(targetShort(10000, 3, 400), 1);
    });
  });

  group('rightSize: what Look Back will accept', () {
    test('the long edge is the limit, or the source when it is smaller', () {
      expect(rightSize((2048, 1536), (4000, 3000), 2048), isTrue);
      expect(rightSize((1536, 2048), (4000, 3000), 2048), isTrue); // rotated
      expect(rightSize((300, 200), (300, 200), 2048), isTrue);
      expect(rightSize((400, 300), (2048, 1536), 400), isTrue);
    });

    test('one pixel of rounding is fine, more is not', () {
      expect(rightSize((2047, 1535), (4000, 3000), 2048), isTrue);
      expect(rightSize((2049, 1537), (4000, 3000), 2048), isTrue);
      expect(rightSize((2051, 1538), (4000, 3000), 2048), isFalse);
      expect(rightSize((2731, 2048), (4000, 3000), 2048), isFalse);
      expect(rightSize((1024, 768), (4000, 3000), 2048), isFalse);
    });
  });

  group('tooSlow: judged per megapixel, small pictures as 2 MP', () {
    test('12 MP may take 1.8 s', () {
      expect(tooSlow(const Duration(milliseconds: 1700), 4000, 3000), isFalse);
      expect(tooSlow(const Duration(milliseconds: 1900), 4000, 3000), isTrue);
    });

    test('a small picture gets the 2 MP allowance', () {
      expect(tooSlow(const Duration(milliseconds: 250), 300, 200), isFalse);
      expect(tooSlow(const Duration(milliseconds: 350), 300, 200), isTrue);
    });
  });
}
