/// Result type for proper error handling
/// Replaces silent failures with structured error propagation
sealed class Result<T> {
  const Result();

  /// Success result with data
  factory Result.success(T data) => Success(data);

  /// Error result with exception
  factory Result.error(Exception error) => Error(error);

  /// Empty result (no data, no error)
  factory Result.empty() => Empty();

  /// Map result to another type
  Result<U> map<U>(U Function(T) transform) {
    return switch (this) {
      Success(data: final data) => Result.success(transform(data)),
      Error(error: final error) => Result.error(error),
      Empty() => Result.empty(),
    };
  }

  /// Get data or null
  T? getOrNull() {
    return switch (this) {
      Success(data: final data) => data,
      _ => null,
    };
  }

  /// Get error or null
  Exception? getErrorOrNull() {
    return switch (this) {
      Error(error: final error) => error,
      _ => null,
    };
  }

  /// Check if result is success
  bool get isSuccess => this is Success;

  /// Check if result is error
  bool get isError => this is Error;

  /// Check if result is empty
  bool get isEmpty => this is Empty;
}

/// Success result
final class Success<T> extends Result<T> {
  final T data;
  const Success(this.data);
}

/// Error result
final class Error<T> extends Result<T> {
  final Exception error;
  const Error(this.error);
}

/// Empty result
final class Empty<T> extends Result<T> {
  const Empty();
}
