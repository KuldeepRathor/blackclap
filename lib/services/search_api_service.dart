import '../config/app_url.dart';
import '../models/search_result.dart';
import 'api_service.dart';

class SearchApiService {
  final ApiService _api;

  SearchApiService(this._api);

  Future<SearchResult> search({
    required String query,
    String type = 'all',
    int limit = 20,
    int offset = 0,
    String? cursor,
  }) async {
    final encodedQuery = Uri.encodeQueryComponent(query);
    final path =
        '${AppUrl.search}?q=$encodedQuery&type=$type&limit=$limit&offset=$offset'
        '${cursor != null ? '&cursor=${Uri.encodeQueryComponent(cursor)}' : ''}';

    // Strip the base URL prefix since ApiService.get() prepends baseUrl internally.
    // AppUrl.search = baseUrl + '/search', so we need just '/search?...'
    final relativePath = path.replaceFirst(AppUrl.baseUrl, '');

    final data = await _api.get(relativePath);
    return SearchResult.fromMap(data);
  }
}
