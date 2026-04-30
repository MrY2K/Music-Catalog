import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/catalog_state.dart';
import 'album_details_page.dart';
import 'settings_page.dart';

/// HomePage is the main screen of the application.
/// It contains a search bar and a grid of albums that update based on the search query.
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// Triggered when the user presses the search button or submits from the keyboard
  void _performSearch() {
    final query = _searchController.text;
    Provider.of<CatalogState>(context, listen: false).searchAlbums(query);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Music Catalog'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'Settings',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsPage()),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search for artists or albums...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                      prefixIcon: const Icon(Icons.search),
                    ),
                    onSubmitted: (_) => _performSearch(),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _performSearch,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Search'),
                ),
              ],
            ),
          ),
          
          // Results Area
          Expanded(
            child: Consumer<CatalogState>(
              builder: (context, state, child) {
                // 1. Show loading indicator if searching
                if (state.isLoadingAlbums) {
                  return const Center(child: CircularProgressIndicator());
                }

                // 2. Show error message if API call failed
                if (state.errorMessage.isNotEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        'Error: \${state.errorMessage}',
                        style: const TextStyle(color: Colors.red, fontSize: 16),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }

                // 3. Show empty state if no albums are loaded and not searching
                if (state.allAlbums.isEmpty) {
                  return const Center(
                    child: Text(
                      'Search for your favorite albums!',
                      style: TextStyle(fontSize: 18, color: Colors.grey),
                    ),
                  );
                }

                // 4. Show the results with a filter toggle at the top
                return Column(
                  children: [
                    // Filter Toggle
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                      child: SegmentedButton<AlbumFilter>(
                        segments: const [
                          ButtonSegment(value: AlbumFilter.all, label: Text('All')),
                          ButtonSegment(value: AlbumFilter.albums, label: Text('Albums')),
                          ButtonSegment(value: AlbumFilter.singles, label: Text('Singles')),
                        ],
                        selected: {state.currentFilter},
                        onSelectionChanged: (Set<AlbumFilter> newSelection) {
                          state.setFilter(newSelection.first);
                        },
                      ),
                    ),
                    
                    // The Grid of Albums
                    Expanded(
                      child: state.filteredAlbums.isEmpty
                          ? const Center(
                              child: Text(
                                'No items found for this filter.',
                                style: TextStyle(color: Colors.grey),
                              ),
                            )
                          : GridView.builder(
                              padding: const EdgeInsets.all(16),
                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2, // 2 columns
                                childAspectRatio: 0.75, // Aspect ratio to fit image and text
                                crossAxisSpacing: 16,
                                mainAxisSpacing: 16,
                              ),
                              itemCount: state.filteredAlbums.length,
                              itemBuilder: (context, index) {
                                final album = state.filteredAlbums[index];
                                return GestureDetector(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => AlbumDetailsPage(album: album),
                                      ),
                                    );
                                  },
                                  child: Card(
                                    elevation: 4,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    clipBehavior: Clip.antiAlias,
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.stretch,
                                      children: [
                                        // Album Art
                                        Expanded(
                                          child: Image.network(
                                            album.artworkUrl100,
                                            fit: BoxFit.cover,
                                            errorBuilder: (context, error, stackTrace) => 
                                                const Icon(Icons.album, size: 60, color: Colors.grey),
                                          ),
                                        ),
                                        // Album Metadata
                                        Padding(
                                          padding: const EdgeInsets.all(8.0),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                album.collectionName,
                                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                album.artistName,
                                                style: const TextStyle(fontSize: 12, color: Colors.grey),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                album.isSingle ? 'Single' : 'Album',
                                                style: const TextStyle(fontSize: 10, color: Color(0xFFC8202E), fontWeight: FontWeight.w600),
                                              ),
                                            ],
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
              },
            ),
          ),
        ],
      ),
    );
  }
}
