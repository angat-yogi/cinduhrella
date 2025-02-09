import 'package:cinduhrella/services/auth_service.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get_it/get_it.dart';
import 'package:cinduhrella/services/database_service.dart';
import 'package:cinduhrella/models/to_dos/custom_task.dart';
import 'package:cinduhrella/models/to_dos/goal.dart';
import 'package:cinduhrella/models/to_dos/wishlist.dart';

class GoalTasksSection extends StatelessWidget {
  final DatabaseService _databaseService =
      GetIt.instance.get<DatabaseService>();
  final AuthService _authService = GetIt.instance.get<AuthService>();
  final String userId = GetIt.instance.get<AuthService>().user!.uid;

  GoalTasksSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildGoalsSection(context),
        const SizedBox(height: 20),
        _buildWishlistSection(),
        const SizedBox(height: 20),
        _buildTasksSection(),
      ],
    );
  }

  /// **📌 Goals Section**
  Widget _buildGoalsSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Goals in Progress',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            IconButton(
              icon: const Icon(Icons.add, color: Colors.blue),
              onPressed: () => _addGoal(context),
            ),
          ],
        ),
        const SizedBox(height: 10),
        StreamBuilder<List<Goal>>(
          stream: _databaseService.getGoals(userId),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasData) {
              final goals = snapshot.data!;
              return SizedBox(
                height: 150,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: goals.length,
                  itemBuilder: (context, index) {
                    final goal = goals[index];
                    return Card(
                      child: Container(
                        width: 200,
                        padding: const EdgeInsets.all(8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    goal.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ),
                                IconButton(
                                  icon:
                                      const Icon(Icons.add, color: Colors.blue),
                                  onPressed: () =>
                                      _addTaskToGoal(context, goal.id!),
                                ),
                              ],
                            ),
                            const SizedBox(height: 5),
                            LinearProgressIndicator(value: goal.progress / 100),
                            Text('${goal.progress}% complete'),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              );
            } else {
              return const Text('No goals found.');
            }
          },
        ),
      ],
    );
  }

  /// **📌 Wishlist Section**
  Widget _buildWishlistSection() {
    return StreamBuilder<List<Wishlist>>(
      stream: _databaseService.getWishlist(userId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const CircularProgressIndicator();
        final wishlist = snapshot.data!;
        if (wishlist.isEmpty) {
          return const Text('No items in wishlist.');
        }
        final nextItem = wishlist.first;
        return ListTile(
          leading: Image.network(nextItem.imageUrl),
          title: Text(nextItem.name),
          subtitle: Text('Unlock in ${nextItem.pointsNeeded} points'),
        );
      },
    );
  }

  /// **📌 Tasks Section**
  Widget _buildTasksSection() {
    return StreamBuilder<List<CustomTask>>(
      stream: _databaseService.getTasks(userId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const CircularProgressIndicator();
        final tasks = snapshot.data!;
        return Column(
          children: tasks.map((task) {
            return CheckboxListTile(
              title: Text(task.name),
              value: task.completed,
              onChanged: (newValue) {
                final updatedTask = CustomTask(
                  id: task.id,
                  name: task.name,
                  completed: newValue!,
                  goalId: task.goalId,
                );
                _databaseService.updateTask(userId, task.id!, updatedTask);
              },
            );
          }).toList(),
        );
      },
    );
  }

  /// **📌 Add Goal Dialog**
  void _addGoal(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        final TextEditingController nameController = TextEditingController();
        return AlertDialog(
          title: const Text('Add Goal'),
          content: TextField(
            controller: nameController,
            decoration: const InputDecoration(hintText: 'Goal Name'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                final goalId = _generateGoalId();
                final goal =
                    Goal(id: goalId, name: nameController.text, progress: 0);
                _databaseService.addGoal(userId, goal);
                Navigator.pop(context);
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  /// **📌 Add Task to Goal Dialog**
  void _addTaskToGoal(BuildContext context, String? goalId) {
    showDialog(
      context: context,
      builder: (context) {
        final TextEditingController taskController = TextEditingController();
        return AlertDialog(
          title: const Text('Add Task'),
          content: TextField(
            controller: taskController,
            decoration: const InputDecoration(hintText: 'Task Name'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                final task = CustomTask(
                    name: taskController.text,
                    completed: false,
                    goalId: goalId);
                if (goalId != null) {
                  _databaseService.addTaskToGoal(userId, goalId, task);
                } else {
                  _databaseService.addTask(userId, task);
                }
                Navigator.pop(context);
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  /// **📌 Generate Unique Goal ID**
  String _generateGoalId() {
    final userIdFor = _authService.user!.uid;
    final userIdHash = sha256.convert(utf8.encode(userIdFor)).toString();
    return '$userIdHash-${DateTime.now().millisecondsSinceEpoch}';
  }
}
