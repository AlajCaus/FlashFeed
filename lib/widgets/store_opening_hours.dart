// StoreOpeningHours Widget
// Zeigt Öffnungszeiten einer Filiale mit Status-Anzeige

import 'package:flutter/material.dart';
import '../models/models.dart';

class StoreOpeningHours extends StatelessWidget {
  final Store store;
  final bool showFullWeek;
  final bool compact;
  
  const StoreOpeningHours({
    super.key,
    required this.store,
    this.showFullWeek = false,
    this.compact = false,
  });
  
  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final isOpen = store.isOpenAt(now);
    final nextChange = _getNextStatusChange(now);
    
    if (compact) {
      return _buildCompactView(context, isOpen, nextChange);
    }
    
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildStatusHeader(context, isOpen, nextChange),
            if (showFullWeek) ...[
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),
              _buildWeekSchedule(context),
            ],
          ],
        ),
      ),
    );
  }
  
  Widget _buildCompactView(BuildContext context, bool isOpen, String nextChange) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isOpen ? Colors.green.shade50 : Colors.red.shade50,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isOpen ? Colors.green : Colors.red,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isOpen ? Icons.check_circle : Icons.cancel,
            size: 16,
            color: isOpen ? Colors.green : Colors.red,
          ),
          const SizedBox(width: 4),
          Text(
            isOpen ? 'Geöffnet' : 'Geschlossen',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: isOpen ? Colors.green.shade700 : Colors.red.shade700,
            ),
          ),
          if (nextChange.isNotEmpty) ...[
            const SizedBox(width: 4),
            Text(
              '• $nextChange',
              style: TextStyle(
                fontSize: 11,
                color: Theme.of(context).textTheme.bodySmall?.color,
              ),
            ),
          ],
        ],
      ),
    );
  }
  
  Widget _buildStatusHeader(BuildContext context, bool isOpen, String nextChange) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isOpen ? Colors.green.shade100 : Colors.red.shade100,
            shape: BoxShape.circle,
          ),
          child: Icon(
            isOpen ? Icons.lock_open : Icons.lock,
            color: isOpen ? Colors.green : Colors.red,
            size: 24,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isOpen ? 'Jetzt geöffnet' : 'Geschlossen',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: isOpen ? Colors.green : Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (nextChange.isNotEmpty)
                Text(
                  nextChange,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
            ],
          ),
        ),
      ],
    );
  }
  
  Widget _buildWeekSchedule(BuildContext context) {
    final days = [
      'Montag',
      'Dienstag', 
      'Mittwoch',
      'Donnerstag',
      'Freitag',
      'Samstag',
      'Sonntag',
    ];
    
    final today = DateTime.now().weekday - 1; // 0-indexed
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Öffnungszeiten',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 8),
        ...List.generate(7, (index) {
          final dayOpeningHours = _getOpeningHoursForDay(index);
          final isToday = index == today;
          
          return Container(
            padding: const EdgeInsets.symmetric(vertical: 4),
            decoration: BoxDecoration(
              color: isToday ? Theme.of(context).primaryColor.withValues(alpha: 0.05) : null,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 100,
                  child: Text(
                    days[index],
                    style: TextStyle(
                      fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                      color: isToday ? Theme.of(context).primaryColor : null,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    dayOpeningHours,
                    style: TextStyle(
                      fontWeight: isToday ? FontWeight.w500 : FontWeight.normal,
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
  
  String _getNextStatusChange(DateTime now) {
    final currentHour = now.hour;
    final currentMinute = now.minute;
    final currentTimeInMinutes = currentHour * 60 + currentMinute;
    
    if (store.isOpenAt(now)) {
      // Store is open, find closing time
      final closingTime = _getClosingTimeForDay(now.weekday - 1);
      if (closingTime != null) {
        final minutesUntilClose = closingTime - currentTimeInMinutes;
        if (minutesUntilClose > 0 && minutesUntilClose <= 120) {
          if (minutesUntilClose <= 60) {
            return 'Schließt in $minutesUntilClose Min.';
          } else {
            final hours = minutesUntilClose ~/ 60;
            final mins = minutesUntilClose % 60;
            return 'Schließt in ${hours}h ${mins > 0 ? "${mins}min" : ""}';
          }
        } else if (minutesUntilClose > 120) {
          final hours = closingTime ~/ 60;
          final mins = closingTime % 60;
          return 'Schließt um ${hours.toString().padLeft(2, '0')}:${mins.toString().padLeft(2, '0')} Uhr';
        }
      }
    } else {
      // Store is closed, find next opening time
      final openingTime = _getNextOpeningTime(now);
      if (openingTime != null) {
        return openingTime;
      }
    }
    
    return '';
  }
  
  String _getOpeningHoursForDay(int dayIndex) {
    // Get opening hours from store model
    final openingHours = store.openingHours;
    
    if (openingHours.isEmpty) {
      // Default hours if not specified
      if (dayIndex == 6) { // Sunday
        return 'Geschlossen';
      }
      return '08:00 - 20:00';
    }
    
    // Map weekday index to German weekday name
    final weekdays = ['Montag', 'Dienstag', 'Mittwoch', 'Donnerstag', 'Freitag', 'Samstag', 'Sonntag'];
    final weekdayName = weekdays[dayIndex];
    
    // Get opening hours for this day from the Map
    final dayHours = openingHours[weekdayName];
    
    if (dayHours == null || dayHours.isClosed) {
      return 'Geschlossen';
    }
    
    return dayHours.displayTime;
  }
  
  int? _getClosingTimeForDay(int dayIndex) {
    final hoursStr = _getOpeningHoursForDay(dayIndex);
    if (hoursStr == 'Geschlossen') return null;
    
    final parts = hoursStr.split(' - ');
    if (parts.length != 2) return null;
    
    final closingParts = parts[1].split(':');
    if (closingParts.length != 2) return null;
    
    return int.parse(closingParts[0]) * 60 + int.parse(closingParts[1]);
  }
  
  String? _getNextOpeningTime(DateTime now) {
    // Check if opens later today
    final todayHours = _getOpeningHoursForDay(now.weekday - 1);
    if (todayHours != 'Geschlossen') {
      final parts = todayHours.split(' - ');
      if (parts.length == 2) {
        final openingParts = parts[0].split(':');
        if (openingParts.length == 2) {
          final openingHour = int.parse(openingParts[0]);
          final openingMinute = int.parse(openingParts[1]);
          final openingTimeInMinutes = openingHour * 60 + openingMinute;
          final currentTimeInMinutes = now.hour * 60 + now.minute;
          
          if (openingTimeInMinutes > currentTimeInMinutes) {
            final minutesUntilOpen = openingTimeInMinutes - currentTimeInMinutes;
            if (minutesUntilOpen <= 120) {
              return 'Öffnet in ${minutesUntilOpen ~/ 60}h ${minutesUntilOpen % 60}min';
            } else {
              return 'Öffnet um ${openingHour.toString().padLeft(2, '0')}:${openingMinute.toString().padLeft(2, '0')} Uhr';
            }
          }
        }
      }
    }
    
    // Find next day that's open
    for (int i = 1; i <= 7; i++) {
      final nextDayIndex = (now.weekday - 1 + i) % 7;
      final nextDayHours = _getOpeningHoursForDay(nextDayIndex);
      if (nextDayHours != 'Geschlossen') {
        final dayName = ['Mo', 'Di', 'Mi', 'Do', 'Fr', 'Sa', 'So'][nextDayIndex];
        final parts = nextDayHours.split(' - ');
        if (parts.length == 2) {
          return 'Öffnet $dayName ${parts[0]} Uhr';
        }
      }
    }
    
    return null;
  }
}

// Status badge widget for quick display
class StoreStatusBadge extends StatelessWidget {
  final Store store;
  
  const StoreStatusBadge({
    super.key,
    required this.store,
  });
  
  @override
  Widget build(BuildContext context) {
    final isOpen = store.isOpenAt(DateTime.now());
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isOpen ? Colors.green : Colors.red,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isOpen ? Icons.access_time : Icons.block,
            color: Colors.white,
            size: 12,
          ),
          const SizedBox(width: 4),
          Text(
            isOpen ? 'Offen' : 'Geschlossen',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
