import 'package:flutter/material.dart';
import '../../../theme/theme.dart';
import 'fund_option_insight_sheet.dart';

enum OptionSearchTab { all, fundName, manager, description }

/// Normalizes API values for minimum deposit display.
String _formatMinimumDeposit(dynamic v) {
  if (v == null) return '';
  final s = v.toString().trim();
  if (s.isEmpty || s.toLowerCase() == 'n/a') return '';
  final n = v is num ? v.toDouble() : double.tryParse(s);
  if (n == null) return s;
  if (n == n.roundToDouble()) return n.toInt().toString();
  return n.toStringAsFixed(n >= 100 ? 0 : 2);
}

/// Normalizes interest for display (percentage).
String _formatInterestPercent(dynamic v) {
  if (v == null) return '';
  final s = v.toString().trim();
  if (s.isEmpty || s.toLowerCase() == 'n/a') return '';
  if (v is num) {
    final n = v.toDouble();
    if (n == n.roundToDouble()) return '${n.toInt()}%';
    return '${n.toStringAsFixed(2)}%';
  }
  final stripped = s.replaceAll('%', '').trim();
  final n = double.tryParse(stripped);
  if (n == null) return s.endsWith('%') ? s : '$s%';
  if (n == n.roundToDouble()) return '${n.toInt()}%';
  return '${n.toStringAsFixed(2)}%';
}

/// Maturity in months.
String _formatMaturityMonths(dynamic v) {
  if (v == null) return '';
  final s = v.toString().trim();
  if (s.isEmpty || s.toLowerCase() == 'n/a') return '';
  final n = v is num ? v.round() : int.tryParse(s);
  if (n == null) return '$s mo';
  return '$n mo';
}

bool _hasDisplayable(dynamic v) {
  if (v == null) return false;
  final s = v.toString().trim();
  if (s.isEmpty) return false;
  if (s.toLowerCase() == 'n/a') return false;
  return true;
}

class InvestmentOptionStep extends StatefulWidget {
  final Map<String, dynamic> selectedClass;
  final String searchQuery;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<Map<String, dynamic>> onOptionSelected;
  final VoidCallback? onBack;
  final int? preferredOptionId;

  const InvestmentOptionStep({
    Key? key,
    required this.selectedClass,
    required this.searchQuery,
    required this.onSearchChanged,
    required this.onOptionSelected,
    required this.onBack,
    this.preferredOptionId,
  }) : super(key: key);

  @override
  State<InvestmentOptionStep> createState() => _InvestmentOptionStepState();
}

class _InvestmentOptionStepState extends State<InvestmentOptionStep> {
  OptionSearchTab _tab = OptionSearchTab.all;

  int _optionId(Map<String, dynamic> opt) {
    final raw = opt['investment_option_id'];
    if (raw is int) return raw;
    return int.tryParse('$raw') ?? 0;
  }

  Map<String, dynamic> _optionPayload(Map<String, dynamic> opt) => {
        'investment_option': opt['investment_option'],
        'investment_option_id': opt['investment_option_id'],
        'handler': opt['handler'],
        'fund_manager_email': opt['fund_manager_email'],
        'fund_manager': opt['fund_manager'],
        'minimum_deposit': opt['minimum_deposit'],
        'interest': opt['interest'],
        'maturity': opt['maturity'],
        'description': opt['description'],
        'status': opt['status'],
        'units': opt['units'],
      };

  bool _matchesFilter(Map<String, dynamic> opt) {
    final q = widget.searchQuery.toLowerCase().trim();
    final name = opt['investment_option']?.toString().toLowerCase() ?? '';
    final handler = opt['handler']?.toString().toLowerCase() ?? '';
    final desc = opt['description']?.toString().toLowerCase() ?? '';
    if (q.isEmpty) return true;
    switch (_tab) {
      case OptionSearchTab.all:
        return name.contains(q) || handler.contains(q) || desc.contains(q);
      case OptionSearchTab.fundName:
        return name.contains(q);
      case OptionSearchTab.manager:
        return handler.contains(q);
      case OptionSearchTab.description:
        return desc.contains(q);
    }
  }

  String get _hint {
    switch (_tab) {
      case OptionSearchTab.all:
        return 'Search fund, manager, or description…';
      case OptionSearchTab.fundName:
        return 'Search by fund / option name…';
      case OptionSearchTab.manager:
        return 'Search by fund manager name…';
      case OptionSearchTab.description:
        return 'Search by description…';
    }
  }

  void _openInsightSheet(
    BuildContext context, {
    required String name,
    required int oid,
    required Map<String, dynamic> opt,
  }) {
    showFundOptionInsightSheet(
      context,
      fundName: name,
      investmentOptionId: oid,
      optionPayload: _optionPayload(opt),
      onContinueInvest: widget.onOptionSelected,
    );
  }

  Widget _classContextStrip() {
    final className =
        widget.selectedClass['investment_class']?.toString() ?? 'Your class';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: primaryTwo.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: primaryTwo.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(Icons.category_outlined, size: 18, color: primaryTwo),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              className,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade800,
                height: 1.25,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _metricChip({required IconData icon, required String text}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: primaryTwo),
          const SizedBox(width: 4),
          Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1a1d2e),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final options = List<Map<String, dynamic>>.from(
        widget.selectedClass['investment_options'] ?? []);
    final filteredOptions = options.where(_matchesFilter).toList();
    final pref = widget.preferredOptionId;
    if (pref != null) {
      filteredOptions.sort((a, b) {
        final pa = _optionId(a) == pref ? 0 : 1;
        final pb = _optionId(b) == pref ? 0 : 1;
        return pa.compareTo(pb);
      });
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Choose a fund',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: primaryTwo,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Pick a fund under your class — compare minimums and yield at a glance',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey.shade600,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 12),
        _classContextStrip(),
        const SizedBox(height: 14),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _chip('All', OptionSearchTab.all),
            _chip('Fund', OptionSearchTab.fundName),
            _chip('Manager', OptionSearchTab.manager),
            _chip('Details', OptionSearchTab.description),
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
          child: filteredOptions.isEmpty && widget.searchQuery.isNotEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.search_off,
                          size: 56, color: Colors.grey.shade400),
                      const SizedBox(height: 16),
                      Text(
                        'No options found',
                        style: TextStyle(
                          color: Colors.grey.shade700,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Try another tab or search term',
                        style: TextStyle(
                            color: Colors.grey.shade600, fontSize: 14),
                      ),
                    ],
                  ),
                )
              : ListView.separated(
                  itemCount: filteredOptions.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (ctx, i) {
                    final opt = filteredOptions[i];
                    final name = opt['investment_option'] ?? 'Unknown';
                    final handlerRaw = opt['handler'];
                    final descRaw = opt['description'];
                    final minStr = _formatMinimumDeposit(opt['minimum_deposit']);
                    final intStr = _formatInterestPercent(opt['interest']);
                    final matStr = _formatMaturityMonths(opt['maturity']);
                    final handlerStr =
                        _hasDisplayable(handlerRaw) ? '$handlerRaw' : '';
                    final descStr =
                        _hasDisplayable(descRaw) ? descRaw.toString().trim() : '';
                    final initial = name.toString().isNotEmpty
                        ? name.toString()[0].toUpperCase()
                        : '?';
                    final oid = _optionId(opt);

                    final chips = <Widget>[];
                    if (minStr.isNotEmpty) {
                      chips.add(_metricChip(
                        icon: Icons.savings_outlined,
                        text: 'Min $minStr',
                      ));
                    }
                    if (intStr.isNotEmpty) {
                      chips.add(_metricChip(
                        icon: Icons.show_chart_outlined,
                        text: intStr,
                      ));
                    }
                    if (matStr.isNotEmpty) {
                      chips.add(_metricChip(
                        icon: Icons.schedule_outlined,
                        text: matStr,
                      ));
                    }

                    return Material(
                      color: Colors.white,
                      elevation: 1.5,
                      shadowColor: primaryTwo.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(16),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(4, 4, 4, 4),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: InkWell(
                                onTap: () => widget
                                    .onOptionSelected(_optionPayload(opt)),
                                borderRadius: BorderRadius.circular(14),
                                child: Padding(
                                  padding: const EdgeInsets.fromLTRB(
                                      10, 12, 4, 12),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        width: 48,
                                        height: 48,
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                            colors: [
                                              primaryTwo
                                                  .withValues(alpha: 0.14),
                                              primaryTwo
                                                  .withValues(alpha: 0.06),
                                            ],
                                          ),
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          border: Border.all(
                                            color: primaryTwo
                                                .withValues(alpha: 0.22),
                                          ),
                                        ),
                                        alignment: Alignment.center,
                                        child: Text(
                                          initial,
                                          style: const TextStyle(
                                            fontSize: 17,
                                            fontWeight: FontWeight.w900,
                                            color: primaryTwo,
                                            letterSpacing: -0.5,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              name.toString(),
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w700,
                                                fontSize: 16,
                                                color: Color(0xFF1a1d2e),
                                              ),
                                            ),
                                            if (handlerStr.isNotEmpty) ...[
                                              const SizedBox(height: 4),
                                              Text(
                                                handlerStr,
                                                maxLines: 1,
                                                overflow:
                                                    TextOverflow.ellipsis,
                                                style: TextStyle(
                                                  fontSize: 13,
                                                  color: Colors.grey.shade700,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ],
                                            if (descStr.isNotEmpty) ...[
                                              const SizedBox(height: 4),
                                              Text(
                                                descStr,
                                                maxLines: 2,
                                                overflow:
                                                    TextOverflow.ellipsis,
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  height: 1.35,
                                                  color: Colors.grey.shade600,
                                                ),
                                              ),
                                            ],
                                            if (chips.isNotEmpty) ...[
                                              const SizedBox(height: 10),
                                              Wrap(
                                                spacing: 6,
                                                runSpacing: 6,
                                                children: chips,
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.only(
                                            left: 4, top: 8),
                                        child: Icon(
                                          Icons.chevron_right_rounded,
                                          color: primaryTwo.withValues(
                                              alpha: 0.65),
                                          size: 22,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            if (oid > 0)
                              IconButton(
                                tooltip: 'Charts & factsheets',
                                icon: Icon(
                                  Icons.insert_chart_outlined,
                                  color: primaryTwo,
                                  size: 22,
                                ),
                                constraints: const BoxConstraints(
                                  minWidth: 40,
                                  minHeight: 40,
                                ),
                                padding: EdgeInsets.zero,
                                onPressed: () => _openInsightSheet(
                                  context,
                                  name: name.toString(),
                                  oid: oid,
                                  opt: opt,
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _chip(String label, OptionSearchTab tab) {
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
