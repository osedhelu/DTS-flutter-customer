import 'dart:convert';
import 'dart:io';

import 'package:dts_customer/firebase_options.dart';
import 'package:flutter_test/flutter_test.dart';

/// Tests de configuración (sin UI): detectan desajustes OAuth/Firebase
/// que provocan fallos reales de Google Sign-In en dispositivo.
void main() {
  final root = Directory.current.path.endsWith('test')
      ? Directory.current.parent.path
      : Directory.current.path;

  Map<String, dynamic> readJson(String relative) {
    final file = File('$root/$relative');
    expect(file.existsSync(), isTrue, reason: 'Falta $relative');
    return jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
  }

  String readText(String relative) {
    final file = File('$root/$relative');
    expect(file.existsSync(), isTrue, reason: 'Falta $relative');
    return file.readAsStringSync();
  }

  group('Firebase project alignment', () {
    test('firebase_options usa proyecto dtsdrop-85330', () {
      expect(DefaultFirebaseOptions.android.projectId, 'dtsdrop-85330');
      expect(DefaultFirebaseOptions.ios.projectId, 'dtsdrop-85330');
      expect(DefaultFirebaseOptions.ios.iosBundleId, 'com.osedhelu.dts');
      expect(
        DefaultFirebaseOptions.googleServerClientId,
        contains('1015036938407-3b42tv87mauud225f3vfett7c5rtogof'),
      );
      expect(
        DefaultFirebaseOptions.ios.iosClientId,
        contains('1015036938407-5sv7g0c6ujt98g2imkq3u6qlddolij9s'),
      );
    });

    test('GoogleService-Info.plist coincide con firebase_options iOS', () {
      final plist = readText('ios/Runner/GoogleService-Info.plist');
      expect(plist, contains('dtsdrop-85330'));
      expect(plist, contains('com.osedhelu.dts'));
      expect(
        plist,
        contains(DefaultFirebaseOptions.ios.iosClientId!),
      );
      expect(
        plist,
        contains('1:1015036938407:ios:15899df8d947799f08b382'),
      );
    });

    test('Info.plist tiene GIDClientID y URL scheme de iOS OAuth', () {
      final info = readText('ios/Runner/Info.plist');
      final clientId = DefaultFirebaseOptions.ios.iosClientId!;
      final reversed =
          'com.googleusercontent.apps.${clientId.replaceAll('.apps.googleusercontent.com', '')}';

      expect(info, contains('<key>GIDClientID</key>'));
      expect(info, contains(clientId));
      expect(info, contains(reversed));
    });

    test('google-services.json package y project coinciden', () {
      final json = readJson('android/app/google-services.json');
      expect(json['project_info']['project_id'], 'dtsdrop-85330');

      final clients = json['client'] as List<dynamic>;
      final customer = clients.cast<Map<String, dynamic>>().firstWhere(
            (c) =>
                c['client_info']['android_client_info']['package_name'] ==
                'com.osedhelu.dts',
          );

      expect(
        customer['client_info']['mobilesdk_app_id'],
        DefaultFirebaseOptions.android.appId,
      );
    });
  });

  group('OAuth clients requeridos para Google Sign-In', () {
    test(
      'Android customer tiene oauth_client type 1 (SHA-1 registrado)',
      () {
        final json = readJson('android/app/google-services.json');
        final clients = json['client'] as List<dynamic>;
        final customer = clients.cast<Map<String, dynamic>>().firstWhere(
              (c) =>
                  c['client_info']['android_client_info']['package_name'] ==
                  'com.osedhelu.dts',
            );

        final oauth = (customer['oauth_client'] as List<dynamic>)
            .cast<Map<String, dynamic>>();
        final androidClients =
            oauth.where((o) => o['client_type'] == 1).toList();
        final webClients = oauth.where((o) => o['client_type'] == 3).toList();

        expect(
          webClients,
          isNotEmpty,
          reason: 'Falta Web client (type 3) = serverClientId',
        );
        expect(
          androidClients,
          isNotEmpty,
          reason:
              'Falta Android OAuth client (type 1). '
              'Sin SHA-1 en Firebase Console → ApiException: 10 / DEVELOPER_ERROR '
              'en Google Sign-In Android.',
        );
      },
    );

    test('serverClientId de firebase_options está en google-services.json', () {
      final json = readJson('android/app/google-services.json');
      final raw = jsonEncode(json);
      expect(raw, contains(DefaultFirebaseOptions.googleServerClientId));
    });

    test('iOS OAuth client (type 2) existe en google-services.json', () {
      final json = readJson('android/app/google-services.json');
      final raw = jsonEncode(json);
      expect(raw, contains(DefaultFirebaseOptions.ios.iosClientId!));
      expect(raw, contains('"client_type":2'));
    });
  });

  group('Bundle / package identifiers', () {
    test('Xcode bundle id es com.osedhelu.dts', () {
      final pbx = readText('ios/Runner.xcodeproj/project.pbxproj');
      expect(
        pbx,
        contains('PRODUCT_BUNDLE_IDENTIFIER = com.osedhelu.dts;'),
      );
      expect(pbx, isNot(contains('com.dts.dtsCustomer')));
    });

    test('Android applicationId es com.osedhelu.dts', () {
      final gradle = readText('android/app/build.gradle.kts');
      expect(gradle, contains('applicationId = "com.osedhelu.dts"'));
    });
  });
}
