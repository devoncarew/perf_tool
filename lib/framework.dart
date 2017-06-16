// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:html' hide Screen;

import 'package:vm_service_lib/vm_service_lib.dart';

import 'globals.dart';
import 'perf_main.dart';
import 'service.dart';
import 'ui/elements.dart';

class Framework {
  List<Screen> screens = [];

  Screen current;

  Framework() {
    window.onPopState.listen(handlePopState);
  }

  void addScreen(Screen screen) {
    screens.add(screen);
  }

  static int foo = 0;

  void navigateTo(String id) {
    Screen screen = getScreen(id);
    assert(screen != null);

    String search = window.location.search;
    String ref = search == null ? screen.ref : '${screen.ref}$search';
    window.history.pushState(null, screen.name, ref);

    load(screen);
  }

  void performInitialLoad() {
    loadScreenFromLocation();
    _initService();
  }

  void loadScreenFromLocation() {
    // Look for an explicit path, otherwise re-direct to '/'
    String path = window.location.pathname;

    // Special case the development path.
    if (path == '/perf_tool/web/index.html' || path == '/index.html') {
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

  void _initService() {
    int port;

    if (window.location.search.isNotEmpty) {
      Uri uri = Uri.parse(window.location.toString());
      String portStr = uri.queryParameters['port'];
      if (portStr != null) {
        port = int.parse(portStr, onError: (_) => null);
      }
    }

    port ??= int.parse(window.location.port);

    Completer finishedCompleter = new Completer();

    connect('localhost', port, finishedCompleter).then((VmService service) {
      serviceInfo.vmServiceOpened(service, finishedCompleter.future);
    }).catchError((e) {
      // TODO:
      print('unable to connect to service on port $port: $e');
    });
  }

  Screen getScreen(String id) {
    return screens.firstWhere((s) => s.id == id, orElse: () => null);
  }

  void handlePopState(PopStateEvent event) {
    loadScreenFromLocation();
  }

  CoreElement get mainElement =>
      new CoreElement.from(querySelector('#content'));

  void load(Screen screen) {
    current?.exiting();

    CoreElement element = mainElement;
    element.clear();

    current = screen;
    // TODO: Don't do this when re-visiting a page.
    current.createContent(element);

    current?.entering();

    updatePage();
  }

  void updatePage() {
    // nav
    for (Element element in querySelectorAll('header a')) {
      CoreElement e = new CoreElement.from(element);
      bool isCurrent = current.ref == element.attributes['href'];
      e.enabled = !isCurrent;
      element.classes.toggle('active', isCurrent);
    }

    // status
    CoreElement helpLink = new CoreElement.from(querySelector('#docsLink'));
    HelpInfo helpInfo = current.helpInfo;
    if (helpInfo == null) {
      helpLink.hidden(true);
    } else {
      helpLink.clear();
      helpLink.add([
        span(text: '${helpInfo.title} '),
        span(c: 'octicon octicon-link-external small-octicon'),
      ]);
      helpLink.setAttribute('href', helpInfo.url);
      helpLink.hidden(false);
    }
  }
}

abstract class Screen {
  final String name;
  final String id;

  Screen(this.name, this.id);

  String get ref => id == '/' ? id : '/$id';

  void createContent(CoreElement mainDiv) {}

  void entering() {}

  void exiting() {}

  HelpInfo get helpInfo => null;

  String toString() => id;
}

class HelpInfo {
  final String title;
  final String url;

  HelpInfo(this.title, this.url);
}
