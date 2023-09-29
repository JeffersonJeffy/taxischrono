// ignore_for_file: use_build_context_synchronously

import 'dart:async';
import 'dart:convert';

import "package:flutter/material.dart";
import 'package:flutter/services.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';

import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:page_transition/page_transition.dart';

import 'package:sliding_up_panel/sliding_up_panel.dart';
import 'package:taxischrono/modeles/applicationuser/appliactionuser.dart';
import 'package:taxischrono/modeles/applicationuser/client.dart';
import 'package:taxischrono/modeles/autres/reservation.dart';
import 'package:taxischrono/modeles/autres/transaction.dart';
import 'package:taxischrono/modeles/autres/vehicule.dart';
import 'package:taxischrono/screens/auths/completteprofile.dart';
import 'package:taxischrono/screens/auths/login_page.dart';
import 'package:taxischrono/screens/homepage.dart';
import 'package:taxischrono/screens/paquage.dart';

import 'package:taxischrono/services/mapservice.dart';

import 'package:taxischrono/varibles/variables.dart';

import 'composants/maprequest.dart';

class MapReservation extends StatefulWidget {
  final Reservation reservation;
  final RouteModel routeModel;

  const MapReservation({
    super.key,
    required this.reservation,
    required this.routeModel,
  });

  @override
  State<MapReservation> createState() => _MapReservationState();
}

class _MapReservationState extends State<MapReservation> {
  ///////////////////
  // les variables
  ///////////////.

  Completer<GoogleMapController> controllerMap =
      Completer<GoogleMapController>();

  String destination = '';
  PolylinePoints polylinePoints = PolylinePoints();

  final scaffoldKey = GlobalKey<ScaffoldState>();

  bool voirs = false;
  Map<PolylineId, Polyline> polylinesSets = {};
  Set<Marker> markersSets = {};
  bool loader = false;
  // la finction de démarage.
  @override
  void initState() {
    setState(() {
      markersSets = {};
    });
    getLines();
    markermecker();
    setState(() {});
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: scaffoldKey,
      body: loader
          ? Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text("Recherche du véhicule en cours ...", style: police),
                spacerHeight(50),
                const LoadingComponen(),
              ],
            )
          : SafeArea(
              child: Stack(
                children: [
                  SlidingUpPanel(
                      parallaxEnabled: true,
                      minHeight: taille(context).height * 0.16,
                      maxHeight: 480,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      borderRadius:
                          const BorderRadius.vertical(top: Radius.circular(20)),
                      body: GoogleMap(
                        initialCameraPosition: CameraPosition(
                          target:
                              widget.reservation.pointDepart.adresseposition,
                          zoom: 14,
                        ),
                        myLocationButtonEnabled: true,
                        mapType: MapType.normal,
                        onMapCreated: (controller) {
                          setState(() {
                            controllerMap.complete(controller);
                          });
                        },
                        markers: markersSets,
                        polylines: Set<Polyline>.of(polylinesSets.values),
                      ),
                      panelBuilder: (controller) {
                        return ListView(
                          controller: controller,
                          children: [
                            Center(
                              child: SizedBox(
                                child: Container(
                                  margin: const EdgeInsets.all(10),
                                  height: 10,
                                  width: 30,
                                  decoration: BoxDecoration(
                                      color: Colors.grey.shade400,
                                      borderRadius: BorderRadius.circular(20)),
                                ),
                              ),
                            ),
                            RequestCard(reservation: widget.reservation),
                            spacerHeight(10),
                            // boutonText(
                            //     action: () {
                            //       // Vehicule.vehiculRequette();
                            //       firestore
                            //           .collection("cars")
                            //           .get()
                            //           .then((event) {
                            //         return event.docs.map((vehi) {
                            //           try {
                            //             print(
                            //                 "ttttttttttttt  ${Vehicule.froJson(vehi.data())}");
                            //             return Vehicule.froJson(vehi.data());
                            //           } catch (e) {
                            //             return null;
                            //           }
                            //         }).toList();
                            //       });
                            //     },
                            //     text: "dd",
                            //     context: context,
                            //     couleur: Colors.brown),
                            boutonText(
                                context: context,
                                couleur: Colors.green,
                                text: 'Valider la commande',
                                action: () async {
                                  setState(() {
                                    loader = true;
                                  });
                                  await ApplicationUser.currentUserFuture()
                                      .then((event) async {
                                    if (event == null) {
                                      setState(() {
                                        loader = false;
                                      });
                                      getsnac(
                                          title: "Echec de la commande",
                                          msg:
                                              "Vous devez vous authentifier avant de valider votre commande");
                                      Navigator.of(context).push(
                                        PageTransition(
                                            child: const LoginPage(),
                                            type:
                                                PageTransitionType.topToBottom),
                                      );
                                    } else {
                                      if (event.userTelephone!.trim().isEmpty) {
                                        setState(() {
                                          loader = false;
                                        });
                                        scaffoldKey.currentState!
                                            .showBottomSheet((context) {
                                          return Container(
                                            height: 300,
                                            padding: const EdgeInsets.all(15),
                                            decoration: BoxDecoration(
                                                color: Colors.grey.shade200,
                                                borderRadius: const BorderRadius
                                                        .vertical(
                                                    top: Radius.circular(20))),
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.center,
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                Text(
                                                  "Vous N'avez pas de numéro de téléphone veillez completer votre profile",
                                                  style: police.copyWith(
                                                      fontSize: 16,
                                                      fontWeight:
                                                          FontWeight.bold),
                                                  textAlign: TextAlign.center,
                                                ),
                                                spacerHeight(30),
                                                boutonText(
                                                    context: context,
                                                    action: () {
                                                      Navigator.of(context)
                                                          .push(PageTransition(
                                                              child: CompletteProfile(
                                                                  applicationUser:
                                                                      event),
                                                              type: PageTransitionType
                                                                  .topToBottom));
                                                    },
                                                    text:
                                                        'Completez votre compte'),
                                              ],
                                            ),
                                          );
                                        });
                                      } else {
                                        setState(() {
                                          loader = true;
                                        });
                                        widget.reservation.idClient =
                                            event.userid!;
                                        await widget.reservation
                                            .valideRservation();
                                        envoieLarequette();

                                        // widget.reservation.valideRservation();
                                      }
                                    }
                                  });
                                }),
                            spacerHeight(10),
                            boutonText(
                                context: context,
                                action: () {
                                  setState(() {
                                    loader = false;
                                  });
                                  Navigator.of(context).pop();
                                },
                                text: "Annuler"),
                          ],
                        );
                      }),
                ],
              ),
            ),
    );
  }
  ///////////////////
  ///les fonctions
  ///////////////.

// creation  de la ligne

  getLines() async {
    // PolylineResult polylineResult =
    List<LatLng> polylineCoordinates = [];
    await polylinePoints
        .getRouteBetweenCoordinates(
      mapApiKey,
      PointLatLng(
        widget.reservation.pointDepart.adresseposition.latitude,
        widget.reservation.pointDepart.adresseposition.longitude,
      ),
      PointLatLng(
        widget.reservation.pointArrive.adresseposition.latitude,
        widget.reservation.pointArrive.adresseposition.longitude,
      ),
      travelMode: TravelMode.driving,
    )
        .then(
      (value) {
        if (value.points.isNotEmpty) {
          for (var element in value.points) {
            polylineCoordinates
                .add(LatLng(element.latitude, element.longitude));
          }
        } else {
          debugPrint(value.errorMessage);
        }
        setState(() {
          addpolylinespoints(polylineCoordinates);
        });
      },
    );
  }

///////////////////////////////////////////////////////////////////////:
  // addpolylinespoins permet de récupérer une liste de latlng et ajouter aux poins.

  addpolylinespoints(List<LatLng> listlatlng) async {
    PolylineId id = const PolylineId("poly");
    Polyline polyline = Polyline(
      polylineId: id,
      points: listlatlng,
      color: Colors.blueAccent.shade200,
      width: 5,
    );
    polylinesSets[id] = polyline;
  }

// mettre à jour la liste des markers
/////////////////////////////////////////////////////////////////////
  markermecker() async {
    final debut = widget.reservation.pointDepart;
    final fin = widget.reservation.pointArrive;
    final bitUser = await bitcone(imgurl);
    // final bitCar = await bitcone(carUrl);
    // ajout du point de départ
    markersSets.add(
      Marker(
        markerId: MarkerId(debut.adresseCode),
        position: debut.adresseposition,
        infoWindow: InfoWindow(
          title: debut.adresseName,
        ),
        icon: BitmapDescriptor.defaultMarker,
      ),
    );
    // Ajout du point d'arrivé
    markersSets.add(
      Marker(
        markerId: MarkerId("position de la persone"),
        position: GooGleMapServices.currentPosition!,
        infoWindow: InfoWindow(
          title: "Votre position",
        ),
        icon: BitmapDescriptor.fromBytes(bitUser),
      ),
    );
    markersSets.add(
      Marker(
        markerId: MarkerId(fin.adresseCode),
        position: fin.adresseposition,
        infoWindow: InfoWindow(
          title: fin.adresseName,
        ),
        icon: BitmapDescriptor.defaultMarker,
      ),
    );
  }

// /////////////////////////////////////////////////////////////////
//finction d'envoi de la requette

  envoieLarequette() async {
    await Client.ticketCount(authentication.currentUser!.uid)
        .then((value) async {
      if (value <= 0) {
        setState(() {
          loader = false;
        });
        scaffoldKey.currentState!.showBottomSheet((context) => Container(
              height: 350,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  spacerHeight(10),
                  Text(
                    'Vous n\'avez pas de ticket actif pour le moment\n Veillez activer un forfait',
                    style: police,
                    textAlign: TextAlign.center,
                  ),
                  spacerHeight(30),
                  boutonText(
                    context: context,
                    couleur: Colors.green.shade400,
                    action: () {
                      Navigator.of(context).pop();
                      Navigator.of(context).push(
                        PageTransition(
                          child: const PackageUi(),
                          type: PageTransitionType.leftToRight,
                        ),
                      );
                    },
                    text: "Acherter des tickets",
                  ),
                  spacerHeight(10),
                  boutonText(
                    context: context,
                    action: () {
                      Navigator.of(context).pop();
                    },
                    text: "Annuler",
                  ),
                ],
              ),
            ));
      } else {
        Vehicule.vehiculRequette().then((valu) async {
          for (var vehi in valu) {
            if (vehi != null &&
                vehi.statut &&
                calculateDistance(
                        widget.reservation.pointDepart.adresseposition,
                        vehi.position!) <
                    20) {
              debugPrint(vehi.toMap().toString());
              await sendNotification(
                vehi.token,
                "${widget.reservation.pointArrive.adresseName} ${widget.reservation.prixReservation}",
                calculateDistance(
                        widget.reservation.pointDepart.adresseposition,
                        widget.reservation.pointArrive.adresseposition)
                    .toStringAsFixed(2),
                widget.routeModel.tempsNecessaire.text,
              );
              var ent = await Reservation.sendToChauffeur(
                  vehi.chauffeurId, widget.reservation.idReservation);
              if (ent != 0) break;
              await Future.delayed(const Duration(seconds: 9));
              await Reservation.suprimeraRservationChezUnChaufeur(
                  vehi.chauffeurId, widget.reservation);
            } else {
              continue;
            }
          }
          TransactionApp.currentTransaction(authentication.currentUser!.uid)
              .listen((event) async {
            if (event == null || event.isEmpty) {
              setState(() {
                loader = false;
              });
              scaffoldKey.currentState!.showBottomSheet((context) => Container(
                    height: 200,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius:
                          const BorderRadius.vertical(top: Radius.circular(20)),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        spacerHeight(20),
                        Text(
                          'Aucune voiture dusponible pour le moment',
                          style: police,
                          textAlign: TextAlign.center,
                        ),
                        boutonText(
                          context: context,
                          action: () {
                            Navigator.of(context).pop();
                          },
                          text: "Okey",
                        ),
                      ],
                    ),
                  ));
            } else {
              setState(() {
                loader = false;
              });
              await Client.utiliserUnTicket(authentication.currentUser!.uid);
              Navigator.pushAndRemoveUntil(
                  context,
                  PageTransition(
                      child: const HomePage(),
                      type: PageTransitionType.leftToRight),
                  (route) => false);
            }
          });
        });
      }
    });
  }

// /////////////////////////////////////////////////////////////////
//finction d'envoi de la notification

  Future sendNotification(token, prix, distance, temps) async {
    final header = {
      "Content-Type": "application/json",
      "Authorization":
          "key=AAAAWm7WlHc:APA91bGoKgLamoMZBqHHnx1sodTxSIRvh77grrTw7cGzkL21xcPg_9bptsXT9LftQAp5718I1W88LEiIuqdaGzmauL5mAgpGvkRnKLtsOUqWCrrRJoZ_TRsC3imIQ6FlXfIkL9U9ej8n",
    };
    final queryParams = {
      "to": token,
      "priority": 'high',
      "data": {
        "click_action": "FLUTTER_NOTIFICATION_CLICK",
        "statu": "done",
        "body": "$distance $temps",
        "title": "$prix FCFA"
      },
      "notification": {
        "title": "$prix FCFA",
        "body": "$distance KM  en $temps",
        "android_chanel": "high_importance_channel",
      },
    };

    final uri = Uri.https(
      "fcm.googleapis.com",
      "/fcm/send",
    );
    // print(uri);
    await http
        .post(
      uri,
      headers: header,
      body: jsonEncode(queryParams),
    )
        .then((value) {
      // print("Result : ${value.body}");
    });
  }

  Future<Uint8List> bitcone(imgurli) async {
    return (await NetworkAssetBundle(Uri.parse(imgurli)).load(imgurli))
        .buffer
        .asUint8List();
  }

  String imgurl =
      "https://firebasestorage.googleapis.com/v0/b/taxischrono-c12c9.appspot.com/o/Bonhomme%20LOca122%20(2).png?alt=media&token=a1394dea-4b12-4d90-b223-4473746317ef";
  String carUrl =
      "https://firebasestorage.googleapis.com/v0/b/taxischrono-c12c9.appspot.com/o/Bonhomme%20LOca%20voit.png?alt=media&token=c10224dc-8e5b-48fe-b713-d01f70eb6866";

//////////////////////////////////////////////////////////
  // fin de la fontion principale
}
