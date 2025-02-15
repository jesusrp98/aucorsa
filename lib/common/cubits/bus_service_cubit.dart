import 'package:aucorsa/common/models/bus_stop_line_estimation.dart';
import 'package:aucorsa/common/utils/http_client.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';

class BusServiceCubit extends HydratedCubit<String?> {
  static final cookieRegex = RegExp('"ajax_nonce":"([a-z0-9]+)"');

  BusServiceCubit() : super(null);

  /// Save the 'nonce' cookie from the website, which is present in plain text
  /// in the HTML of the index page.
  ///
  /// This cookie is required to make requests to the API.
  Future<void> reloadCookie() async {
    final page = await httpClient.get<dynamic>('https://aucorsa.es/');

    final cookie = cookieRegex.firstMatch(page.data.toString())?.group(1);

    return emit(cookie);
  }

  /// Use the stored 'nonce' cookie to make a request to the API and get the
  /// estimated arrival times for a bus stop.
  Future<List<BusStopLineEstimation>> requestBusStopData(int stopId) async {
    if (state == null) await reloadCookie();

    final response = await httpClient.get<dynamic>(
      'https://aucorsa.es/wp-json/aucorsa/v1/estimations/stop?stop_id=$stopId&_wpnonce=$state',
    );

    // Invalidate the cookie and retry
    if (response.statusCode == 403) {
      emit(null);
      return requestBusStopData(stopId);
    }

    return BusStopLineEstimation.fromHtml(response.data.toString());
  }

  @override
  String? fromJson(Map<String, dynamic> json) => json['cookie'] as String;

  @override
  Map<String, dynamic>? toJson(String? state) => {'cookie': state};
}
