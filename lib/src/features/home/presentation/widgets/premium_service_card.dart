import 'package:flutter/material.dart';
import 'package:freelancer_flutter/src/core/constants/app_colors.dart';
import 'package:freelancer_flutter/src/features/home/domain/service_model.dart';

class PremiumServiceCard extends StatelessWidget {
  final Service service;
  final VoidCallback? onTap;

  const PremiumServiceCard({
    super.key, 
    required this.service,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Determine a placeholder image based on service title
    String imageUrl = 'https://images.unsplash.com/photo-1461749280684-dccba630e2f6?w=600&q=80'; // Default Tech
    
    if (service.title.contains('App')) imageUrl = 'https://images.unsplash.com/photo-1512941937669-90a1b58e7e9c?w=600&q=80';
    if (service.title.contains('Design')) imageUrl = 'https://images.unsplash.com/photo-1561070791-2526d30994b5?w=600&q=80';
    if (service.title.contains('Marketing')) imageUrl = 'https://images.unsplash.com/photo-1533750516457-a7f992034fec?w=600&q=80';
    if (service.title.contains('Video')) imageUrl = 'https://images.unsplash.com/photo-1492691527719-9d1e07e534b4?w=600&q=80';

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 200, // Fixed width for horizontal lists
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: theme.dividerColor.withOpacity(0.5)),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark 
                ? [theme.cardColor, theme.cardColor.withOpacity(0.8)] 
                : [Colors.white, Colors.grey.shade50],
          ),
          boxShadow: [
            BoxShadow(
              color: isDark ? Colors.black26 : Colors.grey.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cover Image
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              child: Image.network(
                imageUrl,
                height: 110,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  height: 110,
                  color: theme.dividerColor,
                  child: const Center(child: Icon(Icons.broken_image, size: 30)),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Icon(service.icon, color: AppColors.primary, size: 14),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            service.title,
                            style: TextStyle(
                              color: theme.textTheme.bodyLarge?.color,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    Text(
                      service.price,
                      style: TextStyle(
                        color: AppColors.primary,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
