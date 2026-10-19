import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/network/api_endpoints.dart';
import '../../../l10n/l10n.dart';

/// Yol tarifi adresi — yalnız [ApiEndpoints.directionsUrlTemplate] şablonundan üretilir.
Uri? directionsUri(double? lat, double? lng) {
  if (lat == null || lng == null) return null;
  return Uri.parse(
    ApiEndpoints.directionsUrlTemplate.replaceAll('{lat}', lat.toStringAsFixed(6)).replaceAll('{lng}', lng.toStringAsFixed(6)),
  );
}

/// Harici harita uygulamasını açar; açılamazsa [failureMessage] ile snackbar gösterir.
Future<void> openDirections(BuildContext context, Uri? uri, {required String failureMessage}) async {
  var ok = false;
  if (uri != null) {
    try {
      ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    } on Object {
      ok = false;
    }
  }
  if (!ok && context.mounted) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(failureMessage)));
  }
}

/// 650 → "650 m", 1240 → "1,2 km" (yerel ondalık ayırıcıyla).
String formatDistance(BuildContext context, int meters) {
  final l = context.l10n;
  if (meters < 1000) return l.mapDistanceMeters((meters / 10).round() * 10);
  final km = NumberFormat('0.#', Localizations.localeOf(context).languageCode).format(meters / 1000);
  return l.mapDistanceKm(km);
}
