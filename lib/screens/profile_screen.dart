import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/company_record.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import 'login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Future<void> _logout(BuildContext context) async {
    final AuthService? authService = context.read<AuthService?>();
    if (authService == null) {
      return;
    }
    await authService.logout();
    if (!context.mounted) {
      return;
    }
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute<void>(
        builder: (BuildContext context) => const LoginScreen(),
      ),
      (Route<dynamic> route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final FirestoreService? firestore = context.read<FirestoreService?>();
    final AuthService? authService = context.read<AuthService?>();
    final String fallbackName =
        authService?.currentUser?.displayName ?? 'Business Owner';
    final String fallbackEmail = authService?.currentUser?.email ?? '';
    if (firestore == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Profile')),
        body: const Center(child: Text('Profile service unavailable.')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: StreamBuilder<Map<String, dynamic>?>(
        stream: firestore.streamUserProfile(),
        builder:
            (
              BuildContext context,
              AsyncSnapshot<Map<String, dynamic>?> userSnapshot,
            ) {
              return StreamBuilder<CompanyRecord?>(
                stream: firestore.streamActiveCompany(),
                builder:
                    (
                      BuildContext context,
                      AsyncSnapshot<CompanyRecord?> companySnapshot,
                    ) {
                      final Map<String, dynamic>? userProfile =
                          userSnapshot.data;
                      final CompanyRecord? company = companySnapshot.data;
                      final String name =
                          userProfile?['name'] as String? ?? fallbackName;
                      final String email =
                          userProfile?['email'] as String? ?? fallbackEmail;
                      final String phone =
                          userProfile?['phone'] as String? ?? '';
                      final String? photoUrl =
                          userProfile?['photoUrl'] as String?;
                      final ColorScheme colorScheme = Theme.of(
                        context,
                      ).colorScheme;

                      return SingleChildScrollView(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: <Widget>[
                            CircleAvatar(
                              radius: 46,
                              backgroundColor: colorScheme.outline.withValues(
                                alpha: 0.2,
                              ),
                              backgroundImage:
                                  photoUrl != null && photoUrl.isNotEmpty
                                  ? NetworkImage(photoUrl) as ImageProvider
                                  : null,
                              child: photoUrl == null || photoUrl.isEmpty
                                  ? Text(
                                      name.isEmpty
                                          ? '?'
                                          : name[0].toUpperCase(),
                                      style: TextStyle(
                                        fontSize: 28,
                                        color: colorScheme.onSurface,
                                      ),
                                    )
                                  : null,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              name,
                              style: Theme.of(context).textTheme.headlineSmall
                                  ?.copyWith(fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              email,
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                            if (phone.isNotEmpty) ...<Widget>[
                              const SizedBox(height: 2),
                              Text(
                                phone,
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                            const SizedBox(height: 14),
                            Card(
                              child: Padding(
                                padding: const EdgeInsets.all(14),
                                child: Column(
                                  children: <Widget>[
                                    _row(
                                      context,
                                      'Role',
                                      (userProfile?['role'] as String? ??
                                              'admin')
                                          .toUpperCase(),
                                    ),
                                    _row(
                                      context,
                                      'Company',
                                      company?.name ?? 'Not selected',
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 14),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: () => _showEditProfileDialog(
                                  context,
                                  userProfile,
                                  fallbackName,
                                  fallbackEmail,
                                ),
                                icon: const Icon(Icons.edit),
                                label: const Text('Edit Profile'),
                              ),
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: () => _logout(context),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Theme.of(
                                    context,
                                  ).colorScheme.error,
                                  foregroundColor: Theme.of(
                                    context,
                                  ).colorScheme.onError,
                                ),
                                icon: const Icon(Icons.logout),
                                label: const Text('Logout'),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
              );
            },
      ),
    );
  }

  Future<void> _showEditProfileDialog(
    BuildContext context,
    Map<String, dynamic>? userProfile,
    String fallbackName,
    String fallbackEmail,
  ) async {
    final TextEditingController nameController = TextEditingController(
      text: userProfile?['name'] as String? ?? fallbackName,
    );
    final TextEditingController emailController = TextEditingController(
      text: userProfile?['email'] as String? ?? fallbackEmail,
    );
    final TextEditingController phoneController = TextEditingController(
      text: userProfile?['phone'] as String? ?? '',
    );

    final GlobalKey<FormState> formKey = GlobalKey<FormState>();

    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Edit Profile'),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  TextFormField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Name',
                      border: OutlineInputBorder(),
                    ),
                    validator: (String? value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Name cannot be empty';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      border: OutlineInputBorder(),
                    ),
                    validator: (String? value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Email cannot be empty';
                      }
                      final bool valid = RegExp(
                        r'^[\w\.\+\-]+@[\w\-]+\.[a-zA-Z]{2,}$',
                      ).hasMatch(value.trim());
                      if (!valid) return 'Enter a valid email address';
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: phoneController,
                    keyboardType: TextInputType.phone,
                    maxLength: 10,
                    decoration: const InputDecoration(
                      labelText: 'Phone',
                      border: OutlineInputBorder(),
                      counterText: '',
                    ),
                    validator: (String? value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Phone cannot be empty';
                      }
                      if (!RegExp(r'^[6-9]\d{9}$').hasMatch(value.trim())) {
                        return 'Enter a valid 10-digit Indian mobile number';
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (!formKey.currentState!.validate())
                  return; // 👈 validation check
                final FirestoreService? firestore = context
                    .read<FirestoreService?>();
                if (firestore != null) {
                  await firestore.updateUserProfile(
                    name: nameController.text.trim(),
                    email: emailController.text.trim(),
                    phone: phoneController.text.trim(),
                  );
                }
                if (!context.mounted) return;
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Profile updated successfully')),
                );
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  Widget _row(BuildContext context, String label, String value) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Text(label, style: Theme.of(context).textTheme.bodyMedium),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.end,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: colorScheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
