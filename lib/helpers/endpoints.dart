class ApiEndpoints {
  static const String server = "server.cyanase.app";
  // static const String server = "127.0.0.1:8000";

  static const String signup = "https://$server/api/v1/en/register/user/";
  static const String createGroup = "https://$server/api/v1/en/register/user/";
  static const String joinGroup = "https://$server/api/v1/en/register/user/";
  static const String sendMessage = "https://$server/api/v1/en/register/user/";
  static const String fetchGroups = "https://$server/api/v1/en/register/user/";
  static const String apiUrlDeposit = "https://$server/api/v1/en/make/deposit/";
  static const String updateProfile =
      "https://$server/api/v1/en/register/user/";
  static const String fetchMessages =
      "https://$server/api/v1/en/register/user/";

  static const String verifyOtp = "https://$server/api/v1/en/register/user/";
  static const String fetchUserDetails =
      "https://$server/api/v1/en/register/user/";
  static const String apiUrlGetInvestmentClasses =
      "https://$server/api/v1/en/auth/get/investment/classes/";
  static const String apiUrlGetInvestmentOptions =
      "https://$server/api/v1/en/auth/get/investment/options/";
  static const String apiUrlGetInvestmentClassOptions =
      "https://$server/api/v1/en/auth/get/investment/class/options/";
  static const String apiUrlGetFundInvestmentClass =
      "https://$server/api/v1/en/auth/get/fund/investment/class/";
  static const String apiUrlGetInvestmentOption =
      "https://$server/api/v1/en/auth/get/investment/option/";
  static const String apiUrlBankWithdraw =
      "https://$server/api/v1/en/make/bank/withdraw/";
  static const String apiUrlMmWithdraw =
      "https://$server/api/v1/en/make/mm/withdraw/";
  static const String apiUrlGoalBankWithdraw =
      "https://$server/api/v1/en/make/goal/bank/withdraw/";
  static const String apiUrlGoalMmWithdraw =
      "https://$server/api/v1/en/make/goal/mm/withdraw/";
  static const String apiUrlGoalDeposit =
      "https://$server/api/v1/en/make/goal/deposit/";
  static const String apiUrlGetDeposit =
      "https://$server/api/v1/en/get/deposit/";
  static const String apiUrlGetSubStatus =
      "https://$server/api/v1/en/get/subscription/status/";
  static const String apiUrlSubscribe =
      "https://$server/api/v1/en/make/subscription/";
  static const String apiUrlGetWithdraw =
      "https://$server/api/v1/en/get/withdraw/";
  static const String apiUrlGetWithdrawFee =
      "https://$server/api/v1/en/get/withdraw/fee/";
  static const String apiUrlGetPendingWithdraw =
      "https://$server/api/v1/en/get/pending/withdraw/";
  static const String apiUrlGetGoalWithdraw =
      "https://$server/api/v1/en/get/goal/withdraw/";
  static const String apiUrlGoal = "https://$server/api/v1/en/create/goal/";
  static const String apiUrlGetAllFundManagers =
      "https://$server/api/v1/en/auth/fundmanagers/all/";
  static const String apiUrlGetGoalDeposit =
      "https://$server/api/v1/en/get/deposit/by/goal/";
  static const String apiUrlGetGoal =
      "https://$server/api/v1/en/get/user/goal/";
  static const String apiEmailVerify =
      "https://$server/api/v1/en/get/user/verification/";
  static const String apiResendVerificationEmail =
      "https://$server/api/v1/en/resend/verification/email/";
  static const String apiUrlUserProfilePhoto =
      "https://$server/api/v1/en/auth/user/upload/profile/photo/";
  static const String apiUrlGoalPhoto =
      "https://$server/api/v1/en/auth/upload/goal/photo/";
  static const String apiUrlUserGetProfilePhoto =
      "https://$server/static/photo.png";
  static const String apiUrlUserNetWorth =
      "https://$server/api/v1/en/auth/user/networth/";
  static const String login = "https://$server/api/v1/en/auth/user/login/";
  static const String apiUrlUserNextOfKin =
      "https://$server/api/v1/en/user/nextOfKin/";
  static const String apiUrlGetNextOfKin =
      "https://$server/api/v1/en/get/nextOfKin/";
  static const String apiUrlGetToken = "https://$server/api/v1/en/auth/token/";
  static const String apiUrlGetAuthUser =
      "https://$server/api/v1/en/auth/user/";
  static const String apiUrlRegisterApiUser =
      "https://$server/api/v1/en/register/api/user/";
  static const String apiUrlGetAuthUserByEmail =
      "https://$server/api/v1/en/auth/user/email/";
  static const String apiUrlAddAuthUserRiskProfile =
      "https://$server/api/v1/en/auth/user/riskprofile/";
  static const String apiUrlGetRiskProfile =
      "https://$server/api/v1/en/auth/get/riskprofile/";
  static const String apiUrlUserUpdatePassword =
      "https://$server/api/v1/en/auth/user/update/password/";
  static const String apiUrlPasswordReset =
      "https://$server/api/v1/en/password/reset/";
  static const String apiUrlGetUserVerification =
      "https://$server/api/v1/en/get/verification/";
  static const String apiUrlGetRiskAnalysisPercentages =
      "https://$server/api/v1/en/get/risk/analysis/percentages/";
  static const String apiUrlResetPassword = "https://$server/reset/password/";
  static const String profilePhoto =
      "https://$server/media/profile/default_picture.jpg";
  static const String goalPhoto =
      "https://$server/media/goal/default_picture.jpg";
  static const String apiUrlGetInvestmentWithdraws =
      "https://$server/api/v1/en/get/investment/withdraws/";
  static const String apiUrlGetUserTrack =
      "https://$server/api/v1/en/get/user/track/";
  static const String apiUrlGetUserBanks =
      "https://$server/api/v1/en/auth/user/banks/";
  static const String apiDocs = "https://developers.cyanase.app";
}
