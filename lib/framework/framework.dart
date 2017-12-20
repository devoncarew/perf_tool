// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:html' hide Screen;

import 'package:vm_service_lib/vm_service_lib.dart';

import '../globals.dart';
import '../perf_main.dart';
import '../service.dart';
import '../ui/elements.dart';
import '../ui/primer.dart';

class Framework {
  List<Screen> screens = [];
  Screen current;
  _StatusLine _statusLine;

  Framework() {
    window.onPopState.listen(handlePopState);
    _statusLine = new _StatusLine(
        new CoreElement.from(querySelector('#rightStatusLine')));
  }

  void addScreen(Screen screen) {
    screens.add(screen);
  }

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
      showError('Unable to connect to service on port $port');
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

  final Map<Screen, List<Element>> _contents = {};

  void load(Screen screen) {
    if (current != null) {
      current.exiting();
      _statusLine.removeAll(current.statusItems);
      _contents[current] = mainElement.element.children.toList();
      mainElement.element.children.clear();
    } else {
      mainElement.element.children.clear();
    }

    current = screen;

    if (_contents.containsKey(current)) {
      mainElement.element.children.addAll(_contents[current]);
    } else {
      current.createContent(this, mainElement);
    }

    current.entering();
    _statusLine.addAll(current.statusItems);

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

  void showError(String title, [dynamic error]) {
    PFlash flash = new PFlash();
    flash.addClose().click(clearError);
    flash.add(span(text: title));
    if (error != null) {
      flash.add(new CoreElement('br'));
      flash.add(span(text: '$error'));
    }

    CoreElement errorContainer =
        new CoreElement.from(querySelector('#error-container'));
    errorContainer.add(flash);
  }

  void clearError() {
    querySelector('#error-container').children.clear();
  }
}

class _StatusLine {
  final CoreElement element;

  _StatusLine(this.element);

  void add(StatusItem item) {
    SpanElement separator = new SpanElement()
      ..text = '•'
      ..classes.add('separator');

    element.element.children.insert(0, separator);
    element.element.children.insert(0, item.element.element);
  }

  void remove(StatusItem item) {
    int index = element.element.children.indexOf(item.element.element);
    if (index >= 0) {
      element.element.children.removeAt(index);
      element.element.children.removeAt(index);
    }
  }

  void addAll(List<StatusItem> items) {
    for (StatusItem item in items.reversed) {
      add(item);
    }
  }

  void removeAll(List<StatusItem> items) {
    for (StatusItem item in items) {
      remove(item);
    }
  }
}

void toast(String message) {
  // TODO:
  print(message);
}

abstract class Screen {
  final String name;
  final String id;
  final List<StatusItem> statusItems = [];

  Screen(this.name, this.id);

  String get ref => id == '/' ? id : '/$id';

  void createContent(Framework framework, CoreElement mainDiv) {}

  void entering() {}

  void exiting() {}

  void addStatusItem(StatusItem item) {
    // TODO: If we're live, add to the screen
    statusItems.add(item);
  }

  void removeStatusItems(StatusItem item) {
    // TODO: If we're live, remove from the screen
    statusItems.remove(item);
  }

  HelpInfo get helpInfo => null;

  String toString() => id;
}

class HelpInfo {
  final String title;
  final String url;

  HelpInfo(this.title, this.url);
}

class StatusItem {
  final CoreElement element;

  StatusItem() : element = span();
}
