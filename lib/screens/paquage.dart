import 'dart:async';
import 'dart:io';
// import 'dart:convert';
// import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
// import 'package:http/http.dart' as http;
// import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:taxischrono/modeles/applicationuser/client.dart';
import 'package:taxischrono/modeles/autres/package.dart';
import 'package:taxischrono/varibles/variables.dart';
// import 'package:toast/toast.dart';
// import 'package:url_launcher/url_launcher.dart';
// import 'package:url_launcher/url_launcher.dart';

class PackageUi extends StatefulWidget {
  const PackageUi({Key? key}) : super(key: key);

  @override
  State<PackageUi> createState() => _PackState();
}

class _PackState extends State<PackageUi> {
  bool loading = false;
  Future payement({
    required String phoneNumber,
    String? email,
    required Packages packages,
    required String name,
    required GlobalKey<ScaffoldState> scaffoldkey,
  }) async {
    final reference =
        "${packages.idPackage}${authentication.currentUser!.uid}${DateTime.now().microsecondsSinceEpoch}";

    final mapPey = {
      'amount': packages.prixPackage,
      'currency': 'XAF',
      'reference': reference,
      'email': authentication.currentUser!.email,
      'phone': phoneNumber,
      'name': authentication.currentUser!.displayName,
      "description":
          "paiement de packages pour ${authentication.currentUser!.displayName}"
    };
    final dio = Dio();

    try {
      await dio
          .post(
        "https://api.notchpay.co/payments/initialize",
        queryParameters: mapPey,
        options: Options(headers: header),
      )
          .then((value) async {
        loading = false;
        setState(() {});
        // print(value);
        if (value.statusCode == 201) {
          final response = value.data;
          // print("response : $response");
          if (response['status'] == "Accepted") {
            final secondRef = response["transaction"]['reference'];
            // print(" secconde reférnce $secondRef");

            TextEditingController controllerphone = TextEditingController();
            showDialog(
              context: scaffoldkey.currentContext!,
              barrierDismissible: false,
              builder: (context) {
                return AlertDialog(
                  contentPadding: const EdgeInsets.all(8),
                  titlePadding: const EdgeInsets.all(12),
                  title: Text(
                    'entrez votre numéro de téléphone',
                    style: police.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  content: TextFormField(
                    controller: controllerphone,
                    textAlign: TextAlign.center,
                    maxLength: 9,
                    keyboardType: TextInputType.number,
                    style: police.copyWith(fontWeight: FontWeight.bold),
                    decoration: InputDecoration(
                      prefix: Text('+237', style: police),
                      hintText: "number",
                      hintStyle: police,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      child: Text('Annuler',
                          style: police.copyWith(fontWeight: FontWeight.bold)),
                    ),
                    TextButton(
                      onPressed: () async {
                        //
                        // print("+237${controllerphone.text}");
                        if (controllerphone.text.trim().length == 9) {
                          Navigator.of(context).pop();
                          loading = true;
                          setState(() {});
                          final map = {
                            'currency': 'xaf',
                            'channel': 'mobile',
                            'data': {
                              'phone': '+237${controllerphone.text}',
                            },
                          };

                          try {
                            await dio
                                .put(
                              'https://api.notchpay.co/payments/$secondRef',
                              queryParameters: map,
                              options: Options(headers: header),
                            )
                                .then((valuerequest) async {
                              loading = false;
                              setState(() {});
                              // print("Valeur: ${valuerequest.data}");
                              if (valuerequest.statusCode == 422) {
                                debugPrint(valuerequest.data);
                                toaster(
                                    message:
                                        "Unne erreur est survenus lors du paiment veilez vérifier votre solde et votre connexion internet");
                              }
                              if (valuerequest.statusCode == 202) {
                                // dialoginformation(context,
                                //     message:
                                //         "Votre transaction est en cours de traitement\nCela peut prendre jusqu'à 2 minutes",
                                //     icone: Icon(
                                //       Icons.run_circle,
                                //       color: blanc,
                                //     ));
                                toaster(
                                    message:
                                        "Paiement en cour de traitement\nConfirmez la transaction en tapant votre code secret. Ou Taper #150*50# pour valider la transaction",
                                    color: Colors.blueAccent,
                                    long: true);
                                var counta = 0;
                                Timer.periodic(const Duration(seconds: 5),
                                    (timer) async {
                                  counta++;
                                  if (counta == 180) {
                                    timer.cancel();
                                  }

                                  await dio
                                      .get(
                                    "https://api.notchpay.co/payments/$secondRef",
                                    queryParameters: {"currency": "xaf"},
                                    options: Options(headers: header),
                                  )
                                      .then((valuesEnd) async {
                                    // print(
                                    //     "Value end :${valuesEnd.data['transaction']}");
                                    // print(
                                    //     "Code de la transaction :${valuesEnd.statusCode}");
                                    // print(
                                    //     "Etat de la transaction :${valuesEnd.data['transaction']['status']}");
                                    if (valuesEnd.statusCode == 200 &&
                                        valuesEnd.data['transaction']
                                                ['status'] ==
                                            "complete") {
                                      timer.cancel();
                                      await Client.soucrireAunPackage(packages,
                                              authentication.currentUser!.uid)
                                          .then((value) {});
                                      Fluttertoast.showToast(
                                          msg:
                                              'Transaction réussie vous venez de souscrire à un package de ${packages.nombreDeTickets} tickets',
                                          backgroundColor: Colors.green,
                                          toastLength: Toast.LENGTH_LONG);

                                      await Future.delayed(
                                          Duration(seconds: 7));
                                      Fluttertoast.cancel();
                                    }
                                  });
                                });
                              } else {
                                throw Exception('Erruer de validation');
                              }
                            });
                          } catch (e) {
                            loading = false;
                            setState(() {});
                            debugPrint("Erreur $e");
                            toaster(
                                message:
                                    "Erreur de paiment veillez vérifier votre solde",
                                color: Colors.red,
                                long: true);
                          }
                        } else {
                          // erreur de remplissage du champ
                          toaster(
                              message:
                                  "Remplissez correctement le numéro de téléphone",
                              long: true,
                              color: Colors.red);
                          // fin
                        }
                      },
                      child: Text(
                        'valider',
                        style: police.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                );
              },
            );
          } else {
            toaster(
                message:
                    "Une Erreur est survenu: veillez vérifier votre connexion internet",
                long: true);
          }
        } else {
          toaster(
              message:
                  "Erreur de paiement: veillez vérifier votre connexion internet",
              long: true);
        }
      });
    } on SocketException catch (e) {
      loading = false;
      setState(() {});
      debugPrint("Erreur de connexion $e");
      toaster(
          message:
              "Erreur de paiement: veillez vérifier votre connexion internet",
          long: true);
    } catch (e) {
      loading = false;
      setState(() {});
      debugPrint("Erreur $e");
      toaster(
          message:
              "Erreur de paiement: veillez vérifier votre connexion internet",
          long: true);
    }
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: keyscaf,
      // drawer: const SideBar(),
      appBar: AppBar(
        title: Text(
          "Paquage Disponible",
          style: police.copyWith(fontWeight: FontWeight.w800, fontSize: 20),
          textAlign: TextAlign.center,
        ),
        elevation: 0.0,
        backgroundColor: dredColor,
        leading: InkWell(
            onTap: () {
              Navigator.of(context).pop();
            },
            child: const Icon(Icons.arrow_back_ios, size: 30)),
      ),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 10, left: 10, bottom: 0),
            child: GestureDetector(
              onTap: () => FocusManager.instance.primaryFocus!.unfocus(),
              child: GridView(
                shrinkWrap: false,
                physics: const BouncingScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 3,
                    mainAxisSpacing: 5,
                    mainAxisExtent: 245),
                children: [
                  packDetailGrid(
                    name: "Pack1",
                    package: Packages(
                        prixPackage: 1000,
                        idPackage: 100011,
                        nombreDeTickets: 11),
                    rating: 4.5,
                    image: 'illustration1.jpg',
                  ),
                  packDetailGrid(
                    name: "Pack2",
                    package: Packages(
                        prixPackage: 2000,
                        idPackage: 200022,
                        nombreDeTickets: 22),
                    rating: 4.5,
                    image: 'illustration2.jpg',
                  ),
                  packDetailGrid(
                    name: "Pack3",
                    package: Packages(
                        prixPackage: 5000,
                        idPackage: 500055,
                        nombreDeTickets: 55),
                    rating: 4.5,
                    image: 'illustration1.jpg',
                  ),
                  packDetailGrid(
                    name: "Pack4",
                    package: Packages(
                        prixPackage: 3000,
                        idPackage: 300033,
                        nombreDeTickets: 33),
                    rating: 4.5,
                    image: 'illustration2.jpg',
                  ),
                  packDetailGrid(
                    name: "Pack5",
                    package: Packages(
                        prixPackage: 10000,
                        idPackage: 10000110,
                        nombreDeTickets: 110),
                    rating: 4.5,
                    image: 'illustration2.jpg',
                  ),
                ],
              ),
            ),
          ),
          loading
              ? Container(
                  height: double.infinity,
                  width: double.infinity,
                  color: noire.withOpacity(0.5),
                  child: Center(
                    child: const LoadingComponen(),
                  ),
                )
              : const SizedBox.shrink()
        ],
      ),
    );
  }

  Widget packDetail(String name, Packages packages, String image) {
    return Card(
      elevation: 2,
      child: Column(
        children: [
          Container(
            height: 96,
            width: 180,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(5), topRight: Radius.circular(5)),
              image: DecorationImage(
                  image: AssetImage('images/$image'), fit: BoxFit.fill),
            ),
          ),
          Container(
            width: 180,
            padding:
                const EdgeInsets.only(top: 8, bottom: 8, left: 5, right: 5),
            decoration: const BoxDecoration(
              color: Color(0xFFEBFAFF),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.star,
                      color: dredColor,
                      size: 16,
                    ),
                    const SizedBox(
                      width: 3,
                    ),
                    Text(
                      '${packages.prixPackage}',
                      style: const TextStyle(
                          color: Colors.black,
                          fontSize: 11,
                          fontWeight: FontWeight.bold),
                    )
                  ],
                ),
                Text(
                  name,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const Icon(
                  Icons.security,
                  size: 16,
                  color: Colors.cyan,
                )
              ],
            ),
          ),
          Container(
            width: 180,
            padding:
                const EdgeInsets.only(top: 10, left: 10, right: 10, bottom: 5),
            child: Column(
              children: [
                Row(
                  children: [
                    careTile("Nombre de Ticket"),
                    const SizedBox(
                      width: 5,
                    ),
                    careTile("Validité")
                  ],
                ),
                const SizedBox(
                  height: 5,
                ),
                Row(
                  children: [
                    careTile("Avantages"),
                    const SizedBox(
                      width: 5,
                    ),
                    careTile("Description")
                  ],
                ),
              ],
            ),
          ),
          Container(
              width: 180,
              padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 5),
              decoration: const BoxDecoration(
                borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(5),
                    bottomRight: Radius.circular(5)),
                color: Color(0xFFFFFFFF),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 3),
                      decoration: BoxDecoration(
                        border: Border(
                          top: BorderSide(width: 2, color: dredColor),
                          bottom: BorderSide(width: 2, color: dredColor),
                        ),
                      ),
                      child: Text(
                        "Souscrire",
                        style: TextStyle(
                            color: dredColor, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(vertical: 5, horizontal: 12),
                    color: dredColor,
                    child: Text(
                      'F cfa ${packages.prixPackage}',
                      style: const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  )
                ],
              )),
        ],
      ),
    );
  }

  Widget packDetailGrid(
      {required String name,
      required Packages package,
      required double rating,
      required String image}) {
    return GestureDetector(
      onTap: () {
        boobtomshet(
            keys: keyscaf,
            padd: 15,
            hei: 350,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '${authentication.currentUser!.displayName}\nVous Allez acheter chez Taxi chrono le package $name, qui contient ${package.nombreDeTickets}  et qui coute ${package.prixPackage} AXF \nVoulez vous valider l\'opéraion',
                  style: police.copyWith(fontSize: 16),
                  textAlign: TextAlign.center,
                ),
                spacerHeight(50),
                boutonText(
                  context: context,
                  action: () async {
                    Navigator.of(context).pop();
                    loading = true;
                    setState(() {});

                    await payement(
                      phoneNumber: authentication.currentUser!.phoneNumber!,
                      packages: package,
                      name: name,
                      scaffoldkey: keyscaf,
                    );
                    keyscaf.currentState!.setState(() {
                      loading = false;
                    });
                  },
                  text: 'Valider',
                  couleur: Colors.green,
                ),
                spacerHeight(10),
                boutonText(
                  context: context,
                  action: () async {
                    Navigator.of(context).pop();
                  },
                  text: "Anuller",
                )
              ],
            ));
      },
      child: Card(
        elevation: 2,
        child: Column(
          children: [
            Expanded(
              child: Container(
                height: 96,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(5),
                      topRight: Radius.circular(5)),
                  image: DecorationImage(
                      image: AssetImage('images/$image'), fit: BoxFit.fill),
                ),
              ),
            ),
            Container(
              padding:
                  const EdgeInsets.only(top: 8, bottom: 8, left: 5, right: 5),
              decoration: const BoxDecoration(
                color: Color(0xFFEBFAFF),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.star,
                        color: dredColor,
                        size: 16,
                      ),
                      const SizedBox(
                        width: 3,
                      ),
                      Text(rating.toString(),
                          style: police.copyWith(
                              fontWeight: FontWeight.bold, fontSize: 11))
                    ],
                  ),
                  Text(
                    name,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const Icon(
                    Icons.security,
                    size: 16,
                    color: Colors.cyan,
                  )
                ],
              ),
            ),
            Container(
              padding:
                  const EdgeInsets.only(top: 10, left: 5, right: 5, bottom: 5),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      careTileGrid("${package.nombreDeTickets} tickets"),
                      const SizedBox(
                        width: 5,
                      ),
                      careTileGrid("Validité")
                    ],
                  ),
                ],
              ),
            ),
            Container(
                padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 2),
                decoration: const BoxDecoration(
                  borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(5),
                      bottomRight: Radius.circular(5)),
                  color: Color(0xFFFFFFFF),
                ),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(vertical: 5, horizontal: 12),
                  color: dredColor,
                  child: Text(
                    'F cfa ${package.prixPackage}',
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                )),
            Container(
              width: double.infinity,
              margin: const EdgeInsets.all(10),
              padding: const EdgeInsets.symmetric(vertical: 3),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(width: 2, color: dredColor),
                  bottom: BorderSide(width: 2, color: dredColor),
                ),
              ),
              child: Text(
                "Souscrire",
                textAlign: TextAlign.center,
                style: police.copyWith(
                    color: dredColor, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  final keyscaf = GlobalKey<ScaffoldState>();

  Widget careTile(String title) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 3, horizontal: 7),
      decoration: BoxDecoration(
          border: Border.all(width: 2, color: dredColor),
          borderRadius: BorderRadius.circular(4)),
      child: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
      ),
    );
  }

  Widget careTileGrid(String title) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 5),
      decoration: BoxDecoration(
          border: Border.all(width: 1.5, color: dredColor),
          borderRadius: BorderRadius.circular(4)),
      child: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 10),
      ),
    );
  }
}

sucesPay(scaffoldkey) => boobtomshet(
      keys: scaffoldkey,
      hei: 300,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 45,
            backgroundColor: Colors.green,
            child: Center(
              child: Icon(
                Icons.check,
                size: 50,
                color: blanc,
              ),
            ),
          ),
          spacerHeight(30),
          Text(
            'Paiement effectué avec succès',
            style: police.copyWith(fontSize: 16),
            textAlign: TextAlign.center,
          ),
          const Expanded(child: SizedBox()),
          boutonText(
            context: scaffoldkey.currentContext!,
            action: () {
              Navigator.pop(scaffoldkey.currentContext!);
            },
            text: "Okey",
            couleur: Colors.green,
          ),
          spacerHeight(30)
        ],
      ),
    );

final header = {
  "Accept": "application/json",
  "Authorization": publickeyPaiment,
};

Future<dynamic> dialoginformation(BuildContext context,
    {required String message, required Widget icone}) {
  return showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            message,
            style: police.copyWith(fontWeight: FontWeight.bold),
          ),
          contentPadding: const EdgeInsets.all(15),
          titlePadding: const EdgeInsets.all(15),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text("Okey",
                  style: police.copyWith(fontWeight: FontWeight.bold)),
            )
          ],
          content: CircleAvatar(
            backgroundColor: dredColor,
            child: Center(child: icone),
          ),
        );
      });
}
