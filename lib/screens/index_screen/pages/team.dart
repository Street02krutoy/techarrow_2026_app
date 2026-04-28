import 'package:flutter/material.dart';
import 'package:techarrow_2026_app/screens/index_screen/team_pages/creation.dart';
import 'package:techarrow_2026_app/screens/index_screen/team_pages/join.dart';
import 'package:techarrow_2026_app/screens/index_screen/team_pages/team.dart';
import 'package:techarrow_2026_app/services/team.dart';

class TeamPage extends StatefulWidget {
  const TeamPage({super.key});

  @override
  State<TeamPage> createState() => _TeamPageState();
}

class _TeamPageState extends State<TeamPage> {
  TeamPageStatus status = TeamPageStatus.join;

  void changePage(TeamPageStatus newStatus) {
    setState(() {
      status = newStatus;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (StreamTeamScope.of(context).team != null) {
      changePage(TeamPageStatus.info);
    }
    switch (status) {
      case TeamPageStatus.join:
        return TeamJoinPage(changePage: changePage);
      case TeamPageStatus.create:
        return TeamCreationPage(changePage: changePage);
      case TeamPageStatus.info:
        return TeamInfoPage(changePage: changePage);
    }
  }
}

enum TeamPageStatus { info, create, join }
