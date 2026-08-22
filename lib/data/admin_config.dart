const adminEmails = {'haroldisita666@gmail.com'};

bool isAdminEmail(String? email) {
  final value = email?.trim().toLowerCase();
  return value != null && adminEmails.contains(value);
}
