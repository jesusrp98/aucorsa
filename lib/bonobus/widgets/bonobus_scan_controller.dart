import 'dart:async';
import 'dart:typed_data';

import 'package:aucorsa/bonobus/cubits/bonobus_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:intl/intl.dart';
import 'package:nfc_manager/nfc_manager.dart';
import 'package:nfc_manager/nfc_manager_android.dart';

class BonobusScanController extends StatefulWidget {
  final ValueSetter<BonobusState>? onStateChanged;

  const BonobusScanController({super.key, this.onStateChanged});

  @override
  State<BonobusScanController> createState() => _BonobusScanControllerState();
}

class _BonobusScanControllerState extends State<BonobusScanController> {
  @override
  void initState() {
    super.initState();

    unawaited(_startNfcScan());
  }

  @override
  void dispose() {
    unawaited(NfcManager.instance.stopSession());

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }

  Future<void> _startNfcScan() => NfcManager.instance.startSession(
    pollingOptions: NfcPollingOption.values.toSet(),
    onDiscovered: (tag) async {
      String? id;
      String? balance;

      final mifareData = MifareClassicAndroid.from(tag);

      id = _resolveId(mifareData?.tag.id);

      if (mifareData != null) {
        final success = await mifareData.authenticateSectorWithKeyA(
          sectorIndex: int.parse(dotenv.env['CONSORCIO_AUTH_SECTOR_INDEX']!),
          key: _decodeAuthKeyA(dotenv.env['CONSORCIO_AUTH_KEY_A']!),
        );

        if (success) {
          final blockData = await mifareData.readBlock(
            blockIndex: int.parse(dotenv.env['CONSORCIO_READ_BLOCK_INDEX']!),
          );
          if (!mounted) return;

          balance = _resolveBalance(blockData);
        }
      }

      if (widget.onStateChanged != null) {
        return widget.onStateChanged?.call(
          BonobusState(
            id: id,
            balance: balance,
          ),
        );
      }

      if (!mounted) return;

      return context.read<BonobusCubit>().loaded(
        balance: balance,
      );
    },
  );

  String? _resolveId(Uint8List? uidBytes) {
    if (uidBytes == null || uidBytes.isEmpty) return null;

    if (uidBytes.length < 4) {
      var n = BigInt.zero;
      for (final b in uidBytes) {
        n = (n << 8) | BigInt.from(b);
      }

      return n.toString();
    }

    return ByteData.sublistView(
      uidBytes,
      0,
      4,
    ).getUint32(0, Endian.little).toString().padLeft(10, '0');
  }

  String _resolveBalance(List<int> input) {
    final str = input.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    final swapped = str.substring(2, 4) + str.substring(0, 2);
    final value = int.parse(swapped, radix: 16);
    final amount = value / 2.0 / 100.0;

    return '${NumberFormat('#0.00').format(amount)} €';
  }

  Uint8List _decodeAuthKeyA(String hex) {
    final cleaned = hex.replaceAll(RegExp('[^0-9a-fA-F]'), '');
    final result = Uint8List(cleaned.length ~/ 2);
    for (var i = 0; i < cleaned.length; i += 2) {
      result[i ~/ 2] = int.parse(cleaned.substring(i, i + 2), radix: 16);
    }

    return result;
  }
}
