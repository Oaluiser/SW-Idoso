import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'mock_data.dart';
import 'models.dart';

/// Estado do protótipo, persistido no localStorage do navegador.
class AppState extends ChangeNotifier {
  AppState(this._prefs, {Map<String, Map<String, dynamic>>? realSummaries})
    : _real = realSummaries ?? const {} {
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

  /// Resumos reais de ligações, publicados com o site:
  /// `{"yyyy-MM-dd": {json do resumo}}`.
  static const realSummariesAsset = 'assets/summaries/real.json';

  static Future<AppState> load() async {
    final prefs = await SharedPreferences.getInstance();
    return AppState(prefs, realSummaries: await _loadRealSummaries());
  }

  static Future<Map<String, Map<String, dynamic>>> _loadRealSummaries() async {
    try {
      final raw = await rootBundle.loadString(realSummariesAsset);
      return (jsonDecode(raw) as Map<String, dynamic>).map(
        (k, v) => MapEntry(k, v as Map<String, dynamic>),
      );
    } on Object {
      return const {};
    }
  }

  final SharedPreferences _prefs;
  final Map<String, Map<String, dynamic>> _real;
  Profile? _profile;
  Map<String, String> _recados = {};

  Profile? get profile => _profile;

  /// Modo exemplo: mostra 60 dias de histórico simulado, com os resumos
  /// reais no lugar dos simulados nos dias em que existirem. Fora dele o
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

  /// Resumo real do dia, com a data do calendário e o recado da família.
  Map<String, dynamic>? realSummaryJson(DateTime day) {
    final src = _real[dateKey(day)];
    if (src == null) return null;
    final j = Map<String, dynamic>.of(src);
    j['data_ligacao'] = DateFormat('dd/MM/yyyy').format(day);
    final recado = j['recado'];
    final texto = recadoFor(day);
    if (recado is Map<String, dynamic> && texto != null) {
      j['recado'] = {...recado, 'texto': recado['texto'] ?? texto};
    }
    return j;
  }

  /// Só há resumos no modo exemplo; neles, o real tem prioridade sobre o
  /// simulado do mesmo dia.
  CallSummary? summaryFor(DateTime day) {
    final p = _profile;
    if (p == null || !_demo) return null;
    final real = realSummaryJson(day);
    if (real != null) {
      try {
        return CallSummary.fromJson(real);
      } on Object {
        // JSON inválido não pode derrubar o calendário.
      }
    }
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
