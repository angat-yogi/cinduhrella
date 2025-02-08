import 'dart:io';

import 'package:cinduhrella/models/cloth.dart';
import 'package:cinduhrella/models/styled_outfit.dart';
import 'package:cinduhrella/models/to_dos/custom_task.dart';
import 'package:cinduhrella/models/to_dos/goal.dart';
import 'package:cinduhrella/models/to_dos/wishlist.dart';
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

  Future<void> addCloth(
      String userId, String roomId, String storageId, Cloth cloth) async {
    try {
      await _firebaseFirestore
          .collection('users/$userId/rooms/$roomId/storages/$storageId/clothes')
          .add(cloth.toJson());
      _logger.i("Cloth added successfully");
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
      await _usersCollection?.doc(userProfile.uid).set(userProfile.toJson());
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
}
