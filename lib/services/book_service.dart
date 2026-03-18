import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/book.dart';

class BookService {
  static SupabaseClient get _client => Supabase.instance.client;

  static Future<List<Book>> loadBooks(String userId) async {
    final response = await _client
        .from('books')
        .select()
        .eq('user_id', userId)
        .order('cr', ascending: false);
    return (response as List).map((j) => Book.fromJson(j)).toList();
  }

  static Future<Book?> saveBook(Book book, String userId) async {
    book.userId = userId;
    try {
      if (book.id != null && !book.id!.startsWith('tmp_')) {
        final row = book.toJson();
        row['id'] = book.id;
        final response = await _client
            .from('books')
            .upsert(row)
            .select()
            .single();
        return Book.fromJson(response);
      } else {
        final row = book.toInsertJson();
        final response = await _client
            .from('books')
            .insert(row)
            .select()
            .single();
        return Book.fromJson(response);
      }
    } catch (e) {
      return null;
    }
  }

  static Future<bool> deleteBook(String id, String userId) async {
    try {
      await _client
          .from('books')
          .delete()
          .eq('id', id)
          .eq('user_id', userId);
      return true;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> updateStatus(String id, String status, String userId) async {
    try {
      await _client
          .from('books')
          .update({
            'status': status,
            'up': DateTime.now().toUtc().toIso8601String(),
          })
          .eq('id', id)
          .eq('user_id', userId);
      return true;
    } catch (e) {
      return false;
    }
  }
}
