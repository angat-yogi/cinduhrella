import 'dart:io';
import 'dart:typed_data';

import 'package:image_picker/image_picker.dart';
import 'package:photo_manager/photo_manager.dart';

class PhotoLibraryCollection {
  final String id;
  final String name;
  final int assetCount;

  const PhotoLibraryCollection({
    required this.id,
    required this.name,
    required this.assetCount,
  });
}

class PhotoLibraryAssetFile {
  final String assetId;
  final String fileName;
  final File file;
  final AssetEntity asset;

  const PhotoLibraryAssetFile({
    required this.assetId,
    required this.fileName,
    required this.file,
    required this.asset,
  });
}

class MediaService {
  final ImagePicker _picker = ImagePicker();

  MediaService();

  Future<File?> getImageFromGallery() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      return File(image.path);
    }
    return null;
  }

  Future<List<File>> getImagesFromGallery() async {
    final List<XFile> images = await _picker.pickMultiImage();
    return images.map((image) => File(image.path)).toList();
  }

  Future<bool> requestPhotoLibraryAccess() async {
    final permission = await PhotoManager.requestPermissionExtend();
    return permission.hasAccess;
  }

  Future<List<File>> getRecentImagesFromLibrary({
    int limit = 120,
  }) async {
    final hasAccess = await requestPhotoLibraryAccess();
    if (!hasAccess) {
      return const [];
    }

    final albums = await PhotoManager.getAssetPathList(
      type: RequestType.image,
      onlyAll: true,
      filterOption: FilterOptionGroup(
        orders: [
          const OrderOption(
            type: OrderOptionType.createDate,
            asc: false,
          ),
        ],
      ),
    );

    if (albums.isEmpty) {
      return const [];
    }

    final files = <File>[];
    final album = albums.first;
    const pageSize = 80;
    var page = 0;

    while (files.length < limit) {
      final assets = await album.getAssetListPaged(
        page: page,
        size: pageSize,
      );
      if (assets.isEmpty) {
        break;
      }

      for (final asset in assets) {
        final file = await asset.originFile;
        if (file != null) {
          files.add(file);
        }
        if (files.length >= limit) {
          break;
        }
      }

      page += 1;
    }

    return files;
  }

  Future<List<PhotoLibraryCollection>> getImageCollections() async {
    final hasAccess = await requestPhotoLibraryAccess();
    if (!hasAccess) {
      return const [];
    }

    final albums = await PhotoManager.getAssetPathList(
      hasAll: false,
      type: RequestType.image,
      onlyAll: false,
      filterOption: FilterOptionGroup(
        orders: [
          const OrderOption(
            type: OrderOptionType.createDate,
            asc: false,
          ),
        ],
      ),
      pathFilterOption: const PMPathFilter(
        darwin: PMDarwinPathFilter(
          type: [
            PMDarwinAssetCollectionType.album,
          ],
        ),
      ),
    );

    final collections = <PhotoLibraryCollection>[];
    for (final album in albums) {
      final count = await album.assetCountAsync;
      if (count <= 0) {
        continue;
      }
      collections.add(
        PhotoLibraryCollection(
          id: album.id,
          name: album.name,
          assetCount: count,
        ),
      );
    }
    return collections;
  }

  Future<PhotoLibraryCollection?> ensureImageCollection({
    required String name,
  }) async {
    final hasAccess = await requestPhotoLibraryAccess();
    if (!hasAccess || name.trim().isEmpty) {
      return null;
    }

    final existing = await getImageCollections();
    for (final collection in existing) {
      if (collection.name.trim().toLowerCase() == name.trim().toLowerCase()) {
        return collection;
      }
    }

    final created = await PhotoManager.editor.darwin.createAlbum(name.trim());
    if (created == null) {
      return null;
    }
    final count = await created.assetCountAsync;
    return PhotoLibraryCollection(
      id: created.id,
      name: created.name,
      assetCount: count,
    );
  }

  Future<List<PhotoLibraryAssetFile>> getImagesFromCollection({
    required String collectionId,
    int limit = 120,
    Set<String> excludeAssetIds = const {},
  }) async {
    final hasAccess = await requestPhotoLibraryAccess();
    if (!hasAccess || collectionId.trim().isEmpty) {
      return const [];
    }

    final albums = await PhotoManager.getAssetPathList(
      hasAll: false,
      type: RequestType.image,
      onlyAll: false,
      filterOption: FilterOptionGroup(
        orders: [
          const OrderOption(
            type: OrderOptionType.createDate,
            asc: false,
          ),
        ],
      ),
      pathFilterOption: const PMPathFilter(
        darwin: PMDarwinPathFilter(
          type: [
            PMDarwinAssetCollectionType.album,
          ],
        ),
      ),
    );

    AssetPathEntity? album;
    for (final candidate in albums) {
      if (candidate.id == collectionId) {
        album = candidate;
        break;
      }
    }

    if (album == null) {
      return const [];
    }

    final files = <PhotoLibraryAssetFile>[];
    const pageSize = 60;
    var page = 0;

    while (files.length < limit) {
      final assets = await album.getAssetListPaged(
        page: page,
        size: pageSize,
      );
      if (assets.isEmpty) {
        break;
      }

      for (final asset in assets) {
        if (excludeAssetIds.contains(asset.id)) {
          continue;
        }
        final exportedFile = await _exportAssetAsJpeg(asset);
        if (exportedFile == null) {
          continue;
        }
        files.add(
          PhotoLibraryAssetFile(
            assetId: asset.id,
            fileName: exportedFile.path.split('/').last,
            file: exportedFile,
            asset: asset,
          ),
        );
        if (files.length >= limit) {
          break;
        }
      }

      page += 1;
    }

    return files;
  }

  Future<List<PhotoLibraryAssetFile>> getRecentImageAssets({
    int limit = 120,
    Set<String> excludeAssetIds = const {},
  }) async {
    final hasAccess = await requestPhotoLibraryAccess();
    if (!hasAccess) {
      return const [];
    }

    final albums = await PhotoManager.getAssetPathList(
      type: RequestType.image,
      onlyAll: true,
      filterOption: FilterOptionGroup(
        orders: [
          const OrderOption(
            type: OrderOptionType.createDate,
            asc: false,
          ),
        ],
      ),
    );

    if (albums.isEmpty) {
      return const [];
    }

    final files = <PhotoLibraryAssetFile>[];
    final album = albums.first;
    const pageSize = 80;
    var page = 0;

    while (files.length < limit) {
      final assets = await album.getAssetListPaged(
        page: page,
        size: pageSize,
      );
      if (assets.isEmpty) {
        break;
      }

      for (final asset in assets) {
        if (excludeAssetIds.contains(asset.id)) {
          continue;
        }
        final exportedFile = await _exportAssetAsJpeg(asset);
        if (exportedFile == null) {
          continue;
        }
        files.add(
          PhotoLibraryAssetFile(
            assetId: asset.id,
            fileName: exportedFile.path.split('/').last,
            file: exportedFile,
            asset: asset,
          ),
        );
        if (files.length >= limit) {
          break;
        }
      }

      page += 1;
    }

    return files;
  }

  Future<bool> copyAssetToCollection({
    required AssetEntity asset,
    required String collectionId,
  }) async {
    if (collectionId.trim().isEmpty) {
      return false;
    }
    final path = await AssetPathEntity.fromId(collectionId);
    await PhotoManager.editor.copyAssetToPath(
      asset: asset,
      pathEntity: path,
    );
    return true;
  }

  Future<File?> _exportAssetAsJpeg(AssetEntity asset) async {
    final title = asset.title ?? asset.id;
    final safeAssetId = asset.id.replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_');
    final safeName = title.replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_');
    final tempDir =
        Directory('${Directory.systemTemp.path}/cinduhrella_exports');
    if (!await tempDir.exists()) {
      await tempDir.create(recursive: true);
    }
    final file = File(
      '${tempDir.path}/cinduhrella_${safeAssetId}_$safeName.jpg',
    );

    if (await file.exists()) {
      return file;
    }

    final bytes = await asset.thumbnailDataWithSize(
      const ThumbnailSize(1600, 1600),
      quality: 95,
    );

    if (bytes == null || bytes.isEmpty) {
      return null;
    }

    await file.writeAsBytes(Uint8List.fromList(bytes), flush: true);
    return file;
  }
}
