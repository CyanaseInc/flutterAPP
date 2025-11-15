// lib/helpers/deep_link_handler.dart
import 'dart:async';
import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:cyanase/screens/home/group/group_invite.dart';
import 'referral_tracker.dart';

class DeepLinkHandler {
  final AppLinks _appLinks = AppLinks();
  StreamSubscription<Uri?>? _linkSubscription;
  final GlobalKey<NavigatorState> navigatorKey;

  DeepLinkHandler({required this.navigatorKey});

  Future<void> initDeepLinks() async {
    try {
      Uri? initialUri = await _appLinks.getInitialLink();
      if (initialUri != null) {
        _handleDeepLink(initialUri);
      }

      _linkSubscription = _appLinks.uriLinkStream.listen(
        (Uri? uri) {
          debugPrint('Received deep link: $uri');
          if (uri != null) {
            _handleDeepLink(uri);
          }
        },
        onError: (err) {
          debugPrint('Error receiving deep link: $err');
        },
      );
    } catch (e) {
      debugPrint('Failed to initialize deep links: $e');
    }
  }

  void _handleDeepLink(Uri uri) {
    debugPrint('Handling deep link: $uri');
    PendingDeepLink.uri = uri;

    final navigatorState = navigatorKey.currentState;
    if (navigatorState == null || !navigatorState.mounted) {
      debugPrint('Navigator not ready');
      return;
    }

    // ————————————————————
    // 1. Web Referral: https://cyanase.com/referral/r/ABC123
    // ————————————————————
    if (uri.host == 'cyanase.com' && uri.pathSegments.length == 3 && uri.pathSegments[1] == 'r') {
      final code = uri.pathSegments[2];
      if (code.isNotEmpty) {
        ReferralTracker.pendingCode = code;
        _pushIfNotCurrent(navigatorState, '/referral', arguments: {
          'inviteCode': code,
          'totalEarnings': 0.0,
        });
      }
      return;
    }

    // ————————————————————
    // 2. App Referral: cyanase://referral?code=ABC123
    // ————————————————————
    if (uri.scheme == 'cyanase' && uri.host == 'referral') {
      final code = uri.queryParameters['code'];
      if (code?.isNotEmpty == true) {
        ReferralTracker.pendingCode = code;
        _pushIfNotCurrent(navigatorState, '/referral', arguments: {
          'inviteCode': code,
          'totalEarnings': 0.0,
        });
      }
      return;
    }

    // ————————————————————
    // 3. Group Invite
    // ————————————————————
    if (uri.scheme == 'cyanase' && uri.host == 'join') {
      final groupId = uri.queryParameters['group_id'];
      if (groupId?.isNotEmpty == true) {
        try {
          final groupIdInt = int.parse(groupId!);
          debugPrint('Navigating to GroupInviteScreen with groupId=$groupIdInt');

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
          debugPrint('Failed to parse group_id: $e');
        }
      }
      return;
    }

    debugPrint('Unsupported deep link: $uri');
  }

  void _pushIfNotCurrent(
    NavigatorState nav,
    String routeName, {
    Map<String, dynamic>? arguments,
  }) {
    final current = ModalRoute.of(nav.context)?.settings.name;
    if (current == routeName) return;
    nav.pushNamed(routeName, arguments: arguments);
  }

  void dispose() {
    debugPrint('Disposing DeepLinkHandler');
    _linkSubscription?.cancel();
  }
}

class PendingDeepLink {
  static Uri? uri;
}