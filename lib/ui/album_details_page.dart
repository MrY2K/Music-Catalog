import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/album.dart';
import '../state/catalog_state.dart';
import '../state/download_state.dart';
import '../state/settings_state.dart';

/// AlbumDetailsPage displays the details of a specific album, including its tracklist.
class AlbumDetailsPage extends StatefulWidget {
  final Album album;

  const AlbumDetailsPage({super.key, required this.album});

  @override
  State<AlbumDetailsPage> createState() => _AlbumDetailsPageState();
}

class _AlbumDetailsPageState extends State<AlbumDetailsPage> {
  @override
  void initState() {
    super.initState();
    // Load the tracks for this album when the page initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<CatalogState>(context, listen: false).loadAlbumTracks(widget.album.collectionId);
    });
  }

  void _showDownloadDialog(BuildContext context, Album album) {
    final downloadState = Provider.of<DownloadState>(context, listen: false);
    final settings = Provider.of<SettingsState>(context, listen: false);

    downloadState.initiateDownload(
      album,
      settings.slskdUrl,
      settings.username,
      settings.password,
    );

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return Consumer<DownloadState>(
          builder: (dialogContext, state, child) {
            // --- SEARCHING ---
            if (state.status == DownloadStatus.idle ||
                state.status == DownloadStatus.searching) {
              return AlertDialog(
                title: const Text('Searching Soulseek'),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: 16),
                    Text('Searching for "${album.collectionName}"...'),
                    if (state.results.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          '${state.results.length} results found so far...',
                          style: const TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                      ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      state.reset();
                      Navigator.of(dialogContext).pop();
                    },
                    child: const Text('Cancel'),
                  ),
                ],
              );
            }

            // --- RESULTS LIST ---
            if (state.status == DownloadStatus.results) {
              return AlertDialog(
                title: Text('${state.results.length} Results Found'),
                // Use a fixed-height scrollable list so it fits the screen.
                content: SizedBox(
                  width: double.maxFinite,
                  height: 400,
                  child: ListView.separated(
                    itemCount: state.results.length,
                    separatorBuilder: (context, index) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final r = state.results[index];
                      // Pick a badge color based on format.
                      final badgeColor = r.format == 'FLAC'
                          ? Colors.teal
                          : r.format == 'MP3 320kbps'
                              ? const Color(0xFFC8202E)
                              : r.format.startsWith('MP3')
                                  ? Colors.blueGrey
                                  : Colors.grey;

                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                        leading: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 3),
                          decoration: BoxDecoration(
                            color: badgeColor,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            r.format,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        title: Text(
                          r.directory,
                          style: const TextStyle(fontSize: 13),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(
                          '${r.username}  •  ${r.fileCount} files  •  ${r.sizeLabel}',
                          style: const TextStyle(fontSize: 11),
                        ),
                        trailing: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                          ),
                          onPressed: () => state.downloadResult(r),
                          child: const Text('Get', style: TextStyle(fontSize: 12)),
                        ),
                      );
                    },
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      state.reset();
                      Navigator.of(dialogContext).pop();
                    },
                    child: const Text('Cancel'),
                  ),
                ],
              );
            }

            // --- DOWNLOADING ---
            if (state.status == DownloadStatus.downloading) {
              return const AlertDialog(
                title: Text('Starting Download'),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Sending to slskd server...'),
                  ],
                ),
              );
            }

            // --- COMPLETE ---
            if (state.status == DownloadStatus.complete) {
              return AlertDialog(
                title: const Text('Download Queued!'),
                content: const Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check_circle, color: Colors.green, size: 52),
                    SizedBox(height: 16),
                    Text(
                      'The download has been added to your slskd queue.',
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
                actions: [
                  ElevatedButton(
                    onPressed: () {
                      state.reset();
                      Navigator.of(dialogContext).pop();
                    },
                    child: const Text('Close'),
                  ),
                ],
              );
            }

            // --- ERROR ---
            return AlertDialog(
              title: const Text('Error'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 52),
                  const SizedBox(height: 16),
                  Text(
                    state.errorMessage,
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
              actions: [
                ElevatedButton(
                  onPressed: () {
                    state.reset();
                    Navigator.of(dialogContext).pop();
                  },
                  child: const Text('Close'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.album.collectionName),
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            tooltip: 'Download via Soulseek',
            onPressed: () {
              _showDownloadDialog(context, widget.album);
            },
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Album Header
          Container(
            color: const Color(0x33C8202E),
            padding: const EdgeInsets.all(24.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Large Album Art
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    widget.album.artworkUrl100,
                    width: 120,
                    height: 120,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => 
                        const Icon(Icons.album, size: 120, color: Colors.grey),
                  ),
                ),
                const SizedBox(width: 16),
                // Album Meta
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.album.collectionName,
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        widget.album.artistName,
                        style: const TextStyle(fontSize: 16, color: const Color(0xFFC8202E)),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Released: ${widget.album.releaseDate.split('T').first}",
                        style: const TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Tracklist Title
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'Tracks',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          
          // Tracklist
          Expanded(
            child: Consumer<CatalogState>(
              builder: (context, state, child) {
                if (state.isLoadingTracks) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (state.selectedAlbumTracks.isEmpty) {
                  return const Center(child: Text('No tracks found for this album.'));
                }

                return ListView.separated(
                  itemCount: state.selectedAlbumTracks.length,
                  separatorBuilder: (context, index) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final track = state.selectedAlbumTracks[index];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: const Color(0x66C8202E),
                        child: Text('${index + 1}', style: const TextStyle(color: const Color(0xFFC8202E))),
                      ),
                      title: Text(track.trackName),
                      subtitle: Text(track.artistName),
                      trailing: const Icon(Icons.music_note, color: Colors.grey, size: 16),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
