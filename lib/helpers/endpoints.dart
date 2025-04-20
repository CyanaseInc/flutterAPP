class ApiEndpoints {
  //static const String server = "https/://server.cyanase.app";
  static const String server = "http://192.168.206.220:8000";

  static const String checkuser = "$server/api/v1/en/checkUser/user/";
  static const String signup = "$server/api/v1/en/register/user/";
  static const String createGroup = "$server/api/v1/en/register/user/";
  static const String approveRequest =
      "$server/api/v1/en/approve/request/group/";
  static const String loanSettingUrl = "$server/api/v1/en/loan/setting/group/";
  static const String denyRequest = "$server/api/v1/en/deny/request/group/";
  static const String payTojoin = "$server/api/v1/en/pay/to/join/group/";
  static const String newGroup = "$server/api/v1/en/newgroup/group/";
  static const String joinGroup = "$server/api/v1/en/register/user/";
  static const String sendMessage = "$server/api/v1/en/register/user/";
  static const String fetchGroups = "$server/api/v1/en/register/user/";
  static const String apiUrlDeposit = "$server/api/v1/en/make/deposit/";
  static const String updateProfile = "$server/api/v1/en/register/user/";
  static const String fetchMessages = "$server/api/v1/en/register/user/";
  static const String getGroup = "$server/api/v1/en/getgroup/group/";
  static const String validatePhone = "$server/api/v1/en/validate/mm/number/";
  static const String requestPayment = "$server/api/v1/en/request/payment/";
  static const String requestPaymentWebhook =
      "$server/api/v1/en/requestpaymentshook/";
  static const String getTransaction = "$server/api/v1/en/get/transaction/";
  static const String verifyOtp = "$server/api/v1/en/verifyemail/user/";
  static const String passcode = "$server/api/v1/en/passcode/user/";
  static const String fetchUserDetails = "$server/api/v1/en/register/user/";
  static const String apiUrlGetInvestmentClasses =
      "$server/api/v1/en/auth/get/investment/classes/";
  static const apiUrlGetGroupDetails = "$server/api/v1/en/details/group/";
  static const apiUrlGetGroupDetailsNonUser =
      "$server/api/v1/en/details/join/group/";
  static const String apiUrlGetInvestmentOptions =
      "$server/api/v1/en/auth/get/investment/options/";
  static const String apiUrlGetInvestmentClassOptions =
      "$server/api/v1/en/auth/get/investment/class/options/";
  static const String apiUrlGetFundInvestmentClass =
      "$server/api/v1/en/auth/get/fund/investment/class/";
  static const String apiUrlGetInvestmentOption =
      "$server/api/v1/en/auth/get/investment/option/";
  static const String apiUrlBankWithdraw =
      "$server/api/v1/en/make/bank/withdraw/";
  static const String apiUrlMmWithdraw = "$server/api/v1/en/make/mm/withdraw/";
  static const String apiUrlGoalBankWithdraw =
      "$server/api/v1/en/make/goal/bank/withdraw/";
  static const String apiUrlGoalMmWithdraw =
      "$server/api/v1/en/make/goal/mm/withdraw/";
  static const String apiUrlGoalDeposit =
      "$server/api/v1/en/make/goal/deposit/";
  static const String apiUrlGetDeposit = "$server/api/v1/en/get/deposit/";
  static const String apiUrlGetUserTrack = "$server/api/v1/en/get/user/track/";
  static const String apiUrlGetSubStatus =
      "$server/api/v1/en/get/subscription/status/";
  static const String paySubscription = "$server/api/v1/en/make/subscription/";
  static const String apiUrlGetWithdraw = "$server/api/v1/en/get/withdraw/";
  static const String apiUrlGetWithdrawFee =
      "$server/api/v1/en/get/withdraw/fee/";
  static const String apiUrlGetPendingWithdraw =
      "$server/api/v1/en/get/pending/withdraw/";
  static const String apiUrlGetGoalWithdraw =
      "$server/api/v1/en/get/goal/withdraw/";
  static const String apiUrlGoal = "$server/api/v1/en/create/goal/";
  static const String apiUrlGroupGoal = "$server/api/v1/en/creategroup/goal/";
  static const String editGroup = "$server/api/v1/en/editgroup/group/";
  static const String editGroupGoal = "$server/api/v1/en/editgroupgoal/group/";
  static const String addMembers = "$server/api/v1/en/addmembers/group/";
  static const String editGoal = "$server/api/v1/en/edit/goal/";
  static const String deleteGoal = "$server/api/v1/en/delete/goal/by/id/";
  static const String deleteGroupGoal = "$server/api/v1/en/delete/group/goal/";
  static const String deleteGroupPic = "$server/api/v1/en/delete/group/pic/";
  static const String changeGroupPic = "$server/api/v1/en/change/group/pic/";
  static const String uploadGoalPhoto =
      "$server/api/v1/en/auth/upload/goal/photo/";
  static const String apiUrlGetAllFundManagers =
      "$server/api/v1/en/auth/fundmanagers/all/";
  static const String apiUrlGetGoalDeposit =
      "$server/api/v1/en/get/deposit/by/goal/";
  static const String apiUrlGetGoal = "$server/api/v1/en/get/user/goal/";
  static const String apiEmailVerify =
      "$server/api/v1/en/get/user/verification/";
  static const String apiResendVerificationEmail =
      "$server/api/v1/en/resend/verification/email/";
  static const String apiUrlUserProfilePhoto =
      "$server/api/v1/en/auth/user/upload/profile/photo/";
  static const String apiUrlGoalPhoto =
      "$server/api/v1/en/auth/upload/goal/photo/";
  static const String apiUrlUserGetProfilePhoto = "$server/static/photo.png";
  static const String apiUrlUserNetWorth =
      "$server/api/v1/en/auth/user/networth/";
  //static const String login = "$server/api/v1/en/app/user/login/";
  static const String login = "$server/api/v1/en/auth/user/login/";
  static const String passcodeLogin = "$server/api/v1/en/auth/user/passcode/";
  static const String apiUrlUserNextOfKin = "$server/api/v1/en/user/nextOfKin/";
  static const String apiUrlGetNextOfKin = "$server/api/v1/en/get/nextOfKin/";
  static const String apiUrlGetToken = "$server/api/v1/en/auth/token/";
  static const String apiUrlGetAuthUser = "$server/api/v1/en/auth/user/";
  static const String apiUrlRegisterApiUser =
      "$server/api/v1/en/register/api/user/";
  static const String apiUrlGetAuthUserByEmail =
      "$server/api/v1/en/auth/user/email/";
  static const String apiUrlAddAuthUserRiskProfile =
      "$server/api/v1/en/auth/user/riskprofile/";
  static const String apiUrlGetRiskProfile =
      "$server/api/v1/en/auth/get/riskprofile/";
  static const String checkPasswordEmail =
      "$server/api/v1/en/app/password/reset/";
  static const String apiUrlPasswordReset = "$server/app/reset/password/";
  static const String apiUrlGetUserVerification =
      "$server/api/v1/en/get/verification/";
  static const String apiUrlGetRiskAnalysisPercentages =
      "$server/api/v1/en/get/risk/analysis/percentages/";
  static const String apiUrlResetPassword = "$server/reset/password/";
  static const String profilePhoto =
      "$server/media/profile/default_picture.jpg";
  static const String goalPhoto = "$server/media/goal/default_picture.jpg";
  static const String apiUrlGetInvestmentWithdraws =
      "$server/api/v1/en/get/investment/withdraws/";
  static const String apiUrlGetUserBanks = "$server/api/v1/en/auth/user/banks/";
  static const String apiDocs = "developers.cyanase.app";
}
