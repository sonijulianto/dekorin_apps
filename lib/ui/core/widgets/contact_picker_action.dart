import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:dekorin_apps/config/theme/app_colors.dart';
import 'package:dekorin_apps/config/theme/app_typography.dart';
import 'package:dekorin_apps/data/services/contact_picker_service.dart';

/// Tombol chip ringkas untuk memicu pemilihan nomor HP dari kontak perangkat.
class ContactPickerChip extends StatelessWidget {
  const ContactPickerChip({
    super.key,
    required this.onTap,
    this.isLoading = false,
  });

  final VoidCallback? onTap;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) return const SizedBox.shrink();
    return InkWell(
      onTap: isLoading ? null : onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.goldLight,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.primaryGold.withValues(alpha: 0.4)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isLoading)
              const SizedBox(
                width: 13,
                height: 13,
                child: CircularProgressIndicator(
                  strokeWidth: 1.8,
                  color: AppColors.primaryGold,
                ),
              )
            else
              const Icon(Icons.contacts_outlined, size: 14, color: AppColors.primaryGold),
            const SizedBox(width: 4),
            Text(
              'Ambil dari Kontak',
              style: AppTypography.labelMedium.copyWith(
                fontSize: 11.5,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryGold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Membuka pemilih kontak perangkat dan mengisi [phoneController] serta
/// [nameController] (hanya jika field nama masih kosong).
Future<void> pickClientContactIntoFields({
  required BuildContext context,
  required WidgetRef ref,
  required TextEditingController phoneController,
  GlobalKey<FormFieldState<String>>? phoneFieldKey,
  TextEditingController? nameController,
  GlobalKey<FormFieldState<String>>? nameFieldKey,
}) async {
  FocusManager.instance.primaryFocus?.unfocus();
  final messenger = ScaffoldMessenger.of(context);

  try {
    final picked = await ref.read(contactPickerServiceProvider).pickPhoneContact();
    if (!context.mounted || picked == null) return;

    if (picked.phoneNumber.isEmpty) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              'Kontak yang dipilih tidak memiliki nomor HP.',
              style: AppTypography.bodyMedium.copyWith(color: Colors.white),
            ),
            backgroundColor: AppColors.warningAmber,
            duration: const Duration(seconds: 2),
          ),
        );
      return;
    }

    phoneController.text = picked.phoneNumber;
    phoneFieldKey?.currentState?.didChange(picked.phoneNumber);

    var filledName = false;
    if (nameController != null && nameController.text.trim().isEmpty && picked.name.isNotEmpty) {
      nameController.text = picked.name;
      nameFieldKey?.currentState?.didChange(picked.name);
      filledName = true;
    }

    final contactLabel = picked.name.isNotEmpty ? ' "${picked.name}"' : '';
    final message = filledName
        ? 'Nama & Nomor HP dari kontak$contactLabel berhasil diisi!'
        : 'Nomor HP dari kontak$contactLabel berhasil diisi!';

    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            message,
            style: AppTypography.bodyMedium.copyWith(color: Colors.white),
          ),
          backgroundColor: AppColors.successGreen,
          duration: const Duration(seconds: 2),
        ),
      );
  } catch (_) {
    if (!context.mounted) return;
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            'Gagal membuka kontak perangkat. Silakan ketik nomor HP secara manual.',
            style: AppTypography.bodyMedium.copyWith(color: Colors.white),
          ),
          backgroundColor: AppColors.errorRed,
          duration: const Duration(seconds: 2),
        ),
      );
  }
}
