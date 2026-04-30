import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/album.dart';
import '../models/track.dart';

/// The ITunesApi class handles all network requests to the iTunes Search API.
class ITunesApi {
  static const String _baseUrl = 'https://itunes.apple.com';

  /// Searches for albums on iTunes using the provided [query].
  /// 
  /// Returns a list of [Album] objects.
  Future<List<Album>> searchAlbums(String query) async {
    if (query.trim().isEmpty) return [];

    final url = Uri.parse('$_baseUrl/search?term=${Uri.encodeComponent(query)}&entity=album&limit=25');

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final List<dynamic> results = data['results'] ?? [];
        return results.map((json) => Album.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load albums. Status code: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching albums: $e');
    }
  }

  /// Fetches the tracks for a specific [albumId].
  /// 
  /// Returns a list of [Track] objects belonging to the album.
  Future<List<Track>> getAlbumTracks(int albumId) async {
    final url = Uri.parse('$_baseUrl/lookup?id=$albumId&entity=song');

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final List<dynamic> results = data['results'] ?? [];
        
        // The iTunes lookup API returns the Album object as the first result, 
        // followed by the tracks. We filter out the album object by checking wrapperType.
        final trackResults = results.where((item) => item['wrapperType'] == 'track').toList();
        return trackResults.map((json) => Track.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load tracks. Status code: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching tracks: $e');
    }
  }
}
