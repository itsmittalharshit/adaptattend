/// Maps seeded employee usernames to bundled avatar assets.
/// Add entries here when new demo employees are created.
const Map<String, String> kEmployeeAvatars = {
  'emma':    'assets/images/emma.jpg',
  'liam':    'assets/images/liam.jpg',
  'sofia':   'assets/images/sofia.jpg',
  'noah':    'assets/images/noah.jpg',
  'zara':    'assets/images/zara.jpg',
};

String? avatarForUsername(String username) =>
    kEmployeeAvatars[username.toLowerCase()];
