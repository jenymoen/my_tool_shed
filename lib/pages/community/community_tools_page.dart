import 'package:flutter/material.dart';
import 'package:my_tool_shed/models/tool.dart';
import 'package:my_tool_shed/services/community_service.dart';
import 'package:my_tool_shed/widgets/community/tool_card.dart';
import 'package:my_tool_shed/pages/community/tool_details_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:shimmer/shimmer.dart';
import 'package:my_tool_shed/utils/logger.dart';

class CommunityToolsPage extends StatefulWidget {
  const CommunityToolsPage({super.key});

  @override
  State<CommunityToolsPage> createState() => _CommunityToolsPageState();
}

class _CommunityToolsPageState extends State<CommunityToolsPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _sortBy = 'rating'; // Default sort by rating

  Widget _buildShimmerLoading() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 3,
      itemBuilder: (context, index) {
        return Shimmer.fromColors(
          baseColor: Colors.grey[300]!,
          highlightColor: Colors.grey[100]!,
          child: Card(
            margin: const EdgeInsets.only(bottom: 16),
            child: Container(
              height: 120,
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: double.infinity,
                          height: 20,
                          color: Colors.white,
                        ),
                        const SizedBox(height: 8),
                        Container(
                          width: 100,
                          height: 16,
                          color: Colors.white,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

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
    final communityService = CommunityService();
    final currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
    final l10n = AppLocalizations.of(context)!;

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
                    hintText: 'Search tools...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              setState(() {
                                _searchController.clear();
                                _searchQuery = '';
                              });
                            },
                          )
                        : null,
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                ),
              ),
              IconButton(
                icon: const Icon(Icons.sort),
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    builder: (context) => Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ListTile(
                          leading: const Icon(Icons.star),
                          title: const Text('Sort by Rating'),
                          onTap: () {
                            setState(() => _sortBy = 'rating');
                            Navigator.pop(context);
                          },
                        ),
                        ListTile(
                          leading: const Icon(Icons.sort_by_alpha),
                          title: const Text('Sort by Name'),
                          onTap: () {
                            setState(() => _sortBy = 'name');
                            Navigator.pop(context);
                          },
                        ),
                        ListTile(
                          leading: const Icon(Icons.business),
                          title: const Text('Sort by Brand'),
                          onTap: () {
                            setState(() => _sortBy = 'brand');
                            Navigator.pop(context);
                          },
                        ),
                      ],
                    ),
                  );
                },
              ),
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: () {
                  setState(() {});
                },
              ),
            ],
          ),
        ),
        Expanded(
          child: StreamBuilder<List<Tool>>(
            stream: communityService.getCommunityTools(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                AppLogger.error(
                    'Error fetching community tools', snapshot.error);
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline,
                          size: 48, color: Colors.red),
                      const SizedBox(height: 16),
                      Text(
                        'Error: ${snapshot.error}',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          setState(() {});
                        },
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                );
              }

              if (!snapshot.hasData) {
                AppLogger.debug('No data available yet, showing loading state');
                return _buildShimmerLoading();
              }

              final tools = _filterAndSortTools(snapshot.data!);
              AppLogger.debug('Filtered and sorted tools: ${tools.length}');
              for (var tool in tools) {
                AppLogger.debug('Tool: ${tool.name}');
                AppLogger.debug('- ID: ${tool.id}');
                AppLogger.debug('- Brand: ${tool.brand}');
                AppLogger.debug('- Owner: ${tool.ownerName}');
                AppLogger.debug('- Rating: ${tool.communityRating}');
                AppLogger.debug(
                    '- Total Ratings: ${tool.totalCommunityRatings}');
              }

              if (tools.isEmpty) {
                AppLogger.debug('No tools found after filtering');
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.build_outlined,
                        size: 64,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No tools found',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Try adjusting your search or filters',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
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
                            currentUserId: currentUserId,
                          ),
                        ),
                      );
                    },
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
