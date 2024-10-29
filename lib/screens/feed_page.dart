import 'package:flutter/material.dart';

class FeedPage extends StatefulWidget {
  @override
  _FeedPageState createState() => _FeedPageState();
}

class _FeedPageState extends State<FeedPage> {
  // Sample feed data with votes and comments, will get from API later
  final List<Map<String, dynamic>> feedData = [
    {'type': 'image', 'url': 'https://letsenhance.io/static/8f5e523ee6b2479e26ecc91b9c25261e/1015f/MainAfter.jpg', 'caption': 'Beautiful Scenery', 'votes': 0, 'comments': []},
    {'type': 'video', 'url': 'https://www.sample-videos.com/video123/mp4/720/big_buck_bunny_720p_1mb.mp4', 'caption': 'A nice video', 'votes': 0, 'comments': []},
    {'type': 'image', 'url': 'https://letsenhance.io/static/8f5e523ee6b2479e26ecc91b9c25261e/1015f/MainAfter.jpg', 'caption': 'A cool image', 'votes': 0, 'comments': []},
    {'type': 'image', 'url': 'https://letsenhance.io/static/8f5e523ee6b2479e26ecc91b9c25261e/1015f/MainAfter.jpg','caption': 'AI in Healthcare', 'content': 'AI is transforming the healthcare industry...', 'votes': 0, 'comments': []},
    {'type': 'image', 'url': 'https://letsenhance.io/static/8f5e523ee6b2479e26ecc91b9c25261e/1015f/MainAfter.jpg','caption': 'Future of AI', 'content': 'AI will revolutionize multiple industries in the next decade...', 'votes': 0, 'comments': []},
  ];

  // Function to handle upvote
  void _handleVote(int index, bool isUpvote) {
    setState(() {
      if (isUpvote) {
        feedData[index]['votes']++;
      } else {
        feedData[index]['votes']--;
      }
    });
  }

  // Function to add a comment
  void _addComment(int index, String comment) {
    setState(() {
      feedData[index]['comments'].add(comment);
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(10),
      itemCount: feedData.length,
      itemBuilder: (context, index) {
        final feedItem = feedData[index];

        if (feedItem['type'] == 'image') {
          return _buildImageFeedItem(feedItem, index);
        } else if (feedItem['type'] == 'video') {
          return _buildVideoFeedItem(feedItem, index);
        } else if (feedItem['type'] == 'article') {
          return _buildArticleFeedItem(feedItem, index);
        }
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildArticleFeedItem(Map<String, dynamic> feedItem, int index) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          feedItem['title'],
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 5),
        Text(feedItem['content']),
        const SizedBox(height: 10),
        _buildVoteAndCommentSection(index),
        const Divider(),
      ],
    );
  }

  Widget _buildImageFeedItem(Map<String, dynamic> feedItem, int index) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Image.network(feedItem['url']),
        const SizedBox(height: 5),
        Text(
          feedItem['caption'],
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        _buildVoteAndCommentSection(index),
        const Divider(),
      ],
    );
  }

  Widget _buildVideoFeedItem(Map<String, dynamic> feedItem, int index) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 200,
          color: Colors.black,
          child: const Center(
            child: Icon(
              Icons.play_circle_outline,
              color: Colors.white,
              size: 50,
            ),
          ),
        ),
        const SizedBox(height: 5),
        Text(
          feedItem['caption'],
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        _buildVoteAndCommentSection(index),
        const Divider(),
      ],
    );
  }

  // Widget for the voting and commenting section
  Widget _buildVoteAndCommentSection(int index) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Voting buttons
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.thumb_up),
              onPressed: () => _handleVote(index, true),
            ),
            IconButton(
              icon: const Icon(Icons.thumb_down),
              onPressed: () => _handleVote(index, false),
            ),
            Text('Votes: ${feedData[index]['votes']}'),
          ],
        ),
        // Comment input field
        Row(
          children: [
            Expanded(
              child: TextField(
                decoration: const InputDecoration(hintText: 'Add a comment...'),
                onSubmitted: (comment) {
                  _addComment(index, comment);
                },
              ),
            ),
          ],
        ),
        // Display comments
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: feedData[index]['comments'].length,
          itemBuilder: (context, commentIndex) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: Text('- ${feedData[index]['comments'][commentIndex]}'),
            );
          },
        ),
      ],
    );
  }
}