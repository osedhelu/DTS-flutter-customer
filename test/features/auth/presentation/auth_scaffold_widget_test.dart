import 'package:dts_customer/core/theme/app_breakpoints.dart';
import 'package:dts_customer/core/theme/app_theme.dart';
import 'package:dts_customer/features/auth/presentation/widgets/auth_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('AuthScaffold limita el form a authFormMaxWidth en tablet',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(900, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: AuthScaffold(
          body: ColoredBox(
            color: Colors.red,
            child: SizedBox(
              height: 80,
              width: double.infinity,
              child: Text(
                'auth-body',
                key: const Key('auth_body'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final bodySize = tester.getSize(find.byKey(const Key('auth_body')));
    expect(bodySize.width, lessThanOrEqualTo(AppBreakpoints.authFormMaxWidth));
    expect(bodySize.width, lessThan(900));
  });

  testWidgets('AuthScaffold en dark usa surface del ColorScheme',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: AuthScaffold(
          body: Builder(
            builder: (context) {
              final scheme = Theme.of(context).colorScheme;
              return Text(
                'dark-ok',
                style: TextStyle(color: scheme.onSurface),
              );
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final text = tester.widget<Text>(find.text('dark-ok'));
    expect(text.style?.color, AppTheme.dark.colorScheme.onSurface);
    expect(find.text('dark-ok'), findsOneWidget);
  });
}
