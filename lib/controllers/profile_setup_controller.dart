import 'dart:typed_data';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

class ProfileSetupController extends GetxController {
  XFile? pickedImage;
  Uint8List? pickedImageBytes;
  RxString imageDownloadLnk = RxString("");

  void setExistingImage(String url) {
    imageDownloadLnk.value = url;
    pickedImage = null;
    pickedImageBytes = null;
    update();
  }

  void reset() {
    pickedImage = null;
    pickedImageBytes = null;
    imageDownloadLnk.value = "";
    update();
  }

  Future<void> imagePicker() async {
    try {
      final image = await ImagePicker().pickImage(source: ImageSource.gallery);
      if (image == null) {
        return;
      }

      pickedImage = image;
      pickedImageBytes = await image.readAsBytes();

      final storage = FirebaseStorage.instance
          .ref()
          .child("${DateTime.now().millisecondsSinceEpoch}_profilepicture");
      await storage.putData(
        pickedImageBytes!,
        SettableMetadata(contentType: image.mimeType),
      );

      imageDownloadLnk.value = await storage.getDownloadURL();
      update();
    } catch (e) {
      Get.snackbar("error".tr, "upload_profile_failed".tr);
    }
  }
}
