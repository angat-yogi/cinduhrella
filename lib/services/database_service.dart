import 'dart:io';

import 'package:cinduhrella/models/cloth.dart';
import 'package:cinduhrella/models/social/post.dart';
import 'package:cinduhrella/models/styled_outfit.dart';
import 'package:cinduhrella/models/to_dos/custom_task.dart';
import 'package:cinduhrella/models/to_dos/goal.dart';
import 'package:cinduhrella/models/to_dos/wishlist.dart';
import 'package:cinduhrella/models/trip.dart';
import 'package:cinduhrella/models/user_profile.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:logger/logger.dart';

class DatabaseService {
  final Logger _logger = Logger();
  final FirebaseFirestore _firebaseFirestore = FirebaseFirestore.instance;
  final FirebaseStorage _firebaseStorage = FirebaseStorage.instance;

  DatabaseService() {
    _setUpCollectionReferences();
  }

  CollectionReference? _usersCollection;

  void _setUpCollectionReferences() {
    _usersCollection = _firebaseFirestore.collection('users');
  }

  // -------------- Upload to Firebase Storage ----------------
  Future<String> uploadImage(
      String userId, File imageFile, String folder) async {
    try {
      final storageRef = _firebaseStorage.ref().child(
          'users/$userId/$folder/${DateTime.now().millisecondsSinceEpoch}');
      await storageRef.putFile(imageFile);
      return await storageRef.getDownloadURL();
    } catch (e) {
      _logger.e('Error uploading image: $e');
      rethrow;
    }
  }

  // -------------- CRUD Operations for Rooms ----------------

  Future<void> addRoom(String userId, String roomName, String imageUrl) async {
    if (imageUrl.isEmpty ||
        !(Uri.tryParse(imageUrl)?.hasAbsolutePath ?? false)) {
      _logger.e('Invalid image URL for room.');
      return;
    }
    try {
      await _firebaseFirestore
          .collection('users/$userId/rooms')
          .add({'roomName': roomName, 'imageUrl': imageUrl});
      _logger.i("Room added successfully");
    } catch (e) {
      _logger.e('Error adding room: $e');
    }
  }

  Future<void> updateRoom(
      String userId, String roomId, String roomName, String imageUrl) async {
    if (imageUrl.isEmpty ||
        !(Uri.tryParse(imageUrl)?.hasAbsolutePath ?? false)) {
      _logger.e('Invalid image URL for room.');
      return;
    }
    try {
      await _firebaseFirestore
          .collection('users/$userId/rooms')
          .doc(roomId)
          .update({'roomName': roomName, 'imageUrl': imageUrl});
      _logger.i("Room updated successfully");
    } catch (e) {
      _logger.e('Error updating room: $e');
    }
  }

  Future<void> deleteRoom(String userId, String roomId) async {
    try {
      await _firebaseFirestore
          .collection('users/$userId/rooms')
          .doc(roomId)
          .delete();
      _logger.i("Room deleted successfully");
    } catch (e) {
      _logger.e('Error deleting room: $e');
    }
  }

  Stream<List<Map<String, dynamic>>> getRooms(String userId) {
    return _firebaseFirestore.collection('users/$userId/rooms').snapshots().map(
      (snapshot) {
        return snapshot.docs.map((doc) {
          return {'roomId': doc.id, ...doc.data()};
        }).toList();
      },
    );
  }

  // -------------- CRUD Operations for Storages ----------------

  Future<void> addStorage(
      String userId, String roomId, String storageName, String imageUrl) async {
    if (imageUrl.isEmpty ||
        !(Uri.tryParse(imageUrl)?.hasAbsolutePath ?? false)) {
      _logger.e('Invalid image URL for storage.');
      return;
    }
    try {
      await _firebaseFirestore
          .collection('users/$userId/rooms/$roomId/storages')
          .add({'storageName': storageName, 'imageUrl': imageUrl});
      _logger.i("Storage added successfully");
    } catch (e) {
      _logger.e('Error adding storage: $e');
    }
  }

  Future<void> updateStorage(String userId, String roomId, String storageId,
      String storageName, String imageUrl) async {
    if (imageUrl.isEmpty ||
        !(Uri.tryParse(imageUrl)?.hasAbsolutePath ?? false)) {
      _logger.e('Invalid image URL for storage.');
      return;
    }
    try {
      await _firebaseFirestore
          .collection('users/$userId/rooms/$roomId/storages')
          .doc(storageId)
          .update({'storageName': storageName, 'imageUrl': imageUrl});
      _logger.i("Storage updated successfully");
    } catch (e) {
      _logger.e('Error updating storage: $e');
    }
  }

  Future<void> deleteStorage(
      String userId, String roomId, String storageId) async {
    try {
      await _firebaseFirestore
          .collection('users/$userId/rooms/$roomId/storages')
          .doc(storageId)
          .delete();
      _logger.i("Storage deleted successfully");
    } catch (e) {
      _logger.e('Error deleting storage: $e');
    }
  }

  Stream<List<Map<String, dynamic>>> getStorages(String userId, String roomId) {
    return _firebaseFirestore
        .collection('users/$userId/rooms/$roomId/storages')
        .snapshots()
        .map(
      (snapshot) {
        return snapshot.docs.map((doc) {
          return {'storageId': doc.id, ...doc.data()};
        }).toList();
      },
    );
  }

  // -------------- CRUD Operations for Clothes ----------------
  Future<void> addUnassignedCloth(String userId, Cloth cloth) async {
    try {
      // Reference to the 'unassigned' collection
      DocumentReference clothRef = FirebaseFirestore.instance
          .collection('users/$userId/unassigned')
          .doc(cloth.clothId);

      // Save the cloth data
      await clothRef.set({
        'clothId': cloth.clothId,
        'brand': cloth.brand,
        'size': cloth.size,
        'type': cloth.type,
        'color': cloth.color,
        'description': cloth.description,
        'imageUrl': cloth.imageUrl,
        'addedAt': Timestamp.now(), // ✅ Timestamp for tracking
      });
    } catch (e) {
      print("Error adding unassigned cloth: $e");
      throw Exception("Failed to add unassigned cloth.");
    }
  }

  Future<void> addCloth(
      String userId, String roomId, String storageId, Cloth cloth) async {
    try {
      // Create a reference to generate an ID
      DocumentReference clothRef = _firebaseFirestore
          .collection('users/$userId/rooms/$roomId/storages/$storageId/items')
          .doc();

      // Assign the generated ID to `clothId`
      cloth.clothId = clothRef.id;

      // Save the cloth with its ID
      await clothRef.set(cloth.toJson());

      _logger.i("Cloth added successfully with ID: ${cloth.clothId}");
    } catch (e) {
      _logger.e('Error adding cloth: $e');
    }
  }

  Future<void> updateCloth(String userId, String roomId, String storageId,
      String clothId, Cloth cloth) async {
    try {
      await _firebaseFirestore
          .collection('users/$userId/rooms/$roomId/storages/$storageId/clothes')
          .doc(clothId)
          .update(cloth.toJson());
      _logger.i("Cloth updated successfully");
    } catch (e) {
      _logger.e('Error updating cloth: $e');
    }
  }

  Future<void> deleteCloth(
      String userId, String roomId, String storageId, String clothId) async {
    try {
      await _firebaseFirestore
          .collection('users/$userId/rooms/$roomId/storages/$storageId/clothes')
          .doc(clothId)
          .delete();
      _logger.i("Cloth deleted successfully");
    } catch (e) {
      _logger.e('Error deleting cloth: $e');
    }
  }

  Stream<List<Cloth>> getClothes(
      String userId, String roomId, String storageId) {
    return _firebaseFirestore
        .collection('users/$userId/rooms/$roomId/storages/$storageId/clothes')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return Cloth.fromJson(doc.data());
      }).toList();
    });
  }

  Future<void> createUserProfile({required UserProfile userProfile}) async {
    try {
      DocumentReference userDoc = _usersCollection!.doc(userProfile.uid);
      DocumentSnapshot docSnapshot = await userDoc.get();

      // ✅ Only create a new profile if it doesn't exist
      if (!docSnapshot.exists) {
        await userDoc.set({
          "uid": userProfile.uid,
          "fullName": userProfile.fullName ?? "Unknown User",
          "userName": userProfile.userName ?? "user_${userProfile.uid}",
          "profilePictureUrl": userProfile.profilePictureUrl ??
              "https://example.com/default-profile.png",
          "followingCount": userProfile.followingCount,
          "followersCount": userProfile.followersCount,
          "postCount": userProfile.postCount,
          "following": userProfile.following.isNotEmpty
              ? userProfile.following
              : [], // ✅ Ensure the following list exists
        });
      }
    } catch (e) {
      _logger.e('Error creating user profile: $e');
      rethrow;
    }
  }

  Future<UserProfile?> getUserProfile({required String uid}) async {
    try {
      final docSnapshot = await _usersCollection?.doc(uid).get();
      if (docSnapshot != null && docSnapshot.exists) {
        final data = docSnapshot.data();
        if (data != null) {
          return UserProfile.fromJson(data
              as Map<String, dynamic>); // Convert JSON to UserProfile object
        }
      }
      return null; // Return null if user profile doesn't exist
    } catch (e) {
      _logger.e('Error fetching user profile: $e');
      rethrow; // Re-throw the exception for further handling
    }
  }

  //Motivator App related
  // CRUD Operations for Goals
  Future<String> addGoal(String userId, Goal goal) async {
    try {
      final docRef = await _firebaseFirestore
          .collection('users/$userId/goals')
          .add(goal.toJson());
      _logger.i("Goal added successfully");
      return docRef.id; // Return the ID of the added goal
    } catch (e) {
      _logger.e('Error adding goal: $e');
      rethrow;
    }
  }

  Future<void> updateGoal(String userId, String goalId, Goal goal) async {
    try {
      await _firebaseFirestore
          .collection('users/$userId/goals')
          .doc(goalId)
          .update(goal.toJson());
      _logger.i("Goal updated successfully");
    } catch (e) {
      _logger.e('Error updating goal: $e');
    }
  }

  Future<void> deleteGoal(String userId, String goalId) async {
    try {
      // Delete all tasks associated with the goal
      final tasksQuery = await _firebaseFirestore
          .collection('users/$userId/tasks')
          .where('goalId', isEqualTo: goalId)
          .get();

      for (var taskDoc in tasksQuery.docs) {
        await taskDoc.reference.delete();
      }

      // Delete the goal itself
      await _firebaseFirestore
          .collection('users/$userId/goals')
          .doc(goalId)
          .delete();
      _logger.i("Goal and its tasks deleted successfully");
    } catch (e) {
      _logger.e('Error deleting goal: $e');
    }
  }

  Stream<List<Goal>> getGoals(String userId) {
    _logger.e("userId: $userId");
    final a = _firebaseFirestore
        .collection('users/$userId/goals')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final goalData = doc.data();
        goalData['id'] = doc.id;
        return Goal.fromJson(goalData);
      }).toList();
    });
    _logger.i("Goal retrieved successfully");
    return a;
  }

  // CRUD Operations for Tasks
  Future<String> addTask(String userId, CustomTask task) async {
    try {
      final docRef = await _firebaseFirestore
          .collection('users/$userId/tasks')
          .add(task.toJson());
      _logger.i("Task added successfully");
      return docRef.id; // Return the ID of the added task
    } catch (e) {
      _logger.e('Error adding task: $e');
      rethrow;
    }
  }

  Future<void> addTaskToGoal(
      String userId, String goalId, CustomTask task) async {
    try {
      // Add the task to the tasks collection
      final taskId = await addTask(userId, task);

      // Update the goal to include the task ID
      final goalDoc =
          _firebaseFirestore.collection('users/$userId/goals').doc(goalId);
      final goalSnapshot = await goalDoc.get();

      if (goalSnapshot.exists) {
        final goalData = goalSnapshot.data();
        final taskIds =
            (goalData?['taskIds'] as List<dynamic>? ?? []).cast<String>();
        taskIds.add(taskId);

        await goalDoc.update({'taskIds': taskIds});
        _logger.i("Task added to goal successfully");
      }
    } catch (e) {
      _logger.e('Error adding task to goal: $e');
    }
  }

  // Future<void> updateTask(
  //     String userId, String taskId, CustomTask updatedTask) async {
  //   final taskRef =
  //       _firebaseFirestore.collection('users/$userId/tasks').doc(taskId);
  //   final goalRef = _firebaseFirestore
  //       .collection('users/$userId/goals')
  //       .doc(updatedTask.goalId);

  //   await _firebaseFirestore.runTransaction((transaction) async {
  //     // Perform the read for the task
  //     final taskSnapshot = await transaction.get(taskRef);
  //     if (!taskSnapshot.exists) {
  //       throw Exception("Task does not exist!");
  //     }

  //     // Read the goal data if associated
  //     int totalTasks = 0;
  //     int completedTasks = 0;

  //     if (updatedTask.goalId != null) {
  //       final goalTasksQuery = _firebaseFirestore
  //           .collection('users/$userId/tasks')
  //           .where('goalId', isEqualTo: updatedTask.goalId);
  //       final goalTasksSnapshot = await goalTasksQuery.get();

  //       totalTasks = goalTasksSnapshot.docs.length;
  //       completedTasks = goalTasksSnapshot.docs
  //           .where((doc) => (doc.data()['completed'] ?? false) as bool)
  //           .length;
  //     }

  //     // Calculate the new progress
  //     final progress = totalTasks > 0 ? (completedTasks / totalTasks) * 100 : 0;

  //     // Perform all writes
  //     transaction.update(taskRef, updatedTask.toJson());
  //     if (updatedTask.goalId != null) {
  //       transaction.update(goalRef, {'progress': progress});
  //     }
  //   });
  // }

  Future<void> updateTask(
      String userId, String taskId, CustomTask updatedTask) async {
    final taskRef =
        _firebaseFirestore.collection('users/$userId/tasks').doc(taskId);
    final goalRef = _firebaseFirestore
        .collection('users/$userId/goals')
        .doc(updatedTask.goalId);

    await _firebaseFirestore.runTransaction((transaction) async {
      // Update the task's completion status
      transaction.update(taskRef, updatedTask.toJson());

      // If the task is associated with a goal, recalculate progress
      if (updatedTask.goalId != null) {
        final goalTasksQuery = _firebaseFirestore
            .collection('users/$userId/tasks')
            .where('goalId', isEqualTo: updatedTask.goalId);

        final goalTasksSnapshot = await goalTasksQuery.get();

        // Ensure all tasks are properly evaluated
        final totalTasks = goalTasksSnapshot.docs.length;
        final completedTasks = goalTasksSnapshot.docs.where((doc) {
          final data = doc.data();
          return data['completed'] == true; // Explicitly check for `true`
        }).length;

        _logger.i('Total tasks: $totalTasks, Completed tasks: $completedTasks');

        // Calculate progress
        final progress =
            totalTasks > 0 ? (completedTasks / totalTasks) * 100 : 0;

        // Update the goal's progress
        transaction.update(goalRef, {'progress': progress});
      }
    });
  }

  // Future<List<StyledOutfit>> fetchStyledOutfits(String userId) async {
  //   try {
  //     QuerySnapshot snapshot = await _firebaseFirestore
  //         .collection('users/$userId/styledOutfits')
  //         .get();

  //     return snapshot.docs.map((doc) {
  //       return StyledOutfit.fromFirestore(doc);
  //     }).toList();
  //   } catch (e) {
  //     print("Error fetching outfits: $e");
  //     return [];
  //   }
  // }

  // Update outfit like status
  Future<void> updateOutfitLikeStatus(
      String userId, String outfitId, bool liked) async {
    try {
      await _firebaseFirestore
          .collection('users/$userId/styledOutfits')
          .doc(outfitId)
          .update({'liked': liked});
    } catch (e) {
      print("Error updating like status: $e");
      throw e;
    }
  }

  Future<void> deleteTask(String userId, String taskId) async {
    try {
      final taskDoc = await _firebaseFirestore
          .collection('users/$userId/tasks')
          .doc(taskId)
          .get();

      if (taskDoc.exists) {
        final taskData = taskDoc.data();
        final goalId = taskData?['goalId'];

        // Remove task reference from the goal, if any
        if (goalId != null) {
          final goalDoc =
              _firebaseFirestore.collection('users/$userId/goals').doc(goalId);
          final goalSnapshot = await goalDoc.get();

          if (goalSnapshot.exists) {
            final goalData = goalSnapshot.data();
            final taskIds =
                (goalData?['taskIds'] as List<dynamic>? ?? []).cast<String>();
            taskIds.remove(taskId);

            await goalDoc.update({'taskIds': taskIds});
          }
        }

        // Delete the task
        await taskDoc.reference.delete();
        _logger.i("Task deleted successfully");
      }
    } catch (e) {
      _logger.e('Error deleting task: $e');
    }
  }

  Stream<List<CustomTask>> getTasks(String userId) {
    return _firebaseFirestore
        .collection('users/$userId/tasks')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final taskData = doc.data();
        taskData['id'] = doc.id;
        return CustomTask.fromJson(taskData);
      }).toList();
    });
  }

  // CRUD Operations for Wishlist
  Future<void> addWishlistItem(String userId, Wishlist wishlist) async {
    try {
      await _firebaseFirestore
          .collection('users/$userId/wishlist')
          .add(wishlist.toJson());
      _logger.i("Wishlist item added successfully");
    } catch (e) {
      _logger.e('Error adding wishlist item: $e');
    }
  }

  Future<void> updateWishlistItem(
      String userId, String wishlistId, Wishlist wishlist) async {
    try {
      await _firebaseFirestore
          .collection('users/$userId/wishlist')
          .doc(wishlistId)
          .update(wishlist.toJson());
      _logger.i("Wishlist item updated successfully");
    } catch (e) {
      _logger.e('Error updating wishlist item: $e');
    }
  }

  Future<void> deleteWishlistItem(String userId, String wishlistId) async {
    try {
      await _firebaseFirestore
          .collection('users/$userId/wishlist')
          .doc(wishlistId)
          .delete();
      _logger.i("Wishlist item deleted successfully");
    } catch (e) {
      _logger.e('Error deleting wishlist item: $e');
    }
  }

  Stream<Map<String, List<Map<String, dynamic>>>> fetchUserItemsStream(
      String userId) {
    return FirebaseFirestore.instance
        .collection('users/$userId/rooms')
        .snapshots()
        .asyncMap(
      (roomSnapshot) async {
        Map<String, List<Map<String, dynamic>>> categorizedItems = {
          'top wear': [],
          'bottom wear': [],
          'accessories': [],
        };

        for (var room in roomSnapshot.docs) {
          String roomId = room.id;

          // ✅ Fetch all storages in the room
          QuerySnapshot storagesSnapshot = await FirebaseFirestore.instance
              .collection('users/$userId/rooms/$roomId/storages')
              .get();

          for (var storage in storagesSnapshot.docs) {
            String storageId = storage.id;

            // ✅ Listen for changes in each storage's items
            FirebaseFirestore.instance
                .collection(
                    'users/$userId/rooms/$roomId/storages/$storageId/items')
                .snapshots()
                .listen((itemSnapshot) {
              for (var item in itemSnapshot.docs) {
                var itemData = item.data() as Map<String, dynamic>;
                itemData['id'] = item.id;
                itemData['roomId'] = roomId;
                itemData['storageId'] = storageId;

                _categorizeItem(itemData, categorizedItems);
              }
            });
          }
        }

        // ✅ Listen for Unassigned Items
        FirebaseFirestore.instance
            .collection('users/$userId/unassigned')
            .snapshots()
            .listen((unassignedSnapshot) {
          for (var item in unassignedSnapshot.docs) {
            var itemData = item.data() as Map<String, dynamic>;
            itemData['id'] = item.id;
            itemData['roomId'] = null;
            itemData['storageId'] = null;

            _categorizeItem(itemData, categorizedItems);
          }
        });

        return categorizedItems;
      },
    );
  }

  Future<Map<String, List<Map<String, dynamic>>>> fetchUserItems(
      String userId) async {
    Map<String, List<Map<String, dynamic>>> categorizedItems = {
      'top wear': [],
      'bottom wear': [],
      'accessories': [],
    };

    try {
      // ✅ Step 1: Fetch all rooms for the user
      QuerySnapshot roomsSnapshot =
          await _firebaseFirestore.collection('users/$userId/rooms').get();

      for (var room in roomsSnapshot.docs) {
        String roomId = room.id;

        // ✅ Step 2: Fetch all storages inside the room
        QuerySnapshot storagesSnapshot = await _firebaseFirestore
            .collection('users/$userId/rooms/$roomId/storages')
            .get();

        for (var storage in storagesSnapshot.docs) {
          String storageId = storage.id;

          // ✅ Step 3: Fetch all items inside the storage
          QuerySnapshot itemsSnapshot = await _firebaseFirestore
              .collection(
                  'users/$userId/rooms/$roomId/storages/$storageId/items')
              .get();

          for (var item in itemsSnapshot.docs) {
            var itemData = item.data() as Map<String, dynamic>;
            itemData['id'] = item.id; // Store Firestore ID
            itemData['roomId'] = roomId;
            itemData['storageId'] = storageId;

            // ✅ Categorize item based on type
            _categorizeItem(itemData, categorizedItems);
          }
        }
      }

      // ✅ Step 4: Fetch Unassigned Items
      QuerySnapshot unassignedSnapshot =
          await _firebaseFirestore.collection('users/$userId/unassigned').get();

      for (var item in unassignedSnapshot.docs) {
        var itemData = item.data() as Map<String, dynamic>;
        itemData['id'] = item.id; // Store Firestore ID
        itemData['roomId'] = null; // Indicate unassigned item
        itemData['storageId'] = null;

        // ✅ Categorize unassigned item based on type
        _categorizeItem(itemData, categorizedItems);
      }
    } catch (e) {
      print("Error fetching user items: $e");
    }

    return categorizedItems;
  }

  /// **📌 Helper Function to Categorize Items**
  void _categorizeItem(Map<String, dynamic> itemData,
      Map<String, List<Map<String, dynamic>>> categorizedItems) {
    String itemType = itemData['type'].toString().toLowerCase();

    if (itemType == 'top wear') {
      categorizedItems['top wear']?.add(itemData);
    } else if (itemType == 'bottom wear') {
      categorizedItems['bottom wear']?.add(itemData);
    } else {
      categorizedItems['accessories']?.add(itemData);
    }
  }

  Stream<List<Wishlist>> getWishlist(String userId) {
    return _firebaseFirestore
        .collection('users/$userId/wishlist')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final wishlistData = doc.data();
        wishlistData['id'] = doc.id;
        return Wishlist.fromJson(wishlistData);
      }).toList();
    });
  }

  Future<List<StyledOutfit>> fetchStyledOutfits(String userId) async {
    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('users/$userId/styledOutfits')
          .orderBy('createdAt', descending: true)
          .get();

      print("Fetched ${snapshot.docs.length} outfits from Firestore");

      return snapshot.docs.map((doc) {
        var data = doc.data() as Map<String, dynamic>;
        data['outfitId'] = doc.id; // Assign Firestore document ID
        return StyledOutfit.fromJson(data);
      }).toList();
    } catch (e) {
      print("Error fetching styled outfits: $e");
      return [];
    }
  }

  Future<void> assignItemToRoomStorage(String userId, String itemId,
      String roomId, String? storageId, Map<String, dynamic> itemData) async {
    try {
      DocumentReference itemRef = FirebaseFirestore.instance
          .collection('users/$userId/unassigned')
          .doc(itemId);

      if (storageId != null) {
        // Move to storage inside a room
        await FirebaseFirestore.instance
            .collection('users/$userId/rooms/$roomId/storages/$storageId/items')
            .doc(itemId)
            .set(itemData);
      } else {
        // Move to room only (without storage)
        await FirebaseFirestore.instance
            .collection('users/$userId/rooms/$roomId/items')
            .doc(itemId)
            .set(itemData);
      }

      // Remove from unassigned collection
      await itemRef.delete();
    } catch (e) {
      print("Error assigning item: $e");
    }
  }

  //Trip related:
  Future<void> addTrip(String userId, Trip trip) async {
    try {
      DocumentReference tripRef =
          _firebaseFirestore.collection('users/$userId/trips').doc();

      // Assign document ID to trip
      trip.tripId = tripRef.id;

      // Ensure each cloth and outfit has an ID before saving
      for (var cloth in trip.items) {
        if (cloth.clothId == null || cloth.clothId!.isEmpty) {
          cloth.clothId =
              FirebaseFirestore.instance.collection('temp').doc().id;
        }
      }

      for (var outfit in trip.outfits) {
        if (outfit.outfitId == null || outfit.outfitId!.isEmpty) {
          outfit.outfitId =
              FirebaseFirestore.instance.collection('temp').doc().id;
        }
      }

      await tripRef.set(trip.toJson());

      _logger.i("Trip added successfully with ID: ${trip.tripId}");
    } catch (e) {
      _logger.e('Error adding trip: $e');
    }
  }

  Future<List<Post>> getPublicPosts(String uid) async {
    try {
      // ✅ Step 1: Fetch user profile to get the following list
      DocumentSnapshot userDoc =
          await _firebaseFirestore.collection('users').doc(uid).get();

      List<dynamic> following = [];
      if (userDoc.exists) {
        following = userDoc['following'] ?? [];
      }

      print("✅ Following users: $following");

      // ✅ Step 2: Fetch all public posts
      QuerySnapshot querySnapshot = await _firebaseFirestore
          .collection('posts')
          .where('isPublic', isEqualTo: true)
          .get();

      print("✅ Public Posts Found: ${querySnapshot.docs.length}");

      // ✅ Step 3: Convert documents to `Post` objects
      List<Post> posts = querySnapshot.docs
          .map((doc) => Post.fromJson(doc.data() as Map<String, dynamic>))
          .where((post) =>
              post.uid != uid && // Don't include user's own posts
              (following.contains(post.uid) ||
                  post.isPublic)) // Show followed users' posts or public ones
          .toList();

      print("✅ Filtered Posts: ${posts.length}");

      return posts;
    } catch (e) {
      print("❌ Error fetching public posts: $e");
      return [];
    }
  }

  Future<void> followUser(String currentUserId, String targetUserId) async {
    DocumentReference currentUserRef =
        _firebaseFirestore.collection('users').doc(currentUserId);
    DocumentReference targetUserRef =
        _firebaseFirestore.collection('users').doc(targetUserId);

    await _firebaseFirestore.runTransaction((transaction) async {
      DocumentSnapshot currentUserDoc = await transaction.get(currentUserRef);
      DocumentSnapshot targetUserDoc = await transaction.get(targetUserRef);

      if (!currentUserDoc.exists || !targetUserDoc.exists) return;

      // ✅ Cast data to Map<String, dynamic> before checking keys
      Map<String, dynamic> currentUserData =
          currentUserDoc.data() as Map<String, dynamic>? ?? {};
      Map<String, dynamic> targetUserData =
          targetUserDoc.data() as Map<String, dynamic>? ?? {};

      List<dynamic> currentFollowing = currentUserData.containsKey('following')
          ? currentUserData['following']
          : [];

      List<dynamic> targetFollowers = targetUserData.containsKey('followers')
          ? targetUserData['followers']
          : [];

      if (currentFollowing.contains(targetUserId)) {
        // ✅ Unfollow user
        transaction.update(currentUserRef, {
          'following': FieldValue.arrayRemove([targetUserId]),
          'followingCount': FieldValue.increment(-1),
        });

        transaction.update(targetUserRef, {
          'followers': FieldValue.arrayRemove([currentUserId]),
          'followersCount': FieldValue.increment(-1),
        });
      } else {
        // ✅ Follow user
        transaction.update(currentUserRef, {
          'following': FieldValue.arrayUnion([targetUserId]),
          'followingCount': FieldValue.increment(1),
        });

        transaction.update(targetUserRef, {
          'followers': FieldValue.arrayUnion([currentUserId]),
          'followersCount': FieldValue.increment(1),
        });
      }
    });
  }

  Future<List<Post>> getAllPublicPosts() async {
    try {
      QuerySnapshot snapshot = await _firebaseFirestore
          .collection('posts')
          .where('isPublic', isEqualTo: true)
          .get();

      return snapshot.docs
          .map((doc) => Post.fromJson(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print("Error fetching public posts: $e");
      return [];
    }
  }

  Future<List<Post>> getUserPosts(String userId) async {
    QuerySnapshot snapshot = await FirebaseFirestore.instance
        .collection("posts")
        .where("uid", isEqualTo: userId)
        .orderBy("timestamp", descending: true) // ✅ Sort posts by newest first
        .get();

    return snapshot.docs.map((doc) => Post.fromDocument(doc)).toList();
  }

  Future<bool> isFollowing(String currentUserId, String targetUserId) async {
    DocumentSnapshot userDoc =
        await _firebaseFirestore.collection('users').doc(currentUserId).get();
    List<dynamic> following = userDoc['following'] ?? [];
    return following.contains(targetUserId);
  }

  Future<List<UserProfile>> getAllUsers() async {
    try {
      QuerySnapshot snapshot =
          await _firebaseFirestore.collection('users').get();
      return snapshot.docs
          .map(
              (doc) => UserProfile.fromJson(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print("Error fetching users: $e");
      return [];
    }
  }

  Future<void> addPost(Post post) async {
    try {
      await _firebaseFirestore
          .collection('posts')
          .doc(post.postId)
          .set(post.toJson());
    } catch (e) {
      print("Error adding post: $e");
    }
  }

  Future<List<UserProfile>> searchUsers(String query) async {
    try {
      QuerySnapshot querySnapshot = await _firebaseFirestore
          .collection('users')
          .where('userName', isGreaterThanOrEqualTo: query)
          .where('userName',
              isLessThan: query + '\uf8ff') // Firestore search trick
          .get();

      return querySnapshot.docs
          .map(
              (doc) => UserProfile.fromJson(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print("Error searching users: $e");
      return [];
    }
  }
}
