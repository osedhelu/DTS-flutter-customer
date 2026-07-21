import 'package:flutter/material.dart';

class DynamicFieldsForm extends StatefulWidget {
  const DynamicFieldsForm({
    super.key,
    required this.fieldConfig,
    required this.onChanged,
    this.initialValues = const {},
  });

  final Map<String, dynamic> fieldConfig;
  final Map<String, dynamic> initialValues;
  final ValueChanged<Map<String, dynamic>> onChanged;

  @override
  State<DynamicFieldsForm> createState() => _DynamicFieldsFormState();
}

class _DynamicFieldsFormState extends State<DynamicFieldsForm> {
  late final Map<String, dynamic> _values;

  @override
  void initState() {
    super.initState();
    _values = Map<String, dynamic>.from(widget.initialValues);
  }

  void _notify() => widget.onChanged(_values);

  @override
  Widget build(BuildContext context) {
    if (widget.fieldConfig.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Detalles del servicio',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        ...widget.fieldConfig.entries.map((entry) {
          final key = entry.key;
          final config = entry.value;
          if (config is List) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: DropdownButtonFormField<String>(
                decoration: InputDecoration(labelText: key),
                value: _values[key]?.toString(),
                items: config
                    .map(
                      (option) => DropdownMenuItem<String>(
                        value: option.toString(),
                        child: Text(option.toString()),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  setState(() => _values[key] = value);
                  _notify();
                },
              ),
            );
          }
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: TextFormField(
              initialValue: _values[key]?.toString() ?? '',
              decoration: InputDecoration(labelText: key),
              onChanged: (value) {
                _values[key] = value;
                _notify();
              },
            ),
          );
        }),
      ],
    );
  }
}

String formatDynamicValuesNotes(Map<String, dynamic> values) {
  if (values.isEmpty) return '';
  final lines = values.entries
      .map((e) => '${e.key}: ${e.value}')
      .join('\n');
  return 'Detalles del servicio:\n$lines';
}
