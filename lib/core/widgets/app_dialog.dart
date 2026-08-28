import 'package:flutter/material.dart';
import 'package:sole_toast/sole_toast.dart';

enum AppDialogKind { success, error, info }

class AppDialog {
  AppDialog._();

  static Future<void> show(
    BuildContext context, {
    required String message,
    String? title,
    AppDialogKind kind = AppDialogKind.info,
  }) {
    switch (kind) {
      case AppDialogKind.success:
        SoleToast.success(message);
      case AppDialogKind.error:
        SoleToast.error(message);
      case AppDialogKind.info:
        SoleToast.info(message);
    }
    return Future.value();
  }

  static Future<void> success(
    BuildContext context, {
    required String message,
    String? title,
  }) {
    SoleToast.success(message);
    return Future.value();
  }

  static Future<void> error(
    BuildContext context, {
    required String message,
    String? title,
  }) {
    SoleToast.error(message);
    return Future.value();
  }

  static Future<void> info(
    BuildContext context, {
    required String message,
    String? title,
  }) {
    SoleToast.info(message);
    return Future.value();
  }
}
