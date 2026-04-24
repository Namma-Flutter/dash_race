class Track {
  final int id;
  final String name;
  final String imagePath;
  final String collisionMapPath;

  Track({required this.id, this.name = ""})
    : imagePath = "assets/images/track$id.png",
      collisionMapPath = "assets/images/cm$id.png";
}
