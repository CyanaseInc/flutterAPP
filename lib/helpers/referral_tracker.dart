/// Singleton to hold referral code until user logs in
class ReferralTracker {
  static String? pendingCode;

  static void setCode(String code) => pendingCode = code;
  static String? getCode() => pendingCode;
  static void clear() => pendingCode = null;
}