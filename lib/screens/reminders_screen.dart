import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/reminder_record.dart';
import '../services/analytics_service.dart';
import '../services/firestore_service.dart';

class RemindersScreen extends StatefulWidget {
  const RemindersScreen({super.key});

  @override
  State<RemindersScreen> createState() => _RemindersScreenState();
}

class _RemindersScreenState extends State<RemindersScreen> {
  final List<String> _filters = <String>['All', 'Pending', 'Scheduled', 'Done'];
  String _selectedFilter = 'All';

  Color _typeColor(String type) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    switch (type.toLowerCase()) {
      case 'gst':
        return colorScheme.tertiary;
      case 'invoice':
        return colorScheme.primary;
      case 'income tax':
        return colorScheme.secondary;
      default:
        return colorScheme.outline;
    }
  }

  Color _statusColor(String status) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    switch (status.toLowerCase()) {
      case 'done':
        return colorScheme.primary;
      case 'scheduled':
        return colorScheme.secondary;
      case 'pending':
        return colorScheme.error;
      default:
        return colorScheme.outline;
    }
  }

  String _dateLabel(DateTime date) {
    const List<String> months = <String>[
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${date.day} ${months[date.month - 1]}';
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  void _openAddReminderSheet() {
    final GlobalKey<FormState> formKey = GlobalKey<FormState>();
    final TextEditingController titleController = TextEditingController();
    final TextEditingController invoiceIdController = TextEditingController(
      text: '',
    );
    final TextEditingController clientIdController = TextEditingController(
      text: '',
    );
    final TextEditingController clientNameController = TextEditingController();
    final TextEditingController messageController = TextEditingController();

    String status = 'Scheduled';
    String type = 'Invoice';
    String priority = 'Medium';
    String channel = 'WhatsApp';
    bool enabled = true;
    DateTime dueDate = DateTime.now().add(const Duration(days: 2));

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.85,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          builder: (BuildContext context, ScrollController scrollController) {
            return StatefulBuilder(
              builder:
                  (
                    BuildContext context,
                    void Function(void Function()) setModalState,
                  ) {
                    return Container(
                      margin: const EdgeInsets.only(top: 22),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(24),
                        ),
                      ),
                      child: SafeArea(
                        top: false,
                        child: SingleChildScrollView(
                          controller: scrollController,
                          padding: EdgeInsets.fromLTRB(
                            16,
                            16,
                            16,
                            MediaQuery.of(context).viewInsets.bottom + 16,
                          ),
                          child: Form(
                            key: formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Center(
                                  child: Container(
                                    width: 42,
                                    height: 5,
                                    decoration: BoxDecoration(
                                      color: Theme.of(context).dividerColor,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 14),
                                Text(
                                  'Create Reminder',
                                  style: Theme.of(context).textTheme.titleLarge
                                      ?.copyWith(fontWeight: FontWeight.w700),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Saved in users/{uid}/reminders',
                                  style: Theme.of(context).textTheme.bodySmall,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 14),
                                TextFormField(
                                  controller: titleController,
                                  decoration: const InputDecoration(
                                    labelText: 'Title',
                                    prefixIcon: Icon(Icons.alarm_add_outlined),
                                  ),
                                  validator: (String? value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return 'Enter title';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: <Widget>[
                                    Expanded(
                                      child: TextFormField(
                                        controller: invoiceIdController,
                                        decoration: const InputDecoration(
                                          labelText: 'Invoice ID',
                                          prefixIcon: Icon(
                                            Icons.receipt_long_outlined,
                                          ),
                                        ),
                                        validator: (String? value) {
                                          if (value == null ||
                                              value.trim().isEmpty) {
                                            return 'Enter invoice ID';
                                          }
                                          return null;
                                        },
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: TextFormField(
                                        controller: clientIdController,
                                        decoration: const InputDecoration(
                                          labelText: 'Client ID',
                                          prefixIcon: Icon(Icons.badge_outlined),
                                        ),
                                        validator: (String? value) {
                                          if (value == null ||
                                              value.trim().isEmpty) {
                                            return 'Enter client ID';
                                          }
                                          return null;
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                TextFormField(
                                  controller: clientNameController,
                                  decoration: const InputDecoration(
                                    labelText: 'Client Name',
                                    prefixIcon: Icon(Icons.person_outline),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: <Widget>[
                                    Flexible(
                                      flex: 1,
                                      child: DropdownButtonFormField<String>(
                                        isExpanded: true,
                                        initialValue: status,
                                        decoration: const InputDecoration(
                                          labelText: 'Status',
                                          prefixIcon: Icon(Icons.flag_outlined),
                                          isDense: true,
                                          contentPadding: EdgeInsets.symmetric(vertical: 12),
                                        ),
                                        items: const <DropdownMenuItem<String>>[
                                          DropdownMenuItem<String>(
                                            value: 'Pending',
                                            child: Text('Pending'),
                                          ),
                                          DropdownMenuItem<String>(
                                            value: 'Scheduled',
                                            child: Text('Scheduled'),
                                          ),
                                          DropdownMenuItem<String>(
                                            value: 'Done',
                                            child: Text('Done'),
                                          ),
                                        ],
                                        onChanged: (String? value) {
                                          if (value == null) {
                                            return;
                                          }
                                          setModalState(() {
                                            status = value;
                                          });
                                        },
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Flexible(
                                      flex: 1,
                                      child: DropdownButtonFormField<String>(
                                        isExpanded: true,
                                        initialValue: type,
                                        decoration: const InputDecoration(
                                          labelText: 'Type',
                                          prefixIcon: Icon(Icons.category_outlined),
                                          isDense: true,
                                          contentPadding: EdgeInsets.symmetric(vertical: 12),
                                        ),
                                        items: const <DropdownMenuItem<String>>[
                                          DropdownMenuItem<String>(
                                            value: 'Invoice',
                                            child: Text('Invoice'),
                                          ),
                                          DropdownMenuItem<String>(
                                            value: 'GST',
                                            child: Text('GST'),
                                          ),
                                          DropdownMenuItem<String>(
                                            value: 'Income Tax',
                                            child: Text('Income Tax'),
                                          ),
                                        ],
                                        onChanged: (String? value) {
                                          if (value == null) {
                                            return;
                                          }
                                          setModalState(() {
                                            type = value;
                                          });
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: <Widget>[
                                    Flexible(
                                      flex: 1,
                                      child: DropdownButtonFormField<String>(
                                        isExpanded: true,
                                        initialValue: priority,
                                        decoration: const InputDecoration(
                                          labelText: 'Priority',
                                          prefixIcon: Icon(
                                            Icons.priority_high_outlined,
                                          ),
                                          isDense: true,
                                          contentPadding: EdgeInsets.symmetric(vertical: 12),
                                        ),
                                        items: const <DropdownMenuItem<String>>[
                                          DropdownMenuItem<String>(
                                            value: 'High',
                                            child: Text('High'),
                                          ),
                                          DropdownMenuItem<String>(
                                            value: 'Medium',
                                            child: Text('Medium'),
                                          ),
                                          DropdownMenuItem<String>(
                                            value: 'Low',
                                            child: Text('Low'),
                                          ),
                                        ],
                                        onChanged: (String? value) {
                                          if (value == null) {
                                            return;
                                          }
                                          setModalState(() {
                                            priority = value;
                                          });
                                        },
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Flexible(
                                      flex: 1,
                                      child: DropdownButtonFormField<String>(
                                        isExpanded: true,
                                        initialValue: channel,
                                        decoration: const InputDecoration(
                                          labelText: 'Channel',
                                          prefixIcon: Icon(Icons.campaign_outlined),
                                          isDense: true,
                                          contentPadding: EdgeInsets.symmetric(vertical: 12),
                                        ),
                                        items: const <DropdownMenuItem<String>>[
                                          DropdownMenuItem<String>(
                                            value: 'WhatsApp',
                                            child: Text('WhatsApp'),
                                          ),
                                          DropdownMenuItem<String>(
                                            value: 'SMS',
                                            child: Text('SMS'),
                                          ),
                                          DropdownMenuItem<String>(
                                            value: 'Email',
                                            child: Text('Email'),
                                          ),
                                        ],
                                        onChanged: (String? value) {
                                          if (value == null) {
                                            return;
                                          }
                                          setModalState(() {
                                            channel = value;
                                          });
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                InkWell(
                                  borderRadius: BorderRadius.circular(16),
                                  onTap: () async {
                                    final DateTime? pickedDate =
                                        await showDatePicker(
                                          context: context,
                                          firstDate:
                                              DateTime.now().subtract(
                                            const Duration(days: 1),
                                          ),
                                          lastDate: DateTime.now().add(
                                            const Duration(days: 365),
                                          ),
                                          initialDate: dueDate,
                                        );
                                    if (pickedDate == null) {
                                      return;
                                    }
                                    setModalState(() {
                                      dueDate = pickedDate;
                                    });
                                  },
                                  child: InputDecorator(
                                    decoration: const InputDecoration(
                                      labelText: 'Due Date',
                                      prefixIcon: Icon(
                                        Icons.calendar_today_outlined,
                                      ),
                                    ),
                                    child: Text(
                                      _dateLabel(dueDate),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                TextFormField(
                                  controller: messageController,
                                  maxLines: 3,
                                  decoration: const InputDecoration(
                                    labelText: 'Message',
                                    alignLabelWithHint: true,
                                    prefixIcon: Icon(Icons.message_outlined),
                                  ),
                                  validator: (String? value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return 'Enter message';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 12),
                                SwitchListTile(
                                  contentPadding: EdgeInsets.zero,
                                  value: enabled,
                                  onChanged: (bool value) {
                                    setModalState(() {
                                      enabled = value;
                                    });
                                  },
                                  title: const Text('Enable reminder'),
                                ),
                                const SizedBox(height: 12),
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton.icon(
                                    onPressed: () async {
                                      if (!formKey.currentState!.validate()) {
                                        return;
                                      }
                                      final FirestoreService firestoreService =
                                          context.read<FirestoreService>();
                                      final AnalyticsService analyticsService =
                                          context.read<AnalyticsService>();
                                      final NavigatorState navigator =
                                          Navigator.of(
                                        context,
                                      );
                                      try {
                                        await firestoreService.addReminder(
                                          invoiceId: invoiceIdController.text
                                              .trim(),
                                          clientId:
                                              clientIdController.text.trim(),
                                          dueDate: dueDate,
                                          status: status,
                                          reminderSent: false,
                                          title: titleController.text.trim(),
                                          type: type,
                                          priority: priority,
                                          enabled: enabled,
                                          message:
                                              messageController.text.trim(),
                                          channel: channel,
                                          clientName: clientNameController.text
                                              .trim(),
                                        );
                                        await analyticsService.logEvent(
                                          'create_reminder',
                                        );
                                        if (!mounted) {
                                          return;
                                        }
                                        navigator.pop();
                                        _showMessage(
                                          'Reminder saved to Firestore.',
                                        );
                                      } catch (error) {
                                        _showMessage(
                                          'Could not save reminder: $error',
                                        );
                                      }
                                    },
                                    icon: const Icon(Icons.save_outlined),
                                    label: const Text('Save Reminder'),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
            );
          },
        );
      },
    );
  }



  Future<void> _setReminderStatus(
    ReminderRecord reminder,
    String status,
  ) async {
    final FirestoreService firestore = context.read<FirestoreService>();
    final AnalyticsService analytics = context.read<AnalyticsService>();
    try {
      await firestore.updateReminderStatus(
        reminderId: reminder.id,
        status: status,
      );
      await analytics.logEvent(
        'reminder_status_update',
        parameters: <String, Object>{'status': status},
      );
      if (!mounted) {
        return;
      }
      _showMessage('Reminder marked $status.');
    } catch (error) {
      _showMessage('Could not update reminder: $error');
    }
  }

  Future<void> _deleteReminder(ReminderRecord reminder) async {
    final FirestoreService firestore = context.read<FirestoreService>();
    final AnalyticsService analytics = context.read<AnalyticsService>();
    try {
      await firestore.deleteReminder(reminderId: reminder.id);
      await analytics.logEvent('delete_reminder');
      if (!mounted) {
        return;
      }
      _showMessage('Reminder deleted.');
    } catch (error) {
      _showMessage('Could not delete reminder: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    final FirestoreService? firestoreService = context
        .read<FirestoreService?>();
    return StreamBuilder<List<ReminderRecord>>(
      stream:
          firestoreService?.streamReminders() ??
          Stream<List<ReminderRecord>>.value(const <ReminderRecord>[]),
      builder: (BuildContext context, AsyncSnapshot<List<ReminderRecord>> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text('Failed to load reminders: ${snapshot.error}'),
            ),
          );
        }

        final List<ReminderRecord> reminders =
            snapshot.data ?? <ReminderRecord>[];
        final List<ReminderRecord> filtered =
            reminders.where((ReminderRecord reminder) {
              return _selectedFilter == 'All' ||
                  reminder.status == _selectedFilter;
            }).toList()..sort((ReminderRecord a, ReminderRecord b) {
              return a.dueDate.compareTo(b.dueDate);
            });

        return Column(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Icon(
                          Icons.notifications_active_outlined,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Reminders (Realtime)',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                        ),
                        FilledButton.tonalIcon(
                          onPressed: _openAddReminderSheet,
                          style: FilledButton.styleFrom(
                            backgroundColor: Theme.of(
                              context,
                            ).colorScheme.primary.withValues(alpha: 0.15),
                            foregroundColor: Theme.of(
                              context,
                            ).colorScheme.primary,
                          ),
                          icon: const Icon(Icons.add, size: 18),
                          label: const Text('Add'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: <Widget>[
                        Expanded(child: _metric('Count', '${filtered.length}')),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _metric(
                            'Enabled',
                            '${filtered.where((ReminderRecord r) => r.enabled).length}',
                          ),
                        ),
                      ],
                    ),

                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      'Smart reminder timeline with due status',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _filters.map((String filter) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(filter),
                        selected: _selectedFilter == filter,
                        selectedColor: Theme.of(context).colorScheme.primary,
                        backgroundColor: Theme.of(context).colorScheme.surface,
                        labelStyle: TextStyle(
                          color: _selectedFilter == filter
                              ? Theme.of(context).colorScheme.onPrimary
                              : Theme.of(context).colorScheme.onSurface,
                          fontWeight: FontWeight.w600,
                        ),
                        onSelected: (_) {
                          setState(() {
                            _selectedFilter = filter;
                          });
                        },
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
            Expanded(
              child: filtered.isEmpty
                  ? _RemindersEmptyState(onAddReminder: _openAddReminderSheet)
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      itemCount: filtered.length,
                      itemBuilder: (BuildContext context, int index) {
                        final ReminderRecord reminder = filtered[index];
                        final Color typeColor = _typeColor(reminder.type);
                        final Color statusColor = _statusColor(reminder.status);

                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            SizedBox(
                              width: 54,
                              child: Column(
                                children: <Widget>[
                                  Container(
                                    width: 42,
                                    height: 42,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: typeColor.withValues(alpha: 0.14),
                                      border: Border.all(
                                        color: typeColor.withValues(
                                          alpha: 0.45,
                                        ),
                                      ),
                                    ),
                                    child: Center(
                                      child: Text(
                                        _dateLabel(reminder.dueDate),
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                  ),
                                  if (index != filtered.length - 1)
                                    Container(
                                      width: 2,
                                      height: 84,
                                      color: Theme.of(context).dividerColor,
                                    ),
                                ],
                              ),
                            ),
                            Expanded(
                              child: Card(
                                margin: const EdgeInsets.only(bottom: 8),
                                child: Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: <Widget>[
                                      Row(
                                        children: <Widget>[
                                          Expanded(
                                            child: Text(
                                              reminder.title,
                                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                                color: Theme.of(context).colorScheme.onSurface,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 3,
                                            ),
                                            decoration: BoxDecoration(
                                              color: statusColor.withValues(
                                                alpha: 0.12,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                            ),
                                            child: Text(
                                              reminder.status,
                                              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                                color: statusColor,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        reminder.message,
                                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                          color: Theme.of(context).colorScheme.onSurface,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Wrap(
                                        spacing: 8,
                                        runSpacing: 8,
                                        children: <Widget>[
                                          _badge(reminder.type, typeColor),
                                          _badge(
                                            '${reminder.priority} Priority',
                                            reminder.priority.toLowerCase() ==
                                                    'high'
                                                ? Theme.of(context).colorScheme.error
                                                : reminder.priority
                                                          .toLowerCase() ==
                                                      'medium'
                                                ? Theme.of(context)
                                                    .colorScheme
                                                    .secondary
                                                : Theme.of(context)
                                                    .colorScheme
                                                    .tertiary,
                                          ),
                                          _badge(
                                            reminder.channel,
                                            Theme.of(context)
                                                .colorScheme
                                                .outline,
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        children: <Widget>[
                                          Text(
                                            reminder.enabled
                                                ? 'Enabled'
                                                : 'Disabled',
                                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                              color: Theme.of(context).colorScheme.onSurface,
                                            ),
                                          ),
                                          const Spacer(),
                                          PopupMenuButton<String>(
                                            icon: const Icon(
                                              Icons.more_vert,
                                              size: 18,
                                            ),
                                            onSelected: (String value) {
                                              if (value == 'pending') {
                                                _setReminderStatus(
                                                  reminder,
                                                  'Pending',
                                                );
                                                return;
                                              }
                                              if (value == 'scheduled') {
                                                _setReminderStatus(
                                                  reminder,
                                                  'Scheduled',
                                                );
                                                return;
                                              }
                                              if (value == 'done') {
                                                _setReminderStatus(
                                                  reminder,
                                                  'Done',
                                                );
                                                return;
                                              }
                                              if (value == 'delete') {
                                                _deleteReminder(reminder);
                                              }
                                            },
                                            itemBuilder:
                                                (BuildContext context) {
                                                  return const <
                                                    PopupMenuEntry<String>
                                                  >[
                                                    PopupMenuItem<String>(
                                                      value: 'pending',
                                                      child: Text(
                                                        'Mark Pending',
                                                      ),
                                                    ),
                                                    PopupMenuItem<String>(
                                                      value: 'scheduled',
                                                      child: Text(
                                                        'Mark Scheduled',
                                                      ),
                                                    ),
                                                    PopupMenuItem<String>(
                                                      value: 'done',
                                                      child: Text('Mark Done'),
                                                    ),
                                                    PopupMenuItem<String>(
                                                      value: 'delete',
                                                      child: Text('Delete'),
                                                    ),
                                                  ];
                                                },
                                          ),
                                          Switch(
                                            value: reminder.enabled,
                                            onChanged: (bool value) async {
                                              final FirestoreService
                                              firestoreService = context
                                                  .read<FirestoreService>();
                                              final AnalyticsService
                                              analyticsService = context
                                                  .read<AnalyticsService>();
                                              try {
                                                await firestoreService
                                                    .updateReminderEnabled(
                                                      reminderId: reminder.id,
                                                      enabled: value,
                                                    );
                                                await analyticsService.logEvent(
                                                  'toggle_reminder',
                                                );
                                              } catch (error) {
                                                _showMessage(
                                                  'Could not update reminder: $error',
                                                );
                                              }
                                            },
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }

  Widget _badge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
        ),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _metric(String label, String value) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: colorScheme.primary.withValues(alpha: 0.08),
        border: Border.all(
          color: colorScheme.primary.withValues(alpha: 0.15),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            value,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: colorScheme.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}

class _RemindersEmptyState extends StatelessWidget {
  const _RemindersEmptyState({required this.onAddReminder});

  final VoidCallback onAddReminder;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(
                Icons.timeline_outlined,
                size: 48,
                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5),
              ),
              const SizedBox(height: 8),
              Text(
                'No reminders in timeline yet',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 6),
              ElevatedButton.icon(
                onPressed: onAddReminder,
                icon: const Icon(Icons.add),
                label: const Text('Create Reminder'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
