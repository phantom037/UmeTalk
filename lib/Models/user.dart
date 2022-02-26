import 'package:cloud_firestore/cloud_firestore.dart';

class User {
  final String? id;
  final String? name;
  final String? photoUrl;
  final String? createdAt;

  User({
    this.id,
    this.name,
    this.photoUrl,
    this.createdAt,
  });

  /*
  factory User.fromDocument(DocumentSnapshot doc, Map docdata) {
    return User(
      id: doc.id,
      photoUrl: docdata['photoUrl'],
      name: docdata['name'],
      createdAt: docdata['createdAt'],
    );
  }
   */

  factory User.fromDocument(DocumentSnapshot doc) {
    return User(
      id: doc.id,
      name: (doc.data as DocumentSnapshot)['name'],
      photoUrl: (doc.data as DocumentSnapshot)['photoUrl'],
      createdAt: (doc.data as DocumentSnapshot)['createdAt'],
    );
  }
}
