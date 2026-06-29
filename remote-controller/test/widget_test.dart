// Smoke test: the app builds and shows the rover control surface.

import 'package:car_remote_controller/main.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('app boots and shows the control surface', (tester) async {
    // The controller is hosted by a ProviderScope, same as in main().
    await tester.pumpWidget(const ProviderScope(child: MyApp()));
    await tester.pump();

    // The rover label and the idle readout are present on first frame.
    expect(find.text('ROVER'), findsOneWidget);
    expect(find.text('IDLE'), findsOneWidget);
  });
}
