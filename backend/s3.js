const { S3Client, PutObjectCommand, GetObjectCommand } = require('@aws-sdk/client-s3');
const { getSignedUrl } = require('@aws-sdk/s3-request-presigner');
const path = require('path');
require('dotenv').config({ path: path.join(__dirname, '.env') });

const s3Client = new S3Client({
    endpoint: `https://${process.env.B2_ENDPOINT}`,
    region: process.env.B2_REGION || 'us-east-005',
    credentials: {
        accessKeyId: process.env.B2_KEY_ID,
        secretAccessKey: process.env.B2_APPLICATION_KEY
    }
});

/**
 * Uploads a file buffer or stream to the private B2 bucket
 * @param {Buffer} fileBuffer 
 * @param {string} key 
 * @param {string} mimeType 
 */
async function uploadToB2(fileBuffer, key, mimeType = 'audio/mp4') {
    const command = new PutObjectCommand({
        Bucket: process.env.B2_BUCKET_NAME,
        Key: key,
        Body: fileBuffer,
        ContentType: mimeType
    });
    return await s3Client.send(command);
}

/**
 * Generates a pre-signed GET URL for a private file in B2
 * @param {string} key 
 * @param {number} expiresInSeconds 
 */
async function getPresignedUrl(key, expiresInSeconds = 3600) {
    const command = new GetObjectCommand({
        Bucket: process.env.B2_BUCKET_NAME,
        Key: key
    });
    return await getSignedUrl(s3Client, command, { expiresIn: expiresInSeconds });
}

/**
 * Deletes an object from the B2 bucket
 * @param {string} key 
 */
async function deleteFromB2(key) {
    const { DeleteObjectCommand } = require('@aws-sdk/client-s3');
    const command = new DeleteObjectCommand({
        Bucket: process.env.B2_BUCKET_NAME,
        Key: key
    });
    return await s3Client.send(command);
}

module.exports = { uploadToB2, getPresignedUrl, deleteFromB2, s3Client };
