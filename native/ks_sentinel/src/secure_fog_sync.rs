use std::fs::{self, OpenOptions};
use std::io::{BufRead, BufReader, Write};
use std::path::Path;

use aes_gcm::aead::{Aead, OsRng};
use aes_gcm::{Aes256Gcm, KeyInit, Nonce};
use base64::engine::general_purpose::STANDARD as BASE64;
use base64::Engine;
use rand::RngCore;
use serde::{Deserialize, Serialize};

use crate::error::{Result, SentinelError};

#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct AnswerAutosaveEntry {
    pub exam_id: String,
    pub question_id: String,
    pub candidate_reg_no: String,
    pub workstation_id: String,
    pub answer_payload_json: String,
    pub saved_at_iso: String,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
struct EncryptedLine {
    nonce_b64: String,
    cipher_b64: String,
}

pub fn parse_aes_key_hex(hex_key: &str) -> Result<[u8; 32]> {
    let bytes = hex::decode(hex_key.trim())?;
    if bytes.len() != 32 {
        return Err(SentinelError::InvalidKeyLength(bytes.len()));
    }

    let mut key = [0_u8; 32];
    key.copy_from_slice(&bytes);
    Ok(key)
}

pub fn append_encrypted_entry(path: &Path, key: &[u8; 32], entry: &AnswerAutosaveEntry) -> Result<()> {
    if let Some(parent) = path.parent() {
        fs::create_dir_all(parent)?;
    }

    let plain = serde_json::to_vec(entry)?;
    let encrypted = encrypt_bytes(&plain, key)?;

    let line = serde_json::to_string(&encrypted)?;
    let mut file = OpenOptions::new().create(true).append(true).open(path)?;
    file.write_all(line.as_bytes())?;
    file.write_all(b"\n")?;
    file.flush()?;
    Ok(())
}

pub fn load_encrypted_entries(path: &Path, key: &[u8; 32]) -> Result<Vec<AnswerAutosaveEntry>> {
    if !path.exists() {
        return Ok(vec![]);
    }

    let file = OpenOptions::new().read(true).open(path)?;
    let reader = BufReader::new(file);
    let mut result = Vec::new();

    for line in reader.lines() {
        let line = line?;
        let trimmed = line.trim();
        if trimmed.is_empty() {
            continue;
        }

        let encrypted = serde_json::from_str::<EncryptedLine>(trimmed)?;
        let plain = decrypt_bytes(&encrypted, key)?;
        let entry = serde_json::from_slice::<AnswerAutosaveEntry>(&plain)?;
        result.push(entry);
    }

    Ok(result)
}

pub fn clear_store(path: &Path) -> Result<()> {
    if path.exists() {
        fs::remove_file(path)?;
    }
    Ok(())
}

fn encrypt_bytes(plain: &[u8], key: &[u8; 32]) -> Result<EncryptedLine> {
    let cipher = Aes256Gcm::new_from_slice(key)
        .map_err(|_| SentinelError::Crypto("failed to initialize AES-256-GCM".to_string()))?;

    let mut nonce = [0_u8; 12];
    OsRng.fill_bytes(&mut nonce);
    let nonce_ref = Nonce::from_slice(&nonce);

    let cipher_bytes = cipher
        .encrypt(nonce_ref, plain)
        .map_err(|_| SentinelError::Crypto("encryption failed".to_string()))?;

    Ok(EncryptedLine {
        nonce_b64: BASE64.encode(nonce),
        cipher_b64: BASE64.encode(cipher_bytes),
    })
}

fn decrypt_bytes(line: &EncryptedLine, key: &[u8; 32]) -> Result<Vec<u8>> {
    let cipher = Aes256Gcm::new_from_slice(key)
        .map_err(|_| SentinelError::Crypto("failed to initialize AES-256-GCM".to_string()))?;

    let nonce = BASE64.decode(line.nonce_b64.as_bytes())?;
    if nonce.len() != 12 {
        return Err(SentinelError::Crypto("invalid nonce length".to_string()));
    }

    let cipher_bytes = BASE64.decode(line.cipher_b64.as_bytes())?;
    let nonce_ref = Nonce::from_slice(&nonce);

    let plain = cipher
        .decrypt(nonce_ref, cipher_bytes.as_ref())
        .map_err(|_| SentinelError::Crypto("decryption failed".to_string()))?;
    Ok(plain)
}
