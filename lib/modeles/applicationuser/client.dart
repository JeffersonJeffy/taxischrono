import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:page_transition/page_transition.dart';
// import 'package:flutter/material.dart';
// import 'package:page_transition/page_transition.dart';
import 'package:taxischrono/modeles/applicationuser/appliactionuser.dart';
import 'package:taxischrono/modeles/applicationuser/chauffeur.dart';
import 'package:taxischrono/modeles/autres/codepromo.dart';
import 'package:taxischrono/modeles/autres/forfetclient.dart';
import 'package:taxischrono/modeles/autres/package.dart';
import 'package:taxischrono/modeles/autres/reservation.dart';
import 'package:taxischrono/modeles/autres/transaction.dart';
import 'package:taxischrono/modeles/discutions/message.dart';
import 'package:taxischrono/varibles/variables.dart';

import '../../screens/homepage.dart';

// import '../../screens/homepage.dart';

class Client {
  // final String idUser;
  String idUser;
  int tickets;
  Client({required this.idUser, required this.tickets});

  // collection variable
  DocumentReference clientCollection() =>
      firestore.collection("Clients").doc(idUser);

  // serialisation
  Map<String, dynamic> toMap() => {'userid': idUser, "tickets": tickets};
  factory Client.fromMap(Map<String, dynamic> client) => Client(
        tickets: client["tickets"],
        idUser: client['userid'],
      );
// register login and vérification

  Future register() async {
    await clientCollection().set(toMap());
  }

  // souscrire à un code package et utiliser un code promo
  static Future soucrireAunPackage(Packages packages, idUser,
      {CodePromo? codePromo}) async {
    if (codePromo != null) {
      packages.prixPackage =
          packages.prixPackage * codePromo.pourcentageDeReduction;
    }

    ForfetClients forfetsActifs = ForfetClients(
      idUser: idUser,
      activationDate: DateTime.now(),
      nombreDeTicketRestant: packages.nombreDeTickets,
      nombreDeTicketsUtilise: 0,
      idForfait: DateTime.now().microsecondsSinceEpoch.toString(),
      package: packages,
    );
    forfetsActifs.activerForfait();
  }

  static utiliserUnTicket(uid) {
    ForfetClients.utiliserUnTicket(uid);
  }

  //faire une reservations
  faireUneReservation({required Reservation reservation}) async {
    await reservation.valideRservation();
  }

  static Future<bool> exits(uid) async => await firestore
      .collection("Clients")
      .doc(uid)
      .get()
      .then((value) => value.exists);

  commenterLaCourse(
      {required TransactionApp transaction,
      required String commentaire}) async {
    transaction.commenterSurLaconduiteDuChauffeur(commentaire);
  }

  static Future<int> ticketCount(uid) async {
    return await firestore.collection("Clients").doc(uid).get().then((value) {
      Client client = Client.fromMap(value.data()!);
      return client.tickets;
    });
  }

  chaterAvecLeChauffeur(
      {required Chauffeur chauffeur, required String libelle}) {
    final Message message = Message(
      senderUserId: idUser,
      destinationUserId: chauffeur.userid!,
      libelle: libelle,
      messageId: DateTime.now().millisecondsSinceEpoch.toString(),
      type: "chat",
      isRead: false,
    );
    ApplicationUser.envoyerUnMessage(message);
  }

  anullerUneReservation({required Reservation reservation}) {
    reservation.annuletReservation();
  }

  static Future validateOPT(ApplicationUser chauffeurOtp, context,
      {required String smsCode, required String verificationId}) async {
    final credential = PhoneAuthProvider.credential(
      verificationId: verificationId,
      smsCode: smsCode,
    );
    await authentication.signInWithCredential(credential).then((value) async {
      if (value.user != null) {
        chauffeurOtp.userid = value.user!.uid;
        await value.user!.updateEmail(chauffeurOtp.userEmail.toString().trim());
        await value.user!.updateDisplayName(chauffeurOtp.userName);
        await value.user!.updatePassword(chauffeurOtp.motDePasse!);
        await chauffeurOtp.saveUser().then((val) async {
          await Client(idUser: value.user!.uid, tickets: 0)
              .register()
              .then((value) {
            Navigator.of(context).pushAndRemoveUntil(
                PageTransition(
                    child: const HomePage(),
                    type: PageTransitionType.leftToRight),
                (route) => false);
          });
        });
      }
    });
  }
}
