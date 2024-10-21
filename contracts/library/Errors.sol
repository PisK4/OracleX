// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

library Errors {
    error AccessDenied();
    error InvalidAddress();
    error InvalidVerifier();
    error NotImplement();
    error ProofVerificationFailure();
    error CommitmentFailure();
    error QueryModeMismatch();
    error SignatureVerificationFailure();
    error MutiSignatureNotEnough();
    error SignatureLengthError();
    error MissionSuspended();
}
