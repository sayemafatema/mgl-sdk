/// Mirrors TS `FleetSDKConfig`.
class FleetConfig {
  const FleetConfig({
    this.apiBaseUrl = 'https://api.example.com',
    this.authToken,
    this.useMock = true,
  });

  final String apiBaseUrl;
  final String? authToken;

  /// When true, uses in-memory demo fleet data (same IDs as TS mocks).
  final bool useMock;

  FleetConfig copyWith({
    String? apiBaseUrl,
    String? authToken,
    bool? useMock,
  }) {
    return FleetConfig(
      apiBaseUrl: apiBaseUrl ?? this.apiBaseUrl,
      authToken: authToken ?? this.authToken,
      useMock: useMock ?? this.useMock,
    );
  }
}
