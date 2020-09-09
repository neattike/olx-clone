import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:multi_image_picker/multi_image_picker.dart';
import 'package:olx_clone/code/ambience/objs.dart';
import 'package:olx_clone/code/models/ad.dart';
import 'package:olx_clone/code/states/location_state.dart';

class SellState extends ChangeNotifier {
  SellState() {
    setMakers();
  }

  Ad ad;

  List<Asset> images = List<Asset>();
  List<String> downloadUrls = [];

  List<String> pages = ['form', 'uploadPicstures', 'setPrice', 'setLocation'];

  PageController pagesController = PageController();

  List<String> makers = ['sony, samsung, apple, lg, google'];
  String selectedMaker;
  var makerSelectorController = TextEditingController(text: '');

  List conditions = ['New', 'used'];
  String _selectedCondition = '';

  String adTitle;
  String description;
  String price;

  // GeoPoint adUploadLocation;

  // Map ad;

  final formKey = GlobalKey<FormState>();

  get selectedCondition => _selectedCondition;

  set selectedCondition(String value) {
    _selectedCondition = value;
    notifyListeners();
  }

  Future<void> setAd() async {
    // ad.maker = selectedMaker;
    // ad.title = adTitle;
    // ad.description = description;
    // ad.price = price;
    // ad.condition = selectedCondition;
    // ad.images.addAll(downloadUrls);
    User user = auth.currentUser;

    ad = Ad(
      maker: this.selectedMaker,
      title: adTitle,
      description: description,
      price: price,
      condition: selectedCondition,
      images: downloadUrls,
      postedAt: DateTime.now().toIso8601String(),
      postedBy: user.uid,
      adUploadLocation: LocationState().currentGeoPoint,
    );
  }

  setMakers() {
    firestore
        .collection('categories')
        .where('name', isEqualTo: 'Mobiles')
        .get()
        .then((value) {
      // makers.addAll(value.docs[0].data['makers']);
    });
  }

  Future<void> loadAssets() async {
    List<Asset> resultList = List<Asset>();

    try {
      resultList = await MultiImagePicker.pickImages(
        maxImages: 12,
        enableCamera: true,
        selectedAssets: images,
        // cupertinoOptions: CupertinoOptions(takePhotoIcon: "chat"),
        materialOptions: MaterialOptions(
          actionBarColor: "#aaaccc",
          lightStatusBar: false,
          actionBarTitle: "Gallery",
          allViewTitle: "All Photos",
          useDetailsView: false,
          // startInAllView: true,
          selectCircleStrokeColor: "#000000",
        ),
      );
    } catch (e) {
      // error = e.toString();
      print('error loading assets');
      print(e);
    }

    // If the widget was removed from the tree while the asynchronous platform
    // message was in flight, we want to discard the reply rather than calling
    // setState to update our non-existent appearance.
    // if (!mounted) return;

    images = resultList;

    notifyListeners();
  }

  uploadImageToStorage(String imageName, File imagefile, User user) {
    // StorageMetaData metaData = StorageMetaData();
    storage
        .ref()
        .child('images')
        .child(user.displayName)
        .child('ads')
        // make seperate folder for each ad images based on ad tiltle
        .child(imageName)
        .putFile(imagefile)
        .onComplete
        .then((snapshot) {
      snapshot.ref.getDownloadURL().then((url) {
        url.toString();
        downloadUrls.add(url);
      });
    });
  }

  storeImagesInTempDir(List<Asset> images) async {
    final Directory tempDir = Directory.systemTemp;
    // final FirebaseUser user = await auth.currentUser();

    print('temp dir is : ${tempDir.path}');

    images.forEach((image) {
      image.getByteData().then((bytes) {
        File('${tempDir.path}/${DateTime.now()}.png')
            .writeAsBytes(
          bytes.buffer.asUint8List(),
          mode: FileMode.write,
        )
            .then((imageFile) {
          String imageFileName;
          imageFileName =
              '${auth.currentUser.displayName} | ${auth.currentUser.email} ${DateTime.now()}.jpg';

          uploadImageToStorage(imageFileName, imageFile, auth.currentUser);
          // auth.currentUser().then((user) async {
          //   imageFileName =
          //       '${user.displayName} | ${user.email} ${DateTime.now()}.jpg';
          //   print('image file is $imageFile');
          //   // await imageFile.delete();
          //   // print('deleted the image file');
          // });
        });
      });
    });
  }
}
