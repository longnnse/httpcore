import 'package:core_http/core/base_model/base_respone.dart';
import 'package:core_http/core/error_handling/error_object.dart';
import 'package:core_http/core/error_handling/exceptions.dart';
import 'package:core_http/core/error_handling/failures.dart';
import 'package:core_http/core_http.dart';
import 'package:dartz/dartz.dart';
import 'package:example/respository/user_profile.dart';

abstract class Repository {
  // Future<Either<ErrorObject, List<UserProfile>>> fetchPosts();
  Future<Either<ErrorObject, UserProfile>> fetchPost();
}

class RepositoryImp implements Repository {
  final CoreHttp _coreHttp = CoreHttpImplement(appName: 'appName');

  @override
  Future<Either<ErrorObject, UserProfile>> fetchPost() async {
    try {
      const _url = 'https://mocki.io/v1/6193ff21-6a2f-4b40-b431-508bb8109df6';
      var _data = await _coreHttp.get(_url);
      if (_data != null) {
        final _value = BaseObjectResponse<UserProfile>.fromJson(_data, (map) => UserProfile.fromJson(map));
        return Right(_value.data!);
      }
      return Left(ErrorObject.mapFailureToErrorObject(failure: const DataFailFailure()));
    } on ServerException {
      return Left(ErrorObject.mapFailureToErrorObject(failure: const ServerFailure()));
    } on NoConnectionException {
      return Left(ErrorObject.mapFailureToErrorObject(failure: const NoConnectionFailure()));
    } catch (e) {
      return Left(ErrorObject.mapFailureToErrorObject(failure: const DataFailFailure()));
    }
  }

  // @override
  // Future<Either<FailureEntity, List<UserProfile>>> fetchPosts() async {
  //   try {
  //     const _url = 'https://mocki.io/v1/d5d2e6d6-ef23-43d7-a881-c76b4ba9b5e6';
  //     var _data = await _coreHttp.get(_url);
  //     if (_data != null) {
  //       final _value = BaseListResponse<UserProfile>.fromJson(_data, (map) => UserProfile.fromJson(map));
  //       return Right(_value.data!);
  //     }
  //     return const Left(DataParsingFailure());
  //   } on ServerException {
  //     return const Left(ServerFailure());
  //   } on NoConnectionException {
  //     return const Left(NoConnectionFailure());
  //   }
  // }
}
