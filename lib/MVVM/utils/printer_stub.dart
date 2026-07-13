import 'package:swiftclean_admin/MVVM/view/pages.dart/User/Profile_user.dart';
import 'package:swiftclean_admin/MVVM/view/pages.dart/User/User_roles.dart';
import 'package:swiftclean_admin/MVVM/view/pages.dart/User/Banned_users.dart';

void printUsersList(List<UserModel> users) {
  // Fallback for non-web environments
  print("Print users list stub called with ${users.length} users.");
}

void printRolesList(List<RoleModel> roles) {
  // Fallback for non-web environments
  print("Print roles list stub called with ${roles.length} roles.");
}

void printBannedUsersList(List<BannedUserModel> bannedUsers) {
  // Fallback for non-web environments
  print("Print banned users list stub called with ${bannedUsers.length} users.");
}
