package com.hotel.util;

import java.security.MessageDigest;
import java.security.SecureRandom;
import javax.crypto.SecretKeyFactory;
import javax.crypto.spec.PBEKeySpec;

/** Password hashing and verification shared by login and password reset. */
public final class PasswordUtil {
    private static final int ITERATIONS = 210000;
    private static final int SALT_BYTES = 16;
    private static final int HASH_BITS = 256;
    private static final SecureRandom RANDOM = new SecureRandom();
    private static final char[] HEX = "0123456789abcdef".toCharArray();

    private PasswordUtil() { }

    public static String hash(String password) {
        byte[] salt = new byte[SALT_BYTES];
        RANDOM.nextBytes(salt);
        byte[] derived = derive(password, salt, ITERATIONS);
        return "{PBKDF2}" + ITERATIONS + ":" + hex(salt) + ":" + hex(derived);
    }

    /** Shared password policy for registration, reset, and profile changes. */
    public static boolean isStrong(String password) {
        if (password == null || password.length() < 12 || password.length() > 128) return false;
        boolean upper = false, lower = false, digit = false, special = false;
        for (char value : password.toCharArray()) {
            upper |= Character.isUpperCase(value);
            lower |= Character.isLowerCase(value);
            digit |= Character.isDigit(value);
            special |= !Character.isLetterOrDigit(value);
        }
        return upper && lower && digit && special;
    }

    /** Verifies only supported PBKDF2 hashes. Unknown and legacy formats fail closed. */
    public static boolean verify(String password, String stored) {
        if (password == null || stored == null) return false;
        if (!stored.startsWith("{PBKDF2}")) return false;
        try {
            String[] parts = stored.substring(8).split(":", -1);
            if (parts.length != 3) return false;
            int iterations = Integer.parseInt(parts[0]);
            if (iterations < 10000 || iterations > 1000000) return false;
            byte[] salt = unhex(parts[1]);
            byte[] expected = unhex(parts[2]);
            return salt.length >= 16 && expected.length == HASH_BITS / 8
                    && MessageDigest.isEqual(expected, derive(password, salt, iterations));
        } catch (IllegalArgumentException e) {
            return false;
        }
    }

    private static byte[] derive(String password, byte[] salt, int iterations) {
        PBEKeySpec spec = new PBEKeySpec(password.toCharArray(), salt, iterations, HASH_BITS);
        try {
            return SecretKeyFactory.getInstance("PBKDF2WithHmacSHA256")
                    .generateSecret(spec).getEncoded();
        } catch (java.security.GeneralSecurityException e) {
            throw new IllegalStateException("Password hashing is unavailable", e);
        } finally {
            spec.clearPassword();
        }
    }

    private static String hex(byte[] bytes) {
        char[] output = new char[bytes.length * 2];
        for (int i = 0; i < bytes.length; i++) {
            output[i * 2] = HEX[(bytes[i] >>> 4) & 0x0f];
            output[i * 2 + 1] = HEX[bytes[i] & 0x0f];
        }
        return new String(output);
    }

    private static byte[] unhex(String value) {
        if (value.length() % 2 != 0) throw new IllegalArgumentException("Invalid hex");
        byte[] output = new byte[value.length() / 2];
        for (int i = 0; i < output.length; i++) {
            int high = Character.digit(value.charAt(i * 2), 16);
            int low = Character.digit(value.charAt(i * 2 + 1), 16);
            if (high < 0 || low < 0) throw new IllegalArgumentException("Invalid hex");
            output[i] = (byte) ((high << 4) | low);
        }
        return output;
    }
}
