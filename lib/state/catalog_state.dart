import 'package:flutter/foundation.dart';
import '../models/album.dart';
import '../models/track.dart';
import '../api/itunes_api.dart';

/// Filter options for albums
enum AlbumFilter { all, albums, singles }

/// CatalogState is the central state management class for the app.
class CatalogState extends ChangeNotifier {
  final ITunesApi _api = ITunesApi();

  List<Album> _albums = [];
  bool _isLoadingAlbums = false;
  String _errorMessage = '';
  AlbumFilter _currentFilter = AlbumFilter.all;

  // State for a selected album's tracks
  List<Track> _selectedAlbumTracks = [];
  bool _isLoadingTracks = false;

  /// The original list of albums loaded from the search.
  List<Album> get allAlbums => _albums;
  
  /// The currently active filter
  AlbumFilter get currentFilter => _currentFilter;

  /// The filtered list of albums based on the current filter.
  List<Album> get filteredAlbums {
    switch (_currentFilter) {
      case AlbumFilter.albums:
        return _albums.where((album) => !album.isSingle).toList();
      case AlbumFilter.singles:
        return _albums.where((album) => album.isSingle).toList();
      case AlbumFilter.all:
        return _albums;
    }
  }

  bool get isLoadingAlbums => _isLoadingAlbums;
  String get errorMessage => _errorMessage;

  /// The tracks for the currently viewed album.
  List<Track> get selectedAlbumTracks => _selectedAlbumTracks;
  bool get isLoadingTracks => _isLoadingTracks;

  /// Updates the current album filter and notifies UI.
  void setFilter(AlbumFilter filter) {
    _currentFilter = filter;
    notifyListeners();
  }

  /// Initiates a search for music albums based on the [query].
  Future<void> searchAlbums(String query) async {
    if (query.trim().isEmpty) {
      _albums = [];
      notifyListeners();
      return;
    }

    _isLoadingAlbums = true;
    _errorMessage = '';
    // Reset filter to 'all' when a new search begins
    _currentFilter = AlbumFilter.all;
    notifyListeners();

    try {
      _albums = await _api.searchAlbums(query);
    } catch (e) {
      _errorMessage = e.toString();
      _albums = [];
    } finally {
      _isLoadingAlbums = false;
      notifyListeners();
    }
  }

  /// Fetches the tracks for a specific [albumId].
  Future<void> loadAlbumTracks(int albumId) async {
    _isLoadingTracks = true;
    _selectedAlbumTracks = [];
    notifyListeners();

    try {
      _selectedAlbumTracks = await _api.getAlbumTracks(albumId);
    } catch (e) {
      debugPrint('Error loading tracks: $e');
      _selectedAlbumTracks = [];
    } finally {
      _isLoadingTracks = false;
      notifyListeners();
    }
  }

  /// Clears the selected album tracks state (useful when navigating back).
  void clearSelectedAlbum() {
    _selectedAlbumTracks = [];
  }
}
