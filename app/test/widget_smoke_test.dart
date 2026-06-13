import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myspot/core/widgets/verified_badge.dart';
import 'package:myspot/domain/entities/account_type.dart';

void main() {
  test('AccountType.fromId maps known and unknown ids', () {
    expect(AccountType.fromId('business_owner'), AccountType.businessOwner);
    expect(AccountType.fromId('investor'), AccountType.investor);
    expect(AccountType.fromId(null), AccountType.personal);
    expect(AccountType.fromId('nonsense'), AccountType.personal);
  });

  testWidgets('VerifiedBadge renders a semantic verified icon', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: VerifiedBadge())),
    );
    expect(find.byIcon(Icons.verified), findsOneWidget);
  });
}
