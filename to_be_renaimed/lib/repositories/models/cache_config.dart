

class CacheConfig {
  final Duration expireTime;
  final bool forceRefresh;

  const CacheConfig({
    this.expireTime = const Duration(hours: 24),
    this.forceRefresh = false,
  });

  static const CacheConfig defaultConfig = CacheConfig();
  static const CacheConfig shortLived = CacheConfig(expireTime: Duration(minutes: 5));
  static const CacheConfig refresh = CacheConfig(forceRefresh: true);
}