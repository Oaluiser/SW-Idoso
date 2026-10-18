import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'mock_data.dart';
import 'models.dart';

/// Estado do protótipo, persistido no localStorage do navegador.
class AppState extends ChangeNotifier {
  AppState(this._prefs) {
    final raw = _prefs.getString(_kProfile);
    if (raw != null) {
      try {
        _profile = Profile.fromJson(jsonDecode(raw) as Map<String, dynamic>);
      } on Object {
        _prefs.remove(_kProfile);
      }
    }
    final rec = _prefs.getString(_kRecados);
    if (rec != null) {
      try {
        _recados = (jsonDecode(rec) as Map<String, dynamic>).cast();
      } on Object {
        _prefs.remove(_kRecados);
      }
    }
    _demo = _prefs.getBool(_kDemo) ?? false;
  }

  static const _kProfile = 'profile';
  static const _kRecados = 'recados';
  static const _kDemo = 'demo';

  static Future<AppState> load() async =>
      AppState(await SharedPreferences.getInstance());

  final SharedPreferences _prefs;
  Profile? _profile;
  Map<String, String> _recados = {};

  Profile? get profile => _profile;

  /// Modo exemplo: mostra 60 dias de histórico simulado. Fora dele o
  /// calendário começa vazio, como será no uso real.
  bool _demo = false;
  bool get demo => _demo;

  Future<void> setDemo(bool value) async {
    _demo = value;
    await _prefs.setBool(_kDemo, value);
    notifyListeners();
  }

  /// Primeiro dia com ligações: hoje no uso real, 60 dias atrás no exemplo.
  DateTime get historyStart {
    final today = dateOnly(now);
    return _demo
        ? today.subtract(const Duration(days: MockData.historyDays))
        : today;
  }

  // Mostra a mensagem de boas-vindas uma única vez, logo após o cadastro.
  bool _welcome = false;
  void markWelcome() => _welcome = true;
  bool consumeWelcome() {
    final w = _welcome;
    _welcome = false;
    return w;
  }

  DateTime get now => DateTime.now();

  Future<void> saveProfile(Profile p) async {
    _profile = p;
    await _prefs.setString(_kProfile, jsonEncode(p.toJson()));
    notifyListeners();
  }

  String? recadoFor(DateTime day) => _recados[dateKey(day)];

  Future<void> setRecado(DateTime day, String? texto) async {
    final k = dateKey(day);
    if (texto == null || texto.trim().isEmpty) {
      _recados.remove(k);
    } else {
      _recados[k] = texto.trim();
    }
    await _prefs.setString(_kRecados, jsonEncode(_recados));
    notifyListeners();
  }

  CallSummary? summaryFor(DateTime day) {
    final p = _profile;
    if (p == null || !_demo) return null;
    return MockData.summaryFor(p, day, now, userRecado: recadoFor(day));
  }

  Future<void> reset() async {
    _profile = null;
    _recados = {};
    _demo = false;
    await _prefs.remove(_kDemo);
    await _prefs.remove(_kProfile);
    await _prefs.remove(_kRecados);
    notifyListeners();
  }
}
