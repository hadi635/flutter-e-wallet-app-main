import 'dart:typed_data';

import 'package:ewallet/services/profile_image_service.dart';
import 'package:ewallet/utils/public_url.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

class ProfileSetupController extends GetxController {
  final ProfileImageService _profileImageService = ProfileImageService();
  XFile? pickedImage;
  Uint8List? pickedImageBytes;
  RxString imageDownloadLnk = RxString("");
  bool isUploading = false;

  void setExistingImage(String url) {
    imageDownloadLnk.value = normalizePublicUrl(url);
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
      if (pickedImageBytes!.length > 5 * 1024 * 1024) {
        Get.snackbar("error".tr, "image_too_large".tr);
        return;
      }

      isUploading = true;
      update();

      imageDownloadLnk.value = normalizePublicUrl(
        await _profileImageService.uploadProfileImage(
        imageBytes: pickedImageBytes!,
        fileName: image.name,
        contentType: image.mimeType ?? 'image/jpeg',
        ),
      );
      update();
    } catch (e) {
      Get.snackbar("error".tr, "upload_profile_failed".tr);
    } finally {
      isUploading = false;
      update();
    }
  }
}
