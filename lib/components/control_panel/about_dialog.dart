import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

class AboutDialogWidget extends StatefulWidget {
  const AboutDialogWidget({super.key});

  @override
  State<AboutDialogWidget> createState() => _AboutDialogWidgetState();
}

class _AboutDialogWidgetState extends State<AboutDialogWidget> {
  String appName = 'Piano';
  String packageName = '';
  String version = '';
  String buildNumber = '';

  @override
  void initState() {
    super.initState();
    _initPackageInfo();
  }

  Future<void> _initPackageInfo() async {
    final info = await PackageInfo.fromPlatform();
    setState(() {
      appName = info.appName;
      packageName = info.packageName;
      version = info.version;
      buildNumber = info.buildNumber;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final teal = theme.colorScheme.primary;
    final orange = theme.colorScheme.secondary;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: 360),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Top bar with optional logo
              Row(
                children: [
                  // Placeholder for your logo
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: teal.withValues(alpha: 0.2),
                    ),
                    child: Center(
                      child: Image.asset('assets/images/logo_color.png'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    'About $appName',
                    style: theme.textTheme.titleLarge!
                        .copyWith(fontWeight: FontWeight.bold),
                  ),
                ],
              ),

              const SizedBox(height: 16),
              Divider(color: orange.withValues(alpha: 0.4), thickness: 2),

              const SizedBox(height: 16),
              _buildInfoRow('Version', version.isEmpty ? '—' : version),
              _buildInfoRow('Build', buildNumber.isEmpty ? '—' : buildNumber),
              _buildInfoRow('Package', packageName),

              const SizedBox(height: 24),
              Text(
                'Developed by Adeleke Olasope\n© 2025 Empyreal Digital Works',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium!
                    .copyWith(color: Colors.grey[700]),
              ),

              const SizedBox(height: 24),
              // Easter-egg tap target
              GestureDetector(
                onTap: () {
                  Navigator.of(context).pop();
                },
                child: Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.teal,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Close',
                    style: theme.textTheme.labelLarge!
                        .copyWith(color: Colors.white, fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(
            flex: 5,
            child: Text(value, overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
    );
  }
}
