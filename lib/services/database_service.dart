import 'package:cinduhrella/models/cloth.dart';
import 'package:cinduhrella/models/user_profile.dart';
import 'package:cinduhrella/services/auth_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get_it/get_it.dart';


class DatabaseService {

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
    print('Error fetching username: $e'); // Handle errors as needed
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
    print('Error fetching profile picture: $e'); // Handle errors as needed
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
    print('Error fetching fullname: $e'); // Handle errors as needed
  }
  return null; // Return null if the user does not exist
}

Stream<List<Cloth>> getClothesByUid(String uid) {
  return _clothesCollection!
      .where('uid', isEqualTo: uid) // Query clothes by the user's UID
      .snapshots()
      .map((snapshot) => snapshot.docs
          .map((doc) {
            // Ensure that the data is not null and is of type Cloth
            final data = doc.data();
            return data != null ? data as Cloth : null; // Cast with null check
          })
          .whereType<Cloth>() // Filter out any null values
          .toList());
}




}