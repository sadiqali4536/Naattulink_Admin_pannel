export default async function handler(req, res) {
  // Enable CORS for your Flutter Web app
  res.setHeader('Access-Control-Allow-Credentials', true);
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'GET,OPTIONS,PATCH,DELETE,POST,PUT');
  res.setHeader('Access-Control-Allow-Headers', 'X-CSRF-Token, X-Requested-With, Accept, Accept-Version, Content-Length, Content-MD5, Content-Type, Date, X-Api-Version, Authorization');

  if (req.method === 'OPTIONS') {
    res.status(200).end();
    return;
  }

  const { fileId, storageType } = req.body;
  if (!fileId || !storageType) {
    return res.status(400).json({ error: "Missing parameters" });
  }

  try {
    if (!process.env.IMAGEKIT_CONFIG) {
       throw new Error("Missing IMAGEKIT_CONFIG environment variable");
    }
    const configs = JSON.parse(process.env.IMAGEKIT_CONFIG);
    const config = configs[storageType];
    
    if (!config || !config.privateKey) {
       throw new Error(`Unknown storage type or missing environment variables for: ${storageType}`);
    }

    // Convert private key to Basic Auth format (privateKey + ":")
    const authString = Buffer.from(config.privateKey + ':').toString('base64');

    // Make the exact request specified in the ImageKit Docs
    const response = await fetch(`https://api.imagekit.io/v1/files/${fileId}`, {
      method: 'DELETE',
      headers: {
        'Accept': 'application/json',
        'Authorization': `Basic ${authString}`
      }
    });

    if (!response.ok) {
      const errorText = await response.text();
      throw new Error(`ImageKit API Error (${response.status}): ${errorText}`);
    }

    res.status(200).json({ success: true, message: "Image deleted successfully" });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
}
