import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ogree_app/common/api_backend.dart';
import 'package:ogree_app/common/snackbar.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:ogree_app/models/domain.dart';
import 'package:ogree_app/models/tenant.dart';
import 'package:file_picker/file_picker.dart';

class CreateDomainPopup extends StatefulWidget {
  Function() parentCallback;
  String? domainId;
  CreateDomainPopup({super.key, required this.parentCallback, this.domainId});

  @override
  State<CreateDomainPopup> createState() => _CreateDomainPopupState();
}

class _CreateDomainPopupState extends State<CreateDomainPopup>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  String? _domainParent;
  String? _domainName;
  String? _domainColor;
  Color _localColor = Colors.blue.shade900;
  String? _domainDescription;
  bool _isLoading = false;
  bool _isLoadingDelete = false;
  bool _isEdit = false;
  Domain? domain;
  String? domainId;
  late TabController _tabController;
  PlatformFile? _loadedFile;
  String? _loadFileResult;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    _isEdit = widget.domainId != null;
    final localeMsg = AppLocalizations.of(context)!;
    return FutureBuilder(
      future: _isEdit && domain == null ? getDomain() : null,
      builder: (context, _) {
        if (!_isEdit || (_isEdit && domain != null)) {
          return DomainForm(localeMsg);
        } else {
          return const Center(child: CircularProgressIndicator());
        }
      },
    );
  }

  getDomain() async {
    domain = await fetchDomain(widget.domainId!);
    if (domain == null) {
      showSnackBar(context, "Unable to retrieve domain", isError: true);
      Navigator.of(context).pop();
      return;
    }
    domainId = domain!.parent == ""
        ? domain!.name
        : "${domain!.parent}.${domain!.name}";
    _localColor = Color(int.parse("0xFF${domain!.color}"));
  }

  DomainForm(AppLocalizations localeMsg) {
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
                  Text(
                    _isEdit ? "Modifier domain" : "Créer un nouveau domain",
                    style: TextStyle(
                      fontSize: 22,
                      color: Colors.black,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const Divider(),
                  TabBar(
                    controller: _tabController,
                    // labelPadding: const EdgeInsets.only(left: 20, right: 20),
                    // labelColor: Colors.black,
                    // unselectedLabelColor: Colors.grey,
                    // labelStyle: TextStyle(
                    //     fontSize: 14,
                    //     fontFamily: GoogleFonts.inter().fontFamily),
                    // unselectedLabelStyle: TextStyle(
                    //     fontSize: 14,
                    //     fontFamily: GoogleFonts.inter().fontFamily),
                    isScrollable: true,
                    indicatorSize: TabBarIndicatorSize.label,
                    tabs: [
                      Tab(
                        text: "Single domain",
                      ),
                      Tab(
                        text: "Bulk file",
                      ),
                    ],
                  ),
                  Container(
                    height: 250,
                    child: TabBarView(
                        physics: NeverScrollableScrollPhysics(),
                        controller: _tabController,
                        children: [
                          ListView(
                            children: [
                              getFormField(
                                  save: (newValue) => _domainParent = newValue,
                                  label: "Parent Domain",
                                  icon: Icons.auto_awesome_mosaic,
                                  initialValue: _isEdit ? domain!.parent : null,
                                  noValidation: true),
                              getFormField(
                                  save: (newValue) => _domainName = newValue,
                                  label: "Nom du domain",
                                  icon: Icons.auto_awesome_mosaic,
                                  initialValue: _isEdit ? domain!.name : null),
                              getFormField(
                                  save: (newValue) =>
                                      _domainDescription = newValue,
                                  label: "Description",
                                  icon: Icons.message,
                                  initialValue:
                                      _isEdit ? domain!.description : null),
                              getFormField(
                                  save: (newValue) => _domainColor = newValue,
                                  label: "Couleur",
                                  icon: Icons.color_lens,
                                  formatters: [
                                    FilteringTextInputFormatter.allow(
                                        RegExp(r'[0-9a-fA-F]'))
                                  ],
                                  isColor: true,
                                  initialValue: _isEdit ? domain!.color : null),
                            ],
                          ),
                          Center(
                            child: ListView(shrinkWrap: true, children: [
                              Align(
                                child: ElevatedButton.icon(
                                    onPressed: () async {
                                      print("hey there");
                                      FilePickerResult? result =
                                          await FilePicker.platform.pickFiles();
                                      if (result != null) {
                                        print("gotcha");
                                        setState(() {
                                          _loadedFile = result.files.single;
                                        });
                                      }
                                    },
                                    icon: Icon(Icons.download),
                                    label: Text("Select JSON file")),
                              ),
                              _loadedFile != null
                                  ? Padding(
                                      padding: const EdgeInsets.only(top: 8.0),
                                      child: Align(
                                        child: Text(
                                            "File ${_loadedFile!.name} loaded!"),
                                      ),
                                    )
                                  : Container(),
                              _loadFileResult != null
                                  ? Padding(
                                      padding: const EdgeInsets.only(top: 8.0),
                                      child: Text('Result:\n $_loadFileResult'),
                                    )
                                  : Container(),
                            ]),
                          )
                        ]),
                  ),
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
                      _isEdit
                          ? Padding(
                              padding: const EdgeInsets.only(right: 15),
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red),
                                onPressed: () async {
                                  if (_formKey.currentState!.validate()) {
                                    _formKey.currentState!.save();
                                    setState(() {
                                      _isLoadingDelete = true;
                                    });
                                    var response = await removeObject(
                                        domainId!, "domains");
                                    if (response == "") {
                                      widget.parentCallback();
                                      showSnackBar(context, "Domain supprimé");
                                      Navigator.of(context).pop();
                                    } else {
                                      setState(() {
                                        _isLoadingDelete = false;
                                      });
                                      showSnackBar(context, response,
                                          isError: true);
                                    }
                                  }
                                },
                                label: Text(localeMsg.delete),
                                icon: _isLoadingDelete
                                    ? Container(
                                        width: 24,
                                        height: 24,
                                        padding: const EdgeInsets.all(2.0),
                                        child: const CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 3,
                                        ),
                                      )
                                    : const Icon(Icons.delete, size: 16),
                              ),
                            )
                          : Container(),
                      ElevatedButton.icon(
                        onPressed: () async {
                          if (_tabController.index == 1) {
                            if (_loadedFile == null) {
                              showSnackBar(context,
                                  "Select a JSON file for bulk creation");
                            } else {
                              var response =
                                  await createBulkDomain(_loadedFile!.bytes!);
                              setState(() {
                                _loadFileResult =
                                    response.replaceAll(",", ",\n");
                              });
                            }
                          } else {
                            if (_formKey.currentState!.validate()) {
                              _formKey.currentState!.save();
                              setState(() {
                                _isLoading = true;
                              });
                              var newDomain = Domain(
                                  _domainName!,
                                  _domainColor!,
                                  _domainDescription!,
                                  _domainParent!);
                              String response;
                              if (_isEdit) {
                                response =
                                    await updateDomain(domainId!, newDomain);
                              } else {
                                response = await createDomain(newDomain);
                              }
                              if (response == "") {
                                widget.parentCallback();
                                showSnackBar(
                                    context, "Domain créé avec succès ! 🥳",
                                    isSuccess: true);
                                Navigator.of(context).pop();
                              } else {
                                setState(() {
                                  _isLoading = false;
                                });
                                showSnackBar(context, response, isError: true);
                              }
                            }
                          }
                        },
                        label: Text(_isEdit ? "Modifier" : localeMsg.create),
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
                            : const Icon(Icons.check_circle, size: 16),
                      ),
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
      List<TextInputFormatter>? formatters,
      bool isColor = false,
      String? initialValue,
      bool noValidation = false}) {
    return Padding(
      padding: const EdgeInsets.only(left: 2, right: 10),
      child: TextFormField(
        onChanged: isColor
            ? (value) {
                if (value.length == 6) {
                  setState(() {
                    _localColor = Color(int.parse("0xFF$value"));
                  });
                } else {
                  setState(() {
                    _localColor = Colors.blue.shade900;
                  });
                }
              }
            : null,
        onSaved: (newValue) => save(newValue),
        validator: (text) {
          if (noValidation) {
            return null;
          }
          if (text == null || text.isEmpty) {
            return AppLocalizations.of(context)!.mandatoryField;
          }
          if (isColor && text.length < 6) {
            return "Should have 6 characters";
          }
          return null;
        },
        maxLength: isColor ? 6 : null,
        inputFormatters: formatters,
        initialValue: initialValue,
        decoration: InputDecoration(
          icon: Icon(icon, color: isColor ? _localColor : Colors.blue.shade900),
          labelText: label,
        ),
      ),
    );
  }
}
