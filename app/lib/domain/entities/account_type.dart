/// The four user types from the product brief. [id] matches the Firestore value.
enum AccountType {
  personal('personal', 'Personal'),
  businessOwner('business_owner', 'Business Owner'),
  creator('creator', 'Content Creator'),
  investor('investor', 'Investor / Professional');

  const AccountType(this.id, this.label);

  final String id;
  final String label;

  static AccountType fromId(String? id) => AccountType.values.firstWhere(
        (e) => e.id == id,
        orElse: () => AccountType.personal,
      );
}
