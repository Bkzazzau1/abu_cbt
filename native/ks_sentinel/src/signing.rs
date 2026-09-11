use std::fs::{self, OpenOptions};
use std::io::Write;
use std::path::Path;

use base64::engine::general_purpose::STANDARD as BASE64;
use base64::Engine;
use ed25519_dalek::{Signature, Signer, SigningKey, Verifier, VerifyingKey};
use rand::rngs::OsRng;
use serde::{Deserialize, Serialize};

use crate::error::{Result, SentinelError};

#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct SignedPayload {
    pub payload_b64: String,
    pub signature_b64: String,
    pub public_key_b64: String,
}

pub fn load_or_create_signing_key(path: &Path) -> Result<SigningKey> {
    if path.exists() {
        let bytes = fs::read(path)?;
        if bytes.len() != 32 {
            return Err(SentinelError::InvalidKeyLength(bytes.len()));
        }
        let mut secret = [0_u8; 32];
        secret.copy_from_slice(&bytes);
        return Ok(SigningKey::from_bytes(&secret));
    }

    if let Some(parent) = path.parent() {
        fs::create_dir_all(parent)?;
    }

    let key = SigningKey::generate(&mut OsRng);
    let mut file = OpenOptions::new().create_new(true).write(true).open(path)?;
    file.write_all(&key.to_bytes())?;
    file.flush()?;
    Ok(key)
}

pub fn sign_bytes(signing_key: &SigningKey, payload: &[u8]) -> SignedPayload {
    let signature: Signature = signing_key.sign(payload);
    let verifying_key: VerifyingKey = signing_key.verifying_key();

    SignedPayload {
        payload_b64: BASE64.encode(payload),
        signature_b64: BASE64.encode(signature.to_bytes()),
        public_key_b64: BASE64.encode(verifying_key.to_bytes()),
    }
}

pub fn verify_signed_payload(payload: &SignedPayload) -> Result<bool> {
    let payload_bytes = BASE64.decode(payload.payload_b64.as_bytes())?;
    let signature_bytes = BASE64.decode(payload.signature_b64.as_bytes())?;
    let public_key_bytes = BASE64.decode(payload.public_key_b64.as_bytes())?;

    if signature_bytes.len() != 64 {
        return Err(SentinelError::Signature("invalid signature length".to_string()));
    }
    if public_key_bytes.len() != 32 {
        return Err(SentinelError::Signature("invalid public key length".to_string()));
    }

    let signature_arr: [u8; 64] = signature_bytes
        .as_slice()
        .try_into()
        .map_err(|_| SentinelError::Signature("invalid signature bytes".to_string()))?;
    let public_key_arr: [u8; 32] = public_key_bytes
        .as_slice()
        .try_into()
        .map_err(|_| SentinelError::Signature("invalid public key bytes".to_string()))?;

    let signature = Signature::from_bytes(&signature_arr);
    let public_key = VerifyingKey::from_bytes(&public_key_arr)
        .map_err(|err| SentinelError::Signature(err.to_string()))?;

    Ok(public_key.verify(&payload_bytes, &signature).is_ok())
}
