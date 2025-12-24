import 'package:flutter/material.dart';
import 'package:goodlobang/screens/add_listing.dart';
import 'package:goodlobang/screens/home.dart';
import 'package:goodlobang/screens/navigation_bar.dart';

class ListingScreen extends StatelessWidget {
  const ListingScreen({super.key});

  static const String routeName = '/listing-screen';

  @override
  Widget build(BuildContext context) {
    return const BaseScreen(
      content: ListingScreenContent(),
      selectedIndex: 1,
    );
  }
}

class ListingScreenContent extends StatelessWidget {
  const ListingScreenContent({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: theme.colorScheme.surface,
        automaticallyImplyLeading: false, // This needs to be false
        toolbarHeight: 100.0,
        leading: IconButton(
          // Use 'leading' instead of 'actions'
          icon: const Icon(Icons.close),
          onPressed: () {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (context) => const BaseScreen(
                  content: HomeScreen(searchQuery: ''),
                  selectedIndex: 0,
                ),
              ),
            );
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'List anything yourself',
              style: TextStyle(fontSize: 24),
            ),
            const SizedBox(height: 20),
            TextButton(
              style: TextButton.styleFrom(
                padding: const EdgeInsets.all(50),
                side: BorderSide(color: theme.colorScheme.onSurface),
                shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.all(Radius.circular(10))),
              ),
              onPressed: () {
                Navigator.of(context).pushNamed(AddListingScreen.routeName);
                // Implement your functionality here
              },
              child: Column(
                // Replace with a Row for horizontal icon + text
                children: [
                  Icon(
                    Icons.camera_alt,
                    color: theme.iconTheme.color,
                  ),
                  Text(
                    "Add a photo to start a listing",
                    style: TextStyle(
                      fontSize: 20,
                      color: theme.textTheme.bodyLarge?.color, // Use theme color

                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
