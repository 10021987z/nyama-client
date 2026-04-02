import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/error_widget.dart';
import '../../../shared/widgets/loading_shimmer.dart';
import '../../home/data/home_repository.dart';
import '../../home/data/models/cook.dart';
import '../../home/data/models/menu_item.dart';
import '../../../core/utils/fcfa_formatter.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _controller = TextEditingController();
  final _focus = FocusNode();
  Timer? _debounce;
  String _query = '';
  bool _isLoading = false;
  List<MenuItem> _menuResults = [];
  List<Cook> _cookResults = [];
  String? _error;

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    setState(() => _query = value.trim());
    if (value.trim().isEmpty) {
      setState(() {
        _menuResults = [];
        _cookResults = [];
        _error = null;
        _isLoading = false;
      });
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 300), () => _search(value.trim()));
  }

  Future<void> _search(String query) async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final repo = HomeRepository();
    try {
      // 2 appels parallèles
      final results = await Future.wait([
        repo.getMenuItems(search: query, limit: 10),
        repo.getCooks(search: query, limit: 10),
      ]);
      if (!mounted) return;
      setState(() {
        _menuResults = (results[0] as PaginatedResult<MenuItem>).data;
        _cookResults = (results[1] as PaginatedResult<Cook>).data;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasResults = _menuResults.isNotEmpty || _cookResults.isNotEmpty;
    final isEmpty = _query.isNotEmpty && !_isLoading && !hasResults && _error == null;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: AppColors.primary,
        titleSpacing: 12,
        title: TextField(
          controller: _controller,
          focusNode: _focus,
          autofocus: false,
          onChanged: _onChanged,
          decoration: InputDecoration(
            hintText: 'Plat, cuisinière, spécialité...',
            hintStyle: const TextStyle(color: Colors.white60),
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            fillColor: Colors.transparent,
            filled: false,
            prefixIcon:
                const Icon(Icons.search, color: Colors.white70, size: 20),
            suffixIcon: _query.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.close, color: Colors.white70, size: 20),
                    onPressed: () {
                      _controller.clear();
                      _onChanged('');
                    },
                  )
                : null,
            contentPadding: const EdgeInsets.symmetric(vertical: 12),
          ),
          style: const TextStyle(color: Colors.white, fontSize: 15),
          cursorColor: Colors.white,
        ),
      ),
      body: _buildBody(hasResults, isEmpty),
    );
  }

  Widget _buildBody(bool hasResults, bool isEmpty) {
    if (_query.isEmpty) {
      return const _EmptySearchPrompt();
    }

    if (_isLoading) {
      return ListView(
        padding: const EdgeInsets.all(16),
        children: List.generate(
          4,
          (_) => const Padding(
            padding: EdgeInsets.only(bottom: 12),
            child: MenuItemShimmer(),
          ),
        ),
      );
    }

    if (_error != null) {
      return NyamaErrorWidget(
        message: _error!,
        onRetry: () => _search(_query),
      );
    }

    if (isEmpty) {
      return _EmptyResults(query: _query);
    }

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      children: [
        // ── Plats ────────────────────────────────────────────────────
        if (_menuResults.isNotEmpty) ...[
          _SectionTitle(
            title: 'Plats',
            count: _menuResults.length,
          ),
          ..._menuResults.map((item) => _MenuResultTile(item: item)),
          const SizedBox(height: 8),
        ],

        // ── Cuisinières ───────────────────────────────────────────────
        if (_cookResults.isNotEmpty) ...[
          _SectionTitle(
            title: 'Cuisinières',
            count: _cookResults.length,
          ),
          ..._cookResults.map((cook) => _CookResultTile(cook: cook)),
        ],
      ],
    );
  }
}

// ─── Widgets internes ─────────────────────────────────────────────────────

class _EmptySearchPrompt extends StatelessWidget {
  const _EmptySearchPrompt();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('🔍', style: TextStyle(fontSize: 56)),
          const SizedBox(height: 16),
          Text(
            'Tapez pour rechercher\nun plat ou une cuisinière',
            textAlign: TextAlign.center,
            style: Theme.of(context)
                .textTheme
                .bodyLarge
                ?.copyWith(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _EmptyResults extends StatelessWidget {
  final String query;

  const _EmptyResults({required this.query});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('😕', style: TextStyle(fontSize: 56)),
          const SizedBox(height: 16),
          Text(
            'Aucun résultat pour\n"$query"',
            textAlign: TextAlign.center,
            style: Theme.of(context)
                .textTheme
                .bodyLarge
                ?.copyWith(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final int count;

  const _SectionTitle({required this.title, required this.count});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Row(
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '$count',
              style: const TextStyle(
                  color: AppColors.primary,
                  fontSize: 11,
                  fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

class _MenuResultTile extends StatelessWidget {
  final MenuItem item;

  const _MenuResultTile({required this.item});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: SizedBox(
          width: 56,
          height: 56,
          child: item.imageUrl != null
              ? Image.network(
                  item.imageUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (context, url, error) => Container(
                    color: AppColors.surface,
                    child:
                        const Center(child: Text('🍽️', style: TextStyle(fontSize: 24))),
                  ),
                )
              : Container(
                  color: AppColors.surface,
                  child:
                      const Center(child: Text('🍽️', style: TextStyle(fontSize: 24))),
                ),
        ),
      ),
      title: Text(item.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
      subtitle: Text(
        item.cook?.displayName ?? '',
        style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
      ),
      trailing: Text(
        item.priceXaf.toFcfa(),
        style: const TextStyle(
            color: AppColors.primary,
            fontWeight: FontWeight.w700,
            fontSize: 13),
      ),
      onTap: item.cook != null
          ? () => context.go('/restaurant/${item.cook!.id}')
          : null,
    );
  }
}

class _CookResultTile extends StatelessWidget {
  final Cook cook;

  const _CookResultTile({required this.cook});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: CircleAvatar(
        radius: 28,
        backgroundColor: AppColors.primary.withValues(alpha: 0.1),
        child: const Text('👩‍🍳', style: TextStyle(fontSize: 24)),
      ),
      title: Text(cook.displayName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
      subtitle: Text(
        cook.specialty.take(2).join(' · '),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.star, size: 14, color: AppColors.secondary),
          const SizedBox(width: 3),
          Text(
            cook.avgRating.toStringAsFixed(1),
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
          ),
        ],
      ),
      onTap: () => context.go('/restaurant/${cook.id}'),
    );
  }
}
