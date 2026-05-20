import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

enum AppPermission {
  locationWhenInUse,
  camera,
  photos,
  notifications,
  microphone,
  contacts,
}

/// Central permission manager.
///
/// Call [request] anywhere you need a permission — it handles the OS prompt and,
/// if the user has permanently denied, shows a branded dialog that deep-links to
/// Settings. Call [isGranted] for a silent status check with no UI.
class PermissionService {
  static final PermissionService instance = PermissionService._();
  PermissionService._();

  /// Requests [type]. Returns true if granted after this call.
  /// Shows a "go to Settings" dialog automatically when permanently denied.
  Future<bool> request(AppPermission type, BuildContext context) async {
    final permission = _toPermission(type);
    var status = await permission.status;

    if (status.isGranted || status.isLimited) return true;

    if (status.isPermanentlyDenied) {
      if (context.mounted) await _showDeniedDialog(type, context);
      return false;
    }

    status = await permission.request();
    if (status.isGranted || status.isLimited) return true;

    if (status.isPermanentlyDenied && context.mounted) {
      await _showDeniedDialog(type, context);
    }
    return false;
  }

  /// Silent status check — no UI shown. Returns true if granted or limited.
  Future<bool> isGranted(AppPermission type) async {
    final status = await _toPermission(type).status;
    return status.isGranted || status.isLimited;
  }

  Permission _toPermission(AppPermission type) => switch (type) {
        AppPermission.locationWhenInUse => Permission.locationWhenInUse,
        AppPermission.camera => Permission.camera,
        AppPermission.photos => Permission.photos,
        AppPermission.notifications => Permission.notification,
        AppPermission.microphone => Permission.microphone,
        AppPermission.contacts => Permission.contacts,
      };

  Future<void> _showDeniedDialog(AppPermission type, BuildContext context) {
    if (!context.mounted) return Future.value();
    return showDialog<void>(
      context: context,
      builder: (_) => _PermissionDialog(_meta(type)),
    );
  }

  static _PermissionMeta _meta(AppPermission type) => switch (type) {
        AppPermission.locationWhenInUse => const _PermissionMeta(
            icon: Icons.location_on_rounded,
            color: Color(0xFFE91E63),
            title: 'Location Access Required',
            message:
                'Barfliz needs your location to show nearby bars and connect you with friends who are out tonight. Enable it in Settings.',
          ),
        AppPermission.camera => const _PermissionMeta(
            icon: Icons.camera_alt_rounded,
            color: Color(0xFF2196F3),
            title: 'Camera Access Required',
            message:
                'Barfliz needs camera access to take photos and scan friend QR codes. Enable it in Settings.',
          ),
        AppPermission.photos => const _PermissionMeta(
            icon: Icons.photo_library_rounded,
            color: Color(0xFF9C27B0),
            title: 'Photo Library Access Required',
            message:
                'Barfliz needs access to your photos to add them to the venue wall and set a profile picture. Enable it in Settings.',
          ),
        AppPermission.notifications => const _PermissionMeta(
            icon: Icons.notifications_active_rounded,
            color: Color(0xFFFF9800),
            title: 'Notifications Disabled',
            message:
                'Enable notifications to get updates when friends check into nearby venues. Turn them on in Settings.',
          ),
        AppPermission.microphone => const _PermissionMeta(
            icon: Icons.mic_rounded,
            color: Color(0xFF009688),
            title: 'Microphone Access Required',
            message:
                'Barfliz needs microphone access to record video clips from nights out. Enable it in Settings.',
          ),
        AppPermission.contacts => const _PermissionMeta(
            icon: Icons.contacts_rounded,
            color: Color(0xFF4CAF50),
            title: 'Contacts Access Required',
            message:
                'Barfliz can find friends already on the app using your contacts. Enable it in Settings.',
          ),
      };
}

// ---------------------------------------------------------------------------
// Internal helpers
// ---------------------------------------------------------------------------

class _PermissionMeta {
  final IconData icon;
  final Color color;
  final String title;
  final String message;

  const _PermissionMeta({
    required this.icon,
    required this.color,
    required this.title,
    required this.message,
  });
}

class _PermissionDialog extends StatelessWidget {
  final _PermissionMeta meta;
  const _PermissionDialog(this.meta);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      contentPadding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: meta.color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(meta.icon, color: meta.color, size: 32),
          ),
          const SizedBox(height: 16),
          Text(
            meta.title,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 10),
          Text(
            meta.message,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              height: 1.5,
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.65),
            ),
          ),
          const SizedBox(height: 4),
        ],
      ),
      actionsPadding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      actionsAlignment: MainAxisAlignment.center,
      actions: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              openAppSettings();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: meta.color,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text(
              'Open Settings',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ),
        const SizedBox(height: 4),
        SizedBox(
          width: double.infinity,
          child: TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Not Now',
              style: TextStyle(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.5)),
            ),
          ),
        ),
      ],
    );
  }
}
