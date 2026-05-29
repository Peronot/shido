import 'package:flutter/material.dart';
import 'package:quickalert/quickalert.dart';

class AppAlerts {
  static void success(
    BuildContext context, {
    required String title,
    required String text,
  }) {
    QuickAlert.show(
      context: context,
      type: QuickAlertType.success,
      title: title,
      text: text,
    );
  }

  static void error(
    BuildContext context, {
    required String title,
    required String text,
  }) {
    QuickAlert.show(
      context: context,
      type: QuickAlertType.error,
      title: title,
      text: text,
    );
  }

  static void warning(
    BuildContext context, {
    required String title,
    required String text,
  }) {
    QuickAlert.show(
      context: context,
      type: QuickAlertType.warning,
      title: title,
      text: text,
    );
  }

  static void info(
    BuildContext context, {
    required String title,
    required String text,
  }) {
    QuickAlert.show(
      context: context,
      type: QuickAlertType.info,
      title: title,
      text: text,
    );
  }

  static Future<void> confirm(
    BuildContext context, {
    required String title,
    required String text,
    required VoidCallback onConfirm,
  }) async {
    await QuickAlert.show(
      context: context,
      type: QuickAlertType.confirm,
      title: title,
      text: text,
      onConfirmBtnTap: onConfirm,
    );
  }

  static Future<bool> confirmBool(
    BuildContext context, {
    required String title,
    required String text,
    String confirmText = 'Confirm',
    String cancelText = 'Cancel',
  }) async {
    bool confirmed = false;
    await QuickAlert.show(
      context: context,
      type: QuickAlertType.confirm,
      title: title,
      text: text,
      confirmBtnText: confirmText,
      cancelBtnText: cancelText,
      onConfirmBtnTap: () {
        confirmed = true;
        close(context);
      },
      onCancelBtnTap: () {
        confirmed = false;
        close(context);
      },
    );
    return confirmed;
  }

  static void loading(
    BuildContext context, {
    String title = 'Loading',
    String text = 'Fadlan sug...',
  }) {
    QuickAlert.show(
      context: context,
      type: QuickAlertType.loading,
      title: title,
      text: text,
      barrierDismissible: false,
    );
  }

  static void close(BuildContext context) {
    final navigator = Navigator.of(context, rootNavigator: true);
    if (navigator.canPop()) {
      navigator.pop();
    }
  }
}
