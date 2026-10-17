import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/providers.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../checkout/presentation/utils/api_error_detail.dart';
import '../../application/providers/rides_providers.dart';
import '../../domain/entities/fare_quote.dart';
import '../../domain/entities/ride_request.dart';
import '../models/ride_draft.dart';
import '../widgets/fare_breakdown_card.dart';

/// Muestra la cotización (tarifa, distancia y tiempo) antes de confirmar.
class RideQuoteScreen extends ConsumerStatefulWidget {
  const RideQuoteScreen({super.key});

  @override
  ConsumerState<RideQuoteScreen> createState() => _RideQuoteScreenState();
}

class _RideQuoteScreenState extends ConsumerState<RideQuoteScreen> {
  RideDraft? _draft;
  bool _initialized = false;
  FareQuote? _quote;
  bool _loading = true;
  bool _requesting = false;
  String? _error;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;
    final extra = GoRouterState.of(context).extra;
    if (extra is RideDraft) {
      _draft = extra;
      unawaited(_loadQuote());
    } else {
      _loading = false;
      _error = 'No se pudo cargar el viaje.';
    }
  }

  Future<void> _loadQuote() async {
    final draft = _draft;
    if (draft == null) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final quote = await ref.read(quoteRideUseCaseProvider).call(
            QuoteRideParams(pickup: draft.pickup, dropoff: draft.dropoff),
          );
      if (!mounted) return;
      setState(() {
        _quote = quote;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = parseApiErrorDetail(
          error,
          fallback: 'No pudimos cotizar tu viaje.',
        );
        _loading = false;
      });
    }
  }

  Future<void> _requestRide() async {
    final draft = _draft;
    final quote = _quote;
    if (draft == null || quote == null) return;
    setState(() => _requesting = true);
    try {
      final ride = await ref.read(createRideUseCaseProvider).call(
            CreateRideParams(
              pickup: draft.pickup,
              dropoff: draft.dropoff,
              fareBreakdown: quote.fareBreakdown,
              estimatedDurationMinutes: quote.estimatedDurationMinutes,
              estimatedDistanceKm: quote.estimatedDistanceKm,
            ),
          );
      if (!mounted) return;
      context.go('/rides/${ride.id}/tracking');
    } catch (error) {
      if (!mounted) return;
      setState(() => _requesting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            parseApiErrorDetail(error,
                fallback: 'No pudimos solicitar el viaje.'),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: const Key('ride_quote_screen'),
      appBar: AppBar(title: const Text('Confirmar viaje')),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) return const DtsLoading(message: 'Calculando tarifa…');
    if (_error != null) {
      return DtsErrorView(
        message: _error!,
        onRetry: _draft != null ? _loadQuote : null,
      );
    }
    final quote = _quote;
    if (quote == null) {
      return const DtsErrorView(message: 'No pudimos cotizar tu viaje.');
    }

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        _RouteSummary(draft: _draft!),
        const SizedBox(height: AppSpacing.md),
        FareBreakdownCard(
          breakdown: quote.fareBreakdown,
          distanceKm: quote.estimatedDistanceKm,
          durationMinutes: quote.estimatedDurationMinutes,
          zoneName: quote.zoneName,
        ),
        const SizedBox(height: AppSpacing.lg),
        DtsPrimaryButton(
          key: const Key('ride_request_button'),
          label: 'Solicitar viaje',
          icon: Icons.local_taxi,
          isLoading: _requesting,
          onPressed: _requesting ? null : _requestRide,
        ),
      ],
    );
  }
}

class _RouteSummary extends StatelessWidget {
  const _RouteSummary({required this.draft});

  final RideDraft draft;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DtsSectionCard(
      title: 'Ruta',
      child: Column(
        children: [
          _row(
            context,
            icon: Icons.trip_origin,
            color: theme.colorScheme.primary,
            label: 'Origen',
            value: draft.pickup.address,
          ),
          const SizedBox(height: AppSpacing.md),
          _row(
            context,
            icon: Icons.place,
            color: theme.colorScheme.error,
            label: 'Destino',
            value: draft.dropoff.address,
          ),
        ],
      ),
    );
  }

  Widget _row(
    BuildContext context, {
    required IconData icon,
    required Color color,
    required String label,
    required String value,
  }) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              Text(
                value,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
