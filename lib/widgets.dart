import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'models.dart';
import 'theme.dart';

class Wordmark extends StatelessWidget {
  const Wordmark({super.key, this.onDark = false});
  final bool onDark;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: const BoxDecoration(
            color: AppColors.tertiary,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.call_rounded,
            size: 16,
            color: AppColors.onTertiary,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          'Alô Diário',
          style: AppText.labelLg.copyWith(
            color: onDark ? AppColors.onPrimary : AppColors.primaryDeep,
            letterSpacing: -0.3,
          ),
        ),
      ],
    );
  }
}

class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.expand = false,
    this.height = 44,
  });
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool expand;
  final double height;

  @override
  Widget build(BuildContext context) {
    final btn = FilledButton(
      onPressed: onPressed,
      style: ButtonStyle(
        minimumSize: WidgetStatePropertyAll(Size(0, height)),
        padding: const WidgetStatePropertyAll(
          EdgeInsets.symmetric(horizontal: 20),
        ),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
        ),
        textStyle: WidgetStatePropertyAll(AppText.labelMd),
        elevation: const WidgetStatePropertyAll(0),
        foregroundColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.disabled)
              ? AppColors.onSurfaceMuted
              : AppColors.onTertiary,
        ),
        backgroundColor: WidgetStateProperty.resolveWith((s) {
          if (s.contains(WidgetState.disabled)) return AppColors.inputBorder;
          if (s.contains(WidgetState.hovered) ||
              s.contains(WidgetState.pressed)) {
            return AppColors.tertiaryHover;
          }
          return AppColors.tertiary;
        }),
        overlayColor: const WidgetStatePropertyAll(Colors.transparent),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label),
          if (icon != null) ...[const SizedBox(width: 8), Icon(icon, size: 18)],
        ],
      ),
    );
    return expand ? SizedBox(width: double.infinity, child: btn) : btn;
  }
}

class SecondaryButton extends StatelessWidget {
  const SecondaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.onDark = false,
  });
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool onDark;

  @override
  Widget build(BuildContext context) {
    final fg = onDark ? AppColors.onPrimary : AppColors.primary;
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(0, 44),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        foregroundColor: fg,
        side: BorderSide(color: onDark ? AppColors.secondary : fg),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
        textStyle: AppText.labelMd,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[Icon(icon, size: 18), const SizedBox(width: 8)],
          Text(label),
        ],
      ),
    );
  }
}

/// Fundo creme → menta com linhas de contorno em sálvia (DESIGN.MD).
class ContourBackground extends StatelessWidget {
  const ContourBackground({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.neutral, AppColors.surfaceMint],
        ),
      ),
      child: CustomPaint(painter: ContourPainter(), child: child),
    );
  }
}

/// Linhas topográficas em sálvia, usadas como atmosfera de fundo.
class ContourPainter extends CustomPainter {
  ContourPainter({this.opacity = 0.18});
  final double opacity;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = AppColors.secondary.withValues(alpha: opacity);
    for (var i = 0; i < 9; i++) {
      final path = Path();
      final y0 = size.height * (0.15 + i * 0.1);
      for (double x = 0; x <= size.width; x += 8) {
        final y = y0 + sin(x / 180 + i * 0.7) * 28 + sin(x / 67 + i) * 6;
        x == 0 ? path.moveTo(x, y) : path.lineTo(x, y);
      }
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

String onlyDigits(String s) => s.replaceAll(RegExp(r'\D'), '');

String formatPhone(String digits) {
  final d = digits.length > 11 ? digits.substring(0, 11) : digits;
  final b = StringBuffer();
  for (var i = 0; i < d.length; i++) {
    if (i == 0) b.write('(');
    if (i == 2) b.write(') ');
    if (i == (d.length == 11 ? 7 : 6)) b.write('-');
    b.write(d[i]);
  }
  return b.toString();
}

/// Máscara para telefone brasileiro: (11) 91234-5678 ou (11) 3456-7890.
/// Mantém o cursor no lugar ao editar no meio e permite apagar "através"
/// dos caracteres da máscara.
class PhoneInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final cursor = newValue.selection.baseOffset.clamp(0, newValue.text.length);
    var digits = onlyDigits(newValue.text);
    var before = onlyDigits(newValue.text.substring(0, cursor)).length;

    // Backspace sobre "(", ")", " " ou "-": apaga o dígito anterior.
    final deletedMaskChar =
        newValue.text.length < oldValue.text.length &&
        digits == onlyDigits(oldValue.text);
    if (deletedMaskChar && before > 0) {
      digits = digits.substring(0, before - 1) + digits.substring(before);
      before--;
    }
    if (digits.length > 11) digits = digits.substring(0, 11);
    before = min(before, digits.length);

    final text = formatPhone(digits);
    var offset = 0;
    if (before > 0) {
      var seen = 0;
      for (var i = 0; i < text.length; i++) {
        if (RegExp(r'\d').hasMatch(text[i]) && ++seen == before) {
          offset = i + 1;
          break;
        }
      }
    } else if (text.isNotEmpty) {
      offset = 1; // depois do "("
    }
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: offset),
    );
  }
}

/// "maria DA silva" → "Maria da Silva".
String titleCaseName(String s) {
  const lower = {'da', 'de', 'do', 'das', 'dos', 'e'};
  final parts = s.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty);
  var i = 0;
  return parts
      .map((p) {
        final w = p.toLowerCase();
        if (i++ > 0 && lower.contains(w)) return w;
        return w[0].toUpperCase() + w.substring(1);
      })
      .join(' ');
}

/// Nome: obrigatório, só letras (com acento), espaço, hífen e apóstrofo.
String? validateName(String? v, {required String emptyMessage}) {
  final t = (v ?? '').trim();
  if (t.isEmpty) return emptyMessage;
  if (!RegExp(r"^[A-Za-zÀ-ÖØ-öø-ÿ' -]+$").hasMatch(t)) {
    return 'Use apenas letras';
  }
  if (t.replaceAll(RegExp(r"[' -]"), '').length < 2) return 'Nome muito curto';
  return null;
}

/// Telefone BR com DDD. [mobileOnly] exige celular (11 dígitos, começando
/// com 9). [differentFrom] impede repetir outro número do formulário.
String? validatePhone(
  String? v, {
  bool mobileOnly = false,
  String? differentFrom,
  String emptyMessage = 'Informe o telefone',
  String sameMessage = 'Os dois telefones são iguais',
}) {
  final d = onlyDigits(v ?? '');
  if (d.isEmpty) return emptyMessage;
  if (d.length < 10) return 'Número incompleto. Inclua o DDD.';
  if (!RegExp(r'^[1-9]{2}').hasMatch(d)) return 'DDD inválido';
  if (d.length == 11 && d[2] != '9') {
    return 'Celular deve começar com 9 após o DDD';
  }
  if (mobileOnly && d.length != 11) {
    return 'Informe um celular com WhatsApp (9 dígitos + DDD)';
  }
  if (differentFrom != null && onlyDigits(differentFrom) == d) {
    return sameMessage;
  }
  return null;
}

const _emailTypos = {
  'gmial.com': 'gmail.com',
  'gmai.com': 'gmail.com',
  'gmail.co': 'gmail.com',
  'gmail.con': 'gmail.com',
  'gamil.com': 'gmail.com',
  'hotmial.com': 'hotmail.com',
  'hotmail.con': 'hotmail.com',
  'hotmal.com': 'hotmail.com',
  'outlok.com': 'outlook.com',
  'outlook.con': 'outlook.com',
  'yahoo.con': 'yahoo.com',
};

String? validateEmail(String? v) {
  final t = (v ?? '').trim().toLowerCase();
  if (t.isEmpty) return 'Informe seu e-mail';
  if (!RegExp(
    r'^[a-z0-9._%+-]+@[a-z0-9-]+(\.[a-z0-9-]+)*\.[a-z]{2,}$',
  ).hasMatch(t)) {
    return 'E-mail inválido. Ex.: nome@gmail.com';
  }
  final domain = t.split('@').last;
  final fix = _emailTypos[domain];
  if (fix != null) return 'Você quis dizer @$fix?';
  return null;
}

/// Rótulo acima do campo, como no DESIGN.MD (sem label flutuante).
class LabeledField extends StatelessWidget {
  const LabeledField({super.key, required this.label, required this.child});
  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppText.labelMd.copyWith(color: AppColors.onSurface),
        ),
        const SizedBox(height: 6),
        child,
      ],
    );
  }
}

/// Cartão claro (branco ou degradê menta → lima) com borda sálvia.
class MintCard extends StatelessWidget {
  const MintCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.gradient = false,
  });
  final Widget child;
  final EdgeInsets padding;
  final bool gradient;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: gradient ? null : AppColors.surfaceCard,
        gradient: gradient
            ? const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [AppColors.surfaceMint, AppColors.surfaceLimeWash],
              )
            : null,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.secondary.withValues(alpha: 0.5)),
      ),
      child: child,
    );
  }
}

/// Visual de cada status. Lima marca "atenção" (é a ação pedida à família);
/// um vermelho sóbrio fica reservado para o status "vermelho" do backend.
class StatusStyle {
  const StatusStyle(this.bg, this.fg, this.icon, {this.border});
  final Color bg;
  final Color fg;
  final IconData icon;
  final Color? border;

  static StatusStyle of(CallStatus s) => switch (s) {
    CallStatus.verde => const StatusStyle(
      AppColors.surfaceMint,
      AppColors.primary,
      Icons.check_rounded,
    ),
    CallStatus.amarelo => const StatusStyle(
      AppColors.tertiary,
      AppColors.onTertiary,
      Icons.priority_high_rounded,
    ),
    CallStatus.vermelho => const StatusStyle(
      AppColors.error,
      Colors.white,
      Icons.warning_rounded,
    ),
    CallStatus.semLigacao => const StatusStyle(
      Colors.transparent,
      AppColors.onSurfaceMuted,
      Icons.phone_missed_rounded,
      border: AppColors.secondary,
    ),
  };
}

class StatusPill extends StatelessWidget {
  const StatusPill(this.status, {super.key});
  final CallStatus status;

  @override
  Widget build(BuildContext context) {
    final st = StatusStyle.of(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: st.bg,
        borderRadius: BorderRadius.circular(999),
        border: st.border != null ? Border.all(color: st.border!) : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(st.icon, size: 14, color: st.fg),
          const SizedBox(width: 4),
          Text(status.label, style: AppText.labelSm.copyWith(color: st.fg)),
        ],
      ),
    );
  }
}

/// Limita a largura do conteúdo e aplica o gutter lateral.
class Constrained extends StatelessWidget {
  const Constrained({
    super.key,
    required this.child,
    this.maxWidth = 1180,
    this.padding,
  });
  final Widget child;
  final double maxWidth;
  final EdgeInsets? padding;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Padding(
          padding: padding ?? const EdgeInsets.symmetric(horizontal: 16),
          child: child,
        ),
      ),
    );
  }
}
