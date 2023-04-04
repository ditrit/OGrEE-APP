import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:ogree_app/common/api.dart';
import 'package:ogree_app/common/popup_dialog.dart';
import 'package:ogree_app/common/snackbar.dart';
import 'package:ogree_app/models/tenant.dart';
import 'package:ogree_app/pages/tenant_page.dart';
import 'package:ogree_app/widgets/tenants/container_logs_popup.dart';
import 'package:url_launcher/url_launcher.dart';

class TenantCard extends StatelessWidget {
  final Tenant tenant;
  final Function parentCallback;
  const TenantCard(
      {Key? key, required this.tenant, required this.parentCallback});

  @override
  Widget build(BuildContext context) {
    final localeMsg = AppLocalizations.of(context)!;
    return SizedBox(
      width: 265,
      height: 250,
      child: Card(
        elevation: 3,
        surfaceTintColor: Colors.white,
        margin: const EdgeInsets.all(10),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    width: 145,
                    child: Text(tenant.name,
                        overflow: TextOverflow.clip,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                  CircleAvatar(
                    backgroundColor: Colors.red.shade100,
                    radius: 13,
                    child: IconButton(
                        splashRadius: 18,
                        iconSize: 14,
                        padding: const EdgeInsets.all(2),
                        onPressed: () => showCustomPopup(
                            context,
                            DeleteTenantDialog(
                              tenantName: tenant.name,
                              parentCallback: parentCallback,
                            ),
                            isDismissible: true),
                        icon: Icon(
                          Icons.delete,
                          color: Colors.red.shade900,
                        )),
                  ),
                  SizedBox(width: 8),
                  CircleAvatar(
                    radius: 13,
                    child: IconButton(
                        splashRadius: 18,
                        iconSize: 14,
                        padding: const EdgeInsets.all(2),
                        onPressed: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => TenantPage(
                                    userEmail: "userEmail", tenant: tenant),
                              ),
                            ),
                        icon: const Icon(
                          Icons.search,
                        )),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(bottom: 2.0),
                    child: Text("API URL:"),
                  ),
                  Text(
                    "http://localhost:${tenant.apiUrl}",
                    style: TextStyle(backgroundColor: Colors.grey.shade200),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(bottom: 2.0),
                    child: Text("Web URL:"),
                  ),
                  Text(
                    "http://localhost:${tenant.webUrl}",
                    style: TextStyle(backgroundColor: Colors.grey.shade200),
                  ),
                ],
              ),
              Align(
                alignment: Alignment.bottomRight,
                child: TextButton.icon(
                    onPressed: () {
                      launchUrl(Uri.parse("http://localhost:${tenant.webUrl}"));
                    },
                    icon: const Icon(Icons.play_circle),
                    label: Text(localeMsg.launch)),
              )
            ],
          ),
        ),
      ),
    );
  }
}

class DeleteTenantDialog extends StatefulWidget {
  final String tenantName;
  final Function parentCallback;
  const DeleteTenantDialog(
      {super.key, required this.tenantName, required this.parentCallback});

  @override
  State<DeleteTenantDialog> createState() => _DeleteTenantDialogState();
}

class _DeleteTenantDialogState extends State<DeleteTenantDialog> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        height: 230,
        width: 480,
        margin: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
            color: Colors.white, borderRadius: BorderRadius.circular(40)),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 10),
          child: Material(
            color: Colors.white,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text("Êtes-vous sûr ?",
                    style: Theme.of(context).textTheme.headlineLarge),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 40),
                  child: Text(
                      "Toutes les données du tenant seront définitivement perdues !"),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton.icon(
                      style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red.shade900),
                      onPressed: () async {
                        setState(() => _isLoading = true);
                        var response = await deleteTenant(widget.tenantName);
                        setState(() => _isLoading = false);
                        if (response == "") {
                          widget.parentCallback();
                          Navigator.of(context).pop();
                          showSnackBar(context, "Tenant successfully deleted");
                        } else {
                          showSnackBar(context, "Error: " + response);
                        }
                      },
                      label: Text("Supprimer Tenant"),
                      icon: _isLoading
                          ? Container(
                              width: 24,
                              height: 24,
                              padding: const EdgeInsets.all(2.0),
                              child: const CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 3,
                              ),
                            )
                          : Icon(
                              Icons.delete,
                              size: 16,
                            ),
                    ),
                    const SizedBox(width: 15),
                    ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text("Annuler"),
                    )
                  ],
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
