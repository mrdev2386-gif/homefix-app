
enum ResultStatus { loading, success, empty, error }

class ServiceResult<T> {
  final T? data;
  final ResultStatus status;
  final String? errorMessage;

  ServiceResult._({
    this.data,
    required this.status,
    this.errorMessage,
  });

  factory ServiceResult.loading() => ServiceResult._(status: ResultStatus.loading);
  
  factory ServiceResult.success(T data) {
    if (data is List && data.isEmpty) {
      return ServiceResult._(status: ResultStatus.empty);
    }
    return ServiceResult._(data: data, status: ResultStatus.success);
  }

  factory ServiceResult.empty() => ServiceResult._(status: ResultStatus.empty);

  factory ServiceResult.error(String message) => ServiceResult._(
        status: ResultStatus.error,
        errorMessage: message,
      );

  bool get isLoading => status == ResultStatus.loading;
  bool get isSuccess => status == ResultStatus.success;
  bool get isEmpty => status == ResultStatus.empty;
  bool get isError => status == ResultStatus.error;
}
