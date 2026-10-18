import 'dart:convert';

import 'package:alo_diario/mock_data.dart';
import 'package:alo_diario/models.dart';
import 'package:alo_diario/state.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _profile = Profile(
  elderName: 'Maria Aparecida',
  familyName: 'Ana Souza',
  familyEmail: 'ana@exemplo.com',
  familyPhone: '(11) 98765-4321',
  elderPhone: '(11) 3456-7890',
  callHour: 10,
  callMinute: 0,
  callDays: [1, 2, 3, 4, 5, 6, 7],
  questionIds: [0, 2, 8],
  notes: '',
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final now = DateTime(2026, 10, 17, 15);

  test('parseia o JSON de exemplo do backend', () {
    final s = CallSummary.fromJson({
      'idoso': 'Jorge',
      'data_ligacao': '17/10/2026',
      'status': 'verde',
      'titulo': 'Almoço em família e visita às filhas',
      'resumo_familia': 'Jorge relatou que almoçou com os filhos.',
      'sinais': [
        {
          'categoria': 'alimentacao',
          'descricao': 'Relatou ter almoçado com os filhos.',
          'evidencia': 'Hoje eu almocei com os meus dois filhos',
          'confianca': 10,
        },
      ],
      'humor_geral': 6,
      'engajamento': 'alto',
      'mudancas_vs_historico': ['Sem histórico.'],
      'pauta_proxima_ligacao': ['Como foi a visita às suas filhas?'],
    });
    expect(s.data, DateTime(2026, 10, 17));
    expect(s.status, CallStatus.verde);
    expect(s.sinais.single.categoriaLabel, 'Alimentação');
    expect(s.alertas, isEmpty);
    expect(s.tentativas, isEmpty);
  });

  test('histórico simulado cobre todas as situações', () {
    final statuses = <CallStatus>{};
    var retry = false, recado = false, pedido = false;
    for (var i = 0; i <= MockData.historyDays; i++) {
      final s = MockData.summaryFor(
        _profile,
        now.subtract(Duration(days: i)),
        now,
      )!;
      statuses.add(s.status);
      retry |= s.atendida && s.tentativas.length > 1;
      recado |= s.recado?.resposta != null;
      pedido |= s.solicitacoes.isNotEmpty;
      if (s.atendida) {
        expect(s.respostasPerguntas.length, _profile.questionIds.length);
      }
    }
    expect(statuses, CallStatus.values.toSet());
    expect(retry && recado && pedido, isTrue);
  });

  test('futuro e hoje antes do horário não têm resumo', () {
    final morning = DateTime(2026, 10, 17, 9);
    expect(MockData.summaryFor(_profile, morning, morning), isNull);
    expect(MockData.summaryFor(_profile, DateTime(2026, 10, 18), now), isNull);
    expect(MockData.summaryFor(_profile, now, now), isNotNull);
  });

  test('recado da família aparece com resposta no dia', () {
    final day = DateTime(2026, 10, 16);
    final s = MockData.summaryFor(
      _profile,
      day,
      now,
      userRecado: 'Te amo, mãe!',
    )!;
    expect(s.recado!.texto, 'Te amo, mãe!');
    expect(s.recado!.resposta, isNotNull);
  });

  test('calendário começa vazio; modo exemplo mostra o histórico', () async {
    SharedPreferences.setMockInitialValues({});
    final state = await AppState.load();
    await state.saveProfile(_profile);
    final yesterday = DateTime.now().subtract(const Duration(days: 1));

    expect(state.demo, isFalse);
    expect(state.summaryFor(yesterday), isNull);
    expect(state.historyStart, dateOnly(DateTime.now()));

    await state.setDemo(true);
    expect(state.summaryFor(yesterday), isNotNull);
    expect(state.historyStart.isBefore(dateOnly(DateTime.now())), isTrue);

    await state.reset();
    expect(state.demo, isFalse);
  });

  test('rótulos dos dias da semana', () {
    expect(weekdaysLabel([1, 2, 3, 4, 5, 6, 7]), 'Todos os dias');
    expect(weekdaysLabel([1, 2, 3, 4, 5]), 'De segunda a sexta');
    expect(weekdaysLabel([6, 7]), 'Sábado e domingo');
    expect(weekdaysLabel([1, 3, 5]), 'Seg, qua e sex');
    expect(weekdaysLabel([2]), 'Toda terça');
    expect(weekdaysLabel([6]), 'Todo sábado');
  });

  test('só há ligação nos dias escolhidos', () {
    final p = _profile.copyWith(callDays: [1, 3, 5]);
    for (var i = 1; i <= 14; i++) {
      final day = now.subtract(Duration(days: i));
      final s = MockData.summaryFor(p, day, now);
      expect(s != null, p.callsOn(day), reason: '$day');
    }
  });

  test('cadastro antigo sem callDays liga todos os dias', () {
    final j = _profile.toJson()..remove('callDays');
    expect(Profile.fromJson(j).callDays, [1, 2, 3, 4, 5, 6, 7]);
  });

  test('lê o JSON novo do backend (resumo real)', () {
    final s = CallSummary.fromJson({
      'idoso': 'Jorge',
      'tratamento': 'Seu Jorge',
      'data_ligacao': '18/10/2026',
      'duracao_min': null,
      'status': 'verde',
      'titulo': 'Almoço com os filhos',
      'resumo': 'Jorge almoçou com os filhos.',
      'sinais': [],
      'humor_geral': 8,
      'engajamento': 'alto',
      'sono': {'status': 'nao_mencionado', 'detalhe': ''},
      'medicacao': {'status': 'nao_mencionado', 'detalhe': ''},
      'recado': {'havia_recado': false, 'entregue': false, 'resposta': ''},
      'pedidos': [],
      'assuntos': ['Xavante'],
      'mudancas_vs_historico': ['Primeiro registro.'],
      'pauta_proxima_ligacao': ['Como foi o jogo?'],
    });
    expect(s.resumoFamilia, 'Jorge almoçou com os filhos.');
    expect(s.tratamento, 'Seu Jorge');
    expect(s.recado, isNull);
    expect(s.assuntos, ['Xavante']);
    expect(s.sono!.mencionado, isFalse);
    expect(s.duracaoMin, isNull);
  });

  test('resumo real só no exemplo, no lugar do simulado do dia', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final today = dateOnly(DateTime.now());
    final state = AppState(
      prefs,
      realSummaries: {
        dateKey(today): {
          'idoso': 'Jorge',
          'status': 'verde',
          'titulo': 'Almoço com os filhos',
          'resumo': 'Texto',
        },
      },
    );
    await state.saveProfile(_profile);

    // Logo após o cadastro: calendário vazio, inclusive hoje.
    expect(state.summaryFor(today), isNull);

    await state.setDemo(true);
    final s = state.summaryFor(today)!;
    expect(s.titulo, 'Almoço com os filhos');
    expect(s.data, today);
    // Os outros dias seguem simulados.
    expect(
      state.summaryFor(today.subtract(const Duration(days: 1)))!.titulo,
      isNot('Almoço com os filhos'),
    );
  });

  test('asset publicado tem o resumo do Jorge em 18/10', () async {
    final raw = await rootBundle.loadString(AppState.realSummariesAsset);
    final all = jsonDecode(raw) as Map<String, dynamic>;
    final s = CallSummary.fromJson(all['2026-10-18'] as Map<String, dynamic>);
    expect(s.idoso, 'Jorge');
    expect(s.status, CallStatus.verde);
    expect(s.assuntos, contains('Xavante'));
  });
}
