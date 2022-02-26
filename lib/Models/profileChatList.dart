class ProfileChatList {
  String? currentUserId;
  String? idChatWith;
  List chatWithList;

  ProfileChatList(
      {required this.currentUserId,
      required this.idChatWith,
      required this.chatWithList});

  void updateIdChatList() {
    List subList = [];
    subList.add(idChatWith);
    for (var user in chatWithList) {
      if (user != idChatWith) {
        subList.add(user);
      }
    }
    this.chatWithList = subList;
  }

  void printChatWithList() {
    updateIdChatList();
    for (var user in chatWithList) {
      print("This is user: $user");
    }
  }

  List getChatWithList() {
    updateIdChatList();
    return this.chatWithList;
  }
}
