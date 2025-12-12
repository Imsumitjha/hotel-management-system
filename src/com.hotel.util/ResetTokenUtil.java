package com.hotel.util;

import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;

/** Hashes password-reset tokens before they are stored in the database. */
public final class ResetTokenUtil {
    private static final char[] HEX = "0123456789abcdef".toCharArray();

    private ResetTokenUtil() { }

    /** Returns the lowercase hexadecimal SHA-256 digest of a token. */
    public static String hash(String token) {
        if (token == null) throw new IllegalArgumentException("Token is required.");
        try {
            byte[] digest = MessageDigest.getInstance("SHA-256")
                    .digest(token.getBytes(StandardCharsets.UTF_8));
            char[] encoded = new char[digest.length * 2];
            for (int i = 0; i < digest.length; i++) {
                encoded[i * 2] = HEX[(digest[i] >>> 4) & 0x0f];
                encoded[i * 2 + 1] = HEX[digest[i] & 0x0f];
            }
            return new String(encoded);
        } catch (NoSuchAlgorithmException e) {
            throw new IllegalStateException("SHA-256 is unavailable.", e);
        }
    }
}
