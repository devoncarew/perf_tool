// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';
import 'dart:math';

import 'package:intl/intl.dart';

final String loremIpsum = '''
Lorem ipsum dolor sit amet, consectetur adipiscing elit. Donec faucibus dolor quis rhoncus feugiat. Ut imperdiet
libero vel vestibulum vulputate. Aliquam consequat, lectus nec euismod commodo, turpis massa volutpat ex, a
elementum tellus turpis nec arcu. Suspendisse erat nisl, rhoncus ut nisi in, lacinia pretium dui. Donec at erat
ultrices, tincidunt quam sit amet, cursus lectus. Integer justo turpis, vestibulum condimentum lectus eget,
sodales suscipit risus. Nullam consequat sit amet turpis vitae facilisis. Integer sit amet tempus arcu.
''';

String getLoremText([int paragraphCount = 1]) {
  String str = '';
  for (int i = 0; i < paragraphCount; i++) {
    str += '$loremIpsum\n';
  }
  return str.trim();
}

final Random _r = new Random();

final List<String> _words = loremIpsum
    .split(' ')
    .map((w) => w.toLowerCase())
    .map((w) => w.endsWith('.') ? w.substring(0, w.length - 1) : w)
    .map((w) => w.endsWith(',') ? w.substring(0, w.length - 1) : w)
    .toList();

String getLoremFragment([int wordCount]) {
  if (wordCount == null) wordCount = _r.nextInt(8) + 1;
  return toBeginningOfSentenceCase(
      new List.generate(wordCount, (_) => _words[_r.nextInt(_words.length)])
          .join(' '));
}

String escape(String text) => text == null ? '' : HTML_ESCAPE.convert(text);

final NumberFormat nf = new NumberFormat.decimalPattern();

class SampleData {
  static SampleData random() {
    return new SampleData(
        getLoremFragment(), _r.nextInt(1200), _r.nextDouble() * 100.0);
  }

  final String method;
  final int count;
  final double usage;

  SampleData(this.method, this.count, this.usage);
}
