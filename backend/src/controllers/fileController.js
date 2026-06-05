// src/controllers/fileController.js
//
// Simple admin media library. Files are stored on local disk under
// backend/uploads and served statically at /uploads/<name>. For production
// you'd swap this for S3/Cloudinary, but disk is fine for now.

const fs = require('fs');
const path = require('path');

const UPLOAD_DIR = path.join(__dirname, '..', '..', 'uploads');
if (!fs.existsSync(UPLOAD_DIR)) fs.mkdirSync(UPLOAD_DIR, { recursive: true });

function publicUrl(req, name) {
  return `${req.protocol}://${req.get('host')}/uploads/${name}`;
}

// GET /api/admin/files — list uploaded media + total storage used.
exports.listFiles = async (req, res) => {
  try {
    const names = fs.readdirSync(UPLOAD_DIR);
    let totalBytes = 0;
    const files = names.map((name) => {
      const stat = fs.statSync(path.join(UPLOAD_DIR, name));
      totalBytes += stat.size;
      return {
        name,
        url: publicUrl(req, name),
        size: stat.size,
        modified: stat.mtime,
      };
    }).sort((a, b) => b.modified - a.modified);
    res.json({ success: true, count: files.length, totalBytes, data: files });
  } catch (err) {
    console.error('listFiles error:', err);
    res.status(500).json({ success: false, message: 'ফাইল লিস্ট আনতে সমস্যা' });
  }
};

// POST /api/admin/files (multipart, field "file") — handled by multer upstream.
exports.uploadFile = async (req, res) => {
  if (!req.file) {
    return res.status(400).json({ success: false, message: 'কোনো ফাইল পাওয়া যায়নি' });
  }
  res.status(201).json({
    success: true,
    data: { name: req.file.filename, url: publicUrl(req, req.file.filename), size: req.file.size },
  });
};

// DELETE /api/admin/files/:name
exports.deleteFile = async (req, res) => {
  try {
    const name = path.basename(req.params.name); // prevent traversal
    const target = path.join(UPLOAD_DIR, name);
    if (!fs.existsSync(target)) {
      return res.status(404).json({ success: false, message: 'ফাইল পাওয়া যায়নি' });
    }
    fs.unlinkSync(target);
    res.json({ success: true, message: 'মুছে ফেলা হয়েছে' });
  } catch (err) {
    console.error('deleteFile error:', err);
    res.status(500).json({ success: false, message: 'মুছতে সমস্যা' });
  }
};

exports.UPLOAD_DIR = UPLOAD_DIR;
