/// The Album model represents a music album returned by the iTunes Search API.
class Album {
  final int collectionId;
  final String collectionName;
  final String artistName;
  final String artworkUrl100;
  final String releaseDate;
  final int trackCount;

  Album({
    required this.collectionId,
    required this.collectionName,
    required this.artistName,
    required this.artworkUrl100,
    required this.releaseDate,
    required this.trackCount,
  });

  /// Factory constructor to create an Album instance from a JSON map.
  factory Album.fromJson(Map<String, dynamic> json) {
    return Album(
      collectionId: json['collectionId'] ?? 0,
      collectionName: json['collectionName'] ?? 'Unknown Album',
      artistName: json['artistName'] ?? 'Unknown Artist',
      artworkUrl100: json['artworkUrl100']?.replaceAll('100x100bb', '400x400bb') ?? '', // Use higher resolution artwork
      releaseDate: json['releaseDate'] ?? '',
      trackCount: json['trackCount'] ?? 0,
    );
  }
  
  /// Helper to determine if it's a single
  bool get isSingle => trackCount == 1 || collectionName.toLowerCase().endsWith('- single');
}
