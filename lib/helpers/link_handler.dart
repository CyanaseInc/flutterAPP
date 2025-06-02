import 'dart:async';
import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:cyanase/screens/home/group/group_invite.dart';

class DeepLinkHandler {
  final AppLinks _appLinks = AppLinks();
  StreamSubscription<Uri?>? _linkSubscription;
  final GlobalKey<NavigatorState> navigatorKey;

  DeepLinkHandler({required this.navigatorKey});

  Future<void> initDeepLinks() async {
    try {
      // Handle initial link when app is launched
      Uri? initialUri = await _appLinks.getInitialLink();
      
      if (initialUri != null) {
        _handleDeepLink(initialUri);
      }

      // Handle links when app is in foreground/background
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
    if (uri.scheme == 'cyanase' && uri.host == 'join') {
      final groupId = uri.queryParameters['group_id'];

      if (groupId?.isNotEmpty == true) {
        try {
          final groupIdInt = int.parse(groupId!);
          debugPrint(
              'Navigating to GroupInviteScreen with groupId=$groupIdInt');
          final navigatorState = navigatorKey.currentState;
          if (navigatorState != null && navigatorState.mounted) {
            // Prevent duplicate navigation
            if (ModalRoute.of(navigatorState.context)?.settings.name !=
                '/group_invite') {
              navigatorState.push(
                PageRouteBuilder(
                  settings: const RouteSettings(name: '/group_invite'),
                  pageBuilder: (context, animation, secondaryAnimation) =>
                      GroupInviteScreen(
                    groupId: groupIdInt,
                  ),
                  transitionsBuilder:
                      (context, animation, secondaryAnimation, child) {
                    return FadeTransition(
                      opacity: animation,
                      child: child,
                    );
                  },
                  transitionDuration: const Duration(milliseconds: 300),
                ),
              );
            } else {
              debugPrint('Already on GroupInviteScreen, skipping navigation');
            }
          } else {
            debugPrint('Navigator state is null or not mounted');
          }
        } catch (e) {
          debugPrint('Failed to parse group_id: $e');
        }
      } else {
        debugPrint('Invalid deep link parameters: group_id=$groupId');
      }
    } else {
      debugPrint('Unsupported deep link scheme or host: $uri');
    }
  }

  void dispose() {
    debugPrint('Disposing DeepLinkHandler');
    _linkSubscription?.cancel();
  }
}
