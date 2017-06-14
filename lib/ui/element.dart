// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:html';

PElement p(String text) => new PElement.tag('p')..text = text;

PElement h2(String text) => new PElement.tag('h2')..text = text;
PElement h3(String text) => new PElement.tag('h3')..text = text;
PElement h4(String text) => new PElement.tag('h4')..text = text;

class PElement {
  final Element element;

  PElement(this.element);

  PElement.tag(String tag, {String classes}) : element = new Element.tag(tag) {
    if (classes != null) {
      element.classes.add(classes);
    }
  }

  bool hasAttr(String name) => element.attributes.containsKey(name);

  void toggleAttr(String name, bool value) {
    value ? setAttr(name) : clearAttr(name);
  }

  String getAttr(String name) => element.getAttribute(name);

  void setAttr(String name, [String value = '']) =>
      element.setAttribute(name, value);

  String clearAttr(String name) => element.attributes.remove(name);

  String get text => element.text;

  set text(String value) {
    element.text = value;
  }

  bool get enabled => !hasAttr('disabled');

  set enabled(bool val) {
    toggleAttr('disabled', !val);
  }

  //Property get textProperty => new _ElementTextProperty(element);

  void layoutHorizontal() {
    setAttr('layout');
    setAttr('horizontal');
  }

  void layoutVertical() {
    setAttr('layout');
    setAttr('vertical');
  }

  void flex() => setAttr('flex');

  dynamic add(var child) {
    if (child is PElement) {
      element.children.add(child.element);
    } else {
      element.children.add(child);
    }

    return child;
  }

  Stream<Event> get onClick => element.onClick;

  void dispose() {
    if (element.parent == null) return;

    if (element.parent.children.contains(element)) {
      try {
        element.parent.children.remove(element);
      } catch (e) {
        print('foo');
      }
    }
  }

  String toString() => element.toString();
}
