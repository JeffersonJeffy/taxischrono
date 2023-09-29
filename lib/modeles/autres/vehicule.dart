import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../varibles/variables.dart';

class Vehicule {
  String numeroDeChassie;
  String imatriculation;
  String assurance;
  DateTime expirationAssurance;
  String chauffeurId;
  String token;
  bool
      statut; // permet de verifier que le vehicule est soit en ligne soit hors ligne.
  LatLng? position;

  Vehicule({
    required this.assurance,
    required this.expirationAssurance,
    required this.imatriculation,
    required this.numeroDeChassie,
    this.position,
    required this.token,
    required this.chauffeurId,
    required this.statut,
  });

  Map<String, dynamic> toMap() => {
        "assurance": assurance,
        "expirationAssurance": expirationAssurance.millisecondsSinceEpoch,
        "imatriculation": imatriculation,
        "numeroDeChassie": numeroDeChassie,
        if (position != null)
          "position": {
            "latitude": position!.latitude,
            "longitude": position!.longitude,
          },
        "statut": statut,
        'chauffeurId': chauffeurId,
      };
  factory Vehicule.froJson(map) => Vehicule(
      chauffeurId: map['chauffeurId'],
      assurance: map['assurance'],
      expirationAssurance:
          DateTime.fromMicrosecondsSinceEpoch(map['expirationAssurance']),
      imatriculation: map['imatriculation'],
      numeroDeChassie: map["numeroDeChassie"],
      position:
          LatLng(map['position']['latitude'], map['position']['longitude']),
      statut: map['statut'],
      token: map['token']);

// demande d'enrégistrement du véhicule
  Future requestSave() async {
    // print(toMap());
    await datatbase
        .ref("Vehicules")
        .child(chauffeurId)
        .get()
        .then((value) async {
      if (value.exists) {
        return "véhicule déja existant ce véhicule existe déjà";
      } else {
        return await datatbase
            .ref("Vehicules")
            .child(chauffeurId)
            .set(toMap())
            .then((value) {
          return true;
        });
      }
    });
  }

// fonction de miseAjour de la position du chauffeur et ou du véhicule
  static Future setPosition(LatLng positionActuel, String userId) async {
    await datatbase.ref("Vehicules").child(userId).update({
      "position": {
        "latitude": positionActuel.latitude,
        "longitude": positionActuel.longitude,
      }
    });
  }

  //  actuellement en ligne ou or ligne
  setStatut(bool etatActuel) async {
    await datatbase
        .ref("Vehicules")
        .child(chauffeurId)
        .update({"statut": etatActuel});
  }

  static Stream<Vehicule?> vehiculeStrem(idchau) =>
      datatbase.ref("Vehicules").child(idchau).onValue.map((event) {
        try {
          return Vehicule.froJson(event.snapshot.value);
        } catch (e) {
          return null;
        }
      });
  static Future<Vehicule?> vehiculeFuture(idchau) =>
      datatbase.ref("Vehicules").child(idchau).get().then((event) {
        try {
          return Vehicule.froJson(event.value);
        } catch (e) {
          null;
        }
        return null;
      });

  // static Future<List<Vehicule?>> vehiculRequette() =>
  //     datatbase.ref("Vehicules").get().then((event) {
  //       return event.children.map((vehi) {
  //         try {
  //           return Vehicule.froJson(vehi.value);
  //         } catch (e) {
  //           return null;
  //         }
  //       }).toList();
  //     });

  static Future<List<Vehicule?>> vehiculRequette() =>
      firestore.collection("cars").get().then((event) {
        return event.docs.map((vehi) {
          try {
            return Vehicule.froJson(vehi.data());
          } catch (e) {
            return null;
          }
        }).toList();
      });
  // fin de la classe
}
