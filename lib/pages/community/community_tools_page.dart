import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:my_tool_shed/models/tool.dart';
import 'package:my_tool_shed/services/community_service.dart';
import 'package:my_tool_shed/widgets/community/tool_card.dart';
import 'package:my_tool_shed/pages/community/tool_details_page.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CommunityToolsPage extends StatefulWidget {
  const CommunityToolsPage({super.key});

  @override
  State<CommunityToolsPage> createState() => _CommunityToolsPageState();
}

class _CommunityToolsPageState extends State<CommunityToolsPage> {
  final CommunityService _communityService = CommunityService();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _sortBy = 'rating'; // Default sort by rating

  List<Tool> _filterAndSortTools(List<Tool> tools) {
    // Filter tools based on search query
    var filteredTools = tools.where((tool) {
      final name = tool.name.toLowerCase();
      final brand = tool.brand?.toLowerCase() ?? '';
      final query = _searchQuery.toLowerCase();
      return name.contains(query) || brand.contains(query);
    }).toList();

    // Sort tools based on selected criteria
    switch (_sortBy) {
      case 'rating':
        filteredTools
            .sort((a, b) => b.communityRating.compareTo(a.communityRating));
        break;
      case 'name':
        filteredTools.sort((a, b) => a.name.compareTo(b.name));
        break;
      case 'brand':
        filteredTools.sort((a, b) {
          final aBrand = a.brand ?? '';
          final bBrand = b.brand ?? '';
          return aBrand.compareTo(bBrand);
        });
        break;
    }

    return filteredTools;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      body: StreamBuilder<List<Tool>>(
        stream: _communityService.getCommunityTools(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Error loading tools: ${snapshot.error}'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {});
                    },
                    child: Text(l10n.retry),
                  ),
                ],
              ),
            );
          }

          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          final tools = _filterAndSortTools(snapshot.data!);
          if (tools.isEmpty) {
            return Center(
              child: Text(l10n.noToolsAvailable),
            );
          }

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: l10n.searchTools,
                          prefixIcon: const Icon(Icons.search),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onChanged: (value) {
                          setState(() {
                            _searchQuery = value;
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    PopupMenuButton<String>(
                      onSelected: (value) {
                        setState(() {
                          _sortBy = value;
                        });
                      },
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          value: 'rating',
                          child: Text(l10n.sortByRating),
                        ),
                        PopupMenuItem(
                          value: 'name',
                          child: Text(l10n.sortByName),
                        ),
                        PopupMenuItem(
                          value: 'brand',
                          child: Text(l10n.sortByBrand),
                        ),
                      ],
                      child: const Icon(Icons.sort),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: tools.length,
                  itemBuilder: (context, index) {
                    final tool = tools[index];
                    return ToolCard(
                      tool: tool,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ToolDetailsPage(
                              tool: tool,
                              currentUserId:
                                  FirebaseAuth.instance.currentUser?.uid ?? '',
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
