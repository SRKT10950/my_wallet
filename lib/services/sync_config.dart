class SyncConfig {
  static const String host = '192.168.50.109';
  static const String database = 'mWallet';
  static const String username = 'walletintegrationuser';
  static const String password = 'wallet@0909090909@';
  static const int port = 5432;

  // Set this to true to route all database sync queries through an intermediate REST API gateway
  static const bool useApiGateway = true;
  static const String apiGatewayUrl = 'https://db.mhservice.co.in/api/db/mWallet/query';
  static const String apiKey = 'hs_live_8cxzSYAq9aUv79HxDbADCdJ23yLtIWhQ';
}
