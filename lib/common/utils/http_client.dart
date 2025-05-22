import 'package:dio/dio.dart';

final httpClient = Dio()..options = BaseOptions(validateStatus: (_) => true);
