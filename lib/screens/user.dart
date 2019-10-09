import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:discgolf/utils/colors.dart';
import 'package:discgolf/utils/fire_utils.dart';
import 'package:discgolf/widgets/list_title.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class UserScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Container(
      padding: EdgeInsets.all(10),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: <Widget>[
          FriendList(requests: true),
          SizedBox(
            height: 5,
          ),
          FriendList(),
          SizedBox(
            height: 5,
          ),
          ListTitle('Lägg till vänner'),
          SizedBox(
            height: 5,
          ),
          FriendSearch(),
        ],
      ),
    ));
  }
}

class FriendSearch extends StatelessWidget {
  TextEditingController _searchController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    search() {
      print('in search');
      String input = _searchController.text;
      if (input.length > 0) {
        FireUtils.addUserFriendRequest(
            friendEmail: _searchController.text, context: context);
      }
    }

    return Container(
        padding: EdgeInsets.symmetric(horizontal: 4),
        child: Stack(
          children: <Widget>[
            TextFormField(
                controller: _searchController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                    prefix: SizedBox(
                      width: 10,
                    ),
                    labelText: 'Email',
                    border: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.black),
                    ))),
            Positioned(
              right: 10,
              top: 16,
              child: GestureDetector(
                onTap: () {
                  search();
                },
                child: Icon(
                  Icons.search,
                  color: accentColor,
                ),
              ),
            ),
          ],
        ));
  }
}

class FriendList extends StatelessWidget {
  final bool requests;
  FriendList({this.requests = false});
  @override
  Widget build(BuildContext context) {
    final String uid = Provider.of<FirebaseUser>(context).uid;

    return Column(
      children: <Widget>[
        Container(
          child: StreamBuilder(
              stream: Firestore.instance
                  .collection('users')
                  .document(uid)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  if (snapshot.data['friend_requests'] != null && requests) {
                    List<dynamic> friendRequests =
                        snapshot.data['friend_requests'];
                    return Column(
                        children: friendRequestList(friendRequests, uid));
                  } else if (snapshot.data['friends'] != null) {
                    List<dynamic> friends = snapshot.data['friends'];
                    return Column(children: friendList(friends, uid));
                  }
                }
                return Container();
              }),
        ),
      ],
    );
  }

  friendRequestList(List<dynamic> friendRequests, String uid) {
    List<Widget> friendReqWidgets = friendRequests.map<Widget>((friendID) {
      return FriendRequestCard(friendID, uid, friendRequests);
    }).toList();
    if (friendReqWidgets.length > 0)
      friendReqWidgets.insert(0, ListTitle('Förfrågningar'));
    return friendReqWidgets;
  }

  friendList(List<dynamic> friends, String uid) {
    List<Widget> friendWidgets = friends.map<Widget>((friendID) {
      return FriendCard(friendID);
    }).toList();
    if (friendWidgets.length > 0) friendWidgets.insert(0, ListTitle('Vänner'));
    return friendWidgets;
  }
}

class FriendCard extends StatelessWidget {
  final String friend;
  FriendCard(this.friend);
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(4),
      child: Dismissible(
        direction: DismissDirection.endToStart,
        key: Key(friend),
        onDismissed: (direction) {
          FireUtils.removeUserFriend(friendID: friend, context: context);
        },
        background: Card(
          color: Colors.red[800],
          child: Align(
              alignment: Alignment(0.95, 0),
              child: Icon(
                Icons.delete,
                color: Colors.white,
              )),
        ),
        child: Card(
          margin: EdgeInsets.all(0),
          elevation: 4,
          color: mainColor,
          child: ListTile(
              trailing: Icon(
                Icons.navigate_next,
                color: textColor,
              ),
              title: getFriendName(friend)),
        ),
      ),
    );
  }
}

class FriendRequestCard extends StatelessWidget {
  final String friendID;
  final String uid;
  final List<dynamic> friendRequests;
  FriendRequestCard(this.friendID, this.uid, this.friendRequests);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      color: mainColor,
      child: ListTile(
          trailing: Container(
            width: 70,
            height: 50,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                GestureDetector(
                  onTap: () {
                    FireUtils.addUserFriend(
                        friendID: friendID, context: context);
                    FireUtils.addUserToFriend(
                        friendID: friendID, context: context);
                    FireUtils.removeUserFriendRequest(
                        friendID: friendID, context: context);
                  },
                  child: Icon(
                    Icons.check,
                    color: Colors.green,
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    FireUtils.removeUserFriendRequest(
                        friendID: friendID, context: context);
                  },
                  child: Icon(
                    Icons.close,
                    color: Colors.red,
                  ),
                ),
              ],
            ),
          ),
          title: getFriendName(friendID)),
    );
  }
}

getFriendName(String friendID) {
  return StreamBuilder(
    stream:
        Firestore.instance.collection('users').document(friendID).snapshots(),
    builder: (context, snapshot) {
      String name = '';
      if (snapshot.hasData) name = snapshot.data.data['email'];
      return Text(name,
          style: TextStyle(color: accentColor, fontWeight: FontWeight.bold));
    },
  );
}
