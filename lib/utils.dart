// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';
import 'dart:math';

import 'package:intl/intl.dart';
import 'package:vm_service_lib/vm_service_lib.dart';

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

final Random r = new Random();

final List<String> _words = loremIpsum
    .split(' ')
    .map((w) => w.toLowerCase())
    .map((w) => w.endsWith('.') ? w.substring(0, w.length - 1) : w)
    .map((w) => w.endsWith(',') ? w.substring(0, w.length - 1) : w)
    .toList();

String getLoremFragment([int wordCount]) {
  if (wordCount == null) wordCount = r.nextInt(8) + 1;
  return toBeginningOfSentenceCase(
      new List.generate(wordCount, (_) => _words[r.nextInt(_words.length)])
          .join(' '));
}

String escape(String text) => text == null ? '' : HTML_ESCAPE.convert(text);

final NumberFormat nf = new NumberFormat.decimalPattern();

String percent(double d) => '${(d * 100).toStringAsFixed(1)}%';
String percent2(double d) => '${(d * 100).toStringAsFixed(2)}%';

String isolateName(IsolateRef ref) {
  // analysis_server.dart.snapshot$main
  String name = ref.name;
  name = name.replaceFirst(r'.snapshot', '');
  if (name.contains(r'.dart$')) {
    name = name + '()';
  }
  return name;
}

String funcRefName(FuncRef ref) {
  if (ref.owner is LibraryRef) {
    //(ref.owner as LibraryRef).uri;
    return ref.name;
  } else if (ref.owner is ClassRef) {
    return '${ref.owner.name}.${ref.name}';
  } else if (ref.owner is FuncRef) {
    return '${funcRefName(ref.owner)}.${ref.name}';
  } else {
    return ref.name;
  }
}
