import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ogree_app/common/api_backend.dart';
import 'package:ogree_app/common/snackbar.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:ogree_app/models/tenant.dart';

class CreateServerPopup extends StatefulWidget {
  Function() parentCallback;
  CreateServerPopup({super.key, required this.parentCallback});

  @override
  State<CreateServerPopup> createState() => _CreateServerPopupState();
}

class _CreateServerPopupState extends State<CreateServerPopup> {
  final _formKey = GlobalKey<FormState>();
  String? _sshHost;
  String? _sshUser;
  String? _sshKey;
  String? _installPath;
  String? _sshDirPath;
  String? _port;
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final localeMsg = AppLocalizations.of(context)!;
    return Center(
      child: Container(
        // height: 240,
        width: 500,
        margin: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
            color: Colors.white, borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(40, 20, 40, 15),
          child: Material(
            color: Colors.white,
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.add_to_photos),
                      Text(
                        "   Create new Backend Server",
                        style: GoogleFonts.inter(
                          fontSize: 22,
                          color: Colors.black,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 45),
                  getFormField(
                      save: (newValue) => _sshHost = newValue,
                      label: "SSH Host",
                      icon: Icons.dns),
                  getFormField(
                      save: (newValue) => _sshUser = newValue,
                      label: "SSH User",
                      icon: Icons.person),
                  getFormField(
                      save: (newValue) => _sshKey = newValue,
                      label: "SSH Private Key (/local/path/file)",
                      icon: Icons.lock),
                  getFormField(
                      save: (newValue) => _installPath = newValue,
                      label: "Install Path on server",
                      icon: Icons.folder),
                  getFormField(
                      save: (newValue) => _port = newValue,
                      label: "Backend Port on server",
                      icon: Icons.onetwothree,
                      formatters: [FilteringTextInputFormatter.digitsOnly]),
                  const SizedBox(height: 40),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton.icon(
                        style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.blue.shade900),
                        onPressed: () => Navigator.pop(context),
                        label: Text(localeMsg.cancel),
                        icon: const Icon(
                          Icons.cancel_outlined,
                          size: 16,
                        ),
                      ),
                      const SizedBox(width: 15),
                      ElevatedButton.icon(
                          onPressed: () async {
                            if (_formKey.currentState!.validate()) {
                              _formKey.currentState!.save();
                              setState(() {
                                _isLoading = true;
                              });
                              var response =
                                  await createBackendServer(<String, String>{
                                'host': _sshHost!,
                                'user': _sshUser!,
                                'pkey': _sshKey!,
                                'dstpath': _installPath!,
                                'runport': _port!,
                              });
                              if (response == "") {
                                widget.parentCallback();
                                showSnackBar(
                                    context, "New Backend created on server",
                                    isSuccess: true);
                                Navigator.of(context).pop();
                              } else {
                                setState(() {
                                  _isLoading = false;
                                });
                                showSnackBar(context, response, isError: true);
                              }
                            }
                          },
                          label: Text(localeMsg.create),
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
                              : const Icon(Icons.check_circle, size: 16))
                    ],
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  getFormField(
      {required Function(String?) save,
      required String label,
      required IconData icon,
      String? prefix,
      String? suffix,
      List<TextInputFormatter>? formatters}) {
    return Padding(
      padding: const EdgeInsets.only(left: 2, right: 10),
      child: TextFormField(
        onSaved: (newValue) => save(newValue),
        validator: (text) {
          if (text == null || text.isEmpty) {
            return AppLocalizations.of(context)!.mandatoryField;
          }
          return null;
        },
        inputFormatters: formatters,
        decoration: InputDecoration(
          icon: Icon(icon, color: Colors.blue.shade900),
          labelText: label,
          prefixText: prefix,
          suffixText: suffix,
        ),
      ),
    );
  }
}
