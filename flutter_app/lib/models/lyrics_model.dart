class LyricLine {
  final Duration timestamp;
  final String text;

  LyricLine({
    required this.timestamp,
    required this.text,
  });

  Map<String, dynamic> toJson() => {
    'timestampMs': timestamp.inMilliseconds,
    'text': text,
  };

  factory LyricLine.fromJson(Map<String, dynamic> json) => LyricLine(
    timestamp: Duration(milliseconds: json['timestampMs'] as int? ?? 0),
    text: json['text'] as String? ?? '',
  );
}

class LyricsData {
  final List<LyricLine> lines;
  final String? plainLyrics;
  final bool isInstrumental;
  final bool hasSynced;
  final String? source;

  LyricsData({
    required this.lines,
    this.plainLyrics,
    this.isInstrumental = false,
    this.hasSynced = false,
    this.source,
  });

  Map<String, dynamic> toJson() => {
    'synced': hasSynced ? _toLrcString() : null,
    'plain': plainLyrics,
    'isInstrumental': isInstrumental,
    'source': source,
  };

  String _toLrcString() {
    final buffer = StringBuffer();
    for (final line in lines) {
      final minutes = line.timestamp.inMinutes.remainder(60).toString().padLeft(2, '0');
      final seconds = line.timestamp.inSeconds.remainder(60).toString().padLeft(2, '0');
      final millis = (line.timestamp.inMilliseconds.remainder(1000) ~/ 10).toString().padLeft(2, '0');
      buffer.writeln('[$minutes:$seconds.$millis] ${line.text}');
    }
    return buffer.toString();
  }

  factory LyricsData.fromJson(Map<String, dynamic> json) {
    final synced = json['synced'] as String?;
    final plain = json['plain'] as String?;
    final isInstrumental = json['isInstrumental'] as bool? ?? false;
    final source = json['source'] as String?;

    return LyricsData.fromLrc(synced, plain, isInstrumental, source: source);
  }

  factory LyricsData.fromLrc(
    String? lrc,
    String? plain,
    bool instrumental, {
    String? source,
  }) {
    if (instrumental) {
      return LyricsData(
        lines: const [],
        isInstrumental: true,
        hasSynced: false,
        source: source,
      );
    }

    if (lrc == null || lrc.trim().isEmpty) {
      return LyricsData(
        lines: const [],
        plainLyrics: plain?.trim(),
        hasSynced: false,
        isInstrumental: false,
        source: source,
      );
    }

    final parsedLines = <LyricLine>[];
    // Matches [mm:ss.xx] or [mm:ss.xxx] or [mm:ss]
    final regex = RegExp(r'\[(\d{1,2}):(\d{2})(?:\.(\d{1,3}))?\](.*)');

    for (final rawLine in lrc.split('\n')) {
      final trimmed = rawLine.trim();
      if (trimmed.isEmpty) continue;

      final match = regex.firstMatch(trimmed);
      if (match != null) {
        final minutes = int.tryParse(match.group(1) ?? '0') ?? 0;
        final seconds = int.tryParse(match.group(2) ?? '0') ?? 0;
        final rawFraction = match.group(3);
        int millis = 0;
        if (rawFraction != null) {
          if (rawFraction.length == 1) {
            millis = int.parse(rawFraction) * 100;
          } else if (rawFraction.length == 2) {
            millis = int.parse(rawFraction) * 10;
          } else {
            millis = int.parse(rawFraction.substring(0, 3));
          }
        }
        final text = (match.group(4) ?? '').trim();
        // Even empty lyrics lines can represent pauses in karaoke
        parsedLines.add(LyricLine(
          timestamp: Duration(minutes: minutes, seconds: seconds, milliseconds: millis),
          text: text,
        ));
      }
    }

    parsedLines.sort((a, b) => a.timestamp.compareTo(b.timestamp));

    return LyricsData(
      lines: parsedLines,
      plainLyrics: plain?.trim(),
      hasSynced: parsedLines.isNotEmpty,
      isInstrumental: false,
      source: source,
    );
  }
}
