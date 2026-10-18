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
  final List<int> questionIds;
  final String notes;

  static const minQuestions = 2;
  static const maxQuestions = 5;

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

  factory Recado.fromJson(Map<String, dynamic> j) =>
      Recado(texto: j['texto'] as String, resposta: j['resposta'] as String?);
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
  });

  final String idoso;
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
      data: _br.parseStrict(j['data_ligacao'] as String),
      status: CallStatus.parse(j['status'] as String?),
      titulo: j['titulo'] as String? ?? '',
      resumoFamilia: j['resumo_familia'] as String? ?? '',
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
      recado: j['recado'] == null
          ? null
          : Recado.fromJson(j['recado'] as Map<String, dynamic>),
      solicitacoes: list('solicitacoes', (e) => e as String),
      respostasPerguntas: list(
        'respostas_perguntas',
        (e) => QuestionAnswer.fromJson(e as Map<String, dynamic>),
      ),
      whatsappEnviado: j['whatsapp_enviado'] as String?,
    );
  }
}

String dateKey(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);
