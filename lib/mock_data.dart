import 'dart:math';

import 'package:intl/intl.dart';

import 'models.dart';

/// Gera resumos simulados no mesmo formato JSON que o backend vai devolver.
/// Os dados são determinísticos por data, relativos a "hoje", e usam o nome,
/// o horário e as perguntas do cadastro.
abstract final class MockData {
  /// Quantos dias de histórico simulado existem antes de hoje.
  static const historyDays = 60;

  /// Minutos após o horário agendado até o resumo ficar disponível.
  static const summaryDelayMin = 30;

  static CallSummary? summaryFor(
    Profile p,
    DateTime day,
    DateTime now, {
    String? userRecado,
  }) {
    final json = summaryJson(p, day, now, userRecado: userRecado);
    return json == null ? null : CallSummary.fromJson(json);
  }

  /// Hoje, antes do horário da ligação (+ tempo de gerar o resumo).
  static bool isPendingToday(Profile p, DateTime day, DateTime now) {
    if (dateOnly(day) != dateOnly(now) || !p.callsOn(day)) return false;
    final ready = DateTime(
      now.year,
      now.month,
      now.day,
      p.callHour,
      p.callMinute,
    ).add(const Duration(minutes: summaryDelayMin));
    return now.isBefore(ready);
  }

  static Map<String, dynamic>? summaryJson(
    Profile p,
    DateTime day,
    DateTime now, {
    String? userRecado,
  }) {
    final d = dateOnly(day);
    final offset = dateOnly(now).difference(d).inDays;
    if (offset < 0 || offset > historyDays) return null;
    // Só há ligação nos dias da semana escolhidos pela família.
    if (!p.callsOn(d)) return null;
    if (offset == 0 && isPendingToday(p, d, now)) return null;

    final rnd = Random(d.year * 10000 + d.month * 100 + d.day);
    final scenario =
        _scripted[offset] ?? _normalDays[rnd.nextInt(_normalDays.length)];
    final n = p.elderFirstName;
    final fmt = DateFormat('dd/MM/yyyy');
    final hm = DateFormat('HH:mm');

    // Tentativas: no horário, +10 min e +20 min.
    final base = DateTime(d.year, d.month, d.day, p.callHour, p.callMinute);
    final answeredAt = scenario.answeredAttempt; // 0 = nenhuma atendida
    final attemptCount = answeredAt == 0 ? 3 : answeredAt;
    final tentativas = [
      for (var i = 0; i < attemptCount; i++)
        {
          'horario': hm.format(base.add(Duration(minutes: 10 * i))),
          'atendida': i + 1 == answeredAt,
        },
    ];
    final duracao = 6 + rnd.nextInt(13);
    final fim = base.add(Duration(minutes: 10 * (attemptCount - 1) + duracao));
    final whatsapp = hm.format(fim.add(const Duration(minutes: 2)));

    // Recado: o que a família deixou no calendário tem prioridade.
    Map<String, dynamic>? recado;
    final recadoTexto = userRecado ?? scenario.recado?.$1;
    if (recadoTexto != null) {
      recado = {
        'texto': recadoTexto,
        'resposta': answeredAt == 0
            ? null
            : userRecado != null
            ? '$n ficou feliz com o recado e respondeu: '
                  '"Que bom receber notícias! Manda um beijo pra todo mundo."'
            : scenario.recado!.$2.replaceAll('{n}', n),
      };
    }

    if (answeredAt == 0) {
      return {
        'idoso': n,
        'data_ligacao': fmt.format(d),
        'status': 'sem_ligacao',
        'titulo': 'Ligação não atendida',
        'resumo_familia':
            'Fizemos 3 tentativas no horário combinado e $n não atendeu. '
            'Vale a pena entrar em contato ou pedir para alguém próximo '
            'verificar se está tudo bem.',
        'sinais': const [],
        'mudancas_vs_historico': const [],
        'pauta_proxima_ligacao': const [
          'Perguntar como foi o dia anterior e se estava fora de casa.',
        ],
        'tentativas': tentativas,
        'recado': recado,
        'whatsapp_enviado': whatsapp,
      };
    }

    // Respostas das perguntas escolhidas pela família.
    final respostas = [
      for (final q in p.questionIds)
        {
          'pergunta': kQuestions[q],
          'resposta':
              (scenario.bad[q] ?? _normal[q]![rnd.nextInt(_normal[q]!.length)])
                  .resposta
                  .replaceAll('{n}', n),
        },
    ];

    // Pontos de atenção aparecem mesmo que a pergunta não tenha sido
    // escolhida: a IA capta isso na conversa casual.
    final sinais = [
      for (final e in scenario.bad.entries)
        {
          'categoria': _categoria[e.key],
          'descricao': e.value.descricao!.replaceAll('{n}', n),
          'evidencia': e.value.fala,
          'confianca': 8 + rnd.nextInt(3),
          'alerta': true,
        },
      for (final s in scenario.positivos)
        {
          'categoria': s.categoria,
          'descricao': s.descricao.replaceAll('{n}', n),
          'evidencia': s.fala,
          'confianca': 9 + rnd.nextInt(2),
          'alerta': false,
        },
    ];

    final (lo, hi) = scenario.humor;
    final mudancas = offset == historyDays
        ? ['Primeira ligação: ainda não há histórico para comparação.']
        : scenario.mudancas.map((m) => m.replaceAll('{n}', n)).toList();

    // Pauta: o que o cenário sugere + uma pergunta escolhida pela família.
    final pauta = [
      ...scenario.pauta,
      if (p.questionIds.isNotEmpty)
        kQuestions[p.questionIds[rnd.nextInt(p.questionIds.length)]],
    ];

    return {
      'idoso': n,
      'data_ligacao': fmt.format(d),
      'status': scenario.status,
      'titulo': scenario.titulo,
      'resumo_familia': scenario.resumo.replaceAll('{n}', n),
      'sinais': sinais,
      'humor_geral': lo + rnd.nextInt(hi - lo + 1),
      'engajamento': scenario.engajamento,
      'mudancas_vs_historico': mudancas,
      'pauta_proxima_ligacao': pauta,
      'tentativas': tentativas,
      'duracao_min': duracao,
      'recado': recado,
      'solicitacoes': scenario.solicitacoes
          .map((s) => s.replaceAll('{n}', n))
          .toList(),
      'respostas_perguntas': respostas,
      'whatsapp_enviado': whatsapp,
    };
  }
}

class _A {
  const _A(this.resposta, this.fala, [this.descricao]);
  final String resposta;
  final String fala;
  final String? descricao;
}

class _Positive {
  const _Positive(this.categoria, this.descricao, this.fala);
  final String categoria;
  final String descricao;
  final String fala;
}

class _Scenario {
  const _Scenario({
    required this.status,
    this.titulo = '',
    this.resumo = '',
    this.bad = const {},
    this.positivos = const [],
    this.humor = (6, 9),
    this.engajamento = 'alto',
    this.solicitacoes = const [],
    this.answeredAttempt = 1,
    this.recado,
    this.mudancas = const ['Humor e disposição estáveis em relação à semana.'],
    this.pauta = const [],
  });

  final String status;
  final String titulo;
  final String resumo;
  final Map<int, _A> bad;
  final List<_Positive> positivos;
  final (int, int) humor;
  final String engajamento;
  final List<String> solicitacoes;
  final int answeredAttempt;

  /// (texto do recado da família, resposta do idoso)
  final (String, String)? recado;
  final List<String> mudancas;
  final List<String> pauta;
}

const _categoria = {
  0: 'humor',
  1: 'sono',
  2: 'medicacao',
  3: 'saude',
  4: 'alimentacao',
  5: 'autonomia',
  6: 'mobilidade',
  7: 'isolamento',
  8: 'seguranca',
  9: 'familia',
};

/// Respostas "normais" por pergunta.
const _normal = <int, List<_A>>{
  0: [
    _A(
      'Disse que está bem e com disposição.',
      'Tô bem, graças a Deus, com disposição hoje.',
    ),
    _A(
      'Respondeu que o dia está ótimo e que acordou de bom humor.',
      'Hoje o dia tá ótimo, acordei de bom humor.',
    ),
    _A(
      'Está bem, só com o cansaço de sempre.',
      'Tô bem, só aquele cansacinho de sempre.',
    ),
  ],
  1: [
    _A(
      'Dormiu bem e acordou por volta das 7h.',
      'Dormi bem, acordei umas sete horas.',
    ),
    _A('Dormiu a noite toda sem acordar.', 'Dormi a noite inteirinha.'),
  ],
  2: [
    _A(
      'Sim, tomou os remédios da manhã no horário.',
      'Tomei sim, logo depois do café.',
    ),
    _A(
      'Tomou todos, usando a caixinha organizadora.',
      'Tomei, a caixinha tava certinha.',
    ),
  ],
  3: [
    _A('Nenhuma dor hoje.', 'Não, hoje não tô sentindo nada.'),
    _A(
      'Só as pernas um pouco cansadas, nada que incomode.',
      'Só as pernas um pouco cansadas, mas nada demais.',
    ),
  ],
  4: [
    _A(
      'Almoçou arroz, feijão, frango e salada.',
      'Fiz arroz, feijão e um franguinho com salada.',
    ),
    _A(
      'Tomou um café reforçado e vai fazer sopa no jantar.',
      'Tomei um café caprichado e de noite vou fazer uma sopa.',
    ),
  ],
  5: [_A('Não precisou de ajuda hoje.', 'Não, hoje dei conta de tudo.')],
  6: [
    _A(
      'Foi à padaria e caminhou um pouco na praça.',
      'Fui na padaria e dei uma volta na praça.',
    ),
    _A(
      'Ficou em casa cuidando das plantas, como de costume.',
      'Fiquei em casa mexendo nas minhas plantas.',
    ),
  ],
  7: [
    _A(
      'Conversou com a vizinha no portão.',
      'Fiquei conversando com a vizinha no portão.',
    ),
    _A(
      'Falou com amigos da igreja por telefone.',
      'O pessoal da igreja me ligou.',
    ),
  ],
  8: [_A('Não recebeu nenhuma ligação estranha.', 'Não, nada de estranho.')],
  9: [
    _A(
      'Mandou um beijo e disse que está com saudade.',
      'Fala que mandei um beijo e que tô com saudade.',
    ),
    _A(
      'Pediu para avisar que fez o bolo de laranja que a família gosta.',
      'Avisa que fiz aquele bolo de laranja, viu?',
    ),
  ],
};

/// Dias comuns, sorteados (de forma fixa por data) para preencher o histórico.
const _normalDays = [
  _Scenario(
    status: 'verde',
    titulo: 'Manhã de feira e almoço caprichado',
    resumo:
        '{n} contou que foi à feira cedo, escolheu frutas e preparou um '
        'almoço caprichado. A conversa foi leve, com várias risadas ao lembrar '
        'de histórias antigas. Nenhuma queixa de saúde.',
    positivos: [
      _Positive(
        'alimentacao',
        'Relatou boa alimentação e preparo do próprio almoço.',
        'Comprei mamão e banana na feira e fiz um almoço gostoso.',
      ),
    ],
    pauta: ['Perguntar quais frutas comprou e se vai voltar à feira.'],
  ),
  _Scenario(
    status: 'verde',
    titulo: 'Dia tranquilo cuidando das plantas',
    resumo:
        '{n} passou a manhã cuidando das plantas e contou que a roseira '
        'floresceu. Falou com calma, sem relatar problemas, e disse que à '
        'tarde vai assistir à novela.',
    positivos: [
      _Positive(
        'mobilidade',
        'Manteve a rotina de atividades em casa.',
        'A roseira deu flor, fiquei a manhã toda no jardim.',
      ),
    ],
    pauta: ['Perguntar sobre a roseira e o que achou da novela.'],
  ),
  _Scenario(
    status: 'verde',
    titulo: 'Caminhada na praça com a vizinha',
    resumo:
        '{n} caminhou na praça com a vizinha e depois tomaram um café na '
        'padaria. Mostrou bom humor e disposição durante toda a conversa.',
    positivos: [
      _Positive(
        'isolamento',
        'Teve contato social presencial com a vizinha.',
        'Fui caminhar com a Célia e depois tomamos um cafezinho.',
      ),
      _Positive(
        'mobilidade',
        'Fez atividade física leve.',
        'Demos duas voltas na praça.',
      ),
    ],
    humor: (7, 9),
    pauta: ['Perguntar se a caminhada com a vizinha virou rotina.'],
  ),
  _Scenario(
    status: 'verde',
    titulo: 'Tarde de crochê e novela',
    resumo:
        '{n} está terminando um tapete de crochê e passou a tarde '
        'assistindo novela. Comentou com empolgação sobre o capítulo de '
        'ontem. Dia tranquilo, sem queixas.',
    positivos: [
      _Positive(
        'humor',
        'Demonstrou empolgação com um passatempo.',
        'Tô quase terminando o tapete, ficou bonito demais.',
      ),
    ],
    pauta: ['Perguntar se terminou o tapete de crochê.'],
  ),
  _Scenario(
    status: 'verde',
    titulo: 'Missa e almoço com amigos',
    resumo:
        '{n} foi à missa pela manhã e almoçou com um casal de amigos da '
        'paróquia. Contou que se divertiu e que combinaram de repetir no '
        'próximo domingo.',
    positivos: [
      _Positive(
        'isolamento',
        'Relatou almoço com amigos e ida à missa.',
        'Depois da missa fomos almoçar, foi muito bom.',
      ),
    ],
    humor: (7, 9),
    pauta: ['Perguntar como foi o almoço com os amigos da paróquia.'],
  ),
  _Scenario(
    status: 'verde',
    titulo: 'Bolo de laranja e conversa com a irmã',
    resumo:
        '{n} fez bolo de laranja e passou um bom tempo ao telefone com a '
        'irmã. A conversa foi animada e não houve relatos de saúde ou '
        'dificuldades.',
    positivos: [
      _Positive(
        'isolamento',
        'Conversou por telefone com a irmã.',
        'Fiquei quase uma hora no telefone com minha irmã.',
      ),
      _Positive(
        'alimentacao',
        'Preparou alimentos em casa.',
        'Fiz um bolo de laranja pra tomar com café.',
      ),
    ],
    pauta: ['Perguntar como está a irmã.'],
  ),
];

/// Cenários fixos por "dias atrás", garantindo que todas as situações
/// apareçam no calendário recente.
const _scripted = <int, _Scenario>{
  0: _Scenario(
    status: 'verde',
    titulo: 'Bom humor e almoço com a vizinha',
    resumo:
        '{n} atendeu de primeira e estava de ótimo humor. Contou que a '
        'vizinha veio almoçar e trouxe um doce de abóbora. Disse que dormiu '
        'bem e que está tudo em ordem em casa.',
    positivos: [
      _Positive(
        'isolamento',
        'Recebeu visita da vizinha para o almoço.',
        'A Célia veio almoçar comigo e trouxe doce de abóbora.',
      ),
      _Positive(
        'alimentacao',
        'Relatou refeição completa.',
        'Fiz arroz, feijão e uma carne de panela.',
      ),
    ],
    humor: (8, 9),
    mudancas: ['Humor melhor do que a média da última semana.'],
    pauta: ['Perguntar se a dor no joelho melhorou com a pomada.'],
  ),
  1: _Scenario(
    status: 'amarelo',
    titulo: 'Dor no joelho ao subir escadas',
    resumo:
        '{n} conversou bem, mas reclamou de dor no joelho direito ao '
        'subir a escada de casa. Disse que não houve queda e que a dor começou '
        'há dois dias. Pediu para alguém comprar a pomada que costuma usar.',
    bad: {
      3: _A(
        'Reclamou de dor no joelho direito ao subir escadas.',
        'O joelho direito tá doendo quando subo a escada, faz uns dois dias.',
        'Relatou dor no joelho direito há dois dias, sem queda.',
      ),
    },
    positivos: [
      _Positive(
        'alimentacao',
        'Manteve a alimentação normal.',
        'Almocei direitinho, fiz uma sopa de legumes.',
      ),
    ],
    humor: (5, 6),
    engajamento: 'medio',
    solicitacoes: ['Comprar a pomada de arnica na farmácia.'],
    mudancas: [
      'Primeira menção a dor no joelho nas últimas semanas.',
      'Humor um pouco abaixo da média.',
    ],
    pauta: ['Perguntar se a dor no joelho melhorou.'],
  ),
  2: _Scenario(
    status: 'verde',
    titulo: 'Recado recebido com alegria',
    resumo:
        '{n} ficou muito contente com o recado sobre o almoço de domingo '
        'e já está pensando no cardápio. Conversa animada e sem nenhuma '
        'queixa.',
    positivos: [
      _Positive(
        'humor',
        'Reagiu com alegria ao recado da família.',
        'Ai que notícia boa, vou fazer lasanha!',
      ),
    ],
    humor: (8, 10),
    recado: (
      'Domingo vamos almoçar aí com as crianças!',
      '{n} ficou muito feliz e respondeu: "Vou fazer lasanha! Cheguem cedo."',
    ),
    pauta: ['Perguntar se precisa de algo para o almoço de domingo.'],
  ),
  3: _Scenario(status: 'sem_ligacao', answeredAttempt: 0),
  4: _Scenario(
    status: 'verde',
    titulo: 'Atendeu na terceira tentativa',
    resumo:
        '{n} só atendeu na terceira tentativa porque estava no quintal '
        'regando as plantas. Depois conversou normalmente e disse que está '
        'tudo bem.',
    positivos: [
      _Positive(
        'mobilidade',
        'Estava realizando atividades no quintal.',
        'Desculpa, tava lá no quintal molhando as plantas.',
      ),
    ],
    answeredAttempt: 3,
    pauta: ['Perguntar se ficou tudo bem após a ligação não atendida.'],
  ),
  5: _Scenario(
    status: 'vermelho',
    titulo: 'Ligação suspeita pedindo dados do cartão',
    resumo:
        '{n} contou que recebeu uma ligação de alguém dizendo ser do '
        'banco e pedindo a senha do cartão para "cancelar uma compra". Disse '
        'que não passou a senha, mas a conversa mostrou nervosismo. '
        'Recomendamos conversar sobre golpes e verificar a conta.',
    bad: {
      8: _A(
        'Recebeu ligação de alguém se passando pelo banco pedindo a senha do cartão. Não passou os dados.',
        'Ligaram dizendo que era do banco e queriam a senha do cartão pra cancelar uma compra.',
        'Relatou tentativa de golpe por telefone pedindo senha bancária.',
      ),
    },
    humor: (3, 5),
    engajamento: 'medio',
    solicitacoes: ['Ajuda para verificar se houve alguma compra no cartão.'],
    mudancas: ['Primeiro relato de abordagem suspeita.'],
    pauta: [
      'Perguntar se recebeu novas ligações do "banco".',
      'Reforçar que o banco nunca pede senha por telefone.',
    ],
  ),
  6: _Scenario(
    status: 'verde',
    titulo: 'Tapete de crochê quase pronto',
    resumo:
        '{n} passou a tarde no crochê e assistindo novela. Contou que '
        'está quase terminando um tapete para presentear a família.',
    positivos: [
      _Positive(
        'humor',
        'Demonstrou empolgação com um passatempo.',
        'Esse tapete é presente, hein, não conta pra ninguém!',
      ),
    ],
  ),
  7: _Scenario(
    status: 'verde',
    titulo: 'Pedido de visita no fim de semana',
    resumo:
        '{n} estava bem e a conversa foi animada. Comentou que sente '
        'saudade e perguntou se alguém da família pode fazer uma visita no fim '
        'de semana para um almoço.',
    positivos: [
      _Positive(
        'isolamento',
        'Expressou vontade de ver a família.',
        'Tô com saudade, bem que alguém podia vir almoçar aqui no domingo.',
      ),
    ],
    humor: (7, 8),
    solicitacoes: ['Gostaria de uma visita no domingo para almoçar.'],
    pauta: ['Confirmar se a visita de domingo foi combinada.'],
  ),
  8: _Scenario(
    status: 'amarelo',
    titulo: 'Esqueceu o remédio da pressão',
    resumo:
        '{n} atendeu na segunda tentativa. Durante a conversa percebeu '
        'que esqueceu de tomar o remédio da pressão pela manhã e disse que '
        'tomaria em seguida. Fora isso, o dia foi tranquilo.',
    bad: {
      2: _A(
        'Esqueceu de tomar o remédio da pressão pela manhã.',
        'Ih, esqueci o da pressão hoje cedo! Vou tomar agora.',
        'Esqueceu a medicação da manhã (pressão).',
      ),
    },
    humor: (6, 7),
    answeredAttempt: 2,
    mudancas: ['Segundo esquecimento de medicação no mês.'],
    pauta: ['Perguntar se tomou o remédio da pressão hoje.'],
  ),
  10: _Scenario(
    status: 'amarelo',
    titulo: 'Dia mais triste e noite mal dormida',
    resumo:
        'A voz de {n} estava mais baixa hoje. Contou que não dormiu bem '
        'e que passou os últimos dias sem conversar com ninguém desde '
        'domingo. A conversa ajudou a melhorar o ânimo no final.',
    bad: {
      0: _A(
        'Disse que está com tristeza e saudade de todos.',
        'Hoje bateu uma tristeza, uma saudade de todo mundo.',
        'Relatou tristeza e saudade.',
      ),
      1: _A(
        'Acordou várias vezes durante a noite.',
        'Acordei umas quatro vezes, não consegui dormir direito.',
        'Noite mal dormida, acordou várias vezes.',
      ),
      7: _A(
        'Não conversou com ninguém desde domingo.',
        'Desde domingo não falo com ninguém, só com você agora.',
        'Sem contato social há alguns dias.',
      ),
    },
    humor: (3, 4),
    engajamento: 'baixo',
    mudancas: [
      'Humor bem abaixo da média das últimas semanas.',
      'Primeiro relato de isolamento no mês.',
    ],
    pauta: [
      'Perguntar como está o ânimo e o sono.',
      'Sugerir uma atividade com a vizinha ou a igreja.',
    ],
  ),
  12: _Scenario(
    status: 'verde',
    titulo: 'Lembrete da consulta entregue',
    resumo:
        '{n} recebeu o lembrete da consulta e confirmou presença. Contou '
        'que o dia foi tranquilo e que almoçou bem.',
    positivos: [
      _Positive(
        'saude',
        'Confirmou presença na consulta médica.',
        'Pode deixar, já anotei no calendário da cozinha.',
      ),
    ],
    recado: (
      'Lembrete: consulta com a cardiologista na quinta às 14h.',
      '{n} confirmou: "Já anotei, pode deixar. Quem vai me levar?"',
    ),
    solicitacoes: ['Saber quem vai levar à consulta de quinta.'],
  ),
  13: _Scenario(
    status: 'amarelo',
    titulo: 'Pouco apetite durante o dia',
    resumo:
        '{n} disse que está sem fome e que só tomou café com bolacha até '
        'o meio da tarde. Não relatou dor, mas a conversa mostrou pouca '
        'energia.',
    bad: {
      4: _A(
        'Disse que está sem fome e só tomou café com bolacha.',
        'Tô sem fome hoje, só tomei um cafezinho com bolacha.',
        'Alimentação reduzida no dia.',
      ),
    },
    humor: (5, 6),
    engajamento: 'medio',
    pauta: ['Perguntar o que comeu no almoço e no jantar.'],
  ),
  15: _Scenario(status: 'sem_ligacao', answeredAttempt: 0),
  16: _Scenario(
    status: 'amarelo',
    titulo: 'Precisa de ajuda com a lâmpada da cozinha',
    resumo:
        '{n} contou que a lâmpada da cozinha queimou e tentou subir numa '
        'cadeira para trocar, mas desistiu. Está tudo bem, mas pediu ajuda '
        'para resolver.',
    bad: {
      5: _A(
        'Precisou de ajuda para trocar a lâmpada da cozinha e não conseguiu.',
        'A lâmpada da cozinha queimou, subi na cadeira mas fiquei com medo.',
        'Tentou subir em cadeira para trocar lâmpada (risco de queda).',
      ),
    },
    humor: (6, 7),
    solicitacoes: ['Alguém para trocar a lâmpada da cozinha.'],
    pauta: ['Perguntar se a lâmpada da cozinha já foi trocada.'],
  ),
  20: _Scenario(
    status: 'vermelho',
    titulo: 'Escorregou no banheiro',
    resumo:
        '{n} contou que escorregou no banheiro pela manhã e bateu o '
        'braço. Disse que conseguiu se levantar sem ajuda e que ficou um '
        'hematoma, mas sem dor forte. Recomendamos verificar pessoalmente e '
        'avaliar um tapete antiderrapante.',
    bad: {
      3: _A(
        'Escorregou no banheiro e bateu o braço. Ficou um hematoma.',
        'Escorreguei no banheiro e bati o braço, ficou roxo.',
        'Relatou queda no banheiro com hematoma no braço.',
      ),
    },
    humor: (4, 5),
    engajamento: 'medio',
    solicitacoes: ['Comprar um tapete antiderrapante para o banheiro.'],
    mudancas: ['Primeiro relato de queda.'],
    pauta: [
      'Perguntar como está o braço.',
      'Perguntar se já tem tapete antiderrapante.',
    ],
  ),
  27: _Scenario(status: 'sem_ligacao', answeredAttempt: 0),
};
