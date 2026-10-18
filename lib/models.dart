import 'package:intl/intl.dart';

/// Perguntas que a família pode escolher (mín. 2, máx. 5). O índice é o id.
const kQuestions = [
  'Como você está se sentindo hoje?',
  'Dormiu bem esta noite?',
  'Tomou seus medicamentos hoje?',
  'Está sentindo alguma dor ou desconforto?',
  'Conseguiu se alimentar normalmente hoje?',
  'Precisou de ajuda para alguma coisa hoje?',
  'Saiu de casa ou realizou suas atividades normalmente?',
  'Recebeu alguma visita ou conversou com alguém hoje?',
  'Recebeu alguma ligação, mensagem ou abordagem suspeita recentemente?',
  'Gostaria de deixar algum recado para sua família?',
];

/// Dados do cadastro (onboarding / configurações).
class Profile {
  const Profile({
    required this.elderName,
    required this.familyName,
    required this.familyEmail,
    required this.familyPhone,
    required this.elderPhone,
    required this.callHour,
    required this.callMinute,
    required this.callDays,
    required this.questionIds,
    required this.notes,
  });

  final String elderName;
  final String familyName;
  final String familyEmail;
  final String familyPhone;
  final String elderPhone;
  final int callHour;
  final int callMinute;

  /// Dias da semana com ligação, no padrão `DateTime.weekday`
  /// (1 = segunda … 7 = domingo). De 1 a 7 dias.
  final List<int> callDays;
  final List<int> questionIds;
  final String notes;

  static const minQuestions = 2;
  static const maxQuestions = 5;

  bool callsOn(DateTime d) => callDays.contains(d.weekday);

  /// "Todos os dias", "De segunda a sexta", "Seg, qua e sex"…
  String get callDaysLabel => weekdaysLabel(callDays);

  String get callTimeLabel =>
      '${callHour.toString().padLeft(2, '0')}:${callMinute.toString().padLeft(2, '0')}';

  String get elderFirstName => elderName.trim().split(' ').first;
  String get familyFirstName => familyName.trim().split(' ').first;

  Profile copyWith({
    String? elderName,
    String? familyName,
    String? familyEmail,
    String? familyPhone,
    String? elderPhone,
    int? callHour,
    int? callMinute,
    List<int>? callDays,
    List<int>? questionIds,
    String? notes,
  }) => Profile(
    elderName: elderName ?? this.elderName,
    familyName: familyName ?? this.familyName,
    familyEmail: familyEmail ?? this.familyEmail,
    familyPhone: familyPhone ?? this.familyPhone,
    elderPhone: elderPhone ?? this.elderPhone,
    callHour: callHour ?? this.callHour,
    callMinute: callMinute ?? this.callMinute,
    callDays: callDays ?? this.callDays,
    questionIds: questionIds ?? this.questionIds,
    notes: notes ?? this.notes,
  );

  Map<String, dynamic> toJson() => {
    'elderName': elderName,
    'familyName': familyName,
    'familyEmail': familyEmail,
    'familyPhone': familyPhone,
    'elderPhone': elderPhone,
    'callHour': callHour,
    'callMinute': callMinute,
    'callDays': callDays,
    'questionIds': questionIds,
    'notes': notes,
  };

  factory Profile.fromJson(Map<String, dynamic> j) => Profile(
    elderName: j['elderName'] as String,
    familyName: j['familyName'] as String,
    familyEmail: j['familyEmail'] as String,
    familyPhone: j['familyPhone'] as String,
    elderPhone: j['elderPhone'] as String,
    callHour: j['callHour'] as int,
    callMinute: j['callMinute'] as int,
    // Cadastros antigos (antes da escolha de dias) ligavam todos os dias.
    callDays: ((j['callDays'] as List?) ?? const [1, 2, 3, 4, 5, 6, 7])
        .cast<int>(),
    questionIds: (j['questionIds'] as List).cast<int>(),
    notes: j['notes'] as String? ?? '',
  );
}

/// Cor de status vinda da análise da ligação.
/// `semLigacao` é usado quando nenhuma das 3 tentativas foi atendida.
enum CallStatus {
  verde,
  amarelo,
  vermelho,
  semLigacao;

  static CallStatus parse(String? s) => switch (s) {
    'verde' => verde,
    'amarelo' => amarelo,
    'vermelho' => vermelho,
    _ => semLigacao,
  };

  String get label => switch (this) {
    verde => 'Tudo bem',
    amarelo => 'Atenção',
    vermelho => 'Atenção urgente',
    semLigacao => 'Não atendeu',
  };
}

class Signal {
  const Signal({
    required this.categoria,
    required this.descricao,
    required this.evidencia,
    required this.confianca,
    required this.alerta,
  });

  final String categoria;
  final String descricao;
  final String evidencia;
  final int confianca;

  /// Extensão ao contrato: indica se o sinal é um ponto de atenção.
  final bool alerta;

  factory Signal.fromJson(Map<String, dynamic> j) => Signal(
    categoria: j['categoria'] as String,
    descricao: j['descricao'] as String,
    evidencia: j['evidencia'] as String? ?? '',
    confianca: (j['confianca'] as num?)?.toInt() ?? 0,
    alerta: j['alerta'] as bool? ?? false,
  );

  static const _labels = {
    'alimentacao': 'Alimentação',
    'isolamento': 'Convívio social',
    'humor': 'Humor',
    'sono': 'Sono',
    'medicacao': 'Medicação',
    'saude': 'Saúde e dor',
    'mobilidade': 'Atividades',
    'seguranca': 'Segurança',
    'autonomia': 'Autonomia',
  };

  String get categoriaLabel =>
      _labels[categoria] ??
      (categoria.isEmpty
          ? ''
          : categoria[0].toUpperCase() + categoria.substring(1));
}

class Attempt {
  const Attempt({required this.horario, required this.atendida});
  final String horario;
  final bool atendida;

  factory Attempt.fromJson(Map<String, dynamic> j) =>
      Attempt(horario: j['horario'] as String, atendida: j['atendida'] as bool);
}

class Recado {
  const Recado({required this.texto, this.resposta});
  final String texto;
  final String? resposta;

  /// Aceita `{texto, resposta}` (mock) e `{havia_recado, entregue, resposta}`
  /// (backend). Retorna `null` quando não havia recado.
  static Recado? tryParse(Map<String, dynamic>? j) {
    if (j == null) return null;
    if (j.containsKey('havia_recado')) {
      if (j['havia_recado'] != true) return null;
      final resp = (j['resposta'] as String?)?.trim();
      return Recado(
        texto: (j['texto'] as String?) ?? '',
        resposta: j['entregue'] == true && resp != null && resp.isNotEmpty
            ? resp
            : null,
      );
    }
    return Recado(
      texto: j['texto'] as String? ?? '',
      resposta: j['resposta'] as String?,
    );
  }
}

/// Item de saúde citado (ou não) na conversa, ex.: sono e medicação.
class HealthNote {
  const HealthNote({required this.status, required this.detalhe});
  final String status;
  final String detalhe;

  bool get mencionado => status != 'nao_mencionado' && status.isNotEmpty;

  static HealthNote? tryParse(Object? j) {
    if (j is! Map<String, dynamic>) return null;
    return HealthNote(
      status: j['status'] as String? ?? '',
      detalhe: j['detalhe'] as String? ?? '',
    );
  }

  String get statusLabel => switch (status) {
    'nao_mencionado' => 'Não foi mencionado na conversa',
    'bom' || 'ok' || 'em_dia' => 'Tudo certo',
    'ruim' || 'atrasado' || 'esqueceu' => 'Atenção',
    _ => status.replaceAll('_', ' '),
  };
}

class QuestionAnswer {
  const QuestionAnswer({required this.pergunta, required this.resposta});
  final String pergunta;
  final String resposta;

  factory QuestionAnswer.fromJson(Map<String, dynamic> j) => QuestionAnswer(
    pergunta: j['pergunta'] as String,
    resposta: j['resposta'] as String,
  );
}

/// Resumo de um dia no calendário. Segue o JSON do backend
/// (idoso, data_ligacao, status, titulo, resumo_familia, sinais, humor_geral,
/// engajamento, mudancas_vs_historico, pauta_proxima_ligacao) mais os campos
/// opcionais tentativas, duracao_min, recado, solicitacoes, respostas_perguntas
/// e whatsapp_enviado.
class CallSummary {
  const CallSummary({
    required this.idoso,
    this.tratamento,
    required this.data,
    required this.status,
    required this.titulo,
    required this.resumoFamilia,
    required this.sinais,
    required this.humorGeral,
    required this.engajamento,
    required this.mudancasVsHistorico,
    required this.pautaProximaLigacao,
    required this.tentativas,
    required this.duracaoMin,
    required this.recado,
    required this.solicitacoes,
    required this.respostasPerguntas,
    required this.whatsappEnviado,
    this.assuntos = const [],
    this.sono,
    this.medicacao,
  });

  final String idoso;

  /// Como chamar o idoso, ex.: "Seu Jorge".
  final String? tratamento;
  final List<String> assuntos;
  final HealthNote? sono;
  final HealthNote? medicacao;
  final DateTime data;
  final CallStatus status;
  final String titulo;
  final String resumoFamilia;
  final List<Signal> sinais;
  final int? humorGeral;
  final String? engajamento;
  final List<String> mudancasVsHistorico;
  final List<String> pautaProximaLigacao;
  final List<Attempt> tentativas;
  final int? duracaoMin;
  final Recado? recado;
  final List<String> solicitacoes;
  final List<QuestionAnswer> respostasPerguntas;
  final String? whatsappEnviado;

  bool get atendida => status != CallStatus.semLigacao;
  List<Signal> get alertas => sinais.where((s) => s.alerta).toList();
  bool get precisaAtencao =>
      status == CallStatus.amarelo || status == CallStatus.vermelho;

  static final _br = DateFormat('dd/MM/yyyy');

  factory CallSummary.fromJson(Map<String, dynamic> j) {
    List<T> list<T>(String k, T Function(dynamic) f) =>
        ((j[k] as List?) ?? const []).map(f).toList();
    return CallSummary(
      idoso: j['idoso'] as String,
      tratamento: j['tratamento'] as String?,
      data: _br.parseStrict(j['data_ligacao'] as String),
      status: CallStatus.parse(j['status'] as String?),
      titulo: j['titulo'] as String? ?? '',
      resumoFamilia:
          j['resumo'] as String? ?? j['resumo_familia'] as String? ?? '',
      sinais: list('sinais', (e) => Signal.fromJson(e as Map<String, dynamic>)),
      humorGeral: (j['humor_geral'] as num?)?.toInt(),
      engajamento: j['engajamento'] as String?,
      mudancasVsHistorico: list('mudancas_vs_historico', (e) => e as String),
      pautaProximaLigacao: list('pauta_proxima_ligacao', (e) => e as String),
      tentativas: list(
        'tentativas',
        (e) => Attempt.fromJson(e as Map<String, dynamic>),
      ),
      duracaoMin: (j['duracao_min'] as num?)?.toInt(),
      recado: Recado.tryParse(j['recado'] as Map<String, dynamic>?),
      solicitacoes: j.containsKey('pedidos')
          ? list('pedidos', (e) => e as String)
          : list('solicitacoes', (e) => e as String),
      respostasPerguntas: list(
        'respostas_perguntas',
        (e) => QuestionAnswer.fromJson(e as Map<String, dynamic>),
      ),
      whatsappEnviado: j['whatsapp_enviado'] as String?,
      assuntos: list('assuntos', (e) => e as String),
      sono: HealthNote.tryParse(j['sono']),
      medicacao: HealthNote.tryParse(j['medicacao']),
    );
  }
}

String dateKey(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

/// Abreviações na ordem de exibição (domingo primeiro, como no calendário).
const kWeekdayOrder = [7, 1, 2, 3, 4, 5, 6];
const kWeekdayShort = {
  1: 'seg',
  2: 'ter',
  3: 'qua',
  4: 'qui',
  5: 'sex',
  6: 'sáb',
  7: 'dom',
};
const kWeekdayLong = {
  1: 'segunda',
  2: 'terça',
  3: 'quarta',
  4: 'quinta',
  5: 'sexta',
  6: 'sábado',
  7: 'domingo',
};

String weekdaysLabel(Iterable<int> days) {
  final set = days.toSet();
  if (set.isEmpty) return 'Nenhum dia';
  if (set.length == 7) return 'Todos os dias';
  if (set.length == 5 && !set.contains(6) && !set.contains(7)) {
    return 'De segunda a sexta';
  }
  if (set.length == 2 && set.contains(6) && set.contains(7)) {
    return 'Sábado e domingo';
  }
  final names = [
    for (final d in [1, 2, 3, 4, 5, 6, 7])
      if (set.contains(d)) kWeekdayShort[d]!,
  ];
  if (names.length == 1) {
    final d = set.first;
    // "Toda segunda" / "Todo sábado".
    return '${d >= 6 ? 'Todo' : 'Toda'} ${kWeekdayLong[d]!}';
  }
  final last = names.removeLast();
  final text = '${names.join(', ')} e $last';
  return text[0].toUpperCase() + text.substring(1);
}
