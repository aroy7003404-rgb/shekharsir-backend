class YoutubeService {
  static String extractVideoId(String source) {
    if (source.contains('v=')) {
      return source.split('v=').last.split('&').first;
    }
    if (source.contains('youtu.be/')) {
      return source.split('youtu.be/').last.split('?').first;
    }
    return source;
  }
}
