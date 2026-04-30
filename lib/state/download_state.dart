import 'dart:async';
import 'package:flutter/foundation.dart';
import '../api/slskd_api.dart';
import '../models/album.dart';

/// The possible states of the download process.
enum DownloadStatus { idle, searching, results, downloading, complete, error }

/// Represents a single search result candidate from a Soulseek peer.
class SlskdSearchResult {
  /// The Soulseek peer's username.
  final String username;
  /// Detected audio format label (e.g. 'FLAC', 'MP3 320kbps', 'MP3', 'Unknown').
  final String format;
  /// Number of audio files in this result set.
  final int fileCount;
  /// Total size of all files in bytes.
  final int totalSize;
  /// The directory path (for display purposes).
  final String directory;
  /// The full file objects ({filename, size}) to pass to the download API.
  final List<Map<String, dynamic>> files;

  SlskdSearchResult({
    required this.username,
    required this.format,
    required this.fileCount,
    required this.totalSize,
    required this.directory,
    required this.files,
  });

  /// Human-readable size string (e.g. "245 MB").
  String get sizeLabel {
    if (totalSize <= 0) return 'Unknown size';
    final mb = totalSize / (1024 * 1024);
    return '${mb.toStringAsFixed(0)} MB';
  }

  /// Sort priority: lower = better. FLAC=0, MP3 320=1, MP3=2, Other=3.
  int get _priority {
    if (format == 'FLAC') return 0;
    if (format == 'MP3 320kbps') return 1;
    if (format.startsWith('MP3')) return 2;
    return 3;
  }

  static int compare(SlskdSearchResult a, SlskdSearchResult b) {
    final p = a._priority.compareTo(b._priority);
    if (p != 0) return p;
    // Prefer more files (more complete upload).
    return b.fileCount.compareTo(a.fileCount);
  }
}

/// Manages the entire album download lifecycle:
/// search → poll → show top results → user selects → trigger download.
class DownloadState extends ChangeNotifier {
  DownloadStatus _status = DownloadStatus.idle;
  String _errorMessage = '';
  List<SlskdSearchResult> _results = [];
  Timer? _pollTimer;
  SlskdApi? _api;

  DownloadStatus get status => _status;
  String get errorMessage => _errorMessage;
  /// Top results for the user to choose from (up to 10).
  List<SlskdSearchResult> get results => _results;

  /// Kicks off the full download flow for [album].
  /// Credentials come from the Settings page.
  Future<void> initiateDownload(
    Album album,
    String baseUrl,
    String username,
    String password,
  ) async {
    _api = SlskdApi(baseUrl: baseUrl, username: username, password: password);
    _status = DownloadStatus.searching;
    _errorMessage = '';
    _results = [];
    notifyListeners();

    try {
      // Build query: "Artist Album Year"
      final year = album.releaseDate.split('-').first;
      final query = '${album.artistName} ${album.collectionName} $year';

      final searchId = await _api!.startSearch(query);

      // Poll every 3 seconds, up to 60 seconds (20 attempts).
      int attempts = 0;
      _pollTimer = Timer.periodic(const Duration(seconds: 3), (timer) async {
        attempts++;
        if (attempts > 20) {
          timer.cancel();
          if (_results.isNotEmpty) {
            _status = DownloadStatus.results;
          } else {
            _status = DownloadStatus.error;
            _errorMessage =
                'Search timed out. No results found on Soulseek.\n'
                'Try connecting to the VPN or check if slskd is online.';
          }
          notifyListeners();
          return;
        }

        try {
          // Step 1: Lightweight check — is the search still running?
          final state = await _api!.getSearchState(searchId);
          final isDone = state != 'InProgress';

          if (isDone) {
            timer.cancel();
            // Step 2: Only fetch the heavy response data once search is done.
            final responses = await _api!.getSearchResponses(searchId);
            _results = _parseResults(responses);

            if (_results.isNotEmpty) {
              _status = DownloadStatus.results;
            } else {
              _status = DownloadStatus.error;
              _errorMessage =
                  'Search completed (state: $state) but no audio files were found.\n'
                  'Soulseek peers may not have this album available right now.';
            }
            notifyListeners();
          }
          // If still InProgress, we keep polling.
        } catch (e) {
          timer.cancel();
          _status = DownloadStatus.error;
          _errorMessage = 'Error while polling: $e';
          notifyListeners();
        }
      });
    } catch (e) {
      _status = DownloadStatus.error;
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  /// Parses raw slskd peer responses into a sorted list of up to 10 candidates.
  /// Includes any folder that has at least 1 audio file (.flac, .mp3, .ogg, .m4a, .opus).
  List<SlskdSearchResult> _parseResults(List<dynamic> responses) {
    final List<SlskdSearchResult> candidates = [];
    const audioExtensions = ['.flac', '.mp3', '.ogg', '.m4a', '.opus', '.aac', '.wav'];

    for (final response in responses) {
      final peerUsername = response['username'] as String? ?? '';
      final files = response['files'] as List<dynamic>? ?? [];

      // Group files by their directory path.
      final Map<String, List<dynamic>> byDir = {};
      for (final file in files) {
        final path = file['filename'] as String? ?? '';
        // Soulseek paths typically use backslashes.
        final sepIdx = path.lastIndexOf('\\') >= 0
            ? path.lastIndexOf('\\')
            : path.lastIndexOf('/');
        final dir = sepIdx >= 0 ? path.substring(0, sepIdx) : path;
        byDir.putIfAbsent(dir, () => []).add(file);
      }

      // Evaluate each directory.
      byDir.forEach((dir, dirFiles) {
        int flacCount = 0;
        int mp3320Count = 0;
        int mp3Count = 0;
        int audioCount = 0;
        int totalSize = 0;
        final List<Map<String, dynamic>> fileObjects = [];

        for (final f in dirFiles) {
          final filename = f['filename'] as String? ?? '';
          final nameLower = filename.toLowerCase();
          final size = f['size'] as int? ?? 0;
          final bitRate = f['bitRate'] as int? ?? 0;
          totalSize += size;

          // Only include audio files.
          final isAudio = audioExtensions.any((ext) => nameLower.endsWith(ext));
          if (!isAudio) continue;

          audioCount++;
          // Store the full object so we can pass filename+size to download API.
          fileObjects.add({'filename': filename, 'size': size});

          if (nameLower.endsWith('.flac')) {
            flacCount++;
          } else if (nameLower.endsWith('.mp3')) {
            mp3Count++;
            if (bitRate >= 320) mp3320Count++;
          }
        }

        // Skip if no audio files found in this directory.
        if (audioCount == 0) return;

        // Determine format label.
        String format;
        if (flacCount > 0 && flacCount >= audioCount ~/ 2) {
          format = 'FLAC';
        } else if (mp3320Count > 0 && mp3320Count >= mp3Count ~/ 2) {
          format = 'MP3 320kbps';
        } else if (mp3Count > 0) {
          format = 'MP3';
        } else {
          format = 'Audio'; // ogg, m4a, etc.
        }

        // Use the last part of the directory as the display name.
        final dirName = dir.split('\\').last.split('/').last;

        candidates.add(SlskdSearchResult(
          username: peerUsername,
          format: format,
          fileCount: audioCount,
          totalSize: totalSize,
          directory: dirName.isNotEmpty ? dirName : dir,
          files: fileObjects,
        ));
      });
    }

    // Sort by quality and return top 10.
    candidates.sort(SlskdSearchResult.compare);
    return candidates.take(10).toList();
  }

  /// Called when the user selects a specific result to download.
  Future<void> downloadResult(SlskdSearchResult result) async {
    if (_api == null) return;

    _status = DownloadStatus.downloading;
    notifyListeners();

    try {
      await _api!.downloadFiles(result.username, result.files);
      _status = DownloadStatus.complete;
      notifyListeners();
    } catch (e) {
      _status = DownloadStatus.error;
      _errorMessage = 'Download failed: $e';
      notifyListeners();
    }
  }

  /// Resets state back to idle (call when dialog is dismissed).
  void reset() {
    _pollTimer?.cancel();
    _status = DownloadStatus.idle;
    _errorMessage = '';
    _results = [];
    notifyListeners();
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }
}
