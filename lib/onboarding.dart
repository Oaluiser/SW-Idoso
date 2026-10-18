import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'models.dart';
import 'state.dart';
import 'theme.dart';
import 'widgets.dart';

const _wideBreakpoint = 960.0;
const _formMaxWidth = 560.0;

String _hhmm(TimeOfDay t) =>
    '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

TimeOfDay _addMinutes(TimeOfDay t, int m) {
  final total = t.hour * 60 + t.minute + m;
  return TimeOfDay(hour: (total ~/ 60) % 24, minute: total % 60);
}

/// Rascunho do cadastro, compartilhado entre onboarding e configurações.
class ProfileDraft extends ChangeNotifier {
  ProfileDraft([Profile? p])
    : elderName = TextEditingController(text: p?.elderName),
      elderPhone = TextEditingController(text: p?.elderPhone),
      familyName = TextEditingController(text: p?.familyName),
      familyPhone = TextEditingController(text: p?.familyPhone),
      familyEmail = TextEditingController(text: p?.familyEmail),
      notes = TextEditingController(text: p?.notes),
      // No cadastro nada vem pré-selecionado: horário e perguntas são
      // escolhas da família.
      time = p == null
          ? null
          : TimeOfDay(hour: p.callHour, minute: p.callMinute),
      days = {...?p?.callDays},
      questions = {...?p?.questionIds} {
    for (final c in _controllers) {
      c.addListener(notifyListeners);
    }
  }

  final TextEditingController elderName;
  final TextEditingController elderPhone;
  final TextEditingController familyName;
  final TextEditingController familyPhone;
  final TextEditingController familyEmail;
  final TextEditingController notes;
  TimeOfDay? time;

  /// Dias da semana (1 = seg … 7 = dom). No cadastro começa vazio.
  final Set<int> days;
  final Set<int> questions;

  List<TextEditingController> get _controllers => [
    elderName,
    elderPhone,
    familyName,
    familyPhone,
    familyEmail,
    notes,
  ];

  String get elderFirstName => elderName.text.trim().split(' ').first;

  bool get questionsValid =>
      questions.length >= Profile.minQuestions &&
      questions.length <= Profile.maxQuestions;

  bool get timeValid => time != null;
  bool get daysValid => days.isNotEmpty;

  void toggleDay(int weekday) {
    if (!days.remove(weekday)) days.add(weekday);
    notifyListeners();
  }

  void setDays(Iterable<int> value) {
    days
      ..clear()
      ..addAll(value);
    notifyListeners();
  }

  void setTime(TimeOfDay t) {
    time = t;
    notifyListeners();
  }

  /// Marca/desmarca. Retorna `false` se já há o máximo de perguntas.
  bool toggleQuestion(int id) {
    if (questions.remove(id)) {
      notifyListeners();
      return true;
    }
    if (questions.length >= Profile.maxQuestions) return false;
    questions.add(id);
    notifyListeners();
    return true;
  }

  void appendNote(String text) {
    final current = notes.text.trim();
    notes.text = current.isEmpty
        ? text
        : '$current${RegExp(r'[.!?]$').hasMatch(current) ? '' : '.'} $text';
    notes.selection = TextSelection.collapsed(offset: notes.text.length);
  }

  void fillExample() {
    elderName.text = 'Maria Aparecida';
    elderPhone.text = '(11) 3456-7890';
    familyName.text = 'Ana Souza';
    familyPhone.text = '(11) 98765-4321';
    familyEmail.text = 'ana.souza@gmail.com';
  }

  Profile build() => Profile(
    elderName: elderName.text.trim(),
    elderPhone: elderPhone.text.trim(),
    familyName: familyName.text.trim(),
    familyPhone: familyPhone.text.trim(),
    familyEmail: familyEmail.text.trim().toLowerCase(),
    callHour: time!.hour,
    callMinute: time!.minute,
    callDays: days.toList()..sort(),
    questionIds: questions.toList()..sort(),
    notes: notes.text.trim(),
  );

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }
}

// ---------------------------------------------------------------------------
// Onboarding
// ---------------------------------------------------------------------------

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key, required this.state});
  final AppState state;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _draft = ProfileDraft();
  final _contactsKey = GlobalKey<ContactFieldsState>();
  final _callKey = GlobalKey<CallFieldsState>();
  final _scroll = ScrollController();
  int _step = 0;

  @override
  void dispose() {
    _draft.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _goTo(int step) {
    FocusScope.of(context).unfocus();
    setState(() => _step = step);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) _scroll.jumpTo(0);
    });
  }

  Future<void> _next() async {
    if (_step == 0) {
      if (_contactsKey.currentState!.validate()) _goTo(1);
      return;
    }
    if (!_callKey.currentState!.validate()) return;
    widget.state.markWelcome();
    // Após o cadastro o calendário começa vazio, como no uso real.
    await widget.state.setDemo(false);
    await widget.state.saveProfile(_draft.build());
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _step == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _goTo(0);
      },
      child: Scaffold(
        backgroundColor: AppColors.neutral,
        body: LayoutBuilder(
          builder: (context, c) {
            final wide = c.maxWidth >= _wideBreakpoint;
            final pane = SafeArea(
              left: !wide,
              child: _FormPane(
                step: _step,
                wide: wide,
                scroll: _scroll,
                draft: _draft,
                onBack: () => _goTo(0),
                onNext: _next,
                child: _step == 0
                    ? _ContactsStep(
                        fieldsKey: _contactsKey,
                        draft: _draft,
                        onSubmit: _next,
                      )
                    : _CallStep(fieldsKey: _callKey, draft: _draft),
              ),
            );
            if (!wide) return ContourBackground(child: pane);
            return Row(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: SizedBox(
                    width: c.maxWidth * 0.42,
                    child: _BrandPanel(draft: _draft, step: _step),
                  ),
                ),
                Expanded(child: pane),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _FormPane extends StatelessWidget {
  const _FormPane({
    required this.step,
    required this.wide,
    required this.scroll,
    required this.draft,
    required this.onBack,
    required this.onNext,
    required this.child,
  });

  final int step;
  final bool wide;
  final ScrollController scroll;
  final ProfileDraft draft;
  final VoidCallback onBack;
  final VoidCallback onNext;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Constrained(
          maxWidth: _formMaxWidth + 32,
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: _Header(step: step, wide: wide, onBack: onBack),
        ),
        Divider(height: 1, color: AppColors.secondary.withValues(alpha: 0.25)),
        Expanded(
          child: SingleChildScrollView(
            controller: scroll,
            padding: EdgeInsets.only(top: wide ? 40 : 24, bottom: 32),
            child: Constrained(
              maxWidth: _formMaxWidth + 32,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                transitionBuilder: (child, a) => FadeTransition(
                  opacity: a,
                  child: SlideTransition(
                    position: Tween(
                      begin: const Offset(0, 0.02),
                      end: Offset.zero,
                    ).animate(a),
                    child: child,
                  ),
                ),
                child: KeyedSubtree(key: ValueKey(step), child: child),
              ),
            ),
          ),
        ),
        _BottomBar(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (step == 1)
                ListenableBuilder(
                  listenable: draft,
                  builder: (context, _) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Text(
                      '${draft.days.isEmpty ? 'Dias a definir' : weekdaysLabel(draft.days)} · '
                      '${draft.time == null ? 'horário a definir' : _hhmm(draft.time!)} · '
                      '${draft.questions.length} de ${Profile.maxQuestions} '
                      'perguntas',
                      textAlign: TextAlign.center,
                      style: AppText.bodySm.copyWith(
                        color: AppColors.onSurfaceMuted,
                      ),
                    ),
                  ),
                ),
              PrimaryButton(
                expand: true,
                height: 52,
                label: step == 0 ? 'Continuar' : 'Concluir e ver calendário',
                icon: Icons.arrow_forward_rounded,
                onPressed: onNext,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.step, required this.wide, required this.onBack});
  final int step;
  final bool wide;
  final VoidCallback onBack;

  static const _labels = ['Contatos', 'Ligação'];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: 60,
          child: Row(
            children: [
              if (step > 0)
                TextButton.icon(
                  onPressed: onBack,
                  icon: const Icon(Icons.arrow_back_rounded, size: 18),
                  label: const Text('Voltar'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    textStyle: AppText.labelMd,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    minimumSize: const Size(0, 44),
                  ),
                )
              else if (!wide)
                const Wordmark(),
              const Spacer(),
              Text(
                'Etapa ${step + 1} de 2',
                style: AppText.labelMd.copyWith(
                  color: AppColors.onSurfaceMuted,
                ),
              ),
            ],
          ),
        ),
        Row(
          children: [
            for (var i = 0; i < 2; i++) ...[
              if (i > 0) const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      height: 4,
                      decoration: BoxDecoration(
                        color: i <= step
                            ? AppColors.primary
                            : AppColors.secondary.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _labels[i],
                      style: AppText.labelSm.copyWith(
                        color: i == step
                            ? AppColors.onSurface
                            : AppColors.onSurfaceMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

class _BottomBar extends StatelessWidget {
  const _BottomBar({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.neutral,
        border: Border(
          top: BorderSide(color: AppColors.secondary.withValues(alpha: 0.35)),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Constrained(
          maxWidth: _formMaxWidth + 32,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: child,
        ),
      ),
    );
  }
}

class _StepTitle extends StatelessWidget {
  const _StepTitle({required this.title, required this.subtitle});
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= _wideBreakpoint;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppText.headlineLg.copyWith(
            color: AppColors.primaryDeep,
            fontSize: wide ? 36 : 28,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          subtitle,
          style: AppText.bodyLg.copyWith(color: AppColors.onSurfaceMuted),
        ),
      ],
    );
  }
}

class _ContactsStep extends StatelessWidget {
  const _ContactsStep({
    required this.fieldsKey,
    required this.draft,
    required this.onSubmit,
  });
  final GlobalKey<ContactFieldsState> fieldsKey;
  final ProfileDraft draft;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _StepTitle(
          title: 'Para quem vamos ligar?',
          subtitle:
              'Ligamos nos dias e no horário que você escolher, com '
              'conversa de amigo. Depois, você recebe o resumo.',
        ),
        const SizedBox(height: 32),
        ContactFields(key: fieldsKey, draft: draft, onSubmit: onSubmit),
        const SizedBox(height: 24),
        Center(
          child: TextButton(
            onPressed: draft.fillExample,
            style: TextButton.styleFrom(
              foregroundColor: AppColors.onSurfaceMuted,
              textStyle: AppText.bodySm,
            ),
            child: const Text('Só quer conhecer? Usar dados de exemplo'),
          ),
        ),
      ],
    );
  }
}

class _CallStep extends StatelessWidget {
  const _CallStep({required this.fieldsKey, required this.draft});
  final GlobalKey<CallFieldsState> fieldsKey;
  final ProfileDraft draft;

  @override
  Widget build(BuildContext context) {
    final name = draft.elderFirstName;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _StepTitle(
          title: 'Como vai ser a conversa${name.isEmpty ? '' : ' com $name'}?',
          subtitle:
              'Escolha os dias, o horário e o que você gostaria de '
              'saber. Dá para mudar tudo depois.',
        ),
        const SizedBox(height: 32),
        CallFields(key: fieldsKey, draft: draft, onboarding: true),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Campos reutilizáveis (onboarding + configurações)
// ---------------------------------------------------------------------------

/// Campo de texto com rótulo acima, validação ao sair do campo (ou após
/// tentativa de envio) e confirmação visual quando válido.
class AppField extends StatefulWidget {
  const AppField({
    super.key,
    required this.label,
    required this.controller,
    required this.focusNode,
    required this.validator,
    required this.forceValidate,
    this.hint,
    this.helper,
    this.keyboardType,
    this.inputFormatters,
    this.autofillHints,
    this.textInputAction = TextInputAction.next,
    this.textCapitalization = TextCapitalization.none,
    this.onSubmitted,
    this.dependsOn,
    this.formatOnBlur,
  });

  final Listenable? dependsOn;
  final String Function(String)? formatOnBlur;
  final String label;
  final TextEditingController controller;
  final FocusNode focusNode;
  final String? Function(String?) validator;
  final bool forceValidate;
  final String? hint;
  final String? helper;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final Iterable<String>? autofillHints;
  final TextInputAction textInputAction;
  final TextCapitalization textCapitalization;
  final ValueChanged<String>? onSubmitted;

  @override
  State<AppField> createState() => _AppFieldState();
}

class _AppFieldState extends State<AppField> {
  // Campos que já chegam preenchidos (voltar etapa, configurações) começam
  // validados.
  late bool _touched = widget.controller.text.trim().isNotEmpty;

  @override
  void initState() {
    super.initState();
    widget.focusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    widget.focusNode.removeListener(_onFocusChange);
    super.dispose();
  }

  void _onFocusChange() {
    if (widget.focusNode.hasFocus) return;
    final format = widget.formatOnBlur;
    if (format != null) {
      final formatted = format(widget.controller.text);
      if (formatted != widget.controller.text) {
        widget.controller.text = formatted;
      }
    }
    if (!_touched && widget.controller.text.trim().isNotEmpty) {
      setState(() => _touched = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final show = _touched || widget.forceValidate;
    return ListenableBuilder(
      // O rascunho inteiro: validações cruzadas (ex.: telefones iguais)
      // reagem quando o outro campo muda.
      listenable: widget.dependsOn ?? widget.controller,
      builder: (context, _) {
        final error = show ? widget.validator(widget.controller.text) : null;
        final ok = show && error == null;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              widget.label,
              style: AppText.labelMd.copyWith(color: AppColors.onSurface),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: widget.controller,
              focusNode: widget.focusNode,
              keyboardType: widget.keyboardType,
              inputFormatters: widget.inputFormatters,
              autofillHints: widget.autofillHints,
              textInputAction: widget.textInputAction,
              textCapitalization: widget.textCapitalization,
              autocorrect: false,
              onSubmitted: widget.onSubmitted,
              style: AppText.bodyLg.copyWith(color: AppColors.onSurface),
              decoration: InputDecoration(
                hintText: widget.hint,
                helperText: error == null ? widget.helper : null,
                errorText: error,
                suffixIcon: ok
                    ? const Icon(
                        Icons.check_circle_rounded,
                        color: AppColors.primary,
                        size: 20,
                      )
                    : null,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _GroupLabel extends StatelessWidget {
  const _GroupLabel({required this.icon, required this.title, this.subtitle});
  final IconData icon;
  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: AppColors.surfaceMint,
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          child: Icon(icon, size: 20, color: AppColors.primary),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppText.labelLg.copyWith(color: AppColors.onSurface),
              ),
              if (subtitle != null)
                Text(
                  subtitle!,
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

/// Etapa 1: nome e telefone do idoso; nome, WhatsApp e e-mail do familiar.
class ContactFields extends StatefulWidget {
  const ContactFields({super.key, required this.draft, this.onSubmit});
  final ProfileDraft draft;
  final VoidCallback? onSubmit;

  @override
  State<ContactFields> createState() => ContactFieldsState();
}

class ContactFieldsState extends State<ContactFields> {
  final _focus = List.generate(5, (_) => FocusNode());
  final _keys = List.generate(5, (_) => GlobalKey());
  bool _submitted = false;

  ProfileDraft get d => widget.draft;

  /// Mesma ordem dos campos na tela.
  late final List<String? Function()> _checks = [
    () => validateName(
      d.elderName.text,
      emptyMessage: 'Informe o nome de quem vai receber as ligações',
    ),
    () => validatePhone(
      d.elderPhone.text,
      differentFrom: d.familyPhone.text,
      sameMessage: 'Esse é o seu WhatsApp. Informe o telefone do idoso.',
    ),
    () => validateName(d.familyName.text, emptyMessage: 'Informe seu nome'),
    () => validatePhone(
      d.familyPhone.text,
      mobileOnly: true,
      differentFrom: d.elderPhone.text,
      emptyMessage: 'Informe seu WhatsApp',
      sameMessage: 'Esse é o telefone do idoso. Informe o seu WhatsApp.',
    ),
    () => validateEmail(d.familyEmail.text),
  ];

  /// Mostra todos os erros e leva o foco ao primeiro campo inválido.
  bool validate() {
    setState(() => _submitted = true);
    for (var i = 0; i < _checks.length; i++) {
      if (_checks[i]() != null) {
        _focus[i].requestFocus();
        final ctx = _keys[i].currentContext;
        if (ctx != null) {
          Scrollable.ensureVisible(
            ctx,
            alignment: 0.2,
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOut,
          );
        }
        return false;
      }
    }
    return true;
  }

  @override
  void dispose() {
    for (final f in _focus) {
      f.dispose();
    }
    super.dispose();
  }

  Widget _field(
    int i, {
    required String label,
    required TextEditingController controller,
    String? hint,
    String? helper,
    bool phone = false,
    bool name = false,
    bool email = false,
    TextInputType? keyboard,
    Iterable<String>? autofill,
    bool last = false,
  }) {
    return Padding(
      key: _keys[i],
      padding: const EdgeInsets.only(bottom: 20),
      child: AppField(
        label: label,
        controller: controller,
        focusNode: _focus[i],
        validator: (_) => _checks[i](),
        forceValidate: _submitted,
        hint: hint,
        helper: helper,
        keyboardType: phone ? TextInputType.phone : keyboard,
        inputFormatters: phone ? [PhoneInputFormatter()] : null,
        textCapitalization: name
            ? TextCapitalization.words
            : TextCapitalization.none,
        autofillHints: autofill,
        textInputAction: last ? TextInputAction.done : TextInputAction.next,
        onSubmitted: last
            ? (_) => widget.onSubmit?.call()
            : (_) => _focus[i + 1].requestFocus(),
        dependsOn: d,
        formatOnBlur: name
            ? titleCaseName
            : (email ? (s) => s.trim().toLowerCase() : null),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AutofillGroup(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _GroupLabel(
            icon: Icons.elderly_rounded,
            title: 'Quem recebe a ligação',
          ),
          const SizedBox(height: 20),
          _field(
            0,
            label: 'Nome',
            controller: d.elderName,
            hint: 'Nome e sobrenome',
            name: true,
          ),
          _field(
            1,
            label: 'Telefone',
            controller: d.elderPhone,
            hint: '(DDD) número',
            helper: 'Celular ou fixo. É para esse número que vamos ligar.',
            phone: true,
          ),
          const SizedBox(height: 8),
          Divider(color: AppColors.secondary.withValues(alpha: 0.35)),
          const SizedBox(height: 24),
          const _GroupLabel(
            icon: Icons.favorite_outline_rounded,
            title: 'Você',
            subtitle: 'Quem recebe o resumo de cada conversa',
          ),
          const SizedBox(height: 20),
          _field(
            2,
            label: 'Seu nome',
            controller: d.familyName,
            hint: 'Nome e sobrenome',
            name: true,
            autofill: const [AutofillHints.name],
          ),
          _field(
            3,
            label: 'Seu WhatsApp',
            controller: d.familyPhone,
            hint: '(DDD) 9 0000-0000',
            helper: 'O resumo de cada ligação chega aqui.',
            phone: true,
            autofill: const [AutofillHints.telephoneNumber],
          ),
          _field(
            4,
            label: 'Seu e-mail',
            controller: d.familyEmail,
            hint: 'nome@email.com',
            helper: 'Para avisos importantes sobre o serviço.',
            keyboard: TextInputType.emailAddress,
            email: true,
            autofill: const [AutofillHints.email],
            last: true,
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    super.key,
    required this.number,
    required this.title,
    required this.subtitle,
    this.trailing,
  });
  final int number;
  final String title;
  final String subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 28,
          height: 28,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            color: AppColors.primary,
            shape: BoxShape.circle,
          ),
          child: Text(
            '$number',
            style: AppText.labelMd.copyWith(color: AppColors.onPrimary),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 3),
                child: Text(
                  title,
                  style: AppText.labelLg.copyWith(color: AppColors.onSurface),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: AppText.bodyMd.copyWith(color: AppColors.onSurfaceMuted),
              ),
            ],
          ),
        ),
        if (trailing != null) ...[const SizedBox(width: 12), trailing!],
      ],
    );
  }
}

/// Etapa 2: horário, perguntas (2 a 5) e observações.
class CallFields extends StatefulWidget {
  const CallFields({super.key, required this.draft, this.onboarding = false});
  final ProfileDraft draft;
  final bool onboarding;

  @override
  State<CallFields> createState() => CallFieldsState();
}

class CallFieldsState extends State<CallFields> {
  final _daysKey = GlobalKey();
  final _timeKey = GlobalKey();
  final _questionsKey = GlobalKey();
  bool _submitted = false;
  bool _fullHint = false;
  Timer? _hintTimer;

  ProfileDraft get d => widget.draft;

  bool validate() {
    setState(() => _submitted = true);
    if (d.daysValid && d.timeValid && d.questionsValid) return true;
    final target = !d.daysValid
        ? _daysKey
        : !d.timeValid
        ? _timeKey
        : _questionsKey;
    final ctx = target.currentContext;
    if (ctx != null) {
      Scrollable.ensureVisible(
        ctx,
        alignment: 0.1,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    }
    return false;
  }

  void _toggle(int id) {
    if (d.toggleQuestion(id)) {
      if (_fullHint) setState(() => _fullHint = false);
      return;
    }
    HapticFeedback.mediumImpact();
    _hintTimer?.cancel();
    setState(() => _fullHint = true);
    _hintTimer = Timer(const Duration(seconds: 4), () {
      if (mounted) setState(() => _fullHint = false);
    });
  }

  @override
  void dispose() {
    _hintTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: d,
      builder: (context, _) {
        final count = d.questions.length;
        final time = d.time;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _SectionHeader(
              key: _daysKey,
              number: 1,
              title: 'Em quais dias ligamos?',
              subtitle: 'Escolha de 1 a 7 dias da semana.',
            ),
            const SizedBox(height: 16),
            _DaySelector(draft: d),
            AnimatedSize(
              duration: const Duration(milliseconds: 200),
              alignment: Alignment.topCenter,
              child: _submitted && !d.daysValid
                  ? const Padding(
                      padding: EdgeInsets.only(top: 12),
                      child: _InlineMessage(
                        error: true,
                        text: 'Escolha pelo menos 1 dia para continuar.',
                      ),
                    )
                  : const SizedBox(width: double.infinity),
            ),
            const SizedBox(height: 40),
            _SectionHeader(
              key: _timeKey,
              number: 2,
              title: 'Que horas ligamos?',
              subtitle:
                  'Escolha um horário em que costuma estar em casa e '
                  'com tempo para conversar.',
            ),
            const SizedBox(height: 16),
            _TimeSelector(draft: d),
            const SizedBox(height: 12),
            AnimatedSize(
              duration: const Duration(milliseconds: 200),
              alignment: Alignment.topCenter,
              child: time != null
                  ? Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceMint,
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.replay_rounded,
                            size: 18,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              '${d.days.isEmpty ? 'Às' : '${weekdaysLabel(d.days)} às'} '
                              '${_hhmm(time)}. Se não '
                              'atender, tentamos de novo às '
                              '${_hhmm(_addMinutes(time, 10))} e '
                              '${_hhmm(_addMinutes(time, 20))}.',
                              style: AppText.bodySm.copyWith(
                                color: AppColors.onSurface,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  : _InlineMessage(
                      error: _submitted,
                      text: _submitted
                          ? 'Escolha um horário para continuar.'
                          : 'Toque em um horário para escolher.',
                    ),
            ),
            const SizedBox(height: 40),
            _SectionHeader(
              key: _questionsKey,
              number: 3,
              title: 'O que você quer saber?',
              subtitle:
                  'Escolha de ${Profile.minQuestions} a '
                  '${Profile.maxQuestions}. Elas entram na conversa com '
                  'naturalidade, sem parecer questionário.',
              trailing: _CountPill(count: count),
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 200),
              alignment: Alignment.topCenter,
              child: _QuestionsMessage(
                error: _submitted && count < Profile.minQuestions,
                full: _fullHint,
              ),
            ),
            const SizedBox(height: 8),
            for (var i = 0; i < kQuestions.length; i++)
              _QuestionTile(
                text: kQuestions[i],
                selected: d.questions.contains(i),
                onTap: () => _toggle(i),
              ),
            const SizedBox(height: 40),
            const _SectionHeader(
              number: 4,
              title: 'Algo que ajude a conversa?',
              subtitle:
                  'Opcional. Assuntos favoritos, cuidados de saúde, '
                  'jeito de falar.',
            ),
            const SizedBox(height: 16),
            _NoteSuggestions(draft: d),
            const SizedBox(height: 12),
            TextField(
              controller: d.notes,
              minLines: 4,
              maxLines: 8,
              maxLength: 800,
              textCapitalization: TextCapitalization.sentences,
              style: AppText.bodyLg.copyWith(color: AppColors.onSurface),
              decoration: const InputDecoration(
                hintText:
                    'Ex.: adora falar das plantas do quintal e escuta '
                    'pouco do ouvido esquerdo.',
              ),
            ),
          ],
        );
      },
    );
  }
}

class _InlineMessage extends StatelessWidget {
  const _InlineMessage({required this.error, required this.text});
  final bool error;
  final String text;

  @override
  Widget build(BuildContext context) {
    final color = error ? AppColors.error : AppColors.onSurfaceMuted;
    return Semantics(
      liveRegion: error,
      child: Row(
        children: [
          Icon(
            error ? Icons.error_outline_rounded : Icons.touch_app_outlined,
            size: 18,
            color: color,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text, style: AppText.bodyMd.copyWith(color: color)),
          ),
        ],
      ),
    );
  }
}

class _CountPill extends StatelessWidget {
  const _CountPill({required this.count});
  final int count;

  @override
  Widget build(BuildContext context) {
    final ok = count >= Profile.minQuestions;
    return Semantics(
      label: '$count de ${Profile.maxQuestions} perguntas selecionadas',
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: ok ? AppColors.primary : AppColors.surfaceMint,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          '$count/${Profile.maxQuestions}',
          style: AppText.labelMd.copyWith(
            color: ok ? AppColors.onPrimary : AppColors.onSurface,
          ),
        ),
      ),
    );
  }
}

class _QuestionsMessage extends StatelessWidget {
  const _QuestionsMessage({required this.error, required this.full});
  final bool error;
  final bool full;

  @override
  Widget build(BuildContext context) {
    if (!error && !full) return const SizedBox(width: double.infinity);
    final color = error ? AppColors.error : AppColors.primary;
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Semantics(
        liveRegion: true,
        child: Row(
          children: [
            Icon(
              error ? Icons.error_outline_rounded : Icons.info_outline_rounded,
              size: 18,
              color: color,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                error
                    ? 'Escolha pelo menos ${Profile.minQuestions} perguntas '
                          'para continuar.'
                    : 'Você já escolheu ${Profile.maxQuestions}. Desmarque '
                          'uma para trocar.',
                style: AppText.bodyMd.copyWith(color: color),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuestionTile extends StatelessWidget {
  const _QuestionTile({
    required this.text,
    required this.selected,
    required this.onTap,
  });
  final String text;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Semantics(
        checked: selected,
        button: true,
        child: Material(
          color: selected ? AppColors.surfaceMint : AppColors.surfaceCard,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
            side: BorderSide(
              color: selected ? AppColors.primary : AppColors.inputBorder,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(AppRadius.md),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 56),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        color: selected
                            ? AppColors.primary
                            : AppColors.surfaceCard,
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                        border: Border.all(
                          color: selected
                              ? AppColors.primary
                              : AppColors.secondary,
                          width: 1.5,
                        ),
                      ),
                      child: selected
                          ? const Icon(
                              Icons.check_rounded,
                              size: 16,
                              color: AppColors.tertiary,
                            )
                          : null,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        text,
                        style: AppText.bodyLg.copyWith(
                          color: AppColors.onSurface,
                          fontSize: 15,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Seletor de dias da semana + atalhos comuns.
class _DaySelector extends StatelessWidget {
  const _DaySelector({required this.draft});
  final ProfileDraft draft;

  static const _letters = {
    7: 'D',
    1: 'S',
    2: 'T',
    3: 'Q',
    4: 'Q',
    5: 'S',
    6: 'S',
  };

  static const _presets = [
    ('Todos os dias', [1, 2, 3, 4, 5, 6, 7]),
    ('Seg a sex', [1, 2, 3, 4, 5]),
    ('Fim de semana', [6, 7]),
  ];

  @override
  Widget build(BuildContext context) {
    final days = draft.days;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            for (final wd in kWeekdayOrder) ...[
              if (wd != kWeekdayOrder.first) const SizedBox(width: 6),
              Expanded(
                child: Semantics(
                  label: kWeekdayLong[wd],
                  checked: days.contains(wd),
                  button: true,
                  excludeSemantics: true,
                  child: Material(
                    color: days.contains(wd)
                        ? AppColors.primary
                        : AppColors.surfaceCard,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      side: BorderSide(
                        color: days.contains(wd)
                            ? AppColors.primary
                            : AppColors.inputBorder,
                      ),
                    ),
                    child: InkWell(
                      onTap: () => draft.toggleDay(wd),
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      child: SizedBox(
                        height: 52,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _letters[wd]!,
                              style: AppText.labelLg.copyWith(
                                color: days.contains(wd)
                                    ? AppColors.onPrimary
                                    : AppColors.onSurface,
                              ),
                            ),
                            Text(
                              kWeekdayShort[wd]!,
                              style: AppText.labelSm.copyWith(
                                fontSize: 10,
                                color: days.contains(wd)
                                    ? AppColors.onPrimaryMuted
                                    : AppColors.onSurfaceMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final (label, preset) in _presets)
              _PresetChip(
                label: label,
                active:
                    days.length == preset.length && days.containsAll(preset),
                onTap: () => draft.setDays(preset),
              ),
          ],
        ),
      ],
    );
  }
}

class _PresetChip extends StatelessWidget {
  const _PresetChip({
    required this.label,
    required this.active,
    required this.onTap,
  });
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: active,
      child: Material(
        color: active ? AppColors.surfaceMint : AppColors.surfaceCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(999),
          side: BorderSide(
            color: active ? AppColors.primary : AppColors.inputBorder,
          ),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(999),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            child: Text(
              label,
              style: AppText.labelMd.copyWith(color: AppColors.onSurface),
            ),
          ),
        ),
      ),
    );
  }
}

/// Seletor de horário: período (manhã/tarde/noite) + horários de 30 em 30.
class _TimeSelector extends StatefulWidget {
  const _TimeSelector({required this.draft});
  final ProfileDraft draft;

  @override
  State<_TimeSelector> createState() => _TimeSelectorState();
}

class _TimeSelectorState extends State<_TimeSelector> {
  static List<TimeOfDay> _range(int from, int toHour, {bool lastHalf = true}) =>
      [
        for (var h = from; h <= toHour; h++) ...[
          TimeOfDay(hour: h, minute: 0),
          if (h < toHour || lastHalf) TimeOfDay(hour: h, minute: 30),
        ],
      ];

  static final _periods = [
    ('Manhã', Icons.wb_twilight_rounded, _range(8, 11)),
    ('Tarde', Icons.wb_sunny_outlined, _range(13, 17)),
    ('Noite', Icons.nights_stay_outlined, _range(18, 20, lastHalf: false)),
  ];

  static int _periodOf(TimeOfDay t) => t.hour < 12 ? 0 : (t.hour < 18 ? 1 : 2);

  late int _period = widget.draft.time == null
      ? 0
      : _periodOf(widget.draft.time!);

  @override
  Widget build(BuildContext context) {
    final time = widget.draft.time;
    final times = [..._periods[_period].$3];
    // Horário salvo fora da grade (ex.: 12:15) continua visível e selecionado.
    if (time != null && _periodOf(time) == _period && !times.contains(time)) {
      times
        ..add(time)
        ..sort((a, b) => (a.hour * 60 + a.minute) - (b.hour * 60 + b.minute));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: AppColors.surfaceCard,
            borderRadius: BorderRadius.circular(AppRadius.sm),
            border: Border.all(color: AppColors.inputBorder),
          ),
          child: Row(
            children: [
              for (var i = 0; i < _periods.length; i++)
                Expanded(
                  child: Semantics(
                    selected: i == _period,
                    button: true,
                    child: InkWell(
                      onTap: () => setState(() => _period = i),
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        height: 40,
                        decoration: BoxDecoration(
                          color: i == _period
                              ? AppColors.primary
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(AppRadius.sm),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              _periods[i].$2,
                              size: 16,
                              color: i == _period
                                  ? AppColors.tertiary
                                  : AppColors.onSurfaceMuted,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              _periods[i].$1,
                              style: AppText.labelMd.copyWith(
                                color: i == _period
                                    ? AppColors.onPrimary
                                    : AppColors.onSurface,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, c) {
            const cols = 4, gap = 8.0;
            final w = (c.maxWidth - gap * (cols - 1)) / cols;
            return Wrap(
              spacing: gap,
              runSpacing: gap,
              children: [
                for (final t in times)
                  SizedBox(
                    width: w,
                    child: _TimeChip(
                      label: _hhmm(t),
                      selected: t == time,
                      onTap: () => widget.draft.setTime(t),
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _TimeChip extends StatelessWidget {
  const _TimeChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      selected: selected,
      button: true,
      child: Material(
        color: selected ? AppColors.primary : AppColors.surfaceCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          side: BorderSide(
            color: selected ? AppColors.primary : AppColors.inputBorder,
          ),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.sm),
          child: SizedBox(
            height: 44,
            child: Center(
              child: Text(
                label,
                style: AppText.labelMd.copyWith(
                  color: selected ? AppColors.onPrimary : AppColors.onSurface,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NoteSuggestions extends StatelessWidget {
  const _NoteSuggestions({required this.draft});
  final ProfileDraft draft;

  static const _items = [
    'Gosta de falar sobre novela',
    'Escuta pouco, falar devagar',
    'Toma remédio de pressão pela manhã',
    'Adora falar da família',
  ];

  @override
  Widget build(BuildContext context) {
    final notes = draft.notes.text.toLowerCase();
    final left = _items.where((s) => !notes.contains(s.toLowerCase())).toList();
    if (left.isEmpty) return const SizedBox.shrink();
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final s in left)
          ActionChip(
            onPressed: () => draft.appendNote(s),
            avatar: const Icon(Icons.add_rounded, size: 16),
            label: Text(s),
            labelStyle: AppText.bodySm.copyWith(color: AppColors.onSurface),
            backgroundColor: AppColors.surfaceCard,
            side: const BorderSide(color: AppColors.inputBorder),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(999),
            ),
            iconTheme: const IconThemeData(color: AppColors.primary),
          ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Painel lateral (desktop)
// ---------------------------------------------------------------------------

class _BrandPanel extends StatelessWidget {
  const _BrandPanel({required this.draft, required this.step});
  final ProfileDraft draft;
  final int step;

  static const _steps = [
    ('Contatos', 'Quem recebe a ligação e o resumo'),
    ('Ligação', 'Horário e o que perguntar'),
    ('Calendário', 'Acompanhe cada conversa'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(AppRadius.xl),
      ),
      child: CustomPaint(
        painter: ContourPainter(opacity: 0.14),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(48, 40, 48, 48),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Wordmark(onDark: true, height: 44),
              const Spacer(),
              Text(
                'Uma ligação carinhosa.\nUm resumo para você.',
                style: AppText.display.copyWith(color: AppColors.onPrimary),
              ),
              const SizedBox(height: 16),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Text(
                  'Ligamos nos dias e no horário que você escolher, '
                  'conversamos como um amigo e mandamos para você o que '
                  'importa.',
                  style: AppText.bodyLg.copyWith(
                    color: AppColors.onPrimaryMuted,
                  ),
                ),
              ),
              const SizedBox(height: 32),
              for (var i = 0; i < _steps.length; i++)
                _PanelStep(
                  index: i,
                  current: step,
                  title: _steps[i].$1,
                  subtitle: _steps[i].$2,
                ),
              const Spacer(),
              ListenableBuilder(
                listenable: draft,
                builder: (context, _) => _PreviewChip(draft: draft),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PanelStep extends StatelessWidget {
  const _PanelStep({
    required this.index,
    required this.current,
    required this.title,
    required this.subtitle,
  });
  final int index;
  final int current;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final done = index < current;
    final active = index == current;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            width: 28,
            height: 28,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: done ? AppColors.tertiary : Colors.transparent,
              shape: BoxShape.circle,
              border: Border.all(
                color: done || active
                    ? AppColors.tertiary
                    : AppColors.secondary,
                width: 1.5,
              ),
            ),
            child: done
                ? const Icon(
                    Icons.check_rounded,
                    size: 16,
                    color: AppColors.onTertiary,
                  )
                : Text(
                    '${index + 1}',
                    style: AppText.labelSm.copyWith(
                      color: active ? AppColors.tertiary : AppColors.secondary,
                    ),
                  ),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppText.labelMd.copyWith(
                  color: active
                      ? AppColors.onPrimary
                      : AppColors.onPrimaryMuted,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: AppText.bodySm.copyWith(
                  color: AppColors.onPrimaryMuted.withValues(alpha: 0.8),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Chip flutuante que mostra "o produto em ação" com os dados digitados.
class _PreviewChip extends StatelessWidget {
  const _PreviewChip({required this.draft});
  final ProfileDraft draft;

  @override
  Widget build(BuildContext context) {
    final name = draft.elderFirstName.isEmpty ? 'Maria' : draft.elderFirstName;
    final phone = draft.familyPhone.text.trim();
    return Container(
      constraints: const BoxConstraints(maxWidth: 400),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(AppRadius.md),
        boxShadow: chipShadow,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.surfaceMint,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.surfaceCard, width: 2),
            ),
            child: Text(
              name[0].toUpperCase(),
              style: AppText.labelLg.copyWith(color: AppColors.primary),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Resumo de hoje · '
                        '${_hhmm(_addMinutes(draft.time ?? const TimeOfDay(hour: 10, minute: 0), 14))}',
                        style: AppText.labelSm.copyWith(
                          color: AppColors.onSurfaceMuted,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceLimeWash,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        'Tudo bem',
                        style: AppText.labelSm.copyWith(
                          color: AppColors.onSurface,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  '$name atendeu e conversou por 12 minutos. Está bem, '
                  'tomou o remédio e almoçou com a vizinha.',
                  style: AppText.bodyMd.copyWith(color: AppColors.onSurface),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(
                      Icons.chat_outlined,
                      size: 14,
                      color: AppColors.onSurfaceMuted,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      phone.isEmpty
                          ? 'Enviado para o seu WhatsApp'
                          : 'Enviado para $phone',
                      style: AppText.bodySm.copyWith(
                        color: AppColors.onSurfaceMuted,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Configurações
// ---------------------------------------------------------------------------

/// Edita tudo do cadastro e salva no localStorage.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key, required this.state});
  final AppState state;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late final _draft = ProfileDraft(widget.state.profile);
  final _contactsKey = GlobalKey<ContactFieldsState>();
  final _callKey = GlobalKey<CallFieldsState>();

  @override
  void dispose() {
    _draft.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_contactsKey.currentState!.validate()) return;
    if (!_callKey.currentState!.validate()) return;
    await widget.state.saveProfile(_draft.build());
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Alterações salvas')));
    Navigator.of(context).pop();
  }

  Future<void> _reset() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.neutral,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        title: Text('Apagar cadastro?', style: AppText.headlineMd),
        content: Text(
          'Os dados e recados salvos neste navegador serão removidos e você '
          'volta para o início do cadastro.',
          style: AppText.bodyMd,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Apagar'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    Navigator.of(context).popUntil((r) => r.isFirst);
    await widget.state.reset();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.neutral,
      appBar: AppBar(
        backgroundColor: AppColors.neutral,
        surfaceTintColor: Colors.transparent,
        title: Text('Configurações', style: AppText.labelLg),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(top: 16, bottom: 32),
              child: Constrained(
                maxWidth: _formMaxWidth + 32,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ContactFields(key: _contactsKey, draft: _draft),
                    const SizedBox(height: 16),
                    Divider(color: AppColors.secondary.withValues(alpha: 0.35)),
                    const SizedBox(height: 24),
                    CallFields(key: _callKey, draft: _draft),
                    const SizedBox(height: 32),
                    Center(
                      child: TextButton.icon(
                        onPressed: _reset,
                        icon: const Icon(
                          Icons.delete_outline_rounded,
                          size: 18,
                        ),
                        label: const Text('Apagar cadastro e recomeçar'),
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.onSurfaceMuted,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          _BottomBar(
            child: PrimaryButton(
              expand: true,
              height: 52,
              label: 'Salvar alterações',
              icon: Icons.check_rounded,
              onPressed: _save,
            ),
          ),
        ],
      ),
    );
  }
}
