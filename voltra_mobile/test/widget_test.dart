import 'package:flutter_test/flutter_test.dart';
import 'package:voltra_mobile/main.dart';

void main() {
  testWidgets('App boots successfully', (WidgetTester tester) async {
    await tester.pumpWidget(const VoltraApp());
    expect(find.text('VOLTRA'), findsOneWidget);
  });
}
