import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/article.dart';

class NewsService {
  final String apiKey = 'YOUR_API_KEY_HERE'; 
  final String baseUrl = 'https://newsapi.org/v2';

  Future<List<Article>> fetchTopHeadlines() async {
    if (apiKey == 'YOUR_API_KEY_HERE' || apiKey.isEmpty) {
      await Future.delayed(const Duration(milliseconds: 500));
      return _getMockArticles('general');
    }

    try {
      final response = await http.get(Uri.parse('$baseUrl/top-headlines?country=us&apiKey=$apiKey'));
      if (response.statusCode == 200) {
        Map<String, dynamic> json = jsonDecode(response.body);
        List<dynamic> body = json['articles'] ?? [];
        return body.map((item) => Article.fromJson(item)).toList();
      }
    } catch (e) {
      return _getMockArticles('general');
    }
    return _getMockArticles('general');
  }

  Future<List<Article>> fetchByCategory(String category) async {
    if (apiKey == 'YOUR_API_KEY_HERE' || apiKey.isEmpty) {
      await Future.delayed(const Duration(milliseconds: 500));
      return _getMockArticles(category.toLowerCase());
    }

    try {
      final response = await http.get(Uri.parse('$baseUrl/top-headlines?country=us&category=$category&apiKey=$apiKey'));
      if (response.statusCode == 200) {
        Map<String, dynamic> json = jsonDecode(response.body);
        List<dynamic> body = json['articles'] ?? [];
        return body.map((item) => Article.fromJson(item)).toList();
      }
    } catch (e) {
      return _getMockArticles(category.toLowerCase());
    }
    return _getMockArticles(category.toLowerCase());
  }

  List<Article> _getMockArticles(String category) {
    final Map<String, List<Article>> mockData = {
      'general': [
        Article(
          title: "Global Summit 2026: Unity in Action",
          description: "World leaders gather to discuss climate change and global economic stability.",
          urlToImage: "https://images.unsplash.com/photo-1451187580459-43490279c0fa?w=800",
          content: "The annual global summit kicked off today with a focus on collaborative solutions...",
          publishedAt: DateTime.now(),
          sourceName: "Global Times",
          url: "https://www.bbc.com/news/world",
        ),
      ],
      'business': [
        Article(
          title: "Stock Market Hits Record Highs",
          description: "Tech stocks lead the surge as earnings reports exceed analyst expectations.",
          urlToImage: "https://images.unsplash.com/photo-1460925895917-afdab827c52f?w=800",
          content: "Investors are celebrating today as the major indices reached new milestones...",
          publishedAt: DateTime.now(),
          sourceName: "Financial Post",
          url: "https://www.bloomberg.com/markets",
        ),
      ],
      'technology': [
        Article(
          title: "Next-Gen AI Chips Unveiled",
          description: "New hardware promises 10x faster processing for mobile AI applications.",
          urlToImage: "https://images.unsplash.com/photo-1518770660439-4636190af475?w=800",
          content: "A leading tech giant has just revealed its latest semiconductor technology...",
          publishedAt: DateTime.now(),
          sourceName: "Tech Insider",
          url: "https://www.theverge.com/tech",
        ),
      ],
      'science': [
        Article(
          title: "Mars Rover Discovers Ancient Riverbed",
          description: "New evidence suggests water flowed on the red planet for millions of years.",
          urlToImage: "https://images.unsplash.com/photo-1614728263952-84ea206f99b6?w=800",
          content: "NASA's latest mission has provided groundbreaking data about the history of Mars...",
          publishedAt: DateTime.now(),
          sourceName: "Space News",
          url: "https://www.nasa.gov/news-release",
        ),
      ],
      'health': [
        Article(
          title: "Breakthrough in Personalized Medicine",
          description: "DNA-based treatments showing 90% success rate in clinical trials.",
          urlToImage: "https://images.unsplash.com/photo-1505751172107-57322a304509?w=800",
          content: "Scientists have developed a new way to tailor medical treatments to individuals...",
          publishedAt: DateTime.now(),
          sourceName: "Medical News",
          url: "https://www.healthline.com/news",
        ),
      ],
      'sports': [
        Article(
          title: "Olympic Preparations in Full Swing",
          description: "Host city unveils state-of-the-art stadiums for the upcoming games.",
          urlToImage: "https://images.unsplash.com/photo-1504450758481-7338eba7524a?w=800",
          content: "Athletes from around the world are gearing up for the biggest event...",
          publishedAt: DateTime.now(),
          sourceName: "Sports Central",
          url: "https://www.espn.com",
        ),
      ],
      'entertainment': [
        Article(
          title: "Award-Winning Director Announces New Project",
          description: "A star-studded cast is set to join the upcoming fantasy trilogy.",
          urlToImage: "https://images.unsplash.com/photo-1485846234645-a62644f84728?w=800",
          content: "Fans are buzzing with excitement after the official press release...",
          publishedAt: DateTime.now(),
          sourceName: "Cinema Today",
          url: "https://www.hollywoodreporter.com",
        ),
      ],
    };

    return mockData[category] ?? mockData['general']!;
  }
}
