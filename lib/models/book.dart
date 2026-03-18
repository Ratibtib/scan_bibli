class Book {
  String? id;
  String? userId;
  String? isbn;
  String title;
  String authors;
  String? publisher;
  String? year;
  String? pages;
  String? cover;
  String? categories;
  String? description;
  String? collection;
  String? genre;
  String? lieu;
  String? titreOriginal;
  String? dewey;
  String? roles;
  String status;
  String? rangement1;
  String? rangement2;
  String? cr;
  String? up;

  Book({
    this.id,
    this.userId,
    this.isbn,
    this.title = '',
    this.authors = '',
    this.publisher,
    this.year,
    this.pages,
    this.cover,
    this.categories,
    this.description,
    this.collection,
    this.genre,
    this.lieu,
    this.titreOriginal,
    this.dewey,
    this.roles,
    this.status = 'alire',
    this.rangement1,
    this.rangement2,
    this.cr,
    this.up,
  });

  factory Book.fromJson(Map<String, dynamic> json) {
    return Book(
      id: json['id']?.toString(),
      userId: json['user_id'],
      isbn: json['isbn'],
      title: json['title'] ?? '',
      authors: json['authors'] ?? '',
      publisher: json['publisher'],
      year: json['year'],
      pages: json['pages'],
      cover: json['cover'],
      categories: json['categories'],
      description: json['description'],
      collection: json['collection'],
      genre: json['genre'],
      lieu: json['lieu'],
      titreOriginal: json['titre_original'],
      dewey: json['dewey'],
      roles: json['roles'],
      status: json['status'] ?? 'alire',
      rangement1: json['rangement1'],
      rangement2: json['rangement2'],
      cr: json['cr'],
      up: json['up'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null && !id!.startsWith('tmp_')) 'id': id,
      'user_id': userId,
      'isbn': isbn,
      'title': title,
      'authors': authors,
      'publisher': publisher,
      'year': year,
      'pages': pages,
      'cover': cover,
      'categories': categories,
      'description': description,
      'collection': collection,
      'genre': genre,
      'lieu': lieu,
      'titre_original': titreOriginal,
      'dewey': dewey,
      'roles': roles,
      'status': status,
      'rangement1': rangement1,
      'rangement2': rangement2,
      'up': DateTime.now().toUtc().toIso8601String(),
    };
  }

  Map<String, dynamic> toInsertJson() {
    final json = toJson();
    json['cr'] = DateTime.now().toUtc().toIso8601String();
    return json;
  }

  static const statusLabels = {
    'alire': 'À lire',
    'encours': 'En cours',
    'lu': 'Lu',
    'prete': 'Prêté',
  };

  static const statusEmojis = {
    'alire': '📚',
    'encours': '📖',
    'lu': '✅',
    'prete': '🤝',
  };

  static const statusOrder = ['alire', 'encours', 'lu', 'prete'];

  String get statusLabel => statusLabels[status] ?? 'À lire';
  String get metaLine {
    final parts = <String>[];
    if (publisher != null && publisher!.isNotEmpty) parts.add(publisher!);
    if (year != null && year!.isNotEmpty) parts.add(year!);
    if (pages != null && pages!.isNotEmpty) parts.add('${pages} p.');
    return parts.join(' · ');
  }

  String get rangementLine {
    final parts = [rangement1, rangement2].where((e) => e != null && e.isNotEmpty).toList();
    return parts.isEmpty ? '' : '📦 ${parts.join(' / ')}';
  }
}
