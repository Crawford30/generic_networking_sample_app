/// Base URL and paths for the backend. Keep every URL the app calls here so
/// switching environments or versions is a one-file change.
abstract final class ApiEndpoints {
  static const baseUrl = 'https://jsonplaceholder.typicode.com/';

  static const posts = 'posts';
  static String post(int id) => 'posts/$id';
  static String postComments(int id) => 'posts/$id/comments';
}
