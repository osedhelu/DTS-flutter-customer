import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../../../../core/config/env.dart';
import '../../../../core/debug/agent_debug_log.dart';
import '../../../../core/di/providers.dart';
import '../../../../core/widgets/widgets.dart';

class OrderChatScreen extends ConsumerStatefulWidget {
  const OrderChatScreen({super.key, required this.orderId});

  final int orderId;

  @override
  ConsumerState<OrderChatScreen> createState() => _OrderChatScreenState();
}

class _OrderChatScreenState extends ConsumerState<OrderChatScreen> {
  final _controller = TextEditingController();
  final _scroll = ScrollController();
  final _messages = <Map<String, dynamic>>[];
  bool _loading = true;
  bool _sending = false;
  WebSocketChannel? _channel;
  StreamSubscription? _sub;
  Timer? _poll;

  bool _sameId(dynamic a, dynamic b) {
    if (a == null || b == null) return false;
    return a.toString() == b.toString();
  }

  void _upsert(Map<String, dynamic> msg) {
    final id = msg['id'];
    final idx = _messages.indexWhere((m) => _sameId(m['id'], id));
    if (idx >= 0) {
      _messages[idx] = msg;
    } else {
      _messages.add(msg);
    }
  }

  @override
  void initState() {
    super.initState();
    _bootstrap();
    _poll = Timer.periodic(const Duration(seconds: 8), (_) {
      if (mounted) unawaited(_loadHistory(silent: true));
    });
  }

  @override
  void dispose() {
    _poll?.cancel();
    _sub?.cancel();
    _channel?.sink.close();
    _controller.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _bootstrap() async {
    await _loadHistory();
    await _connectWs();
  }

  Future<void> _loadHistory({bool silent = false}) async {
    try {
      final dio = ref.read(apiClientProvider).dio;
      final res = await dio.get('/orders/${widget.orderId}/messages/');
      final list = (res.data as List).cast<dynamic>();
      // #region agent log
      if (!silent) {
        agentDebugLog(
          location: 'order_chat_screen.dart:_loadHistory',
          message: 'chat history loaded',
          hypothesisId: 'D',
          data: {
            'orderId': widget.orderId,
            'count': list.length,
            'statusCode': res.statusCode,
          },
        );
      }
      // #endregion
      if (!mounted) return;
      setState(() {
        if (!silent) {
          _messages.clear();
        }
        for (final e in list) {
          _upsert(Map<String, dynamic>.from(e as Map));
        }
        _loading = false;
      });
      if (!silent) _scrollToEnd();
    } catch (e) {
      // #region agent log
      if (!silent) {
        agentDebugLog(
          location: 'order_chat_screen.dart:_loadHistory',
          message: 'chat history failed',
          hypothesisId: 'D',
          data: {
            'orderId': widget.orderId,
            'error': e.toString(),
          },
        );
      }
      // #endregion
      if (!mounted) return;
      if (!silent) setState(() => _loading = false);
    }
  }

  Future<void> _connectWs() async {
    try {
      final token = await ref.read(tokenStorageProvider).getAccessToken();
      // #region agent log
      agentDebugLog(
        location: 'order_chat_screen.dart:_connectWs',
        message: 'chat ws connect start',
        hypothesisId: 'C',
        data: {
          'orderId': widget.orderId,
          'hasToken': token != null && token.isNotEmpty,
          'tokenLen': token?.length ?? 0,
        },
      );
      // #endregion
      if (token == null || token.isEmpty) return;
      final uri = EnvConfig.buildWsUri(
        '/ws/orders/${widget.orderId}/chat/'
        '?token=${Uri.encodeQueryComponent(token)}',
      );
      // #region agent log
      agentDebugLog(
        location: 'order_chat_screen.dart:_connectWs',
        message: 'chat ws uri built',
        hypothesisId: 'A',
        data: {
          'scheme': uri.scheme,
          'host': uri.host,
          'port': uri.port,
          'hasPort': uri.hasPort,
          'path': uri.path,
          'uriNoQuery': uri.replace(query: '').toString(),
          'containsColonZero': uri.toString().contains(':0'),
        },
      );
      // #endregion
      final channel = WebSocketChannel.connect(uri);
      await channel.ready;
      // #region agent log
      agentDebugLog(
        location: 'order_chat_screen.dart:_connectWs',
        message: 'chat ws ready ok',
        hypothesisId: 'B',
        data: {'orderId': widget.orderId, 'port': uri.port},
      );
      // #endregion
      if (!mounted) {
        await channel.sink.close();
        return;
      }
      _channel = channel;
      _sub = channel.stream.listen(
        (event) {
          try {
            final data = jsonDecode(event as String) as Map<String, dynamic>;
            if (data.containsKey('body')) {
              if (!mounted) return;
              setState(() => _upsert(data));
              _scrollToEnd();
            }
          } catch (_) {}
        },
        onError: (Object err) {
          // #region agent log
          agentDebugLog(
            location: 'order_chat_screen.dart:onError',
            message: 'chat ws stream error',
            hypothesisId: 'B',
            data: {'error': err.toString()},
          );
          // #endregion
        },
        cancelOnError: true,
      );
    } catch (e) {
      // #region agent log
      agentDebugLog(
        location: 'order_chat_screen.dart:_connectWs',
        message: 'chat ws connect failed',
        hypothesisId: 'B',
        data: {
          'orderId': widget.orderId,
          'error': e.toString(),
          'errorType': e.runtimeType.toString(),
        },
      );
      // #endregion
    }
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      _scroll.animateTo(
        _scroll.position.maxScrollExtent + 80,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    });
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _sending) return;
    setState(() => _sending = true);
    try {
      final dio = ref.read(apiClientProvider).dio;
      final res = await dio.post(
        '/orders/${widget.orderId}/messages/',
        data: {'body': text},
      );
      _controller.clear();
      if (!mounted) return;
      final msg = Map<String, dynamic>.from(res.data as Map);
      setState(() => _upsert(msg));
      // REST es source of truth; el backend hace fan-out WS (no sink.add).
      _scrollToEnd();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo enviar')),
      );
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Chat #${widget.orderId}')),
      body: Column(
        children: [
          Expanded(
            child: _loading
                ? const DtsLoading()
                : _messages.isEmpty
                    ? const DtsEmptyState(
                        icon: Icons.chat_bubble_outline,
                        title: 'Sin mensajes',
                        message:
                            'Escribe al comercio o al conductor del pedido.',
                      )
                    : ListView.builder(
                        controller: _scroll,
                        padding: const EdgeInsets.all(12),
                        itemCount: _messages.length,
                        itemBuilder: (_, i) {
                          final m = _messages[i];
                          final mine = m['sender_role'] == 'customer';
                          return Align(
                            alignment: mine
                                ? Alignment.centerRight
                                : Alignment.centerLeft,
                            child: Container(
                              margin: const EdgeInsets.symmetric(vertical: 4),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: mine
                                    ? Theme.of(context)
                                        .colorScheme
                                        .primaryContainer
                                    : Theme.of(context)
                                        .colorScheme
                                        .surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text('${m['body']}'),
                            ),
                          );
                        },
                      ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      onSubmitted: (_) => _send(),
                      decoration: const InputDecoration(
                        hintText: 'Escribe un mensaje…',
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: _send,
                    icon: const Icon(Icons.send),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
