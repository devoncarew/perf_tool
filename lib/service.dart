// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:html';

import 'package:vm_service_lib/vm_service_lib.dart';

Future<VmService> connect(String host, int port, Completer finishedCompleter) {
  WebSocket ws = new WebSocket('ws://${host}:${port}/ws');

  Completer<VmService> connectedCompleter = new Completer();

  ws.onOpen.listen((_) {
    //_logger.info('Connected to observatory on ${url}.');

    VmService service = new VmService(
      ws.onMessage.map((MessageEvent e) => e.data as String),
      (String message) => ws.send(message),
      //log: new ObservatoryLog(_logger)
    );

    ws.onClose.listen((_) {
      finishedCompleter.complete();
      service.dispose();
    });

    connectedCompleter.complete(service);
  });

  ws.onError.listen((e) {
    //_logger.fine('Unable to connect to observatory, port ${port}', e);
    if (!connectedCompleter.isCompleted) connectedCompleter.completeError(e);
  });

  return connectedCompleter.future;
}

class ServiceInfo {
  StreamController _stateController = new StreamController.broadcast();

  VmService service;
  String targetCpu;
  String hostCPU;
  String sdkVersion;
  List<IsolateRef> isolateRefs;

  Stream get onStateChange => _stateController.stream;

  void vmServiceOpened(VmService _service, Future onClosed) {
    _service.getVM().then((VM vm) {
      targetCpu = vm.targetCPU;
      hostCPU = vm.hostCPU;
      sdkVersion = vm.version;
      if (sdkVersion.contains(' ')) {
        sdkVersion = sdkVersion.substring(0, sdkVersion.indexOf(' '));
      }
      isolateRefs = vm.isolates;

      print('${vm.hostCPU}, $sdkVersion');

      // TODO: listen for isolate changes - fire events

      this.service = _service;

      _stateController.add(null);

      onClosed.then((_) => vmServiceClosed());
    }).catchError((e) {
      // TODO:
      print(e);
    });
  }

  void vmServiceClosed() {
    print('service connection closed');

    service = null;
    targetCpu = null;
    hostCPU = null;
    sdkVersion = null;

    _stateController.add(null);
  }
}
