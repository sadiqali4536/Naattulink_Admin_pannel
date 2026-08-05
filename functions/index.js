const { onCall } = require("firebase-functions/v2/https");
const ImageKit = require("imagekit");

const configs = {
  banners: {
    publicKey: "public_lCHQ34M0MLPZC10qeJYNCM8rQv0=",
    privateKey: "private_KgiMaSuYgh1Xx4Q8ZBOydkQdFx0=",
    urlEndpoint: "https://ik.imagekit.io/naattulink",
  },
  services: {
    publicKey: "public_tllKZT9Hfbe4KFXz9S9T5HYWvzU=",
    privateKey: "private_5R9DaVHXj9Ysxuf41h1BaOV4xe0=",
    urlEndpoint: "https://ik.imagekit.io/mgk8josdiz",
  },
  products: {
    publicKey: "account3_public_key",
    privateKey: "account3_private_key",
    urlEndpoint: "https://ik.imagekit.io/account3",
  },
  workers: {
    publicKey: "account4_public_key",
    privateKey: "account4_private_key",
    urlEndpoint: "https://ik.imagekit.io/account4",
  }
};

function getImageKit(storageType) {
  const config = configs[storageType];

  if (!config) {
    throw new Error(`Unknown storage type: ${storageType}`);
  }

  return new ImageKit(config);
}

exports.deleteImageKitFile = onCall(async (request) => {
  const { fileId, storageType } = request.data;

  if (!fileId) {
    throw new Error("fileId is required.");
  }

  if (!storageType) {
    throw new Error("storageType is required.");
  }

  try {
    const imagekit = getImageKit(storageType);

    await imagekit.files.delete(fileId);

    return {
      success: true,
      message: "Image deleted successfully",
    };
  } catch (e) {
    console.error(e);

    throw new Error(e.message);
  }
});
