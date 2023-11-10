class CustomError extends Error {
  final String message;

  CustomError(this.message);

  @override
  String toString() {
    return 'CustomError: $message';
  }
}
