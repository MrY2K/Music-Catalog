import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Handles interactions with the slskd REST API.
///
/// Authentication flow:
///   1. POST /api/v0/session with {username, password}
///   2. On success, the response contains a Bearer token.
///   3. All subsequent requests use "Authorization: Bearer TOKEN".
///
/// Search flow:
///   1. POST /api/v0/searches with {searchText: "..."}
///   2. GET  /api/v0/searches/{id} to poll until 'isComplete' is true.
///   3. Parse the 'responses' array from the result.
///
/// Download flow:
///   POST /api/v0/transfers/downloads/{username}
///   Body: JSON array of full file path strings from the search result.
class SlskdApi {
  final String baseUrl;
  final String username;
  final String password;
  String? _token;

  SlskdApi({
    required this.baseUrl,
    required this.username,
    required this.password,
  });

  /// Authenticate with slskd and store the Bearer token.
  Future<void> authenticate() async {
    final url = Uri.parse('$baseUrl/api/v0/session');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'username': username, 'password': password}),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      _token = data['token'] as String?;
      debugPrint('slskd: Authenticated successfully.');
    } else {
      throw Exception(
        'slskd authentication failed. Status: ${response.statusCode}. '
        'Check your username and password in Settings.',
      );
    }
  }

  /// Returns HTTP headers with the Bearer token.
  /// Calls authenticate() first if we don't have a token yet.
  Future<Map<String, String>> _getHeaders() async {
    if (_token == null) await authenticate();
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $_token',
    };
  }

  /// Initiates a search on the Soulseek network.
  /// [query] is the search text (e.g. "Eminem Recovery 2010").
  /// Returns the search ID string to use when polling.
  Future<String> startSearch(String query) async {
    final headers = await _getHeaders();
    final url = Uri.parse('$baseUrl/api/v0/searches');

    // The slskd API requires "searchText" as the key (not "query").
    final response = await http.post(
      url,
      headers: headers,
      body: json.encode({'searchText': query}),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = json.decode(response.body);
      // The returned object contains the search "id".
      return data['id'] as String? ?? '';
    } else {
      throw Exception(
        'Failed to start slskd search. Status: ${response.statusCode}. Body: ${response.body}',
      );
    }
  }

  /// Checks whether a search is still running.
  /// Returns the state string from slskd (e.g. 'InProgress', 'Completed').
  /// This calls the lightweight endpoint that does NOT include file responses.
  Future<String> getSearchState(String searchId) async {
    final headers = await _getHeaders();
    // Pass includeResponses=false for a lightweight state check.
    final url = Uri.parse(
      '$baseUrl/api/v0/searches/$searchId?includeResponses=false',
    );
    final response = await http.get(url, headers: headers);

    if (response.statusCode == 200) {
      final data = json.decode(response.body) as Map<String, dynamic>;
      // The state field is like 'InProgress', 'Completed', 'TimedOut', etc.
      return data['state'] as String? ?? 'Completed';
    } else {
      throw Exception('Failed to check search state. Status: ${response.statusCode}');
    }
  }

  /// Fetches the actual file responses for a completed search.
  /// This is a SEPARATE endpoint from the state check.
  /// Returns the raw list of peer responses.
  Future<List<dynamic>> getSearchResponses(String searchId) async {
    final headers = await _getHeaders();
    final url = Uri.parse('$baseUrl/api/v0/searches/$searchId/responses');
    final response = await http.get(url, headers: headers);

    if (response.statusCode == 200) {
      return json.decode(response.body) as List<dynamic>;
    } else {
      throw Exception(
        'Failed to fetch search responses. Status: ${response.statusCode}',
      );
    }
  }

  /// Initiates a download of specific files from [peerUsername].
  ///
  /// slskd API: POST /api/v0/transfers/downloads/{username}
  /// Body: JSON array of QueueDownloadRequest objects, each with "filename" and "size".
  ///
  /// Example body:
  /// [{"filename": "path\\to\\file.flac", "size": 12345678}, ...]
  Future<void> downloadFiles(
    String peerUsername,
    List<Map<String, dynamic>> files,
  ) async {
    final headers = await _getHeaders();
    // Username goes in the URL path, not the body.
    final url = Uri.parse(
      '$baseUrl/api/v0/transfers/downloads/$peerUsername',
    );

    // Build the QueueDownloadRequest array — each item needs filename + size.
    final body = files
        .map((f) => {'filename': f['filename'], 'size': f['size'] ?? 0})
        .toList();

    final response = await http.post(
      url,
      headers: headers,
      body: json.encode(body),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception(
        'Failed to initiate download. Status: ${response.statusCode}. Body: ${response.body}',
      );
    }
  }
}
