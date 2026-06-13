import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

import '../../domain/entities/media_item.dart';

/// Picks an image and uploads it to the owner's namespaced Storage path
/// (`users/{uid}/{category}/...`), returning a [MediaItem] for the post/story.
class MediaService {
  MediaService(this._storage);
  final FirebaseStorage _storage;

  final ImagePicker _picker = ImagePicker();

  Future<MediaItem?> pickAndUploadImage({
    required String uid,
    String category = 'posts',
    int imageQuality = 70,
    double maxWidth = 1600,
  }) async {
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: imageQuality,
      maxWidth: maxWidth,
    );
    if (picked == null) return null;

    final bytes = await picked.readAsBytes();
    final name = '${DateTime.now().millisecondsSinceEpoch}.jpg';
    final ref = _storage.ref('users/$uid/$category/$name');
    await ref.putData(
      bytes,
      SettableMetadata(contentType: 'image/jpeg'),
    );
    final url = await ref.getDownloadURL();
    return MediaItem(url: url, type: 'image');
  }
}
