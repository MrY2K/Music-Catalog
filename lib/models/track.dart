/// The Track model represents a single song returned by the iTunes Search API.
/// It contains essential properties like the track name, artist, album art, and an audio preview URL.
class Track {
  final int trackId;
  final String trackName;
  final String artistName;
  final String collectionName;
  final String artworkUrl100;
  final String previewUrl;

  Track({
    required this.trackId,
    required this.trackName,
    required this.artistName,
    required this.collectionName,
    required this.artworkUrl100,
    required this.previewUrl,
  });

  /// Factory constructor to create a Track instance from a JSON map.
  /// This is used when parsing the response from the iTunes API.
  factory Track.fromJson(Map<String, dynamic> json) {
    return Track(
      trackId: json['trackId'] ?? 0,
      trackName: json['trackName'] ?? 'Unknown Track',
      artistName: json['artistName'] ?? 'Unknown Artist',
      collectionName: json['collectionName'] ?? 'Unknown Album',
      artworkUrl100: json['artworkUrl100'] ?? '',
      previewUrl: json['previewUrl'] ?? '',
    );
  }
}
