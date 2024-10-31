import 'package:cinduhrella/models/cloth.dart';
import 'package:cinduhrella/models/user_profile.dart';
import 'package:cinduhrella/services/auth_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get_it/get_it.dart';
import 'package:logger/logger.dart';


class DatabaseService {
  final Logger _logger = Logger(); // Initialize the logger
final FirebaseFirestore _firebaseFirestore = FirebaseFirestore.instance;
late AuthService _authService;

final GetIt _getIt=GetIt.instance;
CollectionReference? _usersCollection;
CollectionReference? _chatsCollection;
CollectionReference? _clothesCollection;
//CollectionReference? _aiChatCollection;

  DatabaseService(){
    _authService=_getIt.get<AuthService>();
    _setUpCollectionReferences();
  }

  CollectionReference? get chatsCollection => _chatsCollection;
  CollectionReference? get clothesCollection => _clothesCollection;

  //CollectionReference? get aiChatCollection=>_aiChatCollection;
  void _setUpCollectionReferences() {
    _usersCollection= _firebaseFirestore.collection('users').withConverter<UserProfile>(
      fromFirestore: (snapshot,_)=>UserProfile.fromJson(snapshot.data()!), 
      toFirestore: (userProfile,_)=> userProfile.toJson(),
    );
    // _chatsCollection=_firebaseFirestore.collection('chats').withConverter<Chat>(
    //   fromFirestore: (snapshot,_)=>Chat.fromJson(snapshot.data()!), 
    //   toFirestore: (chat,_)=> chat.toJson(),
    // );
    //  _aiChatCollection=_firebaseFirestore.collection('ai_chats').withConverter<Chat>(
    //   fromFirestore: (snapshot,_)=>Chat.fromJson(snapshot.data()!), 
    //   toFirestore: (chat,_)=> chat.toJson(),
    // );
    _clothesCollection=_firebaseFirestore.collection('clothes').withConverter<Cloth>(
      fromFirestore: (snapshot,_)=>Cloth.fromJson(snapshot.data()!), 
      toFirestore: (chat,_)=> chat.toJson(),
    );
  }

  Future<void> createUserProfile({required UserProfile userProfile}) async{
    await _usersCollection?.doc(userProfile.uid).set(userProfile);
  }

  Future<void> addClothForUser(String uid, Cloth cloth) async {
    // Define the path for the user's clothes
    CollectionReference<Cloth> userClothesCollection = _firebaseFirestore.collection('clothes/users/$uid').withConverter<Cloth>(
      fromFirestore: (snapshot, _) => Cloth.fromJson(snapshot.data()!),
      toFirestore: (cloth, _) => cloth.toJson(),
    );

    // Add the cloth to the user's collection
    await userClothesCollection.add(cloth);
  }


  Stream<QuerySnapshot<UserProfile>> getUserProfiles(){
     return _usersCollection?.where('uid',isNotEqualTo: _authService.user!.uid).snapshots() as Stream<QuerySnapshot<UserProfile>>;
  }

  Future<String?> getUsernameByUid(String uid) async {
  try {
    DocumentSnapshot<UserProfile> snapshot = await _usersCollection!.doc(uid).get() as DocumentSnapshot<UserProfile>;
    if (snapshot.exists) {
      return snapshot.data()?.userName; // Return the username if the document exists
    }
  } catch (e) {
    _logger.e('Error fetching username: $e'); // Handle errors as needed
  }
  return null; // Return null if the user does not exist
}

 Future<String?> getProfilePictureByUid(String uid) async {
  try {
    DocumentSnapshot<UserProfile> snapshot = await _usersCollection!.doc(uid).get() as DocumentSnapshot<UserProfile>;
    if (snapshot.exists) {
      return snapshot.data()?.profilePictureUrl; // Return the pp if the document exists
    }
  } catch (e) {
    _logger.e('Error fetching profile picture: $e'); // Handle errors as needed
  }
  return null; // Return null if the user does not exist
}

Future<String?> getFullNameByUid(String uid) async {
  try {
    DocumentSnapshot<UserProfile> snapshot = await _usersCollection!.doc(uid).get() as DocumentSnapshot<UserProfile>;
    if (snapshot.exists) {
      return snapshot.data()?.fullName; // Return the username if the document exists
    }
  } catch (e) {
    _logger.e('Error fetching fullname: $e'); // Handle errors as needed
  }
  return null; // Return null if the user does not exist
}

Stream<List<Cloth>> getClothesByUid(String userId) {
  return _firebaseFirestore
      .collection('clothes')
      .doc('users')
      .collection(userId)
      .snapshots()
      .map((snapshot) {
        return snapshot.docs.map((doc) {
          return Cloth.fromJson(doc.data());
        }).toList();
      });
}


Stream<List<Cloth>> getClothesByUidAndType(String userId, String type) {
  var a = _firebaseFirestore
      .collection('clothes')
      .doc('users')
      .collection(userId)
      .snapshots()
      .map((snapshot) {
        return snapshot.docs
            .map((doc) => Cloth.fromJson(doc.data()))
            .where((cloth) => cloth.type == type) // Filter by type
            .toList();
      });

      return a;
}




}