use thiserror::Error;

#[derive(Debug, Error)]
pub enum SentinelError {
    #[error("io error: {0}")]
    Io(#[from] std::io::Error),
    #[error("json error: {0}")]
    Json(#[from] serde_json::Error),
    #[error("hex decode error: {0}")]
    Hex(#[from] hex::FromHexError),
    #[error("base64 decode error: {0}")]
    Base64(#[from] base64::DecodeError),
    #[error("invalid key length: expected 32 bytes, got {0}")]
    InvalidKeyLength(usize),
    #[error("crypto error: {0}")]
    Crypto(String),
    #[error("signature error: {0}")]
    Signature(String),
}

pub type Result<T> = std::result::Result<T, SentinelError>;
