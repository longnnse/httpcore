import 'package:equatable/equatable.dart';

import 'failures.dart';

class ErrorObject extends Equatable {
  const ErrorObject({
    required this.title,
    required this.message,
  });

  final String title;
  final String message;

  @override
  List<Object?> get props => [title, message];

  /// Again, here I leverage the power of sealed_classes to write robust code and
  /// make sure to map evey and each failure with a specific message to show in
  /// the UI.
  static ErrorObject mapFailureToErrorObject({required FailureEntity failure, String? title, String? mess}) {
    return failure.when(
      serverFailure: () => ErrorObject(
        title: title ?? 'Thông báo',
        message: mess ?? 'Kết nối máy chủ không thành công',
      ),
      dataParsingFailure: () => ErrorObject(
        title: title ?? 'Thông báo',
        message: mess ?? 'Phân tích dữ liệu không thành công',
      ),
      noConnectionFailure: () => ErrorObject(
        title: title ?? 'Thông báo',
        message: mess ?? 'Kết nối internet thất bại',
      ),
      dataFailFailure: () => ErrorObject(
        title: title ?? 'Thông báo',
        message: mess ?? 'Dữ liệu không đúng',
      ),
    );
  }
}
