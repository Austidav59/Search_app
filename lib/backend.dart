import 'package:http/http.dart' as http;
import 'dart:convert';

Future<List<String>> pexelsApi(String query, int page) async {
  List<String> imageUrls = [];

  if (query.isEmpty) {
    return imageUrls; // Return empty list if the query is empty
  }

  var url = Uri.parse(
      "https://api.pexels.com/v1/search?query=$query&per_page=13&page=$page");
  var response = await http.get(url, headers: {
    'Authorization':
        'khOF95gCkMbfgkXUbzDV3zl2QphMdxlpCGCePGAvdYNZ3bCFq9aH3eXL', // Use your actual API key here
  });

  if (response.statusCode == 200) {
    var data = json.decode(response.body);
    List photos = data['photos'];
    imageUrls = photos.map<String>((photo) => photo['src']['medium']).toList();
  } else {
    print('Failed to load images');
  }

  return imageUrls;
}
