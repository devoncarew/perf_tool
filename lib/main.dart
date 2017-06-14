// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';
import 'dart:html' hide Screen;

import 'about.dart';
import 'framework.dart';
import 'memory/memory.dart';
import 'performance/performance.dart';
import 'timeline/timeline.dart';
import 'ui/element.dart';

// TODO: connect to the obs. instance, list isolates

class PerfToolFramework extends Framework {
  PerfToolFramework() {
    addScreen(_initReferences(new AboutScreen()));
    addScreen(_initReferences(new MainScreen()));
    addScreen(_initReferences(new TimelineScreen()));
    addScreen(_initReferences(new PerformanceScreen()));
    addScreen(_initReferences(new MemoryScreen()));
  }

  Screen _initReferences(Screen screen) {
    for (Element element in querySelectorAll('a[href="${screen.ref}"]')) {
      element.onClick.listen((event) {
        if (element.attributes.containsKey('disabled')) return;

        event.preventDefault();
        navigateTo(screen.id);
      });
    }

    return screen;
  }
}

class MainScreen extends Screen {
  MainScreen() : super('Observatory', '/');

  @override
  void createContent(Element mainDiv) {
    mainDiv.children.addAll([
      p('''
Lorem ipsum dolor sit amet, consectetur adipiscing elit. Donec faucibus dolor quis rhoncus feugiat. Ut imperdiet
libero vel vestibulum vulputate. Aliquam consequat, lectus nec euismod commodo, turpis massa volutpat ex, a
elementum tellus turpis nec arcu. Suspendisse erat nisl, rhoncus ut nisi in, lacinia pretium dui. Donec at erat
ultrices, tincidunt quam sit amet, cursus lectus. Integer justo turpis, vestibulum condimentum lectus eget,
sodales suscipit risus. Nullam consequat sit amet turpis vitae facilisis. Integer sit amet tempus arcu.
''').element,
    ]);
  }
}

class NotFoundScreen extends Screen {
  NotFoundScreen() : super('Not Found', 'notfound');

  void createContent(Element mainDiv) {
    // TODO:
    mainDiv.children
        .add(p('Page not found: ${window.location.pathname}').element);
  }
}

String escape(String text) => text == null ? '' : HTML_ESCAPE.convert(text);
