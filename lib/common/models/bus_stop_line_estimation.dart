import 'package:aucorsa/common/utils/bus_line_utils.dart';
import 'package:html/parser.dart';

class BusStopLineEstimation implements Comparable<BusStopLineEstimation> {
  static final estimationTimeRegExp = RegExp('^([0-9]*)');

  final String lineId;
  final List<Duration> estimations;

  const BusStopLineEstimation({
    required this.lineId,
    required this.estimations,
  });

  /// Parse the HTML response from the API
  /// and return a list of [BusStopLineEstimation].
  ///
  /// This implementation is directly tied to the HTML file returned by the API.
  static List<BusStopLineEstimation> fromHtml(String rawDocument) {
    final containers = parse(rawDocument).querySelectorAll('.ppp-container');

    final estimationList = <BusStopLineEstimation>[];

    for (final container in containers) {
      final line = container.querySelector('.ppp-line-number')!.text;
      final estimations = container.querySelectorAll('.ppp-estimation');

      estimationList.add(
        BusStopLineEstimation(
          lineId: line,
          estimations: [
            for (final estimation in estimations)
              _parseDuration(estimation.querySelector('strong')!.text),
          ],
        ),
      );
    }

    return estimationList..sort();
  }

  static Duration _parseDuration(String data) {
    final parsedMinutes = int.tryParse(
      estimationTimeRegExp.firstMatch(data)!.group(1)!,
    );

    if (parsedMinutes != null) {
      return Duration(minutes: parsedMinutes);
    }

    return Duration.zero;
  }

  @override
  int compareTo(BusStopLineEstimation other) => BusLineUtils.getLineIndex(
    lineId,
  ).compareTo(BusLineUtils.getLineIndex(other.lineId));
}
