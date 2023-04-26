// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:ogree_app/common/api_backend.dart';
import 'package:ogree_app/models/tenant.dart';

class ApiStatsView extends StatefulWidget {
  Tenant tenant;
  ApiStatsView({
    Key? key,
    required this.tenant,
  }) : super(key: key);
  @override
  State<ApiStatsView> createState() => _ApiStatsViewState();
}

class _ApiStatsViewState extends State<ApiStatsView> {
  Map<String, dynamic>? _tenantStats;

  @override
  Widget build(BuildContext context) {
    final localeMsg = AppLocalizations.of(context)!;
    return FutureBuilder(
        future: getTenantStats(),
        builder: (context, _) {
          if (_tenantStats == null) {
            return const Center(child: CircularProgressIndicator());
          } else if (_tenantStats!.isNotEmpty) {
            List<Widget> stats = [];
            for (var key in _tenantStats!.keys) {
              stats.add(Padding(
                padding: const EdgeInsets.only(left: 2, right: 10),
                child: Row(
                  children: [
                    Text(
                      "$key : ",
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(_tenantStats![key].toString())
                  ],
                ),
              ));
            }
            return Expanded(
              child: SingleChildScrollView(child: Column(children: stats)),
            );
          } else {
            // Empty messages
            return Text(localeMsg.noProjects);
          }
        });
  }

  getTenantStats() async {
    _tenantStats = await fetchTenantStats(
        "http://${widget.tenant.apiUrl}:${widget.tenant.apiPort}");
    Map<String, dynamic> versionStats = await fetchTenantApiVersion(
        "http://${widget.tenant.apiUrl}:${widget.tenant.apiPort}");
    for (var key in versionStats.keys) {
      if (key.contains("Build")) {
        _tenantStats!["API$key"] = versionStats[key];
      } else {
        _tenantStats![key] = versionStats[key];
      }
    }
  }
}
