// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:html';

import 'elements.dart';

PSelect select() => new PSelect();

class PSelect extends CoreElement {
  PSelect() : super('select', classes: 'form-select');

  void small() => clazz('select-sm');

  void option(String name, {String value}) {
    CoreElement e = new CoreElement('option', text: name);
    if (value != null) {
      (e.element as OptionElement).value = value;
    }
    add(e);
  }

  String get value => (element as SelectElement).value;

  set selectedIndex(int index) {
    (element as SelectElement).selectedIndex = index;
  }

  Stream<Event> get onChange => element.onChange.where((_) => !disabled);

  /// Subscribe to the [onChange] event stream with a no-arg handler.
  StreamSubscription<Event> change(void handle()) {
    return onChange.listen((Event e) {
      e.stopImmediatePropagation();
      handle();
    });
  }
}

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

  void primary() => clazz('btn-primary');

  void small() => clazz('btn-sm');
}

class PFlash extends CoreElement {
  PFlash({String text}) : super('div', classes: 'flash flash-warn', text: text);

  CoreElement addClose() {
    return add(span(c: 'octicon octicon-x flash-close js-flash-close'));
  }
}

class PTabNav extends CoreElement {
  PTabNavTab selectedTab;

  PTabNav(List<PTabNavTab> tabs) : super('div', classes: 'tabnav') {
    CoreElement nav = add(new CoreElement('nav', classes: 'tabnav-tabs'));
    nav.add(tabs);

    if (tabs.isNotEmpty) {
      selectTab(tabs.first);
    }

    for (PTabNavTab tab in tabs) {
      tab.click(() {
        selectTab(tab);
      });
    }
  }

  void selectTab(PTabNavTab tab) {
    selectedTab?.toggleClass('selected', false);
    selectedTab = tab;
    selectedTab?.toggleClass('selected', true);
  }
}

class PTabNavTab extends CoreElement {
  PTabNavTab(String name) : super('div', classes: 'tabnav-tab', text: name);
}
