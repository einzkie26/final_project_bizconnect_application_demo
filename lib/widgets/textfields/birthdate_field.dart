import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../controllers/auth_controller.dart';

class BirthdateField extends ConsumerWidget {
  const BirthdateField({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);
    final authNotifier = ref.read(authControllerProvider.notifier);

    return GestureDetector(
      onTap: () async {
        DateTime? picked = await showDatePicker(
          context: context,
          initialDate: DateTime(2000),
          firstDate: DateTime(1900),
          lastDate: DateTime.now(),
        );

        if (picked != null) {
          authNotifier.setBirthdate(
              "${picked.year}-${picked.month}-${picked.day}");
        }
      },
      child: Container(
        width: 320,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        decoration: BoxDecoration(
          color: const Color(0xFFF8EAEF),
          borderRadius: BorderRadius.circular(30),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today, color: Colors.deepPurple),
            const SizedBox(width: 12),
            Text(
              authState.selectedBirthdate ?? "Birthdate",
              style: const TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}