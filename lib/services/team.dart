import 'dart:async';

import 'package:flutter/material.dart';
import 'package:techarrow_2026_app/gen/swagger.swagger.dart';
import 'package:techarrow_2026_app/services/api.dart';

/// Provides current user's team from [Swagger.apiTeamsMeGet] (global app state).
class StreamTeamScope extends InheritedNotifier<StreamTeamNotifier> {
  StreamTeamScope({super.key, required super.child})
    : super(notifier: StreamTeamNotifier());

  static StreamTeam of(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<StreamTeamScope>()!
        .notifier!
        .streamTeam;
  }
}

class StreamTeamNotifier extends ChangeNotifier {
  StreamTeamNotifier() : streamTeam = StreamTeam() {
    streamTeam.onTeamChanged.listen((_) => notifyListeners());
  }

  final StreamTeam streamTeam;

  @override
  void dispose() {
    streamTeam.dispose();
    super.dispose();
  }
}

class StreamTeam {
  StreamTeam()
    : _controller = StreamController<TeamResponse?>.broadcast() {
    _controller.stream.listen((TeamResponse? next) {
      _team = next;
    });
  }

  TeamResponse? _team;

  /// Current team for the signed-in user, or `null` if not in a team or not loaded yet.
  TeamResponse? get team => _team;

  Stream<TeamResponse?> get onTeamChanged => _controller.stream;

  final StreamController<TeamResponse?> _controller;

  /// Publishes a [team] from an API response (e.g. `POST /api/teams` create).
  void setTeam(TeamResponse team) {
    _team = team;
    _controller.add(team);
  }

  /// Loads team from `GET /teams/me`. Safe to call after sign-in or after joining a team.
  Future<void> refresh() async {
    try {
      final res = await ApiService.instance.client.apiTeamsMeGet();
      if (res.isSuccessful && res.body != null) {
        _team = res.body;
        _controller.add(_team);
      } else {
        _team = null;
        _controller.add(null);
      }
    } catch (_) {
      _team = null;
      _controller.add(null);
    }
  }

  void dispose() {
    _controller.close();
  }
}

/// Calls [StreamTeam.refresh] once after the first frame (when auth tokens are ready).
class TeamBootstrap extends StatefulWidget {
  const TeamBootstrap({super.key, required this.child});

  final Widget child;

  @override
  State<TeamBootstrap> createState() => _TeamBootstrapState();
}

class _TeamBootstrapState extends State<TeamBootstrap> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      StreamTeamScope.of(context).refresh();
    });
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
