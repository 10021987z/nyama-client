import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/home_repository.dart';
import '../data/models/cook.dart';
import '../data/models/menu_item.dart';

// ─── Repository ──────────────────────────────────────────────────────────

final homeRepositoryProvider = Provider<HomeRepository>((ref) {
  return HomeRepository();
});

// ─── Tab index (permet aux enfants de changer d'onglet) ─────────────────

final selectedTabProvider = StateProvider<int>((ref) => 0);

// ─── State: catégorie filtrée active ─────────────────────────────────────

final selectedCategoryProvider = StateProvider<String?>((ref) => null);

// ─── Plats du jour ────────────────────────────────────────────────────────

final dailySpecialsProvider =
    FutureProvider<PaginatedResult<MenuItem>>((ref) async {
  return ref.read(homeRepositoryProvider).getMenuItems(
        isDailySpecial: true,
        limit: 10,
      );
});

// ─── Plats filtrés (home tab) ─────────────────────────────────────────────

final filteredMenuItemsProvider =
    FutureProvider<PaginatedResult<MenuItem>>((ref) async {
  final category = ref.watch(selectedCategoryProvider);
  return ref.read(homeRepositoryProvider).getMenuItems(
        category: category,
        limit: 20,
      );
});

// ─── Liste des cuisinières ────────────────────────────────────────────────

final cooksProvider = FutureProvider<PaginatedResult<Cook>>((ref) async {
  return ref.read(homeRepositoryProvider).getCooks(limit: 20);
});

// ─── Détail d'une cuisinière ──────────────────────────────────────────────

final cookDetailProvider =
    FutureProvider.family<Cook, String>((ref, id) async {
  return ref.read(homeRepositoryProvider).getCookDetail(id);
});

// ─── Catégories uniques extraites des plats chargés ──────────────────────

final availableCategoriesProvider = Provider<List<String>>((ref) {
  final menuAsync = ref.watch(filteredMenuItemsProvider);
  return menuAsync.maybeWhen(
    data: (result) {
      final categories = result.data
          .where((item) => item.category != null && item.category!.isNotEmpty)
          .map((item) => item.category!)
          .toSet()
          .toList()
        ..sort();
      return categories;
    },
    orElse: () => [],
  );
});
