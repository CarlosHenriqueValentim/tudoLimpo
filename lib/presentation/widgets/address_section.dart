// lib/presentation/widgets/address_section.dart
//
// Desafio 3 – CEP:
// Cada endereço tem seu próprio campo de CEP (cobrança e entrega).
// O widget recebe os controllers individualmente para maior clareza.

import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

/// Dados de um endereço de cobrança ou entrega.
class AddressData {
  final TextEditingController name;
  final TextEditingController street;
  final TextEditingController city;
  final TextEditingController state;
  final TextEditingController zip; // Desafio 3: campo CEP separado
  final TextEditingController? phone;

  const AddressData({
    required this.name,
    required this.street,
    required this.city,
    required this.state,
    required this.zip,
    this.phone,
  });

  String get fullAddress =>
      '${street.text}, ${city.text} – ${state.text}, CEP ${zip.text}';

  void copyFrom(AddressData other) {
    name.text = other.name.text;
    street.text = other.street.text;
    city.text = other.city.text;
    state.text = other.state.text;
    zip.text = other.zip.text;
  }

  void dispose() {
    name.dispose();
    street.dispose();
    city.dispose();
    state.dispose();
    zip.dispose();
    phone?.dispose();
  }
}

class AddressSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final AddressData data;

  const AddressSection({
    required this.title,
    required this.icon,
    required this.data,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final List<_FieldConfig> fields = <_FieldConfig>[
      _FieldConfig(label: 'Nome completo', controller: data.name),
      _FieldConfig(label: 'Rua e número', controller: data.street),
      _FieldConfig(label: 'Cidade', controller: data.city),
      _FieldConfig(label: 'UF', controller: data.state, maxLength: 2),
      // Desafio 3 – campo CEP independente por endereço
      _FieldConfig(label: 'CEP', controller: data.zip, maxLength: 9, hint: '00000-000'),
      if (data.phone != null)
        _FieldConfig(
          label: 'Telefone',
          controller: data.phone!,
          hint: '(00) 00000-0000',
          keyboardType: TextInputType.phone,
        ),
    ];

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Icon(icon, color: AppColors.primary),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ],
            ),
            const SizedBox(height: 12),
            for (final _FieldConfig f in fields)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: TextFormField(
                  controller: f.controller,
                  maxLength: f.maxLength,
                  keyboardType: f.keyboardType,
                  decoration: InputDecoration(
                    labelText: f.label,
                    hintText: f.hint,
                    border: const OutlineInputBorder(),
                    isDense: true,
                    counterText: '',
                  ),
                  validator: (String? v) =>
                  (v == null || v.trim().isEmpty) ? 'Campo obrigatório' : null,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _FieldConfig {
  final String label;
  final TextEditingController controller;
  final int? maxLength;
  final String? hint;
  final TextInputType keyboardType;

  const _FieldConfig({
    required this.label,
    required this.controller,
    this.maxLength,
    this.hint,
    this.keyboardType = TextInputType.text,
  });
}