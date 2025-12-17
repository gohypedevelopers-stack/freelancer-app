import 'package:flutter/material.dart';
import 'package:freelancer_flutter/src/core/presentation/widgets/fade_slide_transition.dart';
import 'package:freelancer_flutter/src/features/home/presentation/widgets/premium_service_card.dart';
import 'package:freelancer_flutter/src/features/home/domain/service_model.dart';

class ServicesScreen extends StatelessWidget {
  const ServicesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('All Services', 
          style: TextStyle(
            color: theme.textTheme.bodyLarge?.color, 
            fontWeight: FontWeight.bold,
            letterSpacing: -0.5,
          )
        ),
        centerTitle: true,
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        iconTheme: IconThemeData(color: theme.textTheme.bodyLarge?.color),
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.8, // Taller cards for premium look
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        ),
        itemCount: allServices.length,
        itemBuilder: (context, index) {
          return FadeSlideTransition(
            index: index,
            delay: const Duration(milliseconds: 50),
            child: PremiumServiceCard(
              service: allServices[index],
              onTap: () {
                // TODO: Navigate to service details
              },
            ),
          );
        },
      ),
    );
  }
}
