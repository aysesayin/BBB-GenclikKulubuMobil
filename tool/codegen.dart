// Kod üretimi: ARB parçalarını birleştirir, gen-l10n ve (istenirse) build_runner çalıştırır.
//
//   dart run tool/codegen.dart          → yalnız l10n
//   dart run tool/codegen.dart --build  → l10n + freezed/json_serializable
//
// Her özellik kendi metinlerini lib/l10n/parts/<ozellik>_tr.arb ve _en.arb
// dosyalarına yazar; bu betik hepsini lib/l10n/arb/app_{tr,en}.arb'a birleştirir.
// Aynı anda birden çok çalıştırmaya karşı .dart_tool/codegen.lock ile kilitlenir.
import 'dart:convert';
import 'dart:io';

const _locales = ['tr', 'en'];
final _lock = File('.dart_tool/codegen.lock');

Future<void> main(List<String> args) async {
  await _acquire();
  try {
    _merge();
    // l10n.yaml bilerek yok: o dosya varken her flutter run/build çıktıyı yeniden yazıyor ve
    // eşzamanlı komutlarda lib/l10n/generated boş kalabiliyordu. Ayarlar burada.
    await _run(_flutter, [
      'gen-l10n',
      '--arb-dir=lib/l10n/arb',
      '--template-arb-file=app_tr.arb',
      '--output-localization-file=app_localizations.dart',
      '--output-class=AppLocalizations',
      '--output-dir=lib/l10n/generated',
      '--no-nullable-getter',
    ]);
    if (args.contains('--build')) {
      await _run(Platform.resolvedExecutable, ['run', 'build_runner', 'build', '--delete-conflicting-outputs']);
    }
  } finally {
    if (_lock.existsSync()) _lock.deleteSync();
  }
}

void _merge() {
  final parts = Directory('lib/l10n/parts');
  for (final loc in _locales) {
    final merged = <String, Object?>{'@@locale': loc};
    final owners = <String, String>{};
    final files = parts.listSync().whereType<File>().where((f) => f.path.endsWith('_$loc.arb')).toList()
      ..sort((a, b) => a.path.compareTo(b.path));
    for (final f in files) {
      final json = jsonDecode(f.readAsStringSync()) as Map<String, Object?>;
      for (final e in json.entries) {
        if (e.key.startsWith('@@')) continue;
        final prev = owners[e.key];
        if (prev != null) {
          stderr.writeln('HATA: "${e.key}" anahtarı hem $prev hem ${f.path} içinde.');
          exitCode = 1;
          continue;
        }
        owners[e.key] = f.path;
        merged[e.key] = e.value;
      }
    }
    final out = File('lib/l10n/arb/app_$loc.arb')..createSync(recursive: true);
    out.writeAsStringSync('${const JsonEncoder.withIndent('  ').convert(merged)}\n');
    stdout.writeln('l10n: ${files.length} parça → ${out.path} (${owners.length} anahtar)');
  }
  _checkMissing();
}

void _checkMissing() {
  Map<String, Object?> read(String loc) =>
      jsonDecode(File('lib/l10n/arb/app_$loc.arb').readAsStringSync()) as Map<String, Object?>;
  final tr = read('tr').keys.where((k) => !k.startsWith('@')).toSet();
  final en = read('en').keys.where((k) => !k.startsWith('@')).toSet();
  final missing = tr.difference(en);
  if (missing.isNotEmpty) stdout.writeln('UYARI: en çevirisi eksik: ${missing.take(20).join(', ')}');
}

String get _flutter {
  // dart-sdk/bin/dart(.exe) → flutter/bin/flutter(.bat)
  final dartBin = File(Platform.resolvedExecutable).parent;
  final flutterBin = dartBin.parent.parent.parent;
  final name = Platform.isWindows ? 'flutter.bat' : 'flutter';
  final candidate = File('${flutterBin.path}${Platform.pathSeparator}$name');
  return candidate.existsSync() ? candidate.path : 'flutter';
}

Future<void> _run(String exe, List<String> args) async {
  final p = await Process.start(exe, args, runInShell: Platform.isWindows, mode: ProcessStartMode.inheritStdio);
  final code = await p.exitCode;
  if (code != 0) {
    stderr.writeln('${args.join(' ')} başarısız ($code)');
    exitCode = code;
  }
}

Future<void> _acquire() async {
  _lock.parent.createSync(recursive: true);
  final deadline = DateTime.now().add(const Duration(minutes: 10));
  while (true) {
    try {
      _lock.createSync(exclusive: true);
      _lock.writeAsStringSync('$pid');
      return;
    } on FileSystemException {
      final age = _lock.existsSync() ? DateTime.now().difference(_lock.lastModifiedSync()) : Duration.zero;
      if (age > const Duration(minutes: 6)) {
        _lock.deleteSync();
        continue;
      }
      if (DateTime.now().isAfter(deadline)) throw StateError('codegen kilidi alınamadı');
      stdout.writeln('codegen: başka bir üretim bitene kadar bekleniyor…');
      await Future<void>.delayed(const Duration(seconds: 3));
    }
  }
}
