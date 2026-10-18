import 'package:alo_diario/widgets.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

TextEditingValue _v(String text, int cursor) => TextEditingValue(
  text: text,
  selection: TextSelection.collapsed(offset: cursor),
);

void main() {
  final f = PhoneInputFormatter();

  group('PhoneInputFormatter', () {
    test('formata celular e fixo', () {
      expect(
        f.formatEditUpdate(_v('', 0), _v('11987654321', 11)).text,
        '(11) 98765-4321',
      );
      expect(
        f.formatEditUpdate(_v('', 0), _v('1134567890', 10)).text,
        '(11) 3456-7890',
      );
    });

    test('edição no meio mantém o cursor no lugar', () {
      // Apaga o "3" de "(11) 98765-4321" (cursor logo após ele).
      const old = '(11) 98765-4321';
      final r = f.formatEditUpdate(_v(old, 13), _v('(11) 98765-421', 12));
      expect(r.text, '(11) 9876-5421');
      expect(r.text.substring(0, r.selection.baseOffset), '(11) 9876-54');
    });

    test('backspace sobre caractere da máscara apaga o dígito anterior', () {
      // Cursor logo após o "-" em "(11) 98765-4321" (offset 11).
      const old = '(11) 98765-4321';
      final r = f.formatEditUpdate(_v(old, 11), _v('(11) 987654321', 10));
      expect(r.text, '(11) 9876-4321');
    });

    test('limita a 11 dígitos', () {
      expect(
        f.formatEditUpdate(_v('', 0), _v('119876543210000', 15)).text,
        '(11) 98765-4321',
      );
    });
  });

  group('validatePhone', () {
    test('casos inválidos', () {
      expect(validatePhone(''), isNotNull);
      expect(validatePhone('(11) 9876'), contains('incompleto'));
      expect(validatePhone('(01) 98765-4321'), 'DDD inválido');
      expect(validatePhone('(11) 88765-4321'), contains('começar com 9'));
      expect(
        validatePhone('(11) 3456-7890', mobileOnly: true),
        contains('celular'),
      );
      expect(
        validatePhone('(11) 98765-4321', differentFrom: '11987654321'),
        isNotNull,
      );
    });

    test('casos válidos', () {
      expect(validatePhone('(11) 3456-7890'), isNull);
      expect(validatePhone('(21) 99876-5432', mobileOnly: true), isNull);
    });
  });

  test('validateName', () {
    expect(validateName('', emptyMessage: 'x'), 'x');
    expect(validateName('A', emptyMessage: 'x'), 'Nome muito curto');
    expect(validateName('Ana123', emptyMessage: 'x'), 'Use apenas letras');
    expect(validateName("Maria D'Ávila-Souza", emptyMessage: 'x'), isNull);
  });

  test('validateEmail', () {
    expect(validateEmail(''), isNotNull);
    expect(validateEmail('ana@'), contains('inválido'));
    expect(validateEmail('ana@gmial.com'), 'Você quis dizer @gmail.com?');
    expect(validateEmail(' Ana.Souza@Gmail.com '), isNull);
  });
}
