import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/app_user.dart';
import '../core/constants/app_constants.dart';

Future<void> seedDemoUsers() async {
  final db = FirebaseFirestore.instance;
  final usersCollection = db.collection(AppConstants.usersCollection);

  final List<Map<String, dynamic>> demoUsers = [
    // --- GIRLS ---
    {
      'uid': 'demo_user_1',
      'name': 'Mint',
      'birthday': DateTime.now().subtract(const Duration(days: 365 * 22)),
      'gender': 'Woman',
      'interestedIn': 'Men',
      'bio': 'Matcha lover and amateur photographer. Let\'s go cafe hopping in Ari! 🍵📸',
      'lookingFor': 'Long-term partner',
      'photoUrls': [
        'https://images.unsplash.com/photo-1544005313-94ddf0286df2?auto=format&fit=crop&q=80&w=800',
        'https://images.unsplash.com/photo-1524504388940-b1c1722653e1?auto=format&fit=crop&q=80&w=800'
      ],
      'locationName': 'Bangkok, Thailand',
      'interests': ['Cafe Hopping', 'Photography', 'Matcha'],
      'pronouns': 'She/Her',
      'height': "160 cm",
    },
    {
      'uid': 'demo_user_2',
      'name': 'Ploy',
      'birthday': DateTime.now().subtract(const Duration(days: 365 * 26)),
      'gender': 'Woman',
      'interestedIn': 'Men',
      'bio': 'Marketing by day, Pilates instructor by night. Looking for someone to grab mookata with! 🥢',
      'lookingFor': 'Long-term partner',
      'photoUrls': [
        'https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&q=80&w=800',
        'https://images.unsplash.com/photo-1517841905240-472988babdf9?auto=format&fit=crop&q=80&w=800'
      ],
      'locationName': 'Bangkok, Thailand',
      'interests': ['Pilates', 'Mookata', 'Travel'],
      'pronouns': 'She/Her',
      'height': "165 cm",
    },
    {
      'uid': 'demo_user_3',
      'name': 'Fah',
      'birthday': DateTime.now().subtract(const Duration(days: 365 * 20)),
      'gender': 'Woman',
      'interestedIn': 'Men',
      'bio': 'Chula student. I mostly just study and watch K-Dramas. Adopt me? 🥹',
      'lookingFor': 'New friends',
      'photoUrls': [
        'https://images.unsplash.com/photo-1494790108377-be9c29b29330?auto=format&fit=crop&q=80&w=800',
        'https://images.unsplash.com/photo-1438761681033-6461ffad8d80?auto=format&fit=crop&q=80&w=800'
      ],
      'locationName': 'Bangkok, Thailand',
      'interests': ['K-Dramas', 'Studying', 'Food'],
      'pronouns': 'She/Her',
      'height': "158 cm",
    },
    {
      'uid': 'demo_user_4',
      'name': 'Jan',
      'birthday': DateTime.now().subtract(const Duration(days: 365 * 28)),
      'gender': 'Woman',
      'interestedIn': 'Everyone',
      'bio': 'Freelance designer. Just moved to Chiang Mai for the slow life. Show me around? ⛰️',
      'lookingFor': 'Long-term partner',
      'photoUrls': [
        'https://images.unsplash.com/photo-1488426862026-3ee34a7d66df?auto=format&fit=crop&q=80&w=800',
        'https://images.unsplash.com/photo-1517365830460-955ce3ccd263?auto=format&fit=crop&q=80&w=800'
      ],
      'locationName': 'Chiang Mai, Thailand',
      'interests': ['Design', 'Trekking', 'Art'],
      'pronouns': 'She/Her',
      'height': "162 cm",
    },
    {
      'uid': 'demo_user_5',
      'name': 'Ice',
      'birthday': DateTime.now().subtract(const Duration(days: 365 * 24)),
      'gender': 'Woman',
      'interestedIn': 'Men',
      'bio': 'Cat mom of 3. If my cats don\'t like you, it\'s not going to work out. 🐈',
      'lookingFor': 'Long-term partner',
      'photoUrls': [
        'https://images.unsplash.com/photo-1529626455594-4ff0802cfb7e?auto=format&fit=crop&q=80&w=800',
        'https://images.unsplash.com/photo-1513207565459-d7f36bfa1222?auto=format&fit=crop&q=80&w=800'
      ],
      'locationName': 'Bangkok, Thailand',
      'interests': ['Cats', 'Baking', 'Netflix'],
      'pronouns': 'She/Her',
      'height': "155 cm",
    },
    {
      'uid': 'demo_user_6',
      'name': 'May',
      'birthday': DateTime.now().subtract(const Duration(days: 365 * 25)),
      'gender': 'Woman',
      'interestedIn': 'Women',
      'bio': 'Always planning the next beach trip to Phuket. Looking for my travel buddy! 🌊🍹',
      'lookingFor': 'Long-term partner',
      'photoUrls': [
        'https://images.unsplash.com/photo-1606122017369-d782bbb78f32?auto=format&fit=crop&q=80&w=800',
        'https://images.unsplash.com/photo-1527203561188-dae1bc1a417f?auto=format&fit=crop&q=80&w=800'
      ],
      'locationName': 'Phuket, Thailand',
      'interests': ['Beach', 'Cocktails', 'Travel'],
      'pronouns': 'She/Her',
      'height': "168 cm",
    },
    {
      'uid': 'demo_user_7',
      'name': 'Nan',
      'birthday': DateTime.now().subtract(const Duration(days: 365 * 21)),
      'gender': 'Woman',
      'interestedIn': 'Men',
      'bio': 'Dancing is my therapy. Find me at the studio or eating som tum! 🌶️',
      'lookingFor': 'Short-term fun',
      'photoUrls': [
        'https://images.unsplash.com/photo-1485206412256-701ccc5b93ca?auto=format&fit=crop&q=80&w=800',
        'https://images.unsplash.com/photo-1510617300412-a74fcff654f5?auto=format&fit=crop&q=80&w=800'
      ],
      'locationName': 'Bangkok, Thailand',
      'interests': ['Dancing', 'Som Tum', 'Music'],
      'pronouns': 'She/Her',
      'height': "161 cm",
    },

    // --- BOYS ---
    {
      'uid': 'demo_user_9',
      'name': 'Win',
      'birthday': DateTime.now().subtract(const Duration(days: 365 * 24)),
      'gender': 'Man',
      'interestedIn': 'Women',
      'bio': 'Film student. Can talk about movies for hours. Let\'s go to House Samyan. �',
      'lookingFor': 'Long-term partner',
      'photoUrls': [
        'https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?auto=format&fit=crop&q=80&w=800',
        'https://images.unsplash.com/photo-1552058544-e2bfd43064dc?auto=format&fit=crop&q=80&w=800'
      ],
      'locationName': 'Bangkok, Thailand',
      'interests': ['Movies', 'Film Cameras', 'Indie Music'],
      'pronouns': 'He/Him',
      'height': "178 cm",
    },
    {
      'uid': 'demo_user_10',
      'name': 'Bank',
      'birthday': DateTime.now().subtract(const Duration(days: 365 * 27)),
      'gender': 'Man',
      'interestedIn': 'Women',
      'bio': 'Software Engineer. Coffee addict. Looking for someone to pull me away from my keyboard. �☕',
      'lookingFor': 'Long-term partner',
      'photoUrls': [
        'https://images.unsplash.com/photo-1519085360753-af0119f7cbe7?auto=format&fit=crop&q=80&w=800',
        'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?auto=format&fit=crop&q=80&w=800'
      ],
      'locationName': 'Bangkok, Thailand',
      'interests': ['Coding', 'Coffee', 'Gaming'],
      'pronouns': 'He/Him',
      'height': "180 cm",
    },
    {
      'uid': 'demo_user_11',
      'name': 'Earth',
      'birthday': DateTime.now().subtract(const Duration(days: 365 * 25)),
      'gender': 'Man',
      'interestedIn': 'Women',
      'bio': 'Love nature, hiking, and camping. Spend my weekends outside of Bangkok. ⛺',
      'lookingFor': 'Long-term partner',
      'photoUrls': [
        'https://images.unsplash.com/photo-1504257432389-52343af06ae3?auto=format&fit=crop&q=80&w=800',
        'https://images.unsplash.com/photo-1492562080023-ab3db95bfbce?auto=format&fit=crop&q=80&w=800'
      ],
      'locationName': 'Chiang Mai, Thailand',
      'interests': ['Camping', 'Hiking', 'Nature'],
      'pronouns': 'He/Him',
      'height': "175 cm",
    },
    {
      'uid': 'demo_user_12',
      'name': 'Nut',
      'birthday': DateTime.now().subtract(const Duration(days: 365 * 22)),
      'gender': 'Man',
      'interestedIn': 'Men',
      'bio': 'Medical student. Barely have free time but promise to make time for the right guy! 🩺',
      'lookingFor': 'Long-term partner',
      'photoUrls': [
        'https://images.unsplash.com/photo-1531427186611-ecfd6d936c79?auto=format&fit=crop&q=80&w=800',
        'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?auto=format&fit=crop&q=80&w=800'
      ],
      'locationName': 'Bangkok, Thailand',
      'interests': ['Medicine', 'Reading', 'Gym'],
      'pronouns': 'He/Him',
      'height': "177 cm",
    },
    {
      'uid': 'demo_user_13',
      'name': 'Krit',
      'birthday': DateTime.now().subtract(const Duration(days: 365 * 28)),
      'gender': 'Man',
      'interestedIn': 'Women',
      'bio': 'Running a small business. Dog dad to a Golden Retriever named Tofu. 🐕',
      'lookingFor': 'Long-term partner',
      'photoUrls': [
        'https://images.unsplash.com/photo-1530268729831-4b0b9e170218?auto=format&fit=crop&q=80&w=800',
        'https://images.unsplash.com/photo-1480455624313-e29b44bbfde1?auto=format&fit=crop&q=80&w=800'
      ],
      'locationName': 'Bangkok, Thailand',
      'interests': ['Dogs', 'Business', 'Running'],
      'pronouns': 'He/Him',
      'height': "182 cm",
    },
    {
      'uid': 'demo_user_14',
      'name': 'Sun',
      'birthday': DateTime.now().subtract(const Duration(days: 365 * 19)),
      'gender': 'Man',
      'interestedIn': 'Women',
      'bio': 'University student. Love playing guitar and singing. I\'ll write a song for you. 🎸',
      'lookingFor': 'New friends',
      'photoUrls': [
        'https://images.unsplash.com/photo-1513721032312-6a18a42c8763?auto=format&fit=crop&q=80&w=800',
        'https://images.unsplash.com/photo-1519085360753-af0119f7cbe7?auto=format&fit=crop&q=80&w=800'
      ],
      'locationName': 'Bangkok, Thailand',
      'interests': ['Guitar', 'Singing', 'Cafe'],
      'pronouns': 'He/Him',
      'height': "176 cm",
    },
    {
      'uid': 'demo_user_15',
      'name': 'Ken',
      'birthday': DateTime.now().subtract(const Duration(days: 365 * 26)),
      'gender': 'Man',
      'interestedIn': 'Women',
      'bio': 'Fitness trainer. Health is wealth! Looking for a swolemate to hit the gym with. 💪',
      'lookingFor': 'Short-term fun',
      'photoUrls': [
        'https://images.unsplash.com/photo-1570295999919-56ceb5ecca61?auto=format&fit=crop&q=80&w=800'
      ],
      'locationName': 'Bangkok, Thailand',
      'interests': ['Gym', 'Fitness', 'Nutrition'],
      'pronouns': 'He/Him',
      'height': "185 cm",
    },
    {
      'uid': 'demo_user_16',
      'name': 'Poom',
      'birthday': DateTime.now().subtract(const Duration(days: 365 * 23)),
      'gender': 'Man',
      'interestedIn': 'Everyone',
      'bio': 'Photographer and visual artist. Always chasing the perfect golden hour light. �',
      'lookingFor': 'Long-term partner',
      'photoUrls': [
        'https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?auto=format&fit=crop&q=80&w=800',
        'https://images.unsplash.com/photo-1492562080023-ab3db95bfbce?auto=format&fit=crop&q=80&w=800'
      ],
      'locationName': 'Chiang Mai, Thailand',
      'interests': ['Photography', 'Art', 'Travel'],
      'pronouns': 'He/Him',
      'height': "179 cm",
    },
    {
      'uid': 'demo_user_17',
      'name': 'Nawat',
      'birthday': DateTime.now().subtract(const Duration(days: 365 * 21)),
      'gender': 'Man',
      'interestedIn': 'Women',
      'bio': 'Engineering student. Love esports and building mechanical keyboards! ⌨️🎮',
      'lookingFor': 'Long-term partner',
      'photoUrls': [
        'https://images.unsplash.com/photo-1552058544-e2bfd43064dc?auto=format&fit=crop&q=80&w=800',
        'https://images.unsplash.com/photo-1530268729831-4b0b9e170218?auto=format&fit=crop&q=80&w=800'
      ],
      'locationName': 'Bangkok, Thailand',
      'interests': ['Esports', 'Tech', 'Anime'],
      'pronouns': 'He/Him',
      'height': "174 cm",
    },
    {
      'uid': 'demo_user_18',
      'name': 'Tay',
      'birthday': DateTime.now().subtract(const Duration(days: 365 * 28)),
      'gender': 'Man',
      'interestedIn': 'Men',
      'bio': 'Foodie. If we date, I\'ll take you to the best omakase and hidden street food spots! 🍣',
      'lookingFor': 'Long-term partner',
      'photoUrls': [
        'https://images.unsplash.com/photo-1480455624313-e29b44bbfde1?auto=format&fit=crop&q=80&w=800',
        'https://images.unsplash.com/photo-1519085360753-af0119f7cbe7?auto=format&fit=crop&q=80&w=800'
      ],
      'locationName': 'Bangkok, Thailand',
      'interests': ['Foodie', 'Travel', 'Omakase'],
      'pronouns': 'He/Him',
      'height': "178 cm",
    },
    {
      'uid': 'demo_user_19',
      'name': 'Faye',
      'birthday': DateTime.now().subtract(const Duration(days: 365 * 24)),
      'gender': 'Woman',
      'interestedIn': 'Men',
      'bio': 'Data analyst by day, baker by night. Let me bake you some matcha cookies! 🍵🍪',
      'lookingFor': 'Long-term partner',
      'photoUrls': [
        'https://images.unsplash.com/photo-1544005313-94ddf0286df2?auto=format&fit=crop&q=80&w=800',
        'https://images.unsplash.com/photo-1554151228-14d9def656e4?auto=format&fit=crop&q=80&w=800'
      ],
      'locationName': 'Bangkok, Thailand',
      'interests': ['Baking', 'Data Analytics', 'Matcha'],
      'pronouns': 'She/Her',
      'height': "160 cm",
    },
    {
      'uid': 'demo_user_20',
      'name': 'Ning',
      'birthday': DateTime.now().subtract(const Duration(days: 365 * 27)),
      'gender': 'Woman',
      'interestedIn': 'Men',
      'bio': 'Yoga instructor. I love exploring nature and finding the best vegan spots in town. 🌿',
      'lookingFor': 'Long-term partner',
      'photoUrls': [
        'https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&q=80&w=800',
        'https://images.unsplash.com/photo-1524504388940-b1c1722653e1?auto=format&fit=crop&q=80&w=800'
      ],
      'locationName': 'Chiang Mai, Thailand',
      'interests': ['Yoga', 'Nature', 'Vegan Food'],
      'pronouns': 'She/Her',
      'height': "164 cm",
    },
    {
      'uid': 'demo_user_21',
      'name': 'Garn',
      'birthday': DateTime.now().subtract(const Duration(days: 365 * 22)),
      'gender': 'Woman',
      'interestedIn': 'Everyone',
      'bio': 'Medical student. Surviving on iced americanos and 4 hours of sleep. Send caffeine. ☕️',
      'lookingFor': 'Short-term fun',
      'photoUrls': [
        'https://images.unsplash.com/photo-1531746020798-e6953c6e8e04?auto=format&fit=crop&q=80&w=800',
        'https://images.unsplash.com/photo-1494790108377-be9c29b29330?auto=format&fit=crop&q=80&w=800'
      ],
      'locationName': 'Bangkok, Thailand',
      'interests': ['Medicine', 'Coffee', 'Reading'],
      'pronouns': 'She/Her',
      'height': "158 cm",
    },
    {
      'uid': 'demo_user_22',
      'name': 'Jane',
      'birthday': DateTime.now().subtract(const Duration(days: 365 * 25)),
      'gender': 'Woman',
      'interestedIn': 'Men',
      'bio': 'Graphic designer. I probably spend too much time re-arranging my room and buying houseplants. 🪴',
      'lookingFor': 'Long-term partner',
      'photoUrls': [
        'https://images.unsplash.com/photo-1529626455594-4ff0802cfb7e?auto=format&fit=crop&q=80&w=800',
        'https://images.unsplash.com/photo-1517841905240-472988babdf9?auto=format&fit=crop&q=80&w=800'
      ],
      'locationName': 'Bangkok, Thailand',
      'interests': ['Design', 'Houseplants', 'Art'],
      'pronouns': 'She/Her',
      'height': "165 cm",
    },
    {
      'uid': 'demo_user_23',
      'name': 'May',
      'birthday': DateTime.now().subtract(const Duration(days: 365 * 20)),
      'gender': 'Woman',
      'interestedIn': 'Women',
      'bio': 'Fashion design major. Concert buddy needed for indie festivals! 🎵',
      'lookingFor': 'New friends',
      'photoUrls': [
        'https://images.unsplash.com/photo-1438761681033-6461ffad8d80?auto=format&fit=crop&q=80&w=800',
        'https://images.unsplash.com/photo-1503185912284-5271ff81b9a8?auto=format&fit=crop&q=80&w=800'
      ],
      'locationName': 'Bangkok, Thailand',
      'interests': ['Fashion', 'Music festivals', 'Indie music'],
      'pronouns': 'She/They',
      'height': "162 cm",
    },
    {
      'uid': 'demo_user_24',
      'name': 'Bam',
      'birthday': DateTime.now().subtract(const Duration(days: 365 * 26)),
      'gender': 'Woman',
      'interestedIn': 'Men',
      'bio': 'Let\'s go get spicy somtum together. I can definitely handle more chili than you! 🌶️',
      'lookingFor': 'Long-term partner',
      'photoUrls': [
        'https://images.unsplash.com/photo-1517365830460-955ce3ccd263?auto=format&fit=crop&q=80&w=800',
        'https://images.unsplash.com/photo-1508214751196-bfd14092410a?auto=format&fit=crop&q=80&w=800'
      ],
      'locationName': 'Phuket, Thailand',
      'interests': ['Foodie', 'Spicy Food', 'Beach'],
      'pronouns': 'She/Her',
      'height': "168 cm",
    },
  ];

  for (var data in demoUsers) {
    try {
      final docRef = usersCollection.doc(data['uid']);
      final docSnap = await docRef.get();
      // Overwrite or create to ensure the new Thai users take effect if the old ones were already seeded with these UIDs
      final appUser = AppUser(
        uid: data['uid'],
        name: data['name'],
        birthday: data['birthday'],
        gender: data['gender'],
        interestedIn: data['interestedIn'],
        bio: data['bio'],
        lookingFor: data['lookingFor'],
        photoUrls: data['photoUrls'],
        locationName: data['locationName'],
        interests: data['interests'],
        pronouns: data['pronouns'],
        height: data['height'],
        createdAt: docSnap.exists ? (docSnap.data()?['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now() : DateTime.now(),
        lastSeen: DateTime.now(),
        isOnboardingComplete: true,
        hasPremiumFlag: false,
        superLikesCount: 5,
      );
      await docRef.set(appUser.toFirestore());
      print("Seeded demo user: ${data['name']}");
    } catch (e) {
      print("Error seeding ${data['name']}: $e");
    }
  }
}
