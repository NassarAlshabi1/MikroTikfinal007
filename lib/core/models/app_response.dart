class AppResponse<T> {
  final bool status;
  final String message;
  final T? data;
  AppResponse({required this.status, required this.message, this.data});
}



