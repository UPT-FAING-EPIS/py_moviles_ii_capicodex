sealed class UiState<T> {
  const UiState();
}

class Loading<T> extends UiState<T> {
  const Loading();
}

class Success<T> extends UiState<T> {
  final T data;
  const Success(this.data);
}

class Empty<T> extends UiState<T> {
  const Empty();
}

class ErrorState<T> extends UiState<T> {
  final String message;
  final Future<void> Function() retry;

  const ErrorState(this.message, this.retry);
}
