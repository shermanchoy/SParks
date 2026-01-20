class BotService {
  static String reply(String userText) {
    final t = userText.trim().toLowerCase();

    if (t.isEmpty) return 'Send something and I will help you craft a reply.';

    if (t.contains('hi') || t.contains('hello')) {
      return 'Try: "hey, what course are you in, and what is something you actually enjoy about it?"';
    }

    if (t.contains('study') || t.contains('exam') || t.contains('test')) {
      return 'Try: "what are you working on this week, and how is it going so far?"';
    }

    if (t.contains('food') || t.contains('cafe') || t.contains('eat')) {
      return 'Try: "what is your go to food spot in school, and what do you always order?"';
    }

    if (t.contains('interest') || t.contains('hobby')) {
      return 'Try: "what is one hobby you started recently, and what made you try it?"';
    }

    return 'Icebreaker ideas:\n'
        '1) "what is the most fun mod you had so far?"\n'
        '2) "if you could swap schools for a day, which would you pick and why?"\n'
        '3) "what song is stuck in your head lately?"';
  }
}
