import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/ks_status_chip.dart';

class ScientificCalculatorDialog extends StatefulWidget {
  const ScientificCalculatorDialog({super.key});

  @override
  State<ScientificCalculatorDialog> createState() =>
      _ScientificCalculatorDialogState();
}

class _ScientificCalculatorDialogState
    extends State<ScientificCalculatorDialog> {
  String _expression = '';
  String _result = '0';
  bool _degreeMode = true;

  static const List<String> _buttons = [
    'sin',
    'cos',
    'tan',
    'ln',
    'log',
    '√',
    '(',
    ')',
    '^',
    'π',
    'e',
    'AC',
    '7',
    '8',
    '9',
    '÷',
    '%',
    '⌫',
    '4',
    '5',
    '6',
    '×',
    '1/x',
    '±',
    '1',
    '2',
    '3',
    '−',
    '=',
    '0',
    '.',
    '+',
  ];

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final mediaQuery = MediaQuery.of(context);
    final availableWidth = mediaQuery.size.width - 40;
    final availableHeight =
        mediaQuery.size.height -
        mediaQuery.padding.vertical -
        mediaQuery.viewInsets.vertical -
        48;
    final dialogWidth = math.min(560.0, availableWidth);
    final dialogHeight = math.min(780.0, availableHeight);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: SizedBox(
        width: dialogWidth,
        height: dialogHeight,
        child: GlassCard(
          tone: GlassCardTone.primary,
          showGlow: true,
          padding: const EdgeInsets.all(20),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final compactWidth = constraints.maxWidth < 480;
              final compactHeight = constraints.maxHeight < 760;
              final bodySpacing = compactHeight ? 12.0 : 16.0;
              final displayPadding = compactHeight ? 14.0 : 16.0;
              final expressionFontSize = compactHeight ? 16.0 : 18.0;
              final resultFontSize = compactHeight ? 28.0 : 34.0;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(context, compactWidth),
                  const SizedBox(height: 8),
                  Text(
                    'Use the calculator without leaving the exam workspace.',
                    style: TextStyle(
                      color: cs.onSurface.withValues(alpha: 0.74),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: bodySpacing),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.only(right: 2),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: double.infinity,
                            padding: EdgeInsets.all(displayPadding),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              color: Colors.white.withValues(alpha: 0.05),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.08),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: [
                                      KsStatusChip(
                                        label: _degreeMode
                                            ? 'Degree Mode'
                                            : 'Radian Mode',
                                        tone: KsStatusChipTone.accent,
                                      ),
                                      if (_expression.isNotEmpty)
                                        const KsStatusChip(
                                          label: 'Expression Active',
                                          tone: KsStatusChipTone.info,
                                        ),
                                    ],
                                  ),
                                ),
                                SizedBox(height: bodySpacing),
                                SizedBox(
                                  width: double.infinity,
                                  child: SelectableText(
                                    _expression.isEmpty
                                        ? '0'
                                        : _displayExpression(_expression),
                                    textAlign: TextAlign.right,
                                    style: TextStyle(
                                      color: cs.onSurface.withValues(
                                        alpha: 0.76,
                                      ),
                                      fontSize: expressionFontSize,
                                      fontWeight: FontWeight.w700,
                                      fontFamily: 'Courier New',
                                      fontFamilyFallback: const [
                                        'Consolas',
                                        'monospace',
                                      ],
                                    ),
                                  ),
                                ),
                                SizedBox(height: compactHeight ? 8 : 10),
                                SizedBox(
                                  width: double.infinity,
                                  child: Text(
                                    _result,
                                    textAlign: TextAlign.right,
                                    style: TextStyle(
                                      color: _result == 'Error'
                                          ? cs.error
                                          : cs.primary,
                                      fontSize: resultFontSize,
                                      fontWeight: FontWeight.w900,
                                      fontFamily: 'Courier New',
                                      fontFamilyFallback: const [
                                        'Consolas',
                                        'monospace',
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: bodySpacing),
                          LayoutBuilder(
                            builder: (context, keypadConstraints) {
                              final columns = keypadConstraints.maxWidth < 460
                                  ? 4
                                  : 6;
                              final childAspectRatio =
                                  keypadConstraints.maxWidth < 460
                                  ? (compactHeight ? 1.0 : 1.16)
                                  : (compactHeight ? 1.08 : 1.28);

                              return GridView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: _buttons.length,
                                gridDelegate:
                                    SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: columns,
                                      mainAxisSpacing: 10,
                                      crossAxisSpacing: 10,
                                      childAspectRatio: childAspectRatio,
                                    ),
                                itemBuilder: (context, index) {
                                  final label = _buttons[index];
                                  return _CalculatorButton(
                                    label: label,
                                    onTap: () => _handleTap(label),
                                    tone: _toneForLabel(label),
                                  );
                                },
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool compactWidth) {
    final title = const Text(
      'Scientific Calculator',
      style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
    );
    final modeToggle = SegmentedButton<bool>(
      segments: const [
        ButtonSegment<bool>(value: true, label: Text('DEG')),
        ButtonSegment<bool>(value: false, label: Text('RAD')),
      ],
      selected: {_degreeMode},
      onSelectionChanged: (selection) {
        setState(() => _degreeMode = selection.first);
      },
      showSelectedIcon: false,
    );
    final closeButton = IconButton(
      onPressed: () => Navigator.of(context).pop(),
      icon: const Icon(Icons.close_rounded),
    );

    if (compactWidth) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.calculate_outlined),
              const SizedBox(width: 10),
              Expanded(child: title),
              closeButton,
            ],
          ),
          const SizedBox(height: 12),
          Align(alignment: Alignment.centerRight, child: modeToggle),
        ],
      );
    }

    return Row(
      children: [
        const Icon(Icons.calculate_outlined),
        const SizedBox(width: 10),
        Expanded(child: title),
        modeToggle,
        const SizedBox(width: 8),
        closeButton,
      ],
    );
  }

  void _handleTap(String label) {
    switch (label) {
      case 'AC':
        setState(() {
          _expression = '';
          _result = '0';
        });
        return;
      case '⌫':
        setState(() {
          if (_expression.isNotEmpty) {
            _expression = _expression.substring(0, _expression.length - 1);
          }
          if (_expression.isEmpty) {
            _result = '0';
          }
        });
        return;
      case '=':
        _evaluate(commitResultToExpression: true);
        return;
      case '±':
        setState(() => _expression = _toggleSign(_expression));
        _previewEvaluate();
        return;
      case '1/x':
        setState(() {
          if (_expression.trim().isEmpty) {
            _expression = '1/';
          } else {
            _expression = '1/($_expression)';
          }
        });
        _previewEvaluate();
        return;
      default:
        setState(() => _expression += _mappedToken(label));
        _previewEvaluate();
        return;
    }
  }

  void _previewEvaluate() {
    if (_expression.trim().isEmpty) {
      setState(() => _result = '0');
      return;
    }

    try {
      final value = _ScientificExpressionParser(
        source: _expression,
        degreeMode: _degreeMode,
      ).parse();
      setState(() => _result = _formatValue(value));
    } catch (_) {
      setState(() => _result = 'Error');
    }
  }

  void _evaluate({required bool commitResultToExpression}) {
    if (_expression.trim().isEmpty) return;

    try {
      final value = _ScientificExpressionParser(
        source: _expression,
        degreeMode: _degreeMode,
      ).parse();
      final formatted = _formatValue(value);
      setState(() {
        _result = formatted;
        if (commitResultToExpression) {
          _expression = formatted;
        }
      });
    } catch (_) {
      setState(() => _result = 'Error');
    }
  }

  String _mappedToken(String label) {
    switch (label) {
      case '×':
        return '*';
      case '÷':
        return '/';
      case '−':
        return '-';
      case 'π':
        return 'pi';
      case '√':
        return 'sqrt(';
      case 'sin':
      case 'cos':
      case 'tan':
      case 'ln':
      case 'log':
        return '$label(';
      default:
        return label;
    }
  }

  String _toggleSign(String source) {
    final trimmed = source.trimRight();
    if (trimmed.isEmpty) return '-';

    final match = RegExp(r'(\d+(\.\d+)?)$').firstMatch(trimmed);
    if (match == null) {
      return '$trimmed-';
    }

    final start = match.start;
    final end = match.end;
    final prefix = trimmed.substring(0, start);
    final value = trimmed.substring(start, end);

    if (prefix.endsWith('-')) {
      return '${prefix.substring(0, prefix.length - 1)}$value';
    }
    return '$prefix-$value';
  }

  String _displayExpression(String source) {
    return source
        .replaceAll('sqrt', '√')
        .replaceAll('*', '×')
        .replaceAll('/', '÷')
        .replaceAll('-', '−')
        .replaceAll('pi', 'π');
  }

  String _formatValue(double value) {
    if (!value.isFinite) {
      throw const FormatException('Non-finite');
    }
    final rounded = double.parse(value.toStringAsPrecision(12));
    if ((rounded - rounded.roundToDouble()).abs() < 0.0000000001) {
      return rounded.round().toString();
    }
    return rounded.toString();
  }

  GlassCardTone _toneForLabel(String label) {
    switch (label) {
      case '=':
        return GlassCardTone.success;
      case 'AC':
      case '⌫':
        return GlassCardTone.warning;
      case '÷':
      case '×':
      case '−':
      case '+':
      case '^':
      case 'sin':
      case 'cos':
      case 'tan':
      case 'ln':
      case 'log':
      case '√':
      case '1/x':
        return GlassCardTone.primary;
      default:
        return GlassCardTone.normal;
    }
  }
}

class _CalculatorButton extends StatelessWidget {
  const _CalculatorButton({
    required this.label,
    required this.onTap,
    required this.tone,
  });

  final String label;
  final VoidCallback onTap;
  final GlassCardTone tone;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      tone: tone,
      padding: EdgeInsets.zero,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          child: Center(
            child: Text(
              label,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
            ),
          ),
        ),
      ),
    );
  }
}

class _ScientificExpressionParser {
  _ScientificExpressionParser({required this.source, required this.degreeMode});

  final String source;
  final bool degreeMode;
  int _index = 0;

  double parse() {
    final value = _parseExpression();
    _skipWhitespace();
    if (_index != source.length) {
      throw const FormatException('Unexpected token');
    }
    if (!value.isFinite) {
      throw const FormatException('Invalid result');
    }
    return value;
  }

  double _parseExpression() {
    var value = _parseTerm();
    while (true) {
      _skipWhitespace();
      if (_consume('+')) {
        value += _parseTerm();
      } else if (_consume('-')) {
        value -= _parseTerm();
      } else {
        return value;
      }
    }
  }

  double _parseTerm() {
    var value = _parsePower();
    while (true) {
      _skipWhitespace();
      if (_consume('*')) {
        value *= _parsePower();
      } else if (_consume('/')) {
        final divisor = _parsePower();
        if (divisor == 0) {
          throw const FormatException('Division by zero');
        }
        value /= divisor;
      } else {
        return value;
      }
    }
  }

  double _parsePower() {
    var value = _parseUnary();
    _skipWhitespace();
    if (_consume('^')) {
      value = math.pow(value, _parsePower()).toDouble();
    }
    return value;
  }

  double _parseUnary() {
    _skipWhitespace();
    if (_consume('+')) return _parseUnary();
    if (_consume('-')) return -_parseUnary();

    final identifier = _parseIdentifier();
    if (identifier != null) {
      if (identifier == 'pi') return math.pi;
      if (identifier == 'e') return math.e;

      final argument = _parseUnary();
      return _applyFunction(identifier, argument);
    }

    return _parsePostfix();
  }

  double _parsePostfix() {
    var value = _parsePrimary();
    while (true) {
      _skipWhitespace();
      if (_consume('%')) {
        value /= 100;
      } else {
        return value;
      }
    }
  }

  double _parsePrimary() {
    _skipWhitespace();

    if (_consume('(')) {
      final value = _parseExpression();
      _skipWhitespace();
      if (!_consume(')')) {
        throw const FormatException('Missing closing parenthesis');
      }
      return value;
    }

    return _parseNumber();
  }

  double _parseNumber() {
    _skipWhitespace();
    final start = _index;
    var dotSeen = false;

    while (_index < source.length) {
      final char = source[_index];
      if (char == '.') {
        if (dotSeen) break;
        dotSeen = true;
        _index += 1;
        continue;
      }
      if (_isDigit(char)) {
        _index += 1;
        continue;
      }
      break;
    }

    if (start == _index) {
      throw const FormatException('Expected number');
    }

    return double.parse(source.substring(start, _index));
  }

  double _applyFunction(String function, double argument) {
    switch (function) {
      case 'sin':
        return math.sin(_normalizedAngle(argument));
      case 'cos':
        return math.cos(_normalizedAngle(argument));
      case 'tan':
        return math.tan(_normalizedAngle(argument));
      case 'ln':
        if (argument <= 0) throw const FormatException('Invalid ln');
        return math.log(argument);
      case 'log':
        if (argument <= 0) throw const FormatException('Invalid log');
        return math.log(argument) / math.ln10;
      case 'sqrt':
        if (argument < 0) throw const FormatException('Invalid sqrt');
        return math.sqrt(argument);
      default:
        throw const FormatException('Unknown function');
    }
  }

  double _normalizedAngle(double value) {
    if (!degreeMode) return value;
    return value * math.pi / 180;
  }

  String? _parseIdentifier() {
    _skipWhitespace();
    final start = _index;
    while (_index < source.length && _isLetter(source[_index])) {
      _index += 1;
    }

    if (start == _index) return null;
    return source.substring(start, _index);
  }

  bool _consume(String char) {
    if (_index < source.length && source[_index] == char) {
      _index += 1;
      return true;
    }
    return false;
  }

  void _skipWhitespace() {
    while (_index < source.length && source[_index].trim().isEmpty) {
      _index += 1;
    }
  }

  bool _isDigit(String char) =>
      char.codeUnitAt(0) >= 48 && char.codeUnitAt(0) <= 57;

  bool _isLetter(String char) {
    final code = char.codeUnitAt(0);
    return (code >= 65 && code <= 90) || (code >= 97 && code <= 122);
  }
}
