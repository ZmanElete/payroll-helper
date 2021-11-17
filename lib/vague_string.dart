class VagueString {
  String key;
  Set<String> interpritations;

  VagueString({required this.key, this.interpritations = const {}}) {
    interpritations = {
      ...interpritations,
      key,
    };
  }

  @override
  String toString() {
    return key;
  }

  @override
  // ignore: hash_and_equals
  bool operator ==(dynamic other) {
    if (other is String) {
      return other == key || interpritations.contains(other);
    }
    return super == other;
  }
}
