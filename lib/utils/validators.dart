class Validators {
  static String? requiredField(String? v, {String msg = 'Required'}) {
    if (v == null || v.trim().isEmpty) return msg;
    return null;
  }

  static String? email(String? v) {
    if (v == null || v.trim().isEmpty) return 'Email required';
    final ok = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(v.trim());
    if (!ok) return 'Invalid email format';
    return null;
  }

  static String? password(String? v) {
    if (v == null || v.isEmpty) return 'Password required';
    if (v.length < 6) return 'Password must be at least 6 characters';
    return null;
  }
}
