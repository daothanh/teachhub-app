import 'package:teachhub_shared/teachhub_shared.dart';

/// Lỗi gọi TeachHub API dưới dạng [ApiException] (spec §5.6); xem [ApiException.fromDio].
ApiException? apiException(Object? error) => ApiException.fromDio(error);
