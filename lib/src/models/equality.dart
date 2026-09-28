/// Element-wise list equality. Internal; keeps models free of Flutter imports.
bool equalLists<T>(List<T> a, List<T> b) {
  if (identical(a, b)) return true;
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

/// Key/value map equality. Internal.
bool equalMaps<K, V>(Map<K, V> a, Map<K, V> b) {
  if (identical(a, b)) return true;
  if (a.length != b.length) return false;
  for (final key in a.keys) {
    if (!b.containsKey(key) || a[key] != b[key]) return false;
  }
  return true;
}

/// Order-independent hash of a map. Internal.
int hashMap<K, V>(Map<K, V> map) => Object.hashAllUnordered(
  map.entries.map((e) => Object.hash(e.key, e.value)),
);
