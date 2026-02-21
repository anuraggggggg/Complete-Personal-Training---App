class SendReferrals {
  final bool status;
  final ReferralData? data;

  SendReferrals({
    required this.status,
    this.data,
  });

  factory SendReferrals.fromJson(Map<String, dynamic> json) {
    return SendReferrals(
      status: json['status'] ?? false,
      data: json['data'] != null
          ? ReferralData.fromJson(json['data'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'status': status,
      'data': data?.toJson(),
    };
  }
}

class ReferralData {
  final String referralCode;
  final String referralStatus;
  final int referralCreditBalance;
  final int totalReferrals;
  final List<dynamic> redemptions;

  ReferralData({
    required this.referralCode,
    required this.referralStatus,
    required this.referralCreditBalance,
    required this.totalReferrals,
    required this.redemptions,
  });

  factory ReferralData.fromJson(Map<String, dynamic> json) {
    return ReferralData(
      referralCode: json['referral_code'] ?? '',
      referralStatus: json['referral_status'] ?? '',
      referralCreditBalance:
          int.tryParse(json['referral_credit_balance'].toString()) ?? 0,
      totalReferrals:
          int.tryParse(json['total_referrals'].toString()) ?? 0,
      redemptions: json['redemptions'] is List
          ? List<dynamic>.from(json['redemptions'])
          : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'referral_code': referralCode,
      'referral_status': referralStatus,
      'referral_credit_balance': referralCreditBalance,
      'total_referrals': totalReferrals,
      'redemptions': redemptions,
    };
  }

  // 🔥 UI-friendly helpers
  bool get isActive => referralStatus.toLowerCase() == "active";
  bool get hasCredit => referralCreditBalance > 0;
}
