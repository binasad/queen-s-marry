import 'package:flutter/material.dart';

/// Beautiful empty state widget
class EmptyStateWidget extends StatelessWidget {
  final String title;
  final String message;
  final IconData icon;
  final VoidCallback? onRetry;
  final String? retryText;

  const EmptyStateWidget({
    super.key,
    required this.title,
    required this.message,
    this.icon = Icons.inbox_outlined,
    this.onRetry,
    this.retryText,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              message,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: Text(retryText ?? 'Retry'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.pink,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Empty state for categories
class EmptyCategoriesState extends StatelessWidget {
  final VoidCallback? onRetry;
  
  const EmptyCategoriesState({super.key, this.onRetry});

  @override
  Widget build(BuildContext context) {
    return EmptyStateWidget(
      title: 'No Categories Available',
      message: 'We couldn\'t find any service categories at the moment.',
      icon: Icons.category_outlined,
      onRetry: onRetry,
    );
  }
}

/// Empty state for courses
class EmptyCoursesState extends StatelessWidget {
  final VoidCallback? onRetry;
  
  const EmptyCoursesState({super.key, this.onRetry});

  @override
  Widget build(BuildContext context) {
    return EmptyStateWidget(
      title: 'No Courses Available',
      message: 'There are no courses available at the moment. Check back later!',
      icon: Icons.school_outlined,
      onRetry: onRetry,
    );
  }
}

/// Empty state for services
class EmptyServicesState extends StatelessWidget {
  final VoidCallback? onRetry;
  
  const EmptyServicesState({super.key, this.onRetry});

  @override
  Widget build(BuildContext context) {
    return EmptyStateWidget(
      title: 'No Services Found',
      message: 'We couldn\'t find any services matching your criteria.',
      icon: Icons.spa_outlined,
      onRetry: onRetry,
    );
  }
}
