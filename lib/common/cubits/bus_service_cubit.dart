import 'package:aucorsa/common/models/bus_stop_line_estimation.dart';
import 'package:aucorsa/common/utils/http_client.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';

class BusServiceCubit extends HydratedCubit<String?> {
  static const _estimationsUrl =
      'https://lightapi.aucorsa.es/wp-json/aucorsa/v1/estimations/stop';
  static final nonceRegex = RegExp(r'"ajax_nonce"\s*:\s*"([^"]+)"');

  BusServiceCubit() : super(null);

  /// Save the nonce from the website, which is present in plain text in the
  /// HTML of the index page.
  ///
  /// This nonce is required to make requests to the API.
  Future<void> reloadNonce() async {
    final page = await httpClient.get<dynamic>('https://aucorsa.es/');

    final nonce = nonceRegex.firstMatch(page.data.toString())?.group(1);
    if (nonce == null) {
      throw StateError('Could not retrieve the AUCORSA API nonce');
    }

    emit(nonce);
  }

  /// Use the stored nonce to make a request to the API and get the estimated
  /// arrival times for a bus stop.
  Future<List<BusStopLineEstimation>> requestBusStopData(int stopId) =>
      _requestBusStopData(stopId, canRetry: true);

  Future<List<BusStopLineEstimation>> _requestBusStopData(
    int stopId, {
    required bool canRetry,
  }) async {
    if (state == null) await reloadNonce();

    final response = await httpClient.get<dynamic>(
      _estimationsUrl,
      queryParameters: {'stop_id': stopId, '_wpnonce': state},
    );

    // Refresh an expired nonce once. A bounded retry prevents an endless loop
    // when the service is unavailable or rejects the client for another reason.
    if (response.statusCode == 403 && canRetry) {
      emit(null);
      return _requestBusStopData(stopId, canRetry: false);
    }

    if (response.statusCode != 200) {
      throw StateError(
        'AUCORSA estimations request failed (${response.statusCode})',
      );
    }

    final data = response.data;
    if (data is! String) {
      throw StateError('AUCORSA returned an unexpected estimations response');
    }

    return BusStopLineEstimation.fromHtml(data);
  }

  @override
  String? fromJson(Map<String, dynamic> json) => json['cookie'] as String?;

  @override
  Map<String, dynamic>? toJson(String? state) => {'cookie': state};
}
