import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:freelancer_flutter/src/core/api/api_client.dart';
import 'package:freelancer_flutter/src/core/constants/app_colors.dart';
import 'package:freelancer_flutter/src/core/theme/theme_provider.dart';
import 'package:freelancer_flutter/src/features/auth/presentation/auth_selection_screen.dart';
import 'package:freelancer_flutter/src/features/auth/domain/user_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _apiClient = ApiClient();
  UserModel? _user;
  Map<String, dynamic>? _stats;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final user = await _apiClient.getUser();
      final role = user.role.toUpperCase();
      final stats = await _apiClient.fetchProfileStats(role);
      
      if (mounted) {
        setState(() {
          _user = user;
          _stats = stats;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _logout(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    if (context.mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const AuthSelectionScreen()),
        (route) => false,
      );
    }
  }

  String _getInitials(String name) {
    final parts = name.trim().split(' ');
    if (parts.isEmpty) return 'U';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }
    
    final theme = Theme.of(context);

    final name = _user?.fullName ?? 'User';
    final email = _user?.email ?? '';
    final role = _user?.role.toUpperCase() ?? 'FREELANCER';
    // UserModel doesn't have phone/location yet based on my previous creation, checking model...
    // I created the model with: id, email, fullName, role, status, bio, skills.
    // Profile screen used 'phone', 'location', 'headline'. I should add them to model or handle missing.
    // For now I will comment out missing fields or use defaults if they aren't in model.
    // headline isn't in model, use bio or role. If bio is JSON, try to extract 'headline' or 'location'.
    String headline = (role == 'FREELANCER' ? 'Freelancer' : 'Client');
    String location = '';
    String phone = '';

    if (_user?.bio != null) {
      try {
        if (_user!.bio!.trim().startsWith('{')) {
          final bioMap = jsonDecode(_user!.bio!);
          if (bioMap is Map) {
            location = bioMap['location'] ?? '';
            phone = bioMap['phone'] ?? '';
            // If there is a headline field in the JSON, use it. Otherwise use services or fallback.
            if (bioMap['headline'] != null && bioMap['headline'].isNotEmpty) {
               headline = bioMap['headline'];
            } else if (bioMap['services'] != null && (bioMap['services'] as List).isNotEmpty) {
               headline = (bioMap['services'] as List).first.toString();
            }
          }
        } else {
          headline = _user!.bio!;
        }
      } catch (e) {
        headline = _user!.bio!;
      }
    }

    final skills = _user?.skills ?? [];

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Premium Header Card
            Container(
              width: double.infinity,
              margin: const EdgeInsets.fromLTRB(16, 60, 16, 24),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF1E1E1E),
                    Colors.black.withOpacity(0.9),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppColors.primary.withOpacity(0.3), width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.15),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Avatar with Gold Ring
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.primary, width: 2),
                    ),
                    child: CircleAvatar(
                      radius: 40,
                      backgroundColor: AppColors.primary.withOpacity(0.2),
                      child: Text(
                        _getInitials(name),
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Name & Headline
                  Text(
                    name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    headline,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  Divider(color: Colors.white.withOpacity(0.1)),
                  const SizedBox(height: 16),

                  // Stats (White Text for Contrast)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _StatItem(label: 'Projects', value: _stats?['projects'] ?? '0', isDarkCard: true),
                      Container(width: 1, height: 30, color: Colors.white.withOpacity(0.2)),
                      _StatItem(label: 'Completed', value: _stats?['completed'] ?? '0', isDarkCard: true),
                      Container(width: 1, height: 30, color: Colors.white.withOpacity(0.2)),
                      _StatItem(label: 'Proposals', value: _stats?['proposals'] ?? '0', isDarkCard: true),
                    ],
                  ),
                ],
              ),
            ),

            // Contact Info
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 4, bottom: 12),
                    child: Text(
                      'CONTACT INFO',
                      style: TextStyle(
                        color: theme.disabledColor,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.1,
                      ),
                    ),
                  ),
                  _InfoTile(icon: Icons.email_outlined, label: 'Email', value: email),
                  if (phone.isNotEmpty)
                    _InfoTile(icon: Icons.phone_outlined, label: 'Phone', value: phone),
                  if (location.isNotEmpty)
                    _InfoTile(icon: Icons.location_on_outlined, label: 'Location', value: location),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Skills
            if (role == 'FREELANCER' && skills.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                     Padding(
                      padding: const EdgeInsets.only(left: 4, bottom: 12),
                      child: Text(
                        'SKILLS',
                        style: TextStyle(
                          color: theme.disabledColor,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.1,
                        ),
                      ),
                    ),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: skills.map((skill) => _SkillChip(skill: skill)).toList(),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 24),

            // Settings
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 4, bottom: 12),
                    child: Text(
                      'SETTINGS',
                      style: TextStyle(
                        color: theme.disabledColor,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.1,
                      ),
                    ),
                  ),
                  _SettingsTile(
                    icon: Icons.person_outline,
                    label: 'Edit Profile',
                    onTap: () {},
                  ),
                  _SettingsTile(
                    icon: Icons.notifications_outlined,
                    label: 'Notifications',
                    onTap: () {},
                  ),
                  _SettingsTile(
                    icon: Icons.security_outlined,
                    label: 'Security',
                    onTap: () {},
                  ),
                  
                  // Theme Toggle (Styled as tile)
                  Consumer<ThemeProvider>(
                    builder: (context, themeProvider, child) {
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: theme.cardColor,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                               padding: const EdgeInsets.all(8),
                               decoration: BoxDecoration(
                                 color: theme.disabledColor.withOpacity(0.1),
                                 borderRadius: BorderRadius.circular(8),
                               ),
                               child: Icon(themeProvider.isDarkMode ? Icons.dark_mode : Icons.light_mode, size: 20, color: theme.textTheme.bodyMedium?.color)
                            ),
                            const SizedBox(width: 16),
                            Expanded(child: Text('Dark Mode', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: theme.textTheme.bodyLarge?.color))),
                            Switch(
                              value: themeProvider.isDarkMode,
                              activeColor: AppColors.primary,
                              onChanged: (value) => themeProvider.setDarkMode(value),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  
                  _SettingsTile(
                    icon: Icons.logout,
                    label: 'Logout',
                    isDestructive: true,
                    onTap: () => _logout(context),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }
}


class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final bool isDarkCard;

  const _StatItem({required this.label, required this.value, this.isDarkCard = false});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: isDarkCard ? Colors.white : Theme.of(context).textTheme.bodyLarge?.color,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: isDarkCard ? Colors.white.withOpacity(0.6) : Theme.of(context).textTheme.bodyMedium?.color,
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoTile({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16), // More rounded
        boxShadow: [
           BoxShadow(
             color: Colors.black.withOpacity(0.05),
             blurRadius: 10,
             offset: const Offset(0, 4),
           ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(color: theme.textTheme.bodyMedium?.color?.withOpacity(0.6), fontSize: 11, fontWeight: FontWeight.bold)),
                const SizedBox(height: 2),
                Text(value, style: TextStyle(color: theme.textTheme.bodyLarge?.color, fontSize: 15, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SkillChip extends StatelessWidget {
  final String skill;
  const _SkillChip({required this.skill});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.primary, // Solid color for better contrast or stick to outline?
        // Let's stick to the outline style but polished
        gradient: LinearGradient(colors: [AppColors.primary.withOpacity(0.2), AppColors.primary.withOpacity(0.05)]),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withOpacity(0.5)),
      ),
      child: Text(
        skill,
        style: const TextStyle(
          color: AppColors.primary,
          fontSize: 13,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isDestructive;

  const _SettingsTile({required this.icon, required this.label, required this.onTap, this.isDestructive = false});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = isDestructive ? Colors.redAccent : theme.textTheme.bodyLarge?.color;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Row(
              children: [
                Container(
                   padding: const EdgeInsets.all(8),
                   decoration: BoxDecoration(
                     color: isDestructive ? Colors.redAccent.withOpacity(0.1) : theme.disabledColor.withOpacity(0.1),
                     borderRadius: BorderRadius.circular(8),
                   ),
                   child: Icon(icon, size: 20, color: isDestructive ? Colors.redAccent : theme.textTheme.bodyMedium?.color)
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      color: color,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Icon(Icons.chevron_right, color: theme.disabledColor, size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
