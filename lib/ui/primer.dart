// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'elements.dart';

class PTooltip {
  static add(CoreElement element, String text) {
    element.toggleClass('tooltipped', true);
    element.toggleClass('tooltipped-nw', true);
    element.setAttribute('aria-label', text);
  }

  static remove(CoreElement element) {
    element.toggleClass('tooltipped', false);
    element.toggleClass('tooltipped-nw', false);
    element.toggleAttribute('aria-label', false);
  }
}

class PButton extends CoreElement {
  PButton(String text) : super('button', text: text, classes: 'btn') {
    setAttribute('type', 'button');
  }

  void small() => clazz('btn-sm');
}
