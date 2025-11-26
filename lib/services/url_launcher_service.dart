import 'dart:io';

import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/config/app_urls.dart';

class UrlLauncherService {
  /// Launch a URL in the default browser
  Future<bool> launchURL(String url) async {
    try {
      final Uri uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        return await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        debugPrint('Could not launch $url');
        return false;
      }
    } catch (e) {
      debugPrint('Error launching URL: $e');
      return false;
    }
  }

  /// Open email client with pre-filled email
  Future<bool> sendEmail(
    String emailAddress, {
    String subject = '',
    String body = '',
  }) async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: emailAddress,
      queryParameters: {'subject': subject, 'body': body},
    );

    try {
      if (await canLaunchUrl(emailUri)) {
        return await launchUrl(emailUri);
      } else {
        debugPrint('Could not launch email client');
        return false;
      }
    } catch (e) {
      debugPrint('Error launching email: $e');
      return false;
    }
  }

  /// Open the app store page for rating
  Future<bool> openAppStore() async {
    final String appStoreUrl = Platform.isIOS
        ? AppUrls.appStoreReviewUrl
        : AppUrls.playStoreUrl;

    return await launchURL(appStoreUrl);
  }

  /// Share the app with others
  Future<void> shareApp() async {
    try {
      final text =
          '${AppUrls.shareAppMessage}\n\nAppStore: ${AppUrls.appStoreUrl}';

      // Use the basic Share.share method which should be available
      await SharePlus.instance.share(
        ShareParams(
          text: text,
          sharePositionOrigin: Rect.fromLTWH(0, 0, 100, 100),
        ),
      );
    } catch (e) {
      debugPrint('Error sharing app: $e');
    }
  }
}
