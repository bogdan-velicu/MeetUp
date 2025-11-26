import 'package:flutter/material.dart';
import 'widgets/friends_list_view.dart';

class FriendsScreen extends StatelessWidget {
  const FriendsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Friends'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add),
            onPressed: () {
              // TODO: Navigate to add friend screen
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Add friend feature coming soon!'),
                ),
              );
            },
          ),
        ],
      ),
      body: const FriendsListView(),
    );
  }
}

