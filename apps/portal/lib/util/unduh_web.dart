import 'dart:convert';
import 'dart:js_interop';

import 'package:web/web.dart' as web;

/// Unduh berkas teks lewat browser.
Future<void> unduhTeks(String namaBerkas, String isi, {String mime = 'text/plain'}) async {
  // BOM supaya Excel membaca UTF-8 dengan benar.
  final data = utf8.encode('﻿$isi');
  final blob = web.Blob([data.toJS].toJS, web.BlobPropertyBag(type: '$mime;charset=utf-8'));
  final url = web.URL.createObjectURL(blob);
  final a = web.HTMLAnchorElement()
    ..href = url
    ..download = namaBerkas;
  web.document.body?.append(a);
  a.click();
  a.remove();
  web.URL.revokeObjectURL(url);
}
