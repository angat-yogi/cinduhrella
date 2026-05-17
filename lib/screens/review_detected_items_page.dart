import 'package:cinduhrella/models/draft_cloth.dart';
import 'package:cinduhrella/services/alert_service.dart';
import 'package:cinduhrella/services/auth_service.dart';
import 'package:cinduhrella/services/database_service.dart';
import 'package:cinduhrella/shared/draft_item_card.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

class ReviewDetectedItemsPage extends StatefulWidget {
  final String sessionId;

  const ReviewDetectedItemsPage({
    super.key,
    required this.sessionId,
  });

  @override
  State<ReviewDetectedItemsPage> createState() =>
      _ReviewDetectedItemsPageState();
}

class _ReviewDetectedItemsPageState extends State<ReviewDetectedItemsPage> {
  final GetIt _getIt = GetIt.instance;
  late final DatabaseService _databaseService;
  late final AuthService _authService;
  late final AlertService _alertService;

  List<DraftCloth> _drafts = const [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _databaseService = _getIt.get<DatabaseService>();
    _authService = _getIt.get<AuthService>();
    _alertService = _getIt.get<AlertService>();
    _loadDrafts();
  }

  Future<void> _loadDrafts() async {
    final userId = _authService.user?.uid;
    if (userId == null) {
      return;
    }

    final drafts =
        await _databaseService.getDraftItemsBySession(userId, widget.sessionId);
    if (!mounted) {
      return;
    }
    setState(() {
      _drafts = drafts
          .where((draft) => draft.status == DraftItemStatus.draftDetected)
          .toList();
      _loading = false;
    });
  }

  Future<void> _confirmDraft(DraftCloth draft) async {
    final userId = _authService.user?.uid;
    if (userId == null) {
      return;
    }
    await _databaseService.confirmDraftItem(userId, draft);
    _alertService.showToast(
      text: 'Added to your closet.',
      icon: Icons.check_circle,
    );
    await _loadDrafts();
  }

  Future<void> _dismissDraft(DraftCloth draft) async {
    final userId = _authService.user?.uid;
    if (userId == null) {
      return;
    }
    await _databaseService.dismissDraftItem(userId, draft.draftId);
    await _loadDrafts();
  }

  Future<void> _editDraft(DraftCloth draft) async {
    final edited = await showDialog<DraftCloth>(
      context: context,
      builder: (context) => _EditDraftDialog(draft: draft),
    );
    if (edited == null) {
      return;
    }

    final userId = _authService.user?.uid;
    if (userId == null) {
      return;
    }

    await _databaseService.updateDraftItem(userId, edited);
    await _loadDrafts();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Review Detected Items'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _drafts.isEmpty
              ? const Center(
                  child:
                      Text('No pending draft items in this capture session.'),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _drafts.length,
                  itemBuilder: (context, index) {
                    final draft = _drafts[index];
                    return DraftItemCard(
                      draft: draft,
                      onConfirm: () => _confirmDraft(draft),
                      onDismiss: () => _dismissDraft(draft),
                      onEdit: () => _editDraft(draft),
                    );
                  },
                ),
    );
  }
}

class _EditDraftDialog extends StatefulWidget {
  final DraftCloth draft;

  const _EditDraftDialog({required this.draft});

  @override
  State<_EditDraftDialog> createState() => _EditDraftDialogState();
}

class _EditDraftDialogState extends State<_EditDraftDialog> {
  late final TextEditingController _brandController;
  late final TextEditingController _typeController;
  late final TextEditingController _colorController;
  late final TextEditingController _sizeController;
  late final TextEditingController _descriptionController;

  @override
  void initState() {
    super.initState();
    _brandController = TextEditingController(text: widget.draft.brand ?? '');
    _typeController = TextEditingController(text: widget.draft.type ?? '');
    _colorController = TextEditingController(text: widget.draft.color ?? '');
    _sizeController = TextEditingController(text: widget.draft.size ?? '');
    _descriptionController =
        TextEditingController(text: widget.draft.description ?? '');
  }

  @override
  void dispose() {
    _brandController.dispose();
    _typeController.dispose();
    _colorController.dispose();
    _sizeController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Fix Draft Item'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _brandController,
              decoration: const InputDecoration(labelText: 'Brand'),
            ),
            TextField(
              controller: _typeController,
              decoration: const InputDecoration(labelText: 'Type'),
            ),
            TextField(
              controller: _colorController,
              decoration: const InputDecoration(labelText: 'Color'),
            ),
            TextField(
              controller: _sizeController,
              decoration: const InputDecoration(labelText: 'Size'),
            ),
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(labelText: 'Description'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            Navigator.pop(
              context,
              widget.draft.copyWith(
                brand: _brandController.text.trim(),
                type: _typeController.text.trim(),
                color: _colorController.text.trim(),
                size: _sizeController.text.trim(),
                description: _descriptionController.text.trim(),
                confidence: 1,
                needsReview: false,
              ),
            );
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}
