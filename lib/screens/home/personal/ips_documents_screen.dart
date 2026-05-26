import 'package:cyanase/helpers/api_helper.dart';
import 'package:cyanase/helpers/database_helper.dart';
import 'package:cyanase/screens/home/personal/ips_document_edit_screen.dart';
import 'package:cyanase/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Lists formal IPS documents from the Django API for the signed-in user.
class IpsDocumentsScreen extends StatefulWidget {
  const IpsDocumentsScreen({super.key});

  @override
  State<IpsDocumentsScreen> createState() => _IpsDocumentsScreenState();
}

class _IpsDocumentsScreenState extends State<IpsDocumentsScreen> {
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _docs = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final db = await DatabaseHelper().database;
      final rows = await db.query('profile', limit: 1);
      if (rows.isEmpty) throw Exception('Not signed in');
      final token = (rows.first['token'] as String?)?.trim() ?? '';
      if (token.isEmpty) throw Exception('Not signed in');
      final result = await ApiService.getIpsDocuments(token);
      if (result['success'] != true) {
        throw Exception(result['message']?.toString() ?? 'Could not load IPS list');
      }
      final raw = result['ips_documents'];
      final list = raw is List
          ? List<Map<String, dynamic>>.from(
              raw.map((e) => Map<String, dynamic>.from(e as Map)),
            )
          : <Map<String, dynamic>>[];
      if (!mounted) return;
      setState(() {
        _docs = list;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  String _formatDate(dynamic iso) {
    if (iso == null) return '';
    try {
      return DateFormat.yMMMd().format(DateTime.parse(iso.toString()));
    } catch (_) {
      return iso.toString();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'IPS documents',
          style: TextStyle(color: white, fontSize: 18),
        ),
        backgroundColor: primaryTwo,
        foregroundColor: Colors.white,
      ),
      body: RefreshIndicator(
        color: primaryTwo,
        onRefresh: _load,
        child: _loading
            ? ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const [
                  SizedBox(height: 120),
                  Center(child: CircularProgressIndicator(color: primaryTwo)),
                ],
              )
            : _error != null
                ? ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(24),
                    children: [
                      const SizedBox(height: 48),
                      Text(_error!, textAlign: TextAlign.center),
                      const SizedBox(height: 16),
                      Center(
                        child: FilledButton(
                          onPressed: _load,
                          child: const Text('Retry'),
                        ),
                      ),
                    ],
                  )
                : _docs.isEmpty
                    ? ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(24),
                        children: [
                          const SizedBox(height: 64),
                          Icon(Icons.article_outlined,
                              size: 56, color: Colors.grey.shade400),
                          const SizedBox(height: 16),
                          Text(
                            'No IPS documents yet',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade800,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'When you create an Investment Policy Statement through the platform, it will appear here for viewing and editing.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade600,
                              height: 1.35,
                            ),
                          ),
                        ],
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                        itemCount: _docs.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, i) {
                          final d = _docs[i];
                          final name =
                              (d['name'] ?? d['client_name'] ?? 'IPS').toString();
                          final client =
                              (d['client_name'] ?? '').toString();
                          final risk =
                              (d['risk_tolerance'] ?? '').toString();
                          final created = _formatDate(d['created_at']);
                          return Material(
                            elevation: 1,
                            shadowColor: primaryTwo.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(14),
                            color: Colors.white,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(14),
                              onTap: () async {
                                final updated = await Navigator.of(context)
                                    .push<bool>(
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        IpsDocumentEditScreen(document: d),
                                  ),
                                );
                                if (updated == true && mounted) _load();
                              },
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 14),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 44,
                                      height: 44,
                                      decoration: BoxDecoration(
                                        color: primaryTwo.withValues(alpha: 0.12),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      alignment: Alignment.center,
                                      child: Icon(
                                        Icons.description_outlined,
                                        color: primaryTwo,
                                        size: 24,
                                      ),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            name,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w700,
                                              fontSize: 16,
                                              color: Color(0xFF1a1d2e),
                                            ),
                                          ),
                                          if (client.isNotEmpty) ...[
                                            const SizedBox(height: 4),
                                            Text(
                                              client,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                fontSize: 13,
                                                color: Colors.grey.shade700,
                                              ),
                                            ),
                                          ],
                                          const SizedBox(height: 6),
                                          Text(
                                            [
                                              if (risk.isNotEmpty)
                                                risk.replaceAll('_', ' '),
                                              if (created.isNotEmpty) created,
                                            ].join(' · '),
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey.shade600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Icon(Icons.chevron_right_rounded,
                                        color: Colors.grey.shade400),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
      ),
    );
  }
}
