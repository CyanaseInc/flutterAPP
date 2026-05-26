// lib/helpers/deep_link_handler.dart
import 'dart:async';
import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:cyanase/screens/home/group/group_invite.dart';
import 'referral_tracker.dart';
import 'package:cyanase/helpers/database_helper.dart';

class DeepLinkHandler {
  final AppLinks _appLinks = AppLinks();
  StreamSubscription<Uri?>? _linkSubscription;
  final GlobalKey<NavigatorState> navigatorKey;

  DeepLinkHandler({required this.navigatorKey});

  Future<void> initDeepLinks() async {
    try {
      Uri? initialUri = await _appLinks.getInitialLink();
      if (initialUri != null) {
        debugPrint('⚡ Initial deep link received: $initialUri');
        _handleDeepLink(initialUri);
      } else {
        debugPrint('⚡ No initial deep link received');
      }

      _linkSubscription = _appLinks.uriLinkStream.listen(
        (Uri? uri) {
          debugPrint('⚡ Stream deep link received: $uri');
          if (uri != null) {
            _handleDeepLink(uri);
          }
        },
        onError: (err) {
          debugPrint('❌ Error receiving deep link: $err');
        },
      );
    } catch (e, stack) {
      debugPrint('❌ Failed to initialize deep links: $e\n$stack');
    }
  }

  Future<void> _handleDeepLink(Uri uri) async {
    debugPrint('=========================');
    debugPrint('Handling deep link: $uri');
    debugPrint('Scheme: ${uri.scheme}');
    debugPrint('Host: ${uri.host}');
    debugPrint('PathSegments: ${uri.pathSegments}');
    debugPrint('QueryParameters: ${uri.queryParameters}');
    debugPrint('=========================');

    PendingDeepLink.uri = uri;

    final navigatorState = navigatorKey.currentState;
    if (navigatorState == null || !navigatorState.mounted) {
      debugPrint('❌ Navigator not ready, cannot navigate.');
      return;
    }

    // 1️⃣ Web Referral: https://cyanase.com/referral/r/ABC123
    if (uri.scheme == 'https' && uri.host == 'cyanase.com' &&
        uri.pathSegments.length >= 3 && uri.pathSegments[1] == 'r') {
      final code = uri.pathSegments[2];
      if (code.isNotEmpty) {
        debugPrint('✅ Web referral detected, code=$code');
        ReferralTracker.pendingCode = code;
        _pushIfNotCurrent(navigatorState, '/referral', arguments: {
          'inviteCode': code,
          'totalEarnings': 0.0,
        });
      } else {
        debugPrint('❌ Web referral detected but code is empty!');
      }
      return;
    }

    // 2️⃣ App Referral: cyanase://refer/ABC123
    if (uri.scheme == 'cyanase' && uri.host == 'refer') {
      if (uri.pathSegments.isNotEmpty) {
        final code = uri.pathSegments[0];
        debugPrint('✅ App referral detected, code=$code');
        await DatabaseHelper().storeInviteCode(code);
        _pushIfNotCurrent(navigatorState, '/signup');
      } else {
        debugPrint('❌ App referral detected but no code provided in pathSegments!');
      }
      return;
    }

    // 3️⃣ Legacy App/Web Referral: cyanase://referral?code=ABC123 or /referral/XYZ
    if ((uri.scheme == 'cyanase' || uri.scheme == 'https') &&
        uri.pathSegments.isNotEmpty &&
        uri.pathSegments[0] == 'referral') {
      String? code = uri.queryParameters['code'];
      if (code == null && uri.pathSegments.length >= 2) {
        code = uri.pathSegments[1];
      }
      if (code != null && code.isNotEmpty) {
        debugPrint('✅ Legacy referral detected, code=$code');
        await DatabaseHelper().storeInviteCode(code);
        _pushIfNotCurrent(navigatorState, '/signup');
      } else {
        debugPrint('❌ Legacy referral detected but no code found in path or query!');
      }
      return;
    }

    // 4️⃣ Group Invite: cyanase://join?group_id=123
    if (uri.scheme == 'cyanase' && uri.host == 'join') {
      final groupId = uri.queryParameters['group_id'];
      if (groupId?.isNotEmpty == true) {
        try {
          final groupIdInt = int.parse(groupId!);
          debugPrint('✅ Group invite detected, groupId=$groupIdInt');
          if (ModalRoute.of(navigatorState.context)?.settings.name != '/group_invite') {
            navigatorState.push(
              PageRouteBuilder(
                settings: const RouteSettings(name: '/group_invite'),
                pageBuilder: (context, animation, secondaryAnimation) =>
                    GroupInviteScreen(groupId: groupIdInt),
                transitionsBuilder: (context, animation, secondaryAnimation, child) {
                  return FadeTransition(opacity: animation, child: child);
                },
                transitionDuration: const Duration(milliseconds: 300),
              ),
            );
          }
        } catch (e) {
          debugPrint('❌ Failed to parse group_id: $e');
        }
      } else {
 
      }
      return;
    }

   
  }

  void _pushIfNotCurrent(
    NavigatorState nav,
    String routeName, {
    Map<String, dynamic>? arguments,
  }) {
    final current = ModalRoute.of(nav.context)?.settings.name;
    if (current == routeName) {
      debugPrint('ℹ️ Already on route $routeName, skipping push');
      return;
    }
    debugPrint('➡️ Navigating to $routeName with arguments=$arguments');
    nav.pushNamed(routeName, arguments: arguments);
  }

  void dispose() {
    debugPrint('🗑 Disposing DeepLinkHandler');
    _linkSubscription?.cancel();
  }
}

class PendingDeepLink {
  static Uri? uri;
}
