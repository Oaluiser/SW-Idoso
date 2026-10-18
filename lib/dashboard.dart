import 'dart:math';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'mock_data.dart';
import 'models.dart';
import 'onboarding.dart';
import 'state.dart';
import 'theme.dart';
import 'widgets.dart';

const _wideBreakpoint = 960.0;

String _cap(String s) => s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
String _longDate(DateTime d) =>
    _cap(DateFormat("EEEE, d 'de' MMMM", 'pt_BR').format(d));

String _relative(DateTime d, DateTime today) {
  final diff = dateOnly(today).difference(dateOnly(d)).inDays;
  if (diff == 0) return 'Hoje';
  if (diff == 1) return 'Ontem';
  if (diff == -1) return 'Amanhã';
  if (diff > 1 && diff < 7) return 'Há $diff dias';
  return DateFormat("d 'de' MMM", 'pt_BR').format(d);
}

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key, required this.state});
  final AppState state;

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late DateTime _month;

  AppState get state => widget.state;
  DateTime get today => dateOnly(state.now);
  DateTime get historyStart => state.historyStart;

  Future<void> _setDemo(bool value) async {
    await state.setDemo(value);
    if (mounted) setState(() => _month = DateTime(today.year, today.month));
  }

  @override
  void initState() {
    super.initState();
    _month = DateTime(today.year, today.month);
    if (state.consumeWelcome()) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final p = state.profile!;
        final when = nextCallDay == today ? 'hoje' : 'amanhã';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            duration: const Duration(seconds: 6),
            content: Text(
              'Tudo pronto! A próxima ligação para ${p.elderFirstName} é '
              '$when às ${p.callTimeLabel}.',
            ),
          ),
        );
      });
    }
  }

  /// Próximo dia com ligação ainda por acontecer.
  DateTime get nextCallDay =>
      MockData.isPendingToday(state.profile!, today, state.now)
      ? today
      : today.add(const Duration(days: 1));

  /// Resumo do dia e recado abrem sempre em outra tela, em qualquer tamanho.
  void _open(DateTime day) {
    setState(() => _month = DateTime(day.year, day.month));
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _DayPage(state: state, day: dateOnly(day)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: state,
      builder: (context, _) {
        if (state.profile == null) return const SizedBox.shrink();
        return LayoutBuilder(
          builder: (context, c) {
            final wide = c.maxWidth >= _wideBreakpoint;
            return Scaffold(
              backgroundColor: AppColors.neutral,
              body: SafeArea(
                child: Column(
                  children: [
                    _TopBar(state: state),
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.only(bottom: 48),
                        child: Constrained(
                          maxWidth: wide ? 1180 : 640,
                          child: _MainColumn(
                            state: state,
                            wide: wide,
                            month: _month,
                            nextCallDay: nextCallDay,
                            historyStart: historyStart,
                            onOpen: _open,
                            onMonth: (m) => setState(() => _month = m),
                            onDemo: _setDemo,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.state});
  final AppState state;

  @override
  Widget build(BuildContext context) {
    return Constrained(
      child: SizedBox(
        height: 64,
        child: Row(
          children: [
            const Wordmark(),
            const Spacer(),
            FilledButton.icon(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => SettingsScreen(state: state)),
              ),
              icon: const Icon(Icons.tune_rounded, size: 16),
              label: const Text('Configurações'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.onPrimary,
                textStyle: AppText.labelMd,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                minimumSize: const Size(0, 36),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MainColumn extends StatelessWidget {
  const _MainColumn({
    required this.state,
    required this.wide,
    required this.month,
    required this.nextCallDay,
    required this.historyStart,
    required this.onOpen,
    required this.onMonth,
    required this.onDemo,
  });

  final ValueChanged<bool> onDemo;
  final AppState state;
  final bool wide;
  final DateTime month;
  final DateTime nextCallDay;
  final DateTime historyStart;
  final ValueChanged<DateTime> onOpen;
  final ValueChanged<DateTime> onMonth;

  @override
  Widget build(BuildContext context) {
    final demo = state.demo;
    final overview = [
      if (demo) ...[
        _DemoBanner(onExit: () => onDemo(false)),
        const SizedBox(height: 16),
      ],
      _Hero(state: state, nextCallDay: nextCallDay, onOpen: onOpen),
      const SizedBox(height: 16),
      if (demo)
        _AttentionList(state: state, onOpen: onOpen)
      else
        _EmptyState(
          state: state,
          nextCallDay: nextCallDay,
          onShowExample: () => onDemo(true),
        ),
    ];
    final calendar = [
      MonthCalendar(
        state: state,
        month: month,
        selected: null,
        historyStart: historyStart,
        onSelect: onOpen,
        onMonth: onMonth,
      ),
      if (demo) ...[
        const SizedBox(height: 12),
        Text(
          'Exemplo: o histórico de ligações é simulado para demonstração.',
          textAlign: TextAlign.center,
          style: AppText.bodySm.copyWith(color: AppColors.onSurfaceMuted),
        ),
      ],
    ];
    if (wide) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: overview,
            ),
          ),
          const SizedBox(width: 24),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: calendar,
            ),
          ),
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [...overview, const SizedBox(height: 16), ...calendar],
    );
  }
}

/// Seção escura de abertura: saudação, próxima ligação e números recentes.
class _Hero extends StatelessWidget {
  const _Hero({
    required this.state,
    required this.nextCallDay,
    required this.onOpen,
  });
  final AppState state;
  final DateTime nextCallDay;
  final ValueChanged<DateTime> onOpen;

  @override
  Widget build(BuildContext context) {
    final p = state.profile!;
    final today = dateOnly(state.now);
    final isToday = nextCallDay == today;
    final recado = state.recadoFor(nextCallDay);

    var atendidas = 0, atencao = 0, perdidas = 0;
    for (var i = 0; i < 30; i++) {
      final s = state.summaryFor(today.subtract(Duration(days: i)));
      if (s == null) continue;
      if (s.atendida) atendidas++;
      if (s.precisaAtencao) atencao++;
      if (!s.atendida) perdidas++;
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(AppRadius.xl),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Olá, ${p.familyFirstName}',
            style: AppText.bodyLg.copyWith(color: AppColors.onPrimaryMuted),
          ),
          const SizedBox(height: 6),
          Text(
            'Como ${p.elderFirstName} está',
            style: AppText.headlineLg.copyWith(color: AppColors.onPrimary),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primaryRaised,
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(
                color: AppColors.secondary.withValues(alpha: 0.35),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.schedule_rounded,
                      size: 18,
                      color: AppColors.tertiary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Próxima ligação: ${isToday ? 'hoje' : 'amanhã'} '
                        'às ${p.callTimeLabel}',
                        style: AppText.labelMd.copyWith(
                          color: AppColors.onPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  recado == null
                      ? 'Quer que a gente passe algum recado nessa conversa?'
                      : 'Recado: "$recado"',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.bodyMd.copyWith(
                    color: AppColors.onPrimaryMuted,
                  ),
                ),
                const SizedBox(height: 12),
                PrimaryButton(
                  label: recado == null ? 'Deixar recado' : 'Editar recado',
                  icon: Icons.mail_outline_rounded,
                  onPressed: () => onOpen(nextCallDay),
                ),
              ],
            ),
          ),
          if (state.demo) ...[
            const SizedBox(height: 20),
            Text(
              'Últimos 30 dias',
              style: AppText.labelSm.copyWith(color: AppColors.onPrimaryMuted),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _Stat(value: '$atendidas', label: 'conversas'),
                _Stat(value: '$atencao', label: 'com atenção'),
                _Stat(value: '$perdidas', label: 'sem resposta'),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// Calendário ainda sem conversas (uso real logo após o cadastro).
class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.state,
    required this.nextCallDay,
    required this.onShowExample,
  });
  final AppState state;
  final DateTime nextCallDay;
  final VoidCallback onShowExample;

  @override
  Widget build(BuildContext context) {
    final p = state.profile!;
    final when = nextCallDay == dateOnly(state.now) ? 'hoje' : 'amanhã';
    return MintCard(
      gradient: true,
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
      child: Column(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: const BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.calendar_month_rounded,
              color: AppColors.tertiary,
              size: 26,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Ainda não há conversas',
            textAlign: TextAlign.center,
            style: AppText.headlineMd.copyWith(color: AppColors.onSurface),
          ),
          const SizedBox(height: 8),
          Text(
            'A primeira ligação para ${p.elderFirstName} é $when às '
            '${p.callTimeLabel}. Depois de cada conversa, o resumo aparece '
            'neste calendário e no seu WhatsApp.',
            textAlign: TextAlign.center,
            style: AppText.bodyMd.copyWith(color: AppColors.onSurfaceMuted),
          ),
          const SizedBox(height: 20),
          SecondaryButton(
            label: 'Ver exemplo preenchido',
            icon: Icons.visibility_outlined,
            onPressed: onShowExample,
          ),
          const SizedBox(height: 8),
          Text(
            'Mostra dados simulados. Seu cadastro não muda.',
            textAlign: TextAlign.center,
            style: AppText.bodySm.copyWith(color: AppColors.onSurfaceMuted),
          ),
        ],
      ),
    );
  }
}

/// Aviso fixo enquanto o exemplo preenchido está ativo.
class _DemoBanner extends StatelessWidget {
  const _DemoBanner({required this.onExit});
  final VoidCallback onExit;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
      decoration: BoxDecoration(
        color: AppColors.surfaceLimeWash,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.tertiaryHover),
      ),
      child: Row(
        children: [
          const Icon(Icons.visibility_outlined, color: AppColors.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Modo exemplo',
                  style: AppText.labelMd.copyWith(color: AppColors.onSurface),
                ),
                const SizedBox(height: 2),
                Text(
                  'Dados simulados',
                  style: AppText.bodySm.copyWith(
                    color: AppColors.onSurfaceMuted,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          SecondaryButton(label: 'Sair do exemplo', onPressed: onExit),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.value, required this.label});
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: AppText.headlineLg.copyWith(color: AppColors.onPrimary),
          ),
          Text(
            label,
            style: AppText.bodySm.copyWith(color: AppColors.onPrimaryMuted),
          ),
        ],
      ),
    );
  }
}

/// Dias recentes que pedem alguma ação da família.
class _AttentionList extends StatelessWidget {
  const _AttentionList({required this.state, required this.onOpen});
  final AppState state;
  final ValueChanged<DateTime> onOpen;

  @override
  Widget build(BuildContext context) {
    final today = dateOnly(state.now);
    final items = <CallSummary>[];
    for (var i = 0; i < 7 && items.length < 4; i++) {
      final s = state.summaryFor(today.subtract(Duration(days: i)));
      if (s == null) continue;
      if (s.precisaAtencao || !s.atendida || s.solicitacoes.isNotEmpty) {
        items.add(s);
      }
    }
    if (items.isEmpty) return const SizedBox.shrink();

    return MintCard(
      padding: const EdgeInsets.fromLTRB(20, 20, 12, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Vale a sua atenção',
            style: AppText.headlineMd.copyWith(color: AppColors.onSurface),
          ),
          const SizedBox(height: 4),
          Text(
            'Últimos 7 dias',
            style: AppText.bodySm.copyWith(color: AppColors.onSurfaceMuted),
          ),
          const SizedBox(height: 8),
          for (final s in items)
            InkWell(
              onTap: () => onOpen(s.data),
              borderRadius: BorderRadius.circular(AppRadius.md),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Row(
                  children: [
                    _StatusDot(status: s.status, size: 32),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            s.titulo,
                            style: AppText.labelMd.copyWith(
                              color: AppColors.onSurface,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            [
                              _relative(s.data, today),
                              if (s.solicitacoes.isNotEmpty)
                                s.solicitacoes.length == 1
                                    ? '1 pedido'
                                    : '${s.solicitacoes.length} pedidos',
                            ].join(' · '),
                            style: AppText.bodySm.copyWith(
                              color: AppColors.onSurfaceMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.chevron_right_rounded,
                      color: AppColors.secondary,
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _StatusDot extends StatelessWidget {
  const _StatusDot({required this.status, this.size = 28});
  final CallStatus status;
  final double size;

  @override
  Widget build(BuildContext context) {
    final st = StatusStyle.of(status);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: st.bg,
        shape: BoxShape.circle,
        border: st.border != null ? Border.all(color: st.border!) : null,
      ),
      child: Icon(st.icon, size: size * 0.55, color: st.fg),
    );
  }
}

class MonthCalendar extends StatelessWidget {
  const MonthCalendar({
    super.key,
    required this.state,
    required this.month,
    required this.selected,
    required this.historyStart,
    required this.onSelect,
    required this.onMonth,
  });

  final AppState state;
  final DateTime month;
  final DateTime? selected;
  final DateTime historyStart;
  final ValueChanged<DateTime> onSelect;
  final ValueChanged<DateTime> onMonth;

  static const _weekdays = ['D', 'S', 'T', 'Q', 'Q', 'S', 'S'];

  @override
  Widget build(BuildContext context) {
    final today = dateOnly(state.now);
    final first = DateTime(month.year, month.month);
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final lead = first.weekday % 7; // domingo primeiro
    final canPrev = first.isAfter(historyStart);
    final lastAllowed = DateTime(today.year, today.month + 2);
    final canNext = DateTime(month.year, month.month + 1).isBefore(lastAllowed);

    return MintCard(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              IconButton(
                onPressed: canPrev
                    ? () => onMonth(DateTime(month.year, month.month - 1))
                    : null,
                icon: const Icon(Icons.chevron_left_rounded),
                tooltip: 'Mês anterior',
              ),
              Expanded(
                child: Text(
                  _cap(DateFormat('MMMM yyyy', 'pt_BR').format(month)),
                  textAlign: TextAlign.center,
                  style: AppText.labelLg.copyWith(color: AppColors.onSurface),
                ),
              ),
              IconButton(
                onPressed: canNext
                    ? () => onMonth(DateTime(month.year, month.month + 1))
                    : null,
                icon: const Icon(Icons.chevron_right_rounded),
                tooltip: 'Próximo mês',
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              for (final w in _weekdays)
                Expanded(
                  child: Text(
                    w,
                    textAlign: TextAlign.center,
                    style: AppText.labelSm.copyWith(
                      color: AppColors.onSurfaceMuted,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          LayoutBuilder(
            builder: (context, c) => GridView.count(
              crossAxisCount: 7,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 4,
              crossAxisSpacing: 4,
              // Quadradas no celular; no desktop limitamos a altura a ~64px.
              childAspectRatio: max(1, (c.maxWidth / 7) / 64),
              children: [
                for (var i = 0; i < lead; i++) const SizedBox.shrink(),
                for (var d = 1; d <= daysInMonth; d++)
                  _DayCell(
                    day: DateTime(month.year, month.month, d),
                    today: today,
                    state: state,
                    selected: selected == DateTime(month.year, month.month, d),
                    beforeHistory: DateTime(
                      month.year,
                      month.month,
                      d,
                    ).isBefore(historyStart),
                    onTap: onSelect,
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const _Legend(),
        ],
      ),
    );
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.day,
    required this.today,
    required this.state,
    required this.selected,
    required this.beforeHistory,
    required this.onTap,
  });

  final DateTime day;
  final DateTime today;
  final AppState state;
  final bool selected;
  final bool beforeHistory;
  final ValueChanged<DateTime> onTap;

  @override
  Widget build(BuildContext context) {
    final s = state.summaryFor(day);
    final isToday = day == today;
    final upcoming = s == null && !day.isBefore(today);
    final hasRecado = state.recadoFor(day) != null;

    Color bg = Colors.transparent;
    Color fg = AppColors.onSurface;
    if (beforeHistory) fg = AppColors.inputBorder;
    if (s?.status == CallStatus.amarelo) {
      bg = AppColors.tertiary;
      fg = AppColors.onTertiary;
    } else if (s?.status == CallStatus.vermelho) {
      bg = AppColors.error;
      fg = Colors.white;
    } else if (s?.status == CallStatus.verde) {
      bg = AppColors.surfaceMint;
    }
    if (selected) {
      bg = AppColors.primary;
      fg = AppColors.onPrimary;
    }

    Widget? marker;
    final markerColor = selected ? AppColors.tertiary : fg;
    if (s != null) {
      marker = switch (s.status) {
        CallStatus.verde => Container(
          width: 5,
          height: 5,
          decoration: BoxDecoration(color: markerColor, shape: BoxShape.circle),
        ),
        CallStatus.semLigacao => Icon(
          Icons.phone_missed_rounded,
          size: 12,
          color: selected ? AppColors.tertiary : AppColors.onSurfaceMuted,
        ),
        _ => Icon(StatusStyle.of(s.status).icon, size: 12, color: markerColor),
      };
    } else if (upcoming && hasRecado) {
      marker = Icon(Icons.mail_outline_rounded, size: 12, color: markerColor);
    } else if (isToday) {
      marker = Icon(Icons.schedule_rounded, size: 12, color: markerColor);
    }

    final missedBorder = s?.status == CallStatus.semLigacao && !selected;

    return Semantics(
      button: !beforeHistory,
      label:
          '${DateFormat("d 'de' MMMM", 'pt_BR').format(day)}'
          '${s != null ? ', ${s.status.label}' : ''}',
      child: Material(
        color: bg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          side: isToday && !selected
              ? const BorderSide(color: AppColors.primary, width: 1.5)
              : missedBorder
              ? const BorderSide(color: AppColors.secondary)
              : BorderSide.none,
        ),
        child: InkWell(
          onTap: beforeHistory ? null : () => onTap(day),
          borderRadius: BorderRadius.circular(AppRadius.md),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '${day.day}',
                style: AppText.labelMd.copyWith(
                  color: fg,
                  fontWeight: isToday ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
              const SizedBox(height: 3),
              SizedBox(height: 12, child: Center(child: marker)),
            ],
          ),
        ),
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend();

  @override
  Widget build(BuildContext context) {
    Widget item(Widget swatch, String label) => Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        swatch,
        const SizedBox(width: 6),
        Text(
          label,
          style: AppText.bodySm.copyWith(color: AppColors.onSurfaceMuted),
        ),
      ],
    );
    Widget box(Color c, {Color? border}) => Container(
      width: 14,
      height: 14,
      decoration: BoxDecoration(
        color: c,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: border != null ? Border.all(color: border) : null,
      ),
    );
    return Wrap(
      spacing: 16,
      runSpacing: 8,
      alignment: WrapAlignment.center,
      children: [
        item(box(AppColors.surfaceMint), 'Tudo bem'),
        item(box(AppColors.tertiary), 'Atenção'),
        item(box(AppColors.error), 'Urgente'),
        item(
          box(Colors.transparent, border: AppColors.secondary),
          'Não atendeu',
        ),
        item(
          const Icon(
            Icons.mail_outline_rounded,
            size: 14,
            color: AppColors.onSurfaceMuted,
          ),
          'Recado agendado',
        ),
      ],
    );
  }
}

/// Página de um dia no celular.
class _DayPage extends StatelessWidget {
  const _DayPage({required this.state, required this.day});
  final AppState state;
  final DateTime day;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.neutral,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
        surfaceTintColor: Colors.transparent,
        title: Text(
          _relative(day, state.now),
          style: AppText.labelLg.copyWith(color: AppColors.onPrimary),
        ),
      ),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: DayView(state: state, day: day),
        ),
      ),
    );
  }
}

/// Conteúdo de um dia: resumo, agendamento + recado ou "sem ligação".
class DayView extends StatelessWidget {
  const DayView({super.key, required this.state, required this.day});
  final AppState state;
  final DateTime day;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: state,
      builder: (context, _) {
        final p = state.profile;
        if (p == null) return const SizedBox.shrink();
        final s = state.summaryFor(day);
        if (s != null) return _SummaryView(summary: s, profile: p);
        if (!day.isBefore(dateOnly(state.now))) {
          return _ScheduledView(state: state, day: day);
        }
        return _EmptyDay(day: day);
      },
    );
  }
}

class _EmptyDay extends StatelessWidget {
  const _EmptyDay({required this.day});
  final DateTime day;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.event_busy_rounded,
            size: 40,
            color: AppColors.secondary,
          ),
          const SizedBox(height: 12),
          Text(
            _longDate(day),
            style: AppText.labelLg,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            'Ainda não havia ligações neste dia.',
            style: AppText.bodyMd.copyWith(color: AppColors.onSurfaceMuted),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _DayHeader extends StatelessWidget {
  const _DayHeader({
    required this.day,
    required this.title,
    required this.trailing,
    this.meta = const [],
  });
  final DateTime day;
  final String title;
  final Widget trailing;
  final List<(IconData, String)> meta;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: AppColors.primary,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  _longDate(day),
                  style: AppText.bodyMd.copyWith(
                    color: AppColors.onPrimaryMuted,
                  ),
                ),
              ),
              trailing,
            ],
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: AppText.headlineMd.copyWith(color: AppColors.onPrimary),
          ),
          if (meta.isNotEmpty) ...[
            const SizedBox(height: 14),
            Wrap(
              spacing: 16,
              runSpacing: 6,
              children: [
                for (final (icon, text) in meta)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(icon, size: 14, color: AppColors.tertiary),
                      const SizedBox(width: 6),
                      Text(
                        text,
                        style: AppText.bodySm.copyWith(
                          color: AppColors.onPrimaryMuted,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child, this.icon});
  final String title;
  final IconData? icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Icon(icon, size: 18, color: AppColors.primary),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: Text(
                  title,
                  style: AppText.labelLg.copyWith(color: AppColors.onSurface),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

class _Bullets extends StatelessWidget {
  const _Bullets(this.items);
  final List<String> items;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final t in items)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 8, right: 10),
                  child: Container(
                    width: 5,
                    height: 5,
                    decoration: const BoxDecoration(
                      color: AppColors.secondary,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    t,
                    style: AppText.bodyMd.copyWith(color: AppColors.onSurface),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _SummaryView extends StatelessWidget {
  const _SummaryView({required this.summary, required this.profile});
  final CallSummary summary;
  final Profile profile;

  @override
  Widget build(BuildContext context) {
    final s = summary;
    final answered = s.tentativas.where((t) => t.atendida).firstOrNull;
    final attemptIdx = answered == null
        ? 0
        : s.tentativas.indexOf(answered) + 1;

    final meta = <(IconData, String)>[
      if (answered != null)
        (
          Icons.call_rounded,
          'Atendeu às ${answered.horario}'
              '${attemptIdx > 1 ? ' ($attemptIdxª tentativa)' : ''}',
        )
      else
        (Icons.phone_missed_rounded, '${s.tentativas.length} tentativas'),
      if (s.duracaoMin != null) (Icons.timer_outlined, '${s.duracaoMin} min'),
      if (s.whatsappEnviado != null)
        (Icons.chat_outlined, 'Resumo no WhatsApp às ${s.whatsappEnviado}'),
    ];

    return ListView(
      padding: const EdgeInsets.only(bottom: 32),
      children: [
        _DayHeader(
          day: s.data,
          title: s.titulo,
          trailing: StatusPill(s.status),
          meta: meta,
        ),
        if (!s.atendida) ..._missed(s) else ..._answered(s),
      ],
    );
  }

  List<Widget> _missed(CallSummary s) => [
    Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Text(
        s.resumoFamilia,
        style: AppText.bodyLg.copyWith(color: AppColors.onSurface),
      ),
    ),
    _Section(
      title: 'Tentativas',
      icon: Icons.history_rounded,
      child: _Attempts(s.tentativas),
    ),
    if (s.recado != null)
      _Section(
        title: 'Seu recado',
        icon: Icons.mail_outline_rounded,
        child: _RecadoCard(recado: s.recado!, elder: profile.elderFirstName),
      ),
    _Section(
      title: 'Contato de ${profile.elderFirstName}',
      icon: Icons.phone_outlined,
      child: Text(
        profile.elderPhone,
        style: AppText.labelLg.copyWith(color: AppColors.primary),
      ),
    ),
  ];

  List<Widget> _answered(CallSummary s) => [
    Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Text(
        s.resumoFamilia,
        style: AppText.bodyLg.copyWith(color: AppColors.onSurface),
      ),
    ),
    if (s.humorGeral != null)
      Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
        child: _MoodRow(humor: s.humorGeral!, engajamento: s.engajamento),
      ),
    if (s.alertas.isNotEmpty)
      _Section(
        title: 'Pontos de atenção',
        icon: Icons.priority_high_rounded,
        child: Column(
          children: [
            for (final a in s.alertas) _SignalCard(signal: a, alert: true),
          ],
        ),
      ),
    if (s.solicitacoes.isNotEmpty)
      _Section(
        title: 'Pedidos de ${profile.elderFirstName}',
        icon: Icons.volunteer_activism_outlined,
        child: Column(
          children: [
            for (final r in s.solicitacoes)
              Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.surfaceLimeWash,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.front_hand_outlined,
                      size: 18,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        r,
                        style: AppText.labelMd.copyWith(
                          color: AppColors.onSurface,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    if (s.recado != null)
      _Section(
        title: 'Seu recado',
        icon: Icons.mail_outline_rounded,
        child: _RecadoCard(recado: s.recado!, elder: profile.elderFirstName),
      ),
    if (s.respostasPerguntas.isNotEmpty)
      _Section(
        title: 'Suas perguntas',
        icon: Icons.chat_bubble_outline_rounded,
        child: Column(
          children: [
            for (final qa in s.respostasPerguntas)
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.surfaceMint,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      qa.pergunta,
                      style: AppText.bodySm.copyWith(
                        color: AppColors.onSurfaceMuted,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      qa.resposta,
                      style: AppText.bodyMd.copyWith(
                        color: AppColors.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    if (s.sinais.any((x) => !x.alerta))
      _Section(
        title: 'Sinais positivos',
        icon: Icons.eco_outlined,
        child: Column(
          children: [
            for (final x in s.sinais.where((x) => !x.alerta))
              _SignalCard(signal: x, alert: false),
          ],
        ),
      ),
    if (s.mudancasVsHistorico.isNotEmpty)
      _Section(
        title: 'Comparado aos últimos dias',
        icon: Icons.insights_rounded,
        child: _Bullets(s.mudancasVsHistorico),
      ),
    if (s.pautaProximaLigacao.isNotEmpty)
      _Section(
        title: 'Pauta da próxima ligação',
        icon: Icons.event_note_outlined,
        child: _Bullets(s.pautaProximaLigacao),
      ),
    if (s.tentativas.length > 1)
      _Section(
        title: 'Tentativas',
        icon: Icons.history_rounded,
        child: _Attempts(s.tentativas),
      ),
  ];
}

class _MoodRow extends StatelessWidget {
  const _MoodRow({required this.humor, required this.engajamento});
  final int humor;
  final String? engajamento;

  @override
  Widget build(BuildContext context) {
    final (eng, level) = switch (engajamento) {
      'alto' => ('Alto', 3),
      'medio' => ('Médio', 2),
      'baixo' => ('Baixo', 1),
      _ => ('—', 0),
    };
    Widget card(String label, String value, Widget bar) => Expanded(
      child: MintCard(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: AppText.bodySm.copyWith(color: AppColors.onSurfaceMuted),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: AppText.headlineMd.copyWith(color: AppColors.onSurface),
            ),
            const SizedBox(height: 8),
            bar,
          ],
        ),
      ),
    );
    return Row(
      children: [
        card(
          'Humor geral',
          '$humor/10',
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: humor / 10,
              minHeight: 6,
              backgroundColor: AppColors.surfaceMint,
              color: AppColors.primary,
            ),
          ),
        ),
        const SizedBox(width: 12),
        card(
          'Engajamento',
          eng,
          Row(
            children: [
              for (var i = 0; i < 3; i++) ...[
                Expanded(
                  child: Container(
                    height: 6,
                    decoration: BoxDecoration(
                      color: i < level
                          ? AppColors.primary
                          : AppColors.surfaceMint,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                if (i < 2) const SizedBox(width: 4),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _SignalCard extends StatelessWidget {
  const _SignalCard({required this.signal, required this.alert});
  final Signal signal;
  final bool alert;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: alert ? AppColors.surfaceLimeWash : AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: alert
              ? AppColors.tertiaryHover
              : AppColors.secondary.withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: alert ? AppColors.primary : AppColors.surfaceMint,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  signal.categoriaLabel,
                  style: AppText.labelSm.copyWith(
                    color: alert ? AppColors.onPrimary : AppColors.onSurface,
                  ),
                ),
              ),
              const Spacer(),
              Tooltip(
                message: 'Confiança da análise',
                child: Text(
                  'Confiança ${signal.confianca}/10',
                  style: AppText.bodySm.copyWith(
                    color: AppColors.onSurfaceMuted,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            signal.descricao,
            style: AppText.labelMd.copyWith(
              color: AppColors.onSurface,
              height: 1.4,
            ),
          ),
          if (signal.evidencia.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              '"${signal.evidencia}"',
              style: AppText.bodySm.copyWith(
                color: AppColors.onSurfaceMuted,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _RecadoCard extends StatelessWidget {
  const _RecadoCard({required this.recado, required this.elder});
  final Recado recado;
  final String elder;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Align(
          alignment: Alignment.centerRight,
          child: Container(
            constraints: const BoxConstraints(maxWidth: 360),
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(AppRadius.md),
                topRight: Radius.circular(AppRadius.md),
                bottomLeft: Radius.circular(AppRadius.md),
                bottomRight: Radius.circular(AppRadius.sm),
              ),
            ),
            child: Text(
              recado.texto,
              style: AppText.bodyMd.copyWith(color: AppColors.onPrimary),
            ),
          ),
        ),
        const SizedBox(height: 8),
        if (recado.resposta == null)
          Text(
            'Não foi possível entregar porque $elder não atendeu. '
            'Deixe o recado de novo para a próxima ligação.',
            style: AppText.bodySm.copyWith(color: AppColors.onSurfaceMuted),
          )
        else
          Align(
            alignment: Alignment.centerLeft,
            child: Container(
              constraints: const BoxConstraints(maxWidth: 360),
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(
                color: AppColors.surfaceCard,
                boxShadow: chipShadow,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(AppRadius.md),
                  topRight: Radius.circular(AppRadius.md),
                  bottomLeft: Radius.circular(AppRadius.sm),
                  bottomRight: Radius.circular(AppRadius.md),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Resposta de $elder',
                    style: AppText.labelSm.copyWith(
                      color: AppColors.onSurfaceMuted,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    recado.resposta!,
                    style: AppText.bodyMd.copyWith(color: AppColors.onSurface),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _Attempts extends StatelessWidget {
  const _Attempts(this.attempts);
  final List<Attempt> attempts;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var i = 0; i < attempts.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              children: [
                Icon(
                  attempts[i].atendida
                      ? Icons.call_rounded
                      : Icons.phone_missed_rounded,
                  size: 16,
                  color: attempts[i].atendida
                      ? AppColors.primary
                      : AppColors.onSurfaceMuted,
                ),
                const SizedBox(width: 10),
                Text(
                  '${i + 1}ª tentativa · ${attempts[i].horario}',
                  style: AppText.bodyMd.copyWith(color: AppColors.onSurface),
                ),
                const Spacer(),
                Text(
                  attempts[i].atendida ? 'Atendida' : 'Sem resposta',
                  style: AppText.bodySm.copyWith(
                    color: AppColors.onSurfaceMuted,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// Dia futuro (ou hoje antes da ligação): deixar recado.
class _ScheduledView extends StatefulWidget {
  const _ScheduledView({required this.state, required this.day});
  final AppState state;
  final DateTime day;

  @override
  State<_ScheduledView> createState() => _ScheduledViewState();
}

class _ScheduledViewState extends State<_ScheduledView> {
  late final _ctrl = TextEditingController(
    text: widget.state.recadoFor(widget.day),
  );

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _save(String? text) async {
    await widget.state.setRecado(widget.day, text);
    if (text == null) _ctrl.clear();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          text == null
              ? 'Recado removido'
              : 'Recado salvo. Vamos passar na ligação.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.state.profile!;
    final saved = widget.state.recadoFor(widget.day);
    final text = _ctrl.text.trim();
    return ListView(
      padding: const EdgeInsets.only(bottom: 32),
      children: [
        _DayHeader(
          day: widget.day,
          title: 'Ligação agendada às ${p.callTimeLabel}',
          trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.secondary),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              'Agendada',
              style: AppText.labelSm.copyWith(color: AppColors.onPrimaryMuted),
            ),
          ),
          meta: [
            (Icons.call_outlined, p.elderPhone),
            (Icons.repeat_rounded, 'Até 3 tentativas'),
          ],
        ),
        _Section(
          title: 'Deixar recado',
          icon: Icons.mail_outline_rounded,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Vamos passar o recado para ${p.elderFirstName} durante a '
                'conversa e trazer a resposta no resumo do dia.',
                style: AppText.bodyMd.copyWith(color: AppColors.onSurfaceMuted),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _ctrl,
                minLines: 3,
                maxLines: 6,
                maxLength: 300,
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(
                  hintText:
                      'Ex.: Sábado vou passar aí para almoçarmos. Estou com saudade!',
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: PrimaryButton(
                      expand: true,
                      label: saved == null
                          ? 'Salvar recado'
                          : 'Atualizar recado',
                      icon: Icons.check_rounded,
                      onPressed: text.isEmpty || text == saved
                          ? null
                          : () => _save(text),
                    ),
                  ),
                  if (saved != null) ...[
                    const SizedBox(width: 8),
                    SecondaryButton(
                      label: 'Remover',
                      onPressed: () => _save(null),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
        _Section(
          title: 'O que vamos perguntar',
          icon: Icons.chat_bubble_outline_rounded,
          child: _Bullets([for (final q in p.questionIds) kQuestions[q]]),
        ),
      ],
    );
  }
}
