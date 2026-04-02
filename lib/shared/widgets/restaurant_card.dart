import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/fcfa_formatter.dart';
import 'loading_shimmer.dart';

class RestaurantCard extends StatelessWidget {
  final String id;
  final String name;
  final String? imageUrl;
  final double rating;
  final int reviewCount;
  final int deliveryTimeMin;
  final int deliveryFee;
  final bool isOpen;
  final String? subtitle; // quartier / spécialités
  final VoidCallback onTap;

  const RestaurantCard({
    super.key,
    required this.id,
    required this.name,
    this.imageUrl,
    required this.rating,
    required this.reviewCount,
    required this.deliveryTimeMin,
    required this.deliveryFee,
    required this.isOpen,
    this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isOpen ? onTap : null,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
                color: AppColors.cardShadow,
                blurRadius: 8,
                offset: Offset(0, 2)),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image
              Stack(
                children: [
                  SizedBox(
                    height: 130,
                    width: double.infinity,
                    child: imageUrl != null
                        ? CachedNetworkImage(
                            imageUrl: imageUrl!,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => const ShimmerBox(
                              width: double.infinity,
                              height: 130,
                              borderRadius: 0,
                            ),
                            errorWidget: (context, url, error) =>
                                _ImageFallback(),
                          )
                        : _ImageFallback(),
                  ),
                  if (!isOpen)
                    Container(
                      height: 130,
                      color: AppColors.overlay,
                      child: const Center(
                        child: Text(
                          'Fermé',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                ],
              ),

              // Infos
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: Theme.of(context).textTheme.titleMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (subtitle != null && subtitle!.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: AppColors.textSecondary),
                      ),
                    ],
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        RatingBarIndicator(
                          rating: rating,
                          itemSize: 14,
                          itemBuilder: (context, index) => const Icon(
                            Icons.star,
                            color: AppColors.secondary,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${rating.toStringAsFixed(1)} ($reviewCount)',
                          style: Theme.of(context).textTheme.labelMedium,
                        ),
                        const Spacer(),
                        const Icon(Icons.schedule,
                            size: 14, color: AppColors.textSecondary),
                        const SizedBox(width: 4),
                        Text(
                          '~$deliveryTimeMin min',
                          style: Theme.of(context).textTheme.labelMedium,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          deliveryFee == 0
                              ? 'Livraison gratuite'
                              : deliveryFee.toFcfa(),
                          style:
                              Theme.of(context).textTheme.labelMedium?.copyWith(
                                    color: deliveryFee == 0
                                        ? AppColors.success
                                        : null,
                                  ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ImageFallback extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.primary.withValues(alpha: 0.08),
      child: const Center(
        child: Text('👩‍🍳', style: TextStyle(fontSize: 48)),
      ),
    );
  }
}
