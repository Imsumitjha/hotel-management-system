-- One-time hardening for databases created from the older demo schema.
-- This only changes the bundled seed accounts when they still have the exact
-- placeholder value. The generated PBKDF2 values have no known passwords.
USE grand_horizon;

UPDATE users
SET phone = CASE WHEN email = 'admin@grandhorizon.in' THEN NULL ELSE phone END,
    password_hash = CASE email
        WHEN 'admin@grandhorizon.in' THEN '{PBKDF2}210000:77183e76176e38dc03e9e4e8106faed0:442318812deec4ee2a9cd8187be7eaaea598ff3b93b28596bcf7129761803517'
        WHEN 'arjun@example.com' THEN '{PBKDF2}210000:cbd23ab5b30464423dd1736da642ce72:badd5d9448baf6c65cad982b840ee56ce70324e66fce3b606691e274affc09a5'
        WHEN 'priya@example.com' THEN '{PBKDF2}210000:89f516527c8e01be5c8dd99f822e2102:0e0a4a45927523368a3f6c17d5fec42b032156d805cbe4aa91a816d3008385e7'
        WHEN 'rahul@example.com' THEN '{PBKDF2}210000:accfb6b9de0da5a4b181981bcdac02bf:19281312190946eed7a671a6a950329f3b2f0cf84834dc34ae424a62515d6626'
        WHEN 'dev@example.com' THEN '{PBKDF2}210000:8c35107bcb641c3fc849422eb1eb847d:729363a4d479d1f60cf0013044e2a53cd0bb963fb32272c1a2ea804719c761cc'
        WHEN 'sunita@example.com' THEN '{PBKDF2}210000:41be8ef346544d220d5bacb3662b3433:a7f63693dc0d4084e7310ee687a0875c6098c64bdc505f76abd22e3456f068f3'
        WHEN 'neha@example.com' THEN '{PBKDF2}210000:89ab3a2e8d2f7108f910b7741c315c65:8e44e79534529e1a0295d0fa79c7e3e8e1468d03f853cdb2631f6deda0190ed2'
    END,
    email = CASE email
        WHEN 'admin@grandhorizon.in' THEN 'seed-admin@invalid.example'
        ELSE email
    END
WHERE password_hash = '$2a$12$PLACEHOLDER_REPLACE_WITH_REAL_BCRYPT_HASH'
  AND email IN ('admin@grandhorizon.in','arjun@example.com','priya@example.com',
                'rahul@example.com','dev@example.com','sunita@example.com','neha@example.com');
