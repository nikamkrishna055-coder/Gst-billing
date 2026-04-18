import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';

import '../models/invoice_record.dart';
import '../models/reminder_record.dart';
import '../services/firestore_service.dart';

class CalendarDueScreen extends StatefulWidget {
  const CalendarDueScreen({super.key});

  @override
  State<CalendarDueScreen> createState() => _CalendarDueScreenState();
}

class _CalendarDueScreenState extends State<CalendarDueScreen> {
  late DateTime _selectedDate;
  late DateTime _focusedDate;
  CalendarFormat _calendarFormat = CalendarFormat.month;

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
    _focusedDate = DateTime.now();
  }

  @override
  Widget build(BuildContext context) {
    final FirestoreService? firestore = context.read<FirestoreService?>();
    if (firestore == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Calendar & Due Management')),
        body: const Center(child: Text('Calendar service unavailable.')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Calendar & Due Management'),
        elevation: 0,
      ),
      body: StreamBuilder<List<InvoiceRecord>>(
        stream: firestore.streamInvoices(),
        builder:
            (
              BuildContext context,
              AsyncSnapshot<List<InvoiceRecord>> invoiceSnapshot,
            ) {
              return StreamBuilder<List<ReminderRecord>>(
                stream: firestore.streamReminders(),
                builder:
                    (
                      BuildContext context,
                      AsyncSnapshot<List<ReminderRecord>> reminderSnapshot,
                    ) {
                      final List<InvoiceRecord> invoices =
                          invoiceSnapshot.data ?? <InvoiceRecord>[];
                      final List<ReminderRecord> reminders =
                          reminderSnapshot.data ?? <ReminderRecord>[];
                      final Map<DateTime, List<_DueEvent>> events =
                          _buildEventMap(
                            invoices: invoices,
                            reminders: reminders,
                          );

                      final List<_DueEvent> selectedEvents = _getEventsForDay(
                        events,
                        _selectedDate,
                      );

                      return SingleChildScrollView(
                        child: Column(
                          children: <Widget>[
                            _buildCalendar(events),
                            _buildEventsList(selectedEvents),
                          ],
                        ),
                      );
                    },
              );
            },
      ),
    );
  }

  Widget _buildCalendar(Map<DateTime, List<_DueEvent>> events) {
    return Card(
      margin: const EdgeInsets.all(12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: TableCalendar<_DueEvent>(
          firstDay: DateTime(DateTime.now().year - 1),
          lastDay: DateTime(DateTime.now().year + 2),
          focusedDay: _focusedDate,
          selectedDayPredicate: (DateTime day) => isSameDay(_selectedDate, day),
          onDaySelected: (DateTime selectedDay, DateTime focusedDay) {
            setState(() {
              _selectedDate = selectedDay;
              _focusedDate = focusedDay;
            });
          },
          onFormatChanged: (CalendarFormat format) {
            setState(() {
              _calendarFormat = format;
            });
          },
          onPageChanged: (DateTime focusedDay) {
            _focusedDate = focusedDay;
          },
          calendarFormat: _calendarFormat,
          eventLoader: (DateTime day) => _getEventsForDay(events, day),
          headerStyle: HeaderStyle(
            titleCentered: true,
            formatButtonVisible: true,
            titleTextFormatter: (DateTime date, _) =>
                DateFormat('MMMM yyyy').format(date),
            leftChevronIcon: const Icon(Icons.chevron_left),
            rightChevronIcon: const Icon(Icons.chevron_right),
            formatButtonDecoration: BoxDecoration(
              color: Theme.of(
                context,
              ).colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            formatButtonTextStyle: TextStyle(
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          calendarStyle: CalendarStyle(
            outsideDaysVisible: false,
            defaultTextStyle: TextStyle(
              color: Theme.of(context).colorScheme.onSurface,
            ),
            weekendTextStyle: TextStyle(
              color: Theme.of(context).colorScheme.error,
            ),
            holidayTextStyle: TextStyle(
              color: Theme.of(context).colorScheme.error,
            ),
            selectedDecoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
              shape: BoxShape.circle,
            ),
            todayDecoration: BoxDecoration(
              color: Theme.of(
                context,
              ).colorScheme.primary.withValues(alpha: 0.3),
              shape: BoxShape.circle,
            ),
            cellMargin: const EdgeInsets.all(4),
            rowDecoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Colors.transparent)),
            ),
          ),
          daysOfWeekStyle: DaysOfWeekStyle(
            weekdayStyle: TextStyle(
              color: Theme.of(context).colorScheme.onSurface,
              fontWeight: FontWeight.bold,
            ),
            weekendStyle: TextStyle(
              color: Theme.of(context).colorScheme.error,
              fontWeight: FontWeight.bold,
            ),
            decoration: BoxDecoration(
              color: Theme.of(
                context,
              ).colorScheme.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          rowHeight: 60,
        ),
      ),
    );
  }

  Widget _buildEventsList(List<_DueEvent> events) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Due Items',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(
                  DateFormat('EEEE, MMMM d, yyyy').format(_selectedDate),
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          _buildLegend(),
          const SizedBox(height: 12),
          if (events.isEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Center(
                  child: Column(
                    children: <Widget>[
                      Icon(
                        Icons.event_available_outlined,
                        size: 48,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'No due items on this date',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: events.length,
              itemBuilder: (BuildContext context, int index) {
                final _DueEvent event = events[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: _eventColor(
                        event.type,
                      ).withValues(alpha: 0.2),
                      child: Icon(
                        _eventIcon(event.type),
                        color: _eventColor(event.type),
                      ),
                    ),
                    title: Text(
                      event.title,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(event.type),
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _eventColor(event.type).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        event.type,
                        style: TextStyle(
                          color: _eventColor(event.type),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildLegend() {
    return Wrap(
      spacing: 12,
      children: <Widget>[
        _legendItem(
          'Invoice Due',
          _eventColor('Invoice Due'),
          Icons.receipt_long,
        ),
        _legendItem(
          'Reminder',
          _eventColor('Reminder'),
          Icons.notifications_active,
        ),
        _legendItem('Tax', _eventColor('Tax'), Icons.event_note),
      ],
    );
  }

  Widget _legendItem(String label, Color color, IconData icon) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Icon(icon, size: 14, color: color),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  Map<DateTime, List<_DueEvent>> _buildEventMap({
    required List<InvoiceRecord> invoices,
    required List<ReminderRecord> reminders,
  }) {
    final Map<DateTime, List<_DueEvent>> events = <DateTime, List<_DueEvent>>{};

    for (final InvoiceRecord invoice in invoices) {
      final DateTime dateKey = DateTime(
        invoice.dueDate.year,
        invoice.dueDate.month,
        invoice.dueDate.day,
      );
      events
          .putIfAbsent(dateKey, () => <_DueEvent>[])
          .add(
            _DueEvent(
              type: 'Invoice Due',
              title: '${invoice.number} • ${invoice.client}',
              icon: Icons.receipt_long,
            ),
          );
    }

    for (final ReminderRecord reminder in reminders) {
      final DateTime dateKey = DateTime(
        reminder.dueDate.year,
        reminder.dueDate.month,
        reminder.dueDate.day,
      );
      events
          .putIfAbsent(dateKey, () => <_DueEvent>[])
          .add(
            _DueEvent(
              type: reminder.type,
              title: reminder.title,
              icon: Icons.notifications_active,
            ),
          );
    }

    return events;
  }

  List<_DueEvent> _getEventsForDay(
    Map<DateTime, List<_DueEvent>> events,
    DateTime day,
  ) {
    final DateTime dateKey = DateTime(day.year, day.month, day.day);
    return events[dateKey] ?? <_DueEvent>[];
  }

  Color _eventColor(String type) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final String lowerType = type.toLowerCase();
    if (lowerType.contains('invoice')) {
      return colorScheme.error; // Error red
    } else if (lowerType.contains('tax') || lowerType.contains('gst')) {
      return colorScheme.secondary; // Orange/warning
    } else if (lowerType.contains('reminder')) {
      return colorScheme.tertiary; // Purple
    }
    return colorScheme.outline; // Grey
  }

  IconData _eventIcon(String type) {
    final String lowerType = type.toLowerCase();
    if (lowerType.contains('invoice')) {
      return Icons.receipt_long;
    } else if (lowerType.contains('tax') || lowerType.contains('gst')) {
      return Icons.event_note;
    } else if (lowerType.contains('reminder')) {
      return Icons.notifications_active;
    }
    return Icons.calendar_today;
  }
}

class _DueEvent {
  const _DueEvent({
    required this.type,
    required this.title,
    this.icon = Icons.calendar_today,
  });

  final String type;
  final String title;
  final IconData icon;

  @override
  String toString() => title;
}
