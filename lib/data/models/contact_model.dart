class ContactModel {
  final String name;
  final String? phone;
  final String? email;
  final String? company;

  const ContactModel({
    required this.name,
    this.phone,
    this.email,
    this.company,
  });

  factory ContactModel.fromMap(Map<String, dynamic> map) {
    return ContactModel(
      name: map['name'] ?? '',
      phone: map['phone'],
      email: map['email'],
      company: map['company'],
    );
  }

  factory ContactModel.fromString(String raw) {
    final parts = raw.split(' | ');
    return ContactModel(
      name: parts[0],
      phone: parts.length > 1 ? parts[1] : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'phone': phone,
      'email': email,
      'company': company,
    };
  }

  String toDisplayString() {
    final buf = StringBuffer(name);
    if (phone != null && phone!.isNotEmpty) buf.write('\n$phone');
    if (email != null && email!.isNotEmpty) buf.write('\n$email');
    if (company != null && company!.isNotEmpty) buf.write('\n$company');
    return buf.toString();
  }
}
