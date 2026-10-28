/// Monadic Result type for clean, predictable error handling without exceptions.
sealed class Result<T> {
  const Result();

  bool get isSuccess => this is Success<T>;
  bool get isFailure => this is Failure<T>;

  T get data {
    if (this is Success<T>) {
      return (this as Success<T>).value;
    }
    throw StateError('Cannot call data on a Failure: ${(this as Failure<T>).message}');
  }

  T? get dataOrNull {
    if (this is Success<T>) {
      return (this as Success<T>).value;
    }
    return null;
  }

  String? get errorOrNull {
    if (this is Failure<T>) {
      return (this as Failure<T>).message;
    }
    return null;
  }

  String get error {
    if (this is Failure<T>) {
      return (this as Failure<T>).message;
    }
    throw StateError('Cannot call error on a Success');
  }

  R when<R>({
    required R Function(T data) success,
    required R Function(String message, dynamic error) failure,
  }) {
    if (this is Success<T>) {
      return success((this as Success<T>).value);
    } else {
      final f = this as Failure<T>;
      return failure(f.message, f.cause);
    }
  }
}

class Success<T> extends Result<T> {
  final T value;
  const Success(this.value);

  @override
  String toString() => 'Success($value)';
}

class Failure<T> extends Result<T> {
  final String message;
  final dynamic cause;
  const Failure(this.message, [this.cause]);

  @override
  String toString() => 'Failure($message, cause: $cause)';
}
