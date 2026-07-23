import 'package:swiftclean_admin/MVVM/view/pages.dart/User/Profile_user.dart';
import 'package:swiftclean_admin/MVVM/view/pages.dart/User/User_roles.dart';
import 'package:swiftclean_admin/MVVM/view/pages.dart/User/Banned_users.dart';
import 'package:swiftclean_admin/MVVM/view/pages.dart/worker/All_workers.dart';
import 'package:swiftclean_admin/MVVM/view/pages.dart/Bookings/Bookings.dart';
import 'package:swiftclean_admin/MVVM/view/pages.dart/Services/Services.dart';
import 'package:swiftclean_admin/MVVM/view/pages.dart/Services/Categories.dart';

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

void printWorkersList(List<WorkerModel> workers) {
  // Fallback for non-web environments
  print("Print workers list stub called with ${workers.length} workers.");
}

void printBookingsList(List<BookingModel> bookings) {
  // Fallback for non-web environments
  print("Print bookings list stub called with ${bookings.length} bookings.");
}

void printServicesList(List<ServiceModel> services) {
  // Fallback for non-web environments
  print("Print services list stub called with ${services.length} services.");
}

void printCategoriesList(List<CategoryModel> categories) {
  // Fallback for non-web environments
  print("Print categories list stub called with ${categories.length} categories.");
}

void exportPaymentsToPdfWeb(List<Map<String, String>> payments) {
  // Fallback for non-web environments
  print("Print payments list stub called with ${payments.length} payments.");
}
