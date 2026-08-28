import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'connectivity_state.dart';

class ConnectivityCubit extends Cubit<ConnectivityState> {
  final Connectivity _connectivity;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

  ConnectivityCubit({Connectivity? connectivity})
      : _connectivity = connectivity ?? Connectivity(),
        super(ConnectivityInitial()) {
    _monitorConnectivity();
  }

  void _monitorConnectivity() {
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen((List<ConnectivityResult> results) {
      _emitConnectivity(results);
    });
  }

  Future<void> checkConnectivity() async {
    try {
      final results = await _connectivity.checkConnectivity();
      _emitConnectivity(results);
    } catch (e) {
      emit(ConnectivityDisconnected());
    }
  }

  void _emitConnectivity(List<ConnectivityResult> results) {
    if (results.contains(ConnectivityResult.none) || results.isEmpty) {
      emit(ConnectivityDisconnected());
    } else {
      emit(ConnectivityConnected());
    }
  }

  @override
  Future<void> close() {
    _connectivitySubscription?.cancel();
    return super.close();
  }
}
