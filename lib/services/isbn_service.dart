import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/book.dart';

class IsbnService {
  static const _supabaseUrl = 'https://hhmevsifjcdkuowzpupa.supabase.co';
  static const _supabaseKey = 'sb_publishable_GprqRBJVc-SzALVC-HrZbg_YGU22_TB';

  static String normalizeIsbn(String raw) {
    String s = raw.replaceAll(RegExp(r'[^0-9Xx]'), '');
    if (s.length == 10) {
      final base = '978${s.substring(0, 9)}';
      int sum = 0;
      for (int i = 0; i < 12; i++) {
        sum += int.parse(base[i]) * (i % 2 == 0 ? 1 : 3);
      }
      s = '978${s.substring(0, 9)}${(10 - (sum % 10)) % 10}';
    }
    return s;
  }

  static Future<String?> _fetchWithTimeout(String url, {Duration timeout = const Duration(seconds: 6), Map<String, String>? headers, String? body}) async {
    try {
      http.Response response;
      if (body != null) {
        response = await http.post(Uri.parse(url), headers: headers, body: body).timeout(timeout);
      } else {
        response = await http.get(Uri.parse(url), headers: headers).timeout(timeout);
      }
      if (response.statusCode == 200) return response.body;
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Main lookup: parallel GB + BNF, then OL if needed
  static Future<Book> lookup(String rawIsbn, {Function(String)? onProgress}) async {
    final isbn = normalizeIsbn(rawIsbn);
    if (isbn.length < 10) {
      return Book(isbn: rawIsbn, title: 'Code invalide', authors: '');
    }

    final book = Book(isbn: isbn, status: 'alire');

    onProgress?.call('Recherche…');

    // 1. Google Books + BNF in parallel
    final results = await Future.wait([
      _fetchGoogleBooks(isbn),
      _fetchBnf(isbn),
    ]);

    final gbData = results[0] as Map<String, dynamic>?;
    final bnfData = results[1] as Map<String, dynamic>?;

    // Apply Google Books
    if (gbData != null) {
      book.title = gbData['title'] ?? '';
      book.authors = gbData['authors'] ?? '';
      book.publisher = gbData['publisher'];
      book.year = gbData['year'];
      book.pages = gbData['pages'];
      book.categories = gbData['categories'];
      book.description = gbData['description'];
      book.cover = gbData['cover'];
    }

    // Apply BNF (fills gaps + exclusive fields)
    if (bnfData != null && bnfData['title'] != null) {
      if (book.title.isEmpty) book.title = bnfData['title'] ?? '';
      if (book.authors.isEmpty) book.authors = bnfData['authors'] ?? '';
      if (_empty(book.publisher)) book.publisher = bnfData['publisher'];
      if (_empty(book.year)) book.year = bnfData['year'];
      if (_empty(book.pages)) book.pages = bnfData['pages'];
      if (_empty(book.description)) book.description = bnfData['description'];
      if (_empty(book.categories)) book.categories = bnfData['categories'];
      // BNF exclusive fields
      book.collection = bnfData['collection'] ?? book.collection;
      book.genre = bnfData['genre'] ?? book.genre;
      book.lieu = bnfData['lieu'] ?? book.lieu;
      book.titreOriginal = bnfData['titreOriginal'] ?? book.titreOriginal;
      book.dewey = bnfData['dewey'] ?? book.dewey;
      book.roles = bnfData['roles'] ?? book.roles;
    }

    // 2. Open Library if still missing title/authors
    if (book.title.isEmpty || book.authors.isEmpty) {
      onProgress?.call('Open Library…');
      final olData = await _fetchOpenLibrary(isbn);
      if (olData != null) {
        if (book.title.isEmpty) book.title = olData['title'] ?? '';
        if (book.authors.isEmpty) book.authors = olData['authors'] ?? '';
        if (_empty(book.publisher)) book.publisher = olData['publisher'];
        if (_empty(book.year)) book.year = olData['year'];
        if (_empty(book.pages)) book.pages = olData['pages'];
        if (_empty(book.cover)) book.cover = olData['cover'];
        if (_empty(book.categories)) book.categories = olData['categories'];
        if (_empty(book.description)) book.description = olData['description'];
      }
    }

    if (book.title.isEmpty) book.title = 'Titre non trouvé';
    if (book.authors.isEmpty) book.authors = 'Auteur inconnu';

    return book;
  }

  static bool _empty(String? s) => s == null || s.isEmpty;

  // ── Google Books ──
  static Future<Map<String, dynamic>?> _fetchGoogleBooks(String isbn) async {
    final raw = await _fetchWithTimeout(
      'https://www.googleapis.com/books/v1/volumes?q=isbn:$isbn&maxResults=1',
      timeout: const Duration(seconds: 6),
    );
    if (raw == null) return null;
    try {
      final json = jsonDecode(raw);
      if (json['items'] == null || (json['items'] as List).isEmpty) return null;
      final v = json['items'][0]['volumeInfo'];
      String? cover;
      if (v['imageLinks'] != null) {
        cover = (v['imageLinks']['thumbnail'] ?? v['imageLinks']['smallThumbnail'] ?? '')
            .toString()
            .replaceAll('http://', 'https://')
            .replaceAll('zoom=1', 'zoom=2');
      }
      return {
        'title': v['title'] ?? '',
        'authors': (v['authors'] as List?)?.join(', ') ?? '',
        'publisher': v['publisher'] ?? '',
        'year': v['publishedDate']?.toString().substring(0, 4) ?? '',
        'pages': (v['pageCount'] ?? '').toString(),
        'categories': (v['categories'] as List?)?.join(', ') ?? '',
        'description': v['description'] ?? '',
        'cover': cover ?? '',
      };
    } catch (_) {
      return null;
    }
  }

  // ── BNF via Supabase Edge Function ──
  static Future<Map<String, dynamic>?> _fetchBnf(String isbn) async {
    final raw = await _fetchWithTimeout(
      '$_supabaseUrl/functions/v1/hyper-task',
      timeout: const Duration(seconds: 8),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_supabaseKey',
      },
      body: jsonEncode({'isbn': isbn}),
    );
    if (raw == null || !raw.contains('datafield')) return null;
    return _parseBnfUnimarc(raw);
  }

  static Map<String, dynamic>? _parseBnfUnimarc(String xmlText) {
    try {
      // Simple XML parsing using RegExp for UNIMARC fields
      final datafields = <_Datafield>[];
      final dfRegex = RegExp(r'<(?:\w+:)?datafield\s+tag="(\d+)"[^>]*>(.*?)</(?:\w+:)?datafield>', dotAll: true);
      final sfRegex = RegExp(r'<(?:\w+:)?subfield\s+code="([^"]+)"[^>]*>(.*?)</(?:\w+:)?subfield>', dotAll: true);

      for (final m in dfRegex.allMatches(xmlText)) {
        final tag = m.group(1)!;
        final content = m.group(2)!;
        final subs = <String, String>{};
        for (final sm in sfRegex.allMatches(content)) {
          final code = sm.group(1)!;
          final value = _decodeXmlEntities(sm.group(2)!.trim());
          if (!subs.containsKey(code)) subs[code] = value;
        }
        datafields.add(_Datafield(tag, subs));
      }

      if (datafields.isEmpty) return null;

      String sf(String zone, String code) {
        final f = datafields.where((d) => d.tag == zone).toList();
        if (f.isEmpty) return '';
        return f.first.subs[code] ?? '';
      }

      List<String> sfAll(String zone, String code) {
        return datafields
            .where((d) => d.tag == zone)
            .map((d) => d.subs[code] ?? '')
            .where((s) => s.isNotEmpty)
            .toList();
      }

      String sfFirst(List<String> zones, String code) {
        for (final z in zones) {
          final v = sf(z, code);
          if (v.isNotEmpty) return v;
        }
        return '';
      }

      // Title
      final titre200a = sf('200', 'a');
      final titre200e = sf('200', 'e');
      final title = titre200e.isNotEmpty ? '$titre200a — $titre200e' : titre200a;

      // Authors (700 + 701)
      final authorFields = datafields.where((d) => d.tag == '700' || d.tag == '701').toList();
      final authors200f = sf('200', 'f');
      String authors;
      if (authorFields.isNotEmpty) {
        final names = authorFields.map((f) {
          final nom = f.subs['a'] ?? '';
          final prenom = f.subs['b'] ?? '';
          return prenom.isNotEmpty ? '$prenom $nom' : nom;
        }).where((s) => s.isNotEmpty).toSet().toList();
        authors = names.join(', ');
      } else {
        authors = authors200f;
      }

      final publisher = sfFirst(['214', '210'], 'c');
      final yearRaw = sfFirst(['214', '210'], 'd');
      final yearMatch = RegExp(r'\d{4}').firstMatch(yearRaw);
      final year = yearMatch?.group(0) ?? '';
      final pagesRaw = sf('215', 'a');
      final pagesMatch = RegExp(r'\d+').firstMatch(pagesRaw);
      final pages = pagesMatch?.group(0) ?? '';
      final collection = sf('225', 'a');
      final description = sf('330', 'a');
      final categories = [...sfAll('606', 'a'), ...sfAll('610', 'a')].take(6).join(', ');
      final genre = sfAll('608', 'a').take(4).join(', ');
      final lieu = sfAll('607', 'a').take(4).join(', ');
      final titreOriginal = sf('454', 't').isNotEmpty
          ? sf('454', 't')
          : (sf('423', 't').isNotEmpty ? sf('423', 't') : sf('500', 'a'));
      final dewey = sf('676', 'a');

      // Roles (702 = contributeurs)
      const roleNames = {
        '070': 'Auteur', '440': 'Illustrateur', '660': 'Traducteur',
        '730': 'Traducteur', '770': 'Photographe', '400': 'Préfacier',
        '590': 'Narrateur', '650': 'Éditeur scientifique',
      };
      final rolesFields = datafields.where((d) => d.tag == '702').toList();
      final roles = rolesFields.map((f) {
        final nom = f.subs['a'] ?? '';
        final prenom = f.subs['b'] ?? '';
        final code = f.subs['4'] ?? '';
        final name = prenom.isNotEmpty ? '$prenom $nom' : nom;
        final role = roleNames[code] ?? (code.isNotEmpty ? 'Rôle $code' : '');
        return name.isNotEmpty ? (role.isNotEmpty ? '$name ($role)' : name) : '';
      }).where((s) => s.isNotEmpty).join(', ');

      return {
        'title': title,
        'authors': authors,
        'publisher': publisher,
        'year': year,
        'pages': pages,
        'collection': collection.isNotEmpty ? collection : null,
        'description': description.isNotEmpty ? description : null,
        'categories': categories.isNotEmpty ? categories : null,
        'genre': genre.isNotEmpty ? genre : null,
        'lieu': lieu.isNotEmpty ? lieu : null,
        'titreOriginal': titreOriginal.isNotEmpty ? titreOriginal : null,
        'dewey': dewey.isNotEmpty ? dewey : null,
        'roles': roles.isNotEmpty ? roles : null,
      };
    } catch (_) {
      return null;
    }
  }

  // ── Open Library ──
  static Future<Map<String, dynamic>?> _fetchOpenLibrary(String isbn) async {
    try {
      final results = await Future.wait([
        _fetchWithTimeout(
          'https://openlibrary.org/api/books?bibkeys=ISBN:$isbn&format=json&jscmd=data',
          timeout: const Duration(seconds: 7),
        ),
        _fetchWithTimeout(
          'https://openlibrary.org/search.json?isbn=$isbn&limit=1',
          timeout: const Duration(seconds: 7),
        ),
      ]);

      final data = <String, dynamic>{};
      String? workKey;

      // Edition data
      if (results[0] != null) {
        try {
          final json = jsonDecode(results[0]!);
          final key = 'ISBN:$isbn';
          if (json[key] != null) {
            final b = json[key];
            data['title'] = b['title'] ?? '';
            data['authors'] = (b['authors'] as List?)?.map((a) => a['name']).join(', ') ?? '';
            data['publisher'] = (b['publishers'] as List?)?.map((p) => p['name']).join(', ') ?? '';
            data['year'] = b['publish_date']?.toString() ?? '';
            data['pages'] = (b['number_of_pages'] ?? '').toString();
            if (b['cover'] != null) {
              data['cover'] = (b['cover']['medium'] ?? b['cover']['small'] ?? '').toString().replaceAll('http://', 'https://');
            }
            if (b['subjects'] != null) {
              data['categories'] = (b['subjects'] as List)
                  .take(6)
                  .map((s) => s is String ? s : s['name'])
                  .where((s) => s != null)
                  .join(', ');
            }
            if (b['works'] != null && (b['works'] as List).isNotEmpty) {
              workKey = b['works'][0]['key'];
            }
          }
        } catch (_) {}
      }

      // Search data
      if (results[1] != null) {
        try {
          final json = jsonDecode(results[1]!);
          if (json['docs'] != null && (json['docs'] as List).isNotEmpty) {
            final d = json['docs'][0];
            if (_empty(data['title'])) data['title'] = d['title'] ?? '';
            if (_empty(data['authors'])) data['authors'] = (d['author_name'] as List?)?.join(', ') ?? '';
            if (_empty(data['publisher'])) {
              final pub = d['publisher'];
              data['publisher'] = pub is List ? (pub.isNotEmpty ? pub[0] : '') : (pub ?? '');
            }
            if (_empty(data['year'])) data['year'] = (d['first_publish_year'] ?? '').toString();
            final coverId = d['cover_i'];
            if (_empty(data['cover']) && coverId != null && coverId > 0) {
              data['cover'] = 'https://covers.openlibrary.org/b/id/$coverId-M.jpg';
            }
            workKey ??= d['key'];
          }
        } catch (_) {}
      }

      // Work data for description
      if (workKey != null && (_empty(data['description']) || _empty(data['categories']))) {
        final workRaw = await _fetchWithTimeout(
          'https://openlibrary.org$workKey.json',
          timeout: const Duration(seconds: 6),
        );
        if (workRaw != null) {
          try {
            final wd = jsonDecode(workRaw);
            if (_empty(data['categories']) && wd['subjects'] != null) {
              data['categories'] = (wd['subjects'] as List)
                  .where((s) => s.toString().length < 40)
                  .take(6)
                  .join(', ');
            }
            if (_empty(data['description']) && wd['description'] != null) {
              data['description'] = wd['description'] is String
                  ? wd['description']
                  : (wd['description']['value'] ?? '');
            }
          } catch (_) {}
        }
      }

      return data.isEmpty ? null : data;
    } catch (_) {
      return null;
    }
  }

  static String _decodeXmlEntities(String s) {
    return s
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&apos;', "'");
  }
}

class _Datafield {
  final String tag;
  final Map<String, String> subs;
  _Datafield(this.tag, this.subs);
}
