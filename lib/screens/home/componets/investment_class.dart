import 'package:flutter/material.dart';
import '../../../theme/theme.dart';

/// Search scope for class list.
enum ClassSearchTab { all, name, description }

class InvestmentClassStep extends StatefulWidget {
  final List<Map<String, dynamic>> investmentData;
  final String searchQuery;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<Map<String, dynamic>> onClassSelected;

  const InvestmentClassStep({
    Key? key,
    required this.investmentData,
    required this.searchQuery,
    required this.onSearchChanged,
    required this.onClassSelected,
  }) : super(key: key);

  @override
  State<InvestmentClassStep> createState() => _InvestmentClassStepState();
}

class _InvestmentClassStepState extends State<InvestmentClassStep> {
  ClassSearchTab _tab = ClassSearchTab.all;

  bool _matchesFilter(Map<String, dynamic> cls) {
    final q = widget.searchQuery.toLowerCase().trim();
    final name = cls['investment_class']?.toString().toLowerCase() ?? '';
    final desc = cls['description']?.toString().toLowerCase() ?? '';
    if (q.isEmpty) return true;
    switch (_tab) {
      case ClassSearchTab.all:
        return name.contains(q) || desc.contains(q);
      case ClassSearchTab.name:
        return name.contains(q);
      case ClassSearchTab.description:
        return desc.contains(q);
    }
  }

  String get _hint {
    switch (_tab) {
      case ClassSearchTab.all:
        return 'Search by class name or description…';
      case ClassSearchTab.name:
        return 'Search by class name…';
      case ClassSearchTab.description:
        return 'Search by description…';
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered =
        widget.investmentData.where(_matchesFilter).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Select investment class',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: primaryTwo,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Choose the type of investment that matches your goals',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey.shade600,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 14),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _chip('All', ClassSearchTab.all),
            _chip('Class name', ClassSearchTab.name),
            _chip('Description', ClassSearchTab.description),
          ],
        ),
        const SizedBox(height: 12),
        TextField(
          onChanged: widget.onSearchChanged,
          decoration: InputDecoration(
            hintText: _hint,
            hintStyle: TextStyle(color: Colors.grey.shade500),
            prefixIcon: Icon(Icons.search, color: Colors.grey.shade600),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: primaryTwo, width: 1.5),
            ),
            filled: true,
            fillColor: Colors.white,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: filtered.isEmpty && widget.searchQuery.isNotEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.search_off, size: 56, color: Colors.grey.shade400),
                      const SizedBox(height: 16),
                      Text(
                        'No classes found',
                        style: TextStyle(
                          color: Colors.grey.shade700,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Try another tab or search term',
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                      ),
                    ],
                  ),
                )
              : ListView.separated(
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (ctx, i) {
                    final cls = filtered[i];
                    final name = cls['investment_class'] ?? 'Unknown';
                    final desc =
                        (cls['description'] ?? 'No description available').toString();
                    final logo = cls['logo']?.toString();

                    return Material(
                      color: Colors.white,
                      elevation: 1.5,
                      shadowColor: primaryTwo.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(16),
                      child: InkWell(
                        onTap: () => widget.onClassSelected(cls),
                        borderRadius: BorderRadius.circular(16),
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: _ClassThumb(
                                  logoUrl: logo,
                                  className: name.toString(),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      name,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 16,
                                        color: Color(0xFF1a1d2e),
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      desc,
                                      maxLines: 3,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: Colors.grey.shade700,
                                        fontSize: 13,
                                        height: 1.35,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: primaryTwo.withOpacity(0.08),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(
                                  Icons.chevron_right_rounded,
                                  color: primaryTwo,
                                  size: 22,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _chip(String label, ClassSearchTab tab) {
    final selected = _tab == tab;
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => setState(() => _tab = tab),
      selectedColor: primaryTwo.withOpacity(0.15),
      checkmarkColor: primaryTwo,
      labelStyle: TextStyle(
        color: selected ? primaryTwo : Colors.grey.shade800,
        fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
        fontSize: 13,
      ),
      side: BorderSide(
        color: selected ? primaryTwo : Colors.grey.shade300,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
    );
  }
}

class _ClassThumb extends StatelessWidget {
  final String? logoUrl;
  final String className;

  const _ClassThumb({this.logoUrl, required this.className});

  String get _initials {
    final parts = className
        .trim()
        .split(RegExp(r'\s+'))
        .where((e) => e.isNotEmpty)
        .toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) {
      final s = parts[0];
      if (s.length >= 2) return s.substring(0, 2).toUpperCase();
      return s[0].toUpperCase();
    }
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }

  bool get _validHttpUrl {
    final u = logoUrl?.trim() ?? '';
    return u.startsWith('http://') || u.startsWith('https://');
  }

  @override
  Widget build(BuildContext context) {
    const size = 72.0;
    final bg = primaryTwo.withOpacity(0.14);

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        width: size,
        height: size,
        child: Stack(
          fit: StackFit.expand,
          children: [
            ColoredBox(
              color: bg,
              child: Center(
                child: Text(
                  _initials,
                  style: TextStyle(
                    color: primaryTwo,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
            if (_validHttpUrl)
              Image.network(
                logoUrl!.trim(),
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return ColoredBox(
                    color: Colors.white.withOpacity(0.7),
                    child: const Center(
                      child: SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: primaryTwo,
                        ),
                      ),
                    ),
                  );
                },
                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
              ),
            Positioned(
              right: 4,
              bottom: 4,
              child: Icon(
                Icons.savings_outlined,
                size: 16,
                color: primaryTwo.withOpacity(0.75),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
