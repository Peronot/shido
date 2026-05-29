import 'package:flutter/material.dart';

import '../../../core/auth/auth_controller.dart';
import '../../../core/auth/auth_gate.dart';
import '../../../core/network/resource_api.dart';
import '../../../core/ui/app_alerts.dart';
import '../../../core/ui/app_widgets.dart';
import '../../../core/ui/async_state_widgets.dart';

class PlayersScreen extends StatefulWidget {
  const PlayersScreen({super.key});

  @override
  State<PlayersScreen> createState() => _PlayersScreenState();
}

class _PlayersScreenState extends State<PlayersScreen> {
  final ResourceApi _api = ResourceApi();
  late Future<List<Map<String, dynamic>>> _playersFuture;

  Future<List<Map<String, dynamic>>> _loadMyPlayers() async {
    final all = await _api.list('players');
    final userId = (AuthController.currentUser.value?['id'] ?? '').toString();
    if (userId.isEmpty) {
      return <Map<String, dynamic>>[];
    }
    return all.where((p) => (p['user_id'] ?? '').toString() == userId).toList();
  }

  @override
  void initState() {
    super.initState();
    _playersFuture = _loadMyPlayers();
  }

  Future<void> _refreshPlayers() async {
    setState(() {
      _playersFuture = _loadMyPlayers();
    });
    await _playersFuture;
  }

  Future<void> _openAddPlayerForm() async {
    final added = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const _AddPlayerSheet(),
    );

    if (added == true && mounted) {
      AppAlerts.success(
        context,
        title: 'Success',
        text: 'Player registered successfully.',
      );
      await _refreshPlayers();
    }
  }

  Future<void> _openEditPlayerForm(Map<String, dynamic> player) async {
    final updated = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _EditPlayerSheet(player: player),
    );

    if (updated == true && mounted) {
      AppAlerts.success(
        context,
        title: 'Success',
        text: 'Player updated successfully.',
      );
      await _refreshPlayers();
    }
  }

  Future<void> _deletePlayer(Map<String, dynamic> player) async {
    final id = (player['id'] ?? '').toString();
    if (id.isEmpty) return;
    final ok = await AppAlerts.confirmBool(
      context,
      title: 'Delete Player',
      text: 'Are you sure you want to delete this player?',
      confirmText: 'Delete',
    );
    if (!ok) return;
    if (!mounted) return;

    AppAlerts.loading(
      context,
      title: 'Deleting',
      text: 'Player is being deleted...',
    );
    try {
      await _api.remove('players', id);
      if (!mounted) return;
      AppAlerts.close(context);
      AppAlerts.success(
        context,
        title: 'Deleted',
        text: 'Player deleted successfully.',
      );
      await _refreshPlayers();
    } catch (e) {
      if (!mounted) return;
      AppAlerts.close(context);
      AppAlerts.error(
        context,
        title: 'Delete Failed',
        text: e.toString(),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: SectionCard(
        title: 'Players',
        action: FilledButton.icon(
          onPressed: () async {
            final allowed = await requireLogin(context);
            if (!context.mounted || !allowed) return;
            await _openAddPlayerForm();
          },
          icon: const Icon(Icons.person_add),
          label: const Text('Add Player'),
        ),
        child: FutureBuilder<List<Map<String, dynamic>>>(
          future: _playersFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const LoadingState();
            }
            if (snapshot.hasError) {
              return ErrorState(message: snapshot.error.toString());
            }
            final players = snapshot.data ?? [];
            if (players.isEmpty) {
              return const EmptyState(message: 'No players found');
            }
            return RefreshIndicator(
              onRefresh: _refreshPlayers,
              child: ListView.builder(
                shrinkWrap: true,
                physics: const AlwaysScrollableScrollPhysics(),
                itemCount: players.length,
                itemBuilder: (context, index) {
                  final p = players[index];
                  return ListTile(
                    title: Text((p['full_name'] ?? '-').toString()),
                    subtitle: Text(
                      'Nickname: ${(p['nickname'] ?? '-')} • Phone: ${(p['phone'] ?? '-')}',
                    ),
                    trailing: PopupMenuButton<String>(
                      onSelected: (value) async {
                        if (value == 'edit') {
                          await _openEditPlayerForm(p);
                        } else if (value == 'delete') {
                          await _deletePlayer(p);
                        }
                      },
                      itemBuilder: (_) => const [
                        PopupMenuItem(value: 'edit', child: Text('Edit')),
                        PopupMenuItem(value: 'delete', child: Text('Delete')),
                      ],
                    ),
                    leading: Text(
                      (p['is_active'] == true) ? 'Active' : 'Inactive',
                    ),
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }
}

class _AddPlayerSheet extends StatefulWidget {
  const _AddPlayerSheet();

  @override
  State<_AddPlayerSheet> createState() => _AddPlayerSheetState();
}

class _EditPlayerSheet extends StatefulWidget {
  const _EditPlayerSheet({required this.player});

  final Map<String, dynamic> player;

  @override
  State<_EditPlayerSheet> createState() => _EditPlayerSheetState();
}

class _EditPlayerSheetState extends State<_EditPlayerSheet> {
  final _fullNameCtrl = TextEditingController();
  final _nickNameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _api = ResourceApi();
  bool _isSaving = false;
  bool _isActive = true;

  @override
  void initState() {
    super.initState();
    _fullNameCtrl.text = (widget.player['full_name'] ?? '').toString();
    _nickNameCtrl.text = (widget.player['nickname'] ?? '').toString();
    _phoneCtrl.text = (widget.player['phone'] ?? '').toString();
    _isActive = (widget.player['is_active'] ?? true) == true;
  }

  @override
  void dispose() {
    _fullNameCtrl.dispose();
    _nickNameCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveChanges() async {
    final id = (widget.player['id'] ?? '').toString();
    if (id.isEmpty) return;
    if (_fullNameCtrl.text.trim().isEmpty) {
      AppAlerts.warning(
        context,
        title: 'Validation',
        text: 'Player name is required.',
      );
      return;
    }

    setState(() => _isSaving = true);
    AppAlerts.loading(
      context,
      title: 'Saving',
      text: 'Player is being updated...',
    );
    try {
      await _api.update('players', id, {
        'full_name': _fullNameCtrl.text.trim(),
        'nickname': _nickNameCtrl.text.trim().isEmpty ? null : _nickNameCtrl.text.trim(),
        'phone': _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
        'is_active': _isActive,
      });
      if (!mounted) return;
      AppAlerts.close(context);
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      AppAlerts.close(context);
      AppAlerts.error(
        context,
        title: 'Update Failed',
        text: e.toString(),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 20,
        bottom: bottomInset + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Edit Player', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            TextField(
              controller: _fullNameCtrl,
              decoration: const InputDecoration(labelText: 'Full Name *'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _nickNameCtrl,
              decoration: const InputDecoration(labelText: 'Nickname'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _phoneCtrl,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: 'Phone'),
            ),
            const SizedBox(height: 10),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Active Player'),
              value: _isActive,
              onChanged: _isSaving ? null : (value) => setState(() => _isActive = value),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _isSaving ? null : _saveChanges,
                child: Text(_isSaving ? 'Saving...' : 'Save Changes'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AddPlayerSheetState extends State<_AddPlayerSheet> {
  static final RegExp _uuidRegex = RegExp(
    r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[1-5][0-9a-fA-F]{3}-[89abAB][0-9a-fA-F]{3}-[0-9a-fA-F]{12}$',
  );
  final _fullNameCtrl = TextEditingController();
  final _nickNameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _api = ResourceApi();
  bool _isSaving = false;
  bool _isActive = true;

  @override
  void dispose() {
    _fullNameCtrl.dispose();
    _nickNameCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _savePlayer() async {
    final fullName = _fullNameCtrl.text.trim();
    final userId = (AuthController.currentUser.value?['id'] ?? '').toString();
    if (fullName.isEmpty) {
      AppAlerts.warning(
        context,
        title: 'Validation',
        text: 'Player name is required.',
      );
      return;
    }
    if (userId.isEmpty) {
      AppAlerts.error(
        context,
        title: 'Login Required',
        text: 'Please login first to register a player.',
      );
      return;
    }
    if (!_uuidRegex.hasMatch(userId)) {
      AppAlerts.error(
        context,
        title: 'Session Error',
        text: 'Your session is invalid. Please logout and login again.',
      );
      return;
    }

    setState(() => _isSaving = true);
    AppAlerts.loading(
      context,
      title: 'Saving',
      text: 'Player is being registered...',
    );
    try {
      await _api.create('players', {
        'user_id': userId,
        'full_name': fullName,
        'nickname': _nickNameCtrl.text.trim().isEmpty
            ? null
            : _nickNameCtrl.text.trim(),
        'phone': _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
        'is_active': _isActive,
      });

      if (!mounted) return;
      AppAlerts.close(context);
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      AppAlerts.close(context);
      final message = e.toString();
      debugPrint('[PLAYERS][CREATE] Failed: $message');
      AppAlerts.error(
        context,
        title: 'Add Player Failed',
        text: e.toString(),
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 20,
        bottom: bottomInset + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Add Player', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            TextField(
              controller: _fullNameCtrl,
              decoration: const InputDecoration(labelText: 'Full Name *'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _nickNameCtrl,
              decoration: const InputDecoration(labelText: 'Nickname'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _phoneCtrl,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: 'Phone'),
            ),
            const SizedBox(height: 10),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Active Player'),
              value: _isActive,
              onChanged: _isSaving
                  ? null
                  : (value) => setState(() => _isActive = value),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _isSaving ? null : _savePlayer,
                child: Text(_isSaving ? 'Saving...' : 'Save Player'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
