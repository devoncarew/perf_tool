// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:html' hide Screen;

import 'main.dart';

import 'ui/element.dart';

class Framework {
  // TODO: build screen for route
  List<Screen> screens = [];

  Screen current;

  Framework() {
    window.onPopState.listen(handlePopState);
  }

  // TODO: use screen builders instead of screen instances?
  void addScreen(Screen screen) {
    screens.add(screen);
  }

  static int foo = 0;

  void navigateTo(String id) {
    Screen screen = getScreen(id);
    assert(screen != null);
    window.history.pushState({'foo': foo++}, screen.name, screen.ref);
    // TODO: clone this
    load(screen);
  }

  void loadScreenFromLocation() {
    // Look for an explicit path, otherwise re-direct to '/'
    String path = window.location.pathname;

    // Special case the development path.
    if (path == '/perf_tool/web/index.html') {
      path = '/';
    }

    String first =
        (path.startsWith('/') ? path.substring(1) : path).split('/').first;
    Screen screen = getScreen(first.isEmpty ? path : first);
    if (screen != null) {
      load(screen);
    } else {
      load(new NotFoundScreen());
    }
  }

  Screen getScreen(String id) {
    return screens.firstWhere((s) => s.id == id, orElse: () => null);
  }

  void handlePopState(PopStateEvent event) {
    // TODO:
    print('pop: ${window.location.pathname}, ${event.state}');

    loadScreenFromLocation();
  }

  Element get mainElement => querySelector('#content');

  void load(Screen screen) {
    current?.exiting();

    Element element = mainElement;
    element.children.clear();

    current = screen;
    current.createContent(element);

    current?.entering();

    updatePage();
  }

  void updatePage() {
    // title, nav, status

    for (Element element in querySelectorAll('header a')) {
      PElement pe = new PElement(element);
      bool isCurrent = current.ref == element.attributes['href'];
      pe.enabled = !isCurrent;
      element.classes.toggle('active', isCurrent);
    }
  }
}

// TODO: differentiate between entering for the first time (with some url params)
// and re-visiting a page (from a back/forward history change)

abstract class Screen {
  final String name;
  final String id;

  Screen(this.name, this.id);

  String get ref => id == '/' ? id : '/$id';

  void entering() {}

  void createContent(Element mainDiv) {}

  // TODO: save state?
  void exiting() {}

  String toString() => id;
}
