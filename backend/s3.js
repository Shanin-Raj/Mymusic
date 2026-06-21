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
    },
    // Backblaze B2 doesn't support AWS checksums; the SDK's default
    // x-amz-checksum-mode=ENABLED parameter causes B2 to return 403.
    requestChecksumCalculation: 'WHEN_REQUIRED',
    responseChecksumValidation: 'WHEN_REQUIRED',
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
 * Gets the object stream directly from B2 (server-side, no presigned URL needed)
 * @param {string} key
 * @param {string} range
 * @returns {Promise<{stream: ReadableStream, contentType: string, contentLength: number, contentRange: string, acceptRanges: string}>}
 */
async function getObjectStream(key, range) {
    const params = {
        Bucket: process.env.B2_BUCKET_NAME,
        Key: key
    };
    if (range) {
        params.Range = range;
    }
    const command = new GetObjectCommand(params);
    const response = await s3Client.send(command);
    return {
        stream: response.Body,
        contentType: response.ContentType || 'audio/mp4',
        contentLength: response.ContentLength,
        contentRange: response.ContentRange,
        acceptRanges: response.AcceptRanges,
    };
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

module.exports = { uploadToB2, getPresignedUrl, getObjectStream, deleteFromB2, s3Client };
