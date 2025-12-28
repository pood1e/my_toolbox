import 'dart:async';
import 'dart:convert';

import 'package:app_core/logger.dart';
import 'package:auth_api/auth_api.dart';
import 'package:stomp_dart_client/stomp_dart_client.dart';
import 'package:sync_api/sync_api.dart';

import '../realtime_service.dart';

class RealtimeServiceImpl implements RealtimeService {
  final RemoteServer _server;
  final String _token;
  final SyncAction _syncAction;

  // 回调：仅通知外部去刷新 Token，Service 内部不再处理重连逻辑
  final Future<void> Function() _onAuthExpired;

  StompClient? _client;

  RealtimeServiceImpl({
    required RemoteServer server,
    required String token,
    required SyncAction triggerSyncAction,
    required Future<void> Function() onAuthExpired,
  }) : _server = server,
       _token = token,
       _syncAction = triggerSyncAction,
       _onAuthExpired = onAuthExpired;

  /// 启动连接
  @override
  Future<void> start() async {
    if (_client != null) return;

    final wsUrl =
        '${_server.tls ? "wss" : "ws"}://${_server.host}:${_server.port}/ws-sync';

    logger.i('🔌 Sync Realtime: Connecting ...');

    _client = StompClient(
      config: StompConfig(
        url: wsUrl,
        // Header 在构造时确定，不可变
        stompConnectHeaders: {'Authorization': 'Bearer $_token'},
        webSocketConnectHeaders: {'Authorization': 'Bearer $_token'},

        onConnect: _onConnect,

        onWebSocketError: (dynamic error) {
          logger.e('❌ WS Error: $error');
          _checkForAuthError(error.toString());
        },

        onStompError: (frame) {
          logger.e('❌ Stomp Error: ${frame.body}');
          _checkForAuthError(frame.body ?? '');
        },

        onDisconnect: (frame) {
          logger.i('🔌 Sync Realtime Disconnected');
        },

        // 这里的重连只处理网络波动，不处理 Token 刷新
        reconnectDelay: const Duration(seconds: 5),
        heartbeatOutgoing: const Duration(seconds: 10),
        heartbeatIncoming: const Duration(seconds: 10),
      ),
    );

    _client?.activate();
  }

  /// 停止连接 (清理资源)
  @override
  Future<void> stop() async {
    logger.i('🛑 Sync Realtime: Stopping client...');
    _client?.deactivate();
    _client = null;
  }

  void _onConnect(StompFrame frame) {
    logger.i('✅ Sync Realtime Connected');
    _client?.subscribe(
      destination: '/user/topic/sync',
      callback: (frame) {
        if (frame.body != null) {
          try {
            final data = jsonDecode(frame.body!);
            if (data['type'] == 'sync_trigger' && data['resourceId'] != null) {
              _syncAction(data['resourceId']);
            }
          } catch (e) {
            logger.e('⚠️ JSON Parse Error: $e');
          }
        }
      },
    );
  }

  void _checkForAuthError(String errorStr) {
    bool isUnauthorized =
        errorStr.contains('401') || errorStr.contains('Unauthorized');
    if (isUnauthorized) {
      logger.e('🚨 WS: 401 detected, requesting token refresh...');
      _onAuthExpired();
    }
  }
}
