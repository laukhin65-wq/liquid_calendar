import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/calendar_provider.dart';
import '../widgets/glass.dart';
import 'package:string_similarity/string_similarity.dart';

import '../data/models/event_category.dart';
import '../data/models/calendar_event.dart';

import 'dart:async';

class _SearchResult {
  final CalendarEvent event;
  final double score;
  final bool matches;

  const _SearchResult({
    required this.event,
    required this.score,
    required this.matches,
  });
}

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  Timer? _debounce;
  String query = '';
  List<String> recentSearches = [];

  String categoryName(EventCategory category) {
    return category.label.toLowerCase();
  }

  Color _categoryColor(EventCategory category) {
    return category.color;
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  /// Обновление запроса с debounce (общее для обычного и стеклянного поля).
  void _onQueryChanged(String value) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      setState(() {
        query = value;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CalendarProvider>();
    final glass = isGlassTheme(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;
    final hintColor = isDark ? Colors.white54 : Colors.black38;
    final subtitleColor = isDark ? Colors.white60 : Colors.black54;
    final dividerColor = isDark ? Colors.white12 : Colors.black12;

    final q = query.toLowerCase();

    final scored = provider.filteredEvents.map((event) {
      final title = event.title.toLowerCase();

      final date = '${event.start.day.toString().padLeft(2, '0')}.'
          '${event.start.month.toString().padLeft(2, '0')}.'
          '${event.start.year}';

      final time = '${event.start.hour.toString().padLeft(2, '0')}:'
          '${event.start.minute.toString().padLeft(2, '0')}';

      double score = 0;
      bool matches = true;

      if (q.isEmpty) {
        score = 1.0;
      } else {
        if (title.contains(q) ||
            categoryName(event.category).toLowerCase().contains(q) ||
            date.contains(q) ||
            time.contains(q)) {
          score = 1.0;
        } else {
          score = title.similarityTo(q);
          matches = score > 0.35;
        }
      }

      return _SearchResult(event: event, score: score, matches: matches);
    }).where((r) => r.matches).toList();

    scored.sort((a, b) {
      final aStarts = a.event.title.toLowerCase().startsWith(q);
      final bStarts = b.event.title.toLowerCase().startsWith(q);
      if (aStarts && !bStarts) return -1;
      if (!aStarts && bStarts) return 1;
      return b.score.compareTo(a.score);
    });

    final results = scored.map((r) => r.event).toList();

    final searchField = glass
        ? GlassContainer(
            borderRadius: const BorderRadius.all(Radius.circular(16)),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: TextField(
              style: TextStyle(color: textColor),
              decoration: InputDecoration(
                hintText: 'Введите название...',
                hintStyle: TextStyle(color: hintColor),
                prefixIcon: Icon(Icons.search, color: hintColor),
                border: InputBorder.none,
              ),
              onChanged: _onQueryChanged,
            ),
          )
        : TextField(
            style: TextStyle(color: textColor),
            decoration: InputDecoration(
              hintText: 'Введите название...',
              hintStyle: TextStyle(color: hintColor),
              prefixIcon: Icon(Icons.search, color: hintColor),
            ),
            onChanged: _onQueryChanged,
          );

    final searchBody = Scaffold(
      backgroundColor: glass ? Colors.transparent : null,
      appBar: AppBar(
        title: Text('Поиск событий', style: TextStyle(color: textColor)),
        backgroundColor: glass ? Colors.transparent : null,
        elevation: 0,
        iconTheme: IconThemeData(color: textColor),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: searchField,
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Найдено: ${results.length}',
                style: TextStyle(color: subtitleColor),
              ),
            ),
          ),

          const SizedBox(height: 8),

          if (query.isEmpty && recentSearches.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Последние запросы',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: recentSearches.map((search) {
                      return ActionChip(
                        label: Text(search),
                        onPressed: () {
                          setState(() {
                            query = search;
                          });
                        },
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),

          Expanded(
            child: ListView.separated(
              itemCount: results.length,
              separatorBuilder: (_, _) => Divider(
                height: 1,
                color: dividerColor,
                indent: 72,
              ),
              itemBuilder: (context, index) {
                final event = results[index];

                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: _categoryColor(event.category),
                    child: const Icon(
                      Icons.event,
                      color: Colors.white,
                    ),
                  ),
                  title: _HighlightedText(
                    text: event.title,
                    query: query,
                    textColor: textColor,
                    highlightColor: Colors.amber,
                  ),
                  subtitle: Text(
                    '${categoryName(event.category)} • '
                        '${event.start.day.toString().padLeft(2, '0')}.'
                        '${event.start.month.toString().padLeft(2, '0')}.'
                        '${event.start.year} • '
                        '${event.start.hour.toString().padLeft(2, '0')}:'
                        '${event.start.minute.toString().padLeft(2, '0')}',
                    style: TextStyle(color: subtitleColor),
                  ),
                  onTap: () {
                    if (query.isNotEmpty && !recentSearches.contains(query)) {
                      setState(() {
                        recentSearches.insert(0, query);
                        if (recentSearches.length > 5) {
                          recentSearches.removeLast();
                        }
                      });
                    }

                    provider.setDate(event.start);
                    Navigator.pop(context);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );

    if (!glass) return searchBody;
    return GlassBackdrop(child: searchBody);
  }
}

class _HighlightedText extends StatelessWidget {
  final String text;
  final String query;
  final Color textColor;
  final Color highlightColor;

  const _HighlightedText({
    required this.text,
    required this.query,
    this.textColor = Colors.black87,
    this.highlightColor = Colors.amber,
  });

  @override
  Widget build(BuildContext context) {
    if (query.isEmpty) {
      return Text(text, style: TextStyle(color: textColor));
    }

    final lowerText = text.toLowerCase();
    final lowerQuery = query.toLowerCase();
    final start = lowerText.indexOf(lowerQuery);

    if (start == -1) {
      return Text(text, style: TextStyle(color: textColor));
    }

    final end = start + query.length;

    return RichText(
      text: TextSpan(
        style: TextStyle(color: textColor),
        children: [
          TextSpan(
            text: text.substring(0, start),
          ),
          TextSpan(
            text: text.substring(start, end),
            style: TextStyle(
              fontWeight: FontWeight.bold,
              backgroundColor: highlightColor,
            ),
          ),
          TextSpan(
            text: text.substring(end),
          ),
        ],
      ),
    );
  }
}

int levenshtein(String s, String t) {
  if (s == t) return 0;
  if (s.isEmpty) return t.length;
  if (t.isEmpty) return s.length;

  final matrix = List.generate(
    s.length + 1,
        (_) => List.filled(t.length + 1, 0),
  );

  for (int i = 0; i <= s.length; i++) {
    matrix[i][0] = i;
  }

  for (int j = 0; j <= t.length; j++) {
    matrix[0][j] = j;
  }

  for (int i = 1; i <= s.length; i++) {
    for (int j = 1; j <= t.length; j++) {
      final cost = s[i - 1] == t[j - 1] ? 0 : 1;
      matrix[i][j] = [
        matrix[i - 1][j] + 1,
        matrix[i][j - 1] + 1,
        matrix[i - 1][j - 1] + cost,
      ].reduce((a, b) => a < b ? a : b);
    }
  }

  return matrix[s.length][t.length];
}