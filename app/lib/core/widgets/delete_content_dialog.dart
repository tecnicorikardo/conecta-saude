import 'package:flutter/material.dart';

/// Confirma a exclusão e aguarda a API antes de fechar o diálogo.
/// Em caso de falha, mantém o conteúdo e permite tentar novamente.
Future<bool> showDeleteContentDialog({
  required BuildContext context,
  required String kind,
  required String title,
  required Future<void> Function() onDelete,
}) async {
  var deleting = false;
  String? error;
  return await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => StatefulBuilder(
          builder: (context, update) => PopScope(
            canPop: !deleting,
            child: AlertDialog(
              title: Text('Excluir $kind?'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('“$title” deixará de aparecer para todos os usuários.'),
                  if (error != null) ...[
                    const SizedBox(height: 12),
                    Text(error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
                  ],
                ],
              ),
              actions: [
                TextButton(
                  onPressed: deleting ? null : () => Navigator.of(dialogContext).pop(false),
                  child: const Text('Cancelar'),
                ),
                FilledButton(
                  onPressed: deleting ? null : () async {
                    // Bloqueia cliques repetidos enquanto a requisição está em andamento.
                    update(() { deleting = true; error = null; });
                    try {
                      await onDelete();
                      if (dialogContext.mounted) Navigator.of(dialogContext).pop(true);
                    } catch (failure) {
                      if (dialogContext.mounted) {
                        update(() {
                          deleting = false;
                          error = failure.toString().replaceFirst('Exception: ', '');
                        });
                      }
                    }
                  },
                  child: Text(deleting ? 'Excluindo…' : 'Excluir'),
                ),
              ],
            ),
          ),
        ),
      ) ?? false;
}
