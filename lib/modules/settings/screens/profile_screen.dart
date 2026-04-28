import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'package:guardgrey/core/theme/app_colors.dart';
import 'package:guardgrey/core/theme/app_text_styles.dart';
import 'package:guardgrey/core/widgets/list_tile.dart';
import 'package:guardgrey/core/widgets/section_header.dart';
import 'package:guardgrey/routes/app_routes.dart';
import 'edit_profile_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String _fullName = 'Admin User';
  String _email = 'admin@guardgrey.com';
  String _phone = '+91 98765 11001';
  bool _isLoggingOut = false;

  @override
  void initState() {
    super.initState();
    _hydrateProfileFromAuth();
  }

  void _showPlaceholderMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: AppTextStyles.bodyMedium.copyWith(color: Colors.white),
        ),
        backgroundColor: AppColors.primary600,
      ),
    );
  }

  void _hydrateProfileFromAuth() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return;
    }

    final email = user.email?.trim();
    final displayName = user.displayName?.trim();

    setState(() {
      _email = (email?.isNotEmpty ?? false) ? email! : _email;
      _fullName = (displayName?.isNotEmpty ?? false)
          ? displayName!
          : _deriveNameFromEmail(_email);
    });
  }

  Future<void> _logout() async {
    if (_isLoggingOut) {
      return;
    }

    setState(() {
      _isLoggingOut = true;
    });

    try {
      await FirebaseAuth.instance.signOut();
      if (!mounted) {
        return;
      }
      Navigator.pushNamedAndRemoveUntil(
        context,
        AppRoutes.authGate,
        (_) => false,
      );
    } on FirebaseAuthException catch (error) {
      print('Logout error: ${error.code} ${error.message}');
      if (!mounted) {
        return;
      }
      _showPlaceholderMessage('Unable to logout right now.');
    } catch (error) {
      print('Logout error: $error');
      if (!mounted) {
        return;
      }
      _showPlaceholderMessage('Unable to logout right now.');
    } finally {
      if (!mounted) {
        return;
      }
      setState(() {
        _isLoggingOut = false;
      });
    }
  }

  Future<void> _openEditProfile() async {
    final result = await Navigator.push<EditProfileResult>(
      context,
      MaterialPageRoute(
        builder: (_) => EditProfileScreen(
          initialName: _fullName,
          initialEmail: _email,
          initialPhone: _phone,
        ),
      ),
    );

    if (result == null) return;

    setState(() {
      _fullName = result.fullName;
      _email = result.email;
      _phone = result.phone;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Profile updated successfully.',
          style: AppTextStyles.bodyMedium.copyWith(color: Colors.white),
        ),
        backgroundColor: AppColors.success,
      ),
    );
  }

  String _deriveNameFromEmail(String email) {
    final localPart = email.split('@').first.trim();
    if (localPart.isEmpty) {
      return 'Admin User';
    }

    final words = localPart
        .split(RegExp(r'[._-]+'))
        .where((part) => part.trim().isNotEmpty)
        .map(
          (part) =>
              '${part[0].toUpperCase()}${part.substring(1).toLowerCase()}',
        )
        .toList(growable: false);

    return words.isEmpty ? 'Admin User' : words.join(' ');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundLight,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          'Profile',
          style: AppTextStyles.title.copyWith(fontWeight: FontWeight.w700),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.neutral200),
            ),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 36,
                  backgroundColor: AppColors.primary50,
                  child: Text(
                    _fullName.isEmpty ? 'A' : _fullName.substring(0, 1),
                    style: AppTextStyles.headingSmall.copyWith(
                      color: AppColors.primary600,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  _fullName,
                  style: AppTextStyles.title.copyWith(
                    color: AppColors.neutral900,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _email,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.neutral500,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _phone,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.neutral600,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const SectionHeader(title: 'User Info'),
          const SizedBox(height: 10),
          AppListTile(
            title: _fullName,
            subtitle: _email,
            leadingIcon: Icons.person_outline_rounded,
          ),
          const SizedBox(height: 12),
          AppListTile(
            title: 'Phone',
            subtitle: _phone,
            leadingIcon: Icons.call_outlined,
          ),
          const SizedBox(height: 20),
          const SectionHeader(title: 'Account'),
          const SizedBox(height: 10),
          AppListTile(
            title: 'Edit Profile',
            leadingIcon: Icons.edit_outlined,
            onTap: _openEditProfile,
          ),
          const SizedBox(height: 12),
          AppListTile(
            title: 'Change Password',
            leadingIcon: Icons.lock_outline_rounded,
            onTap: () => _showPlaceholderMessage(
              'Password change flow will be available soon.',
            ),
          ),
          const SizedBox(height: 20),
          const SectionHeader(title: 'Action'),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isLoggingOut ? null : _logout,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 54),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
              child: _isLoggingOut
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Logout'),
            ),
          ),
        ],
      ),
    );
  }
}
