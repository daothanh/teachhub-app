package vn.dayhoc.app.core.auth

import android.content.Context
import android.security.keystore.KeyGenParameterSpec
import android.security.keystore.KeyProperties
import androidx.datastore.preferences.core.edit
import androidx.datastore.preferences.core.stringPreferencesKey
import androidx.datastore.preferences.preferencesDataStore
import java.security.GeneralSecurityException
import java.security.KeyStore
import java.util.Base64
import javax.crypto.Cipher
import javax.crypto.KeyGenerator
import javax.crypto.SecretKey
import javax.crypto.spec.GCMParameterSpec
import kotlinx.coroutines.flow.first
import kotlinx.serialization.json.Json

private val Context.authDataStore by preferencesDataStore(name = "auth")

/** Token lưu trong DataStore, mã hóa AES-256-GCM bằng khóa không xuất được của Android Keystore. */
class KeystoreTokenStore(context: Context) : TokenStore {
    private val dataStore = context.applicationContext.authDataStore

    @Volatile
    override var tokens: Tokens? = null
        private set

    override suspend fun load(): Tokens? {
        val blob = dataStore.data.first()[KEY_TOKENS] ?: return null
        tokens = try {
            Json.decodeFromString<Tokens>(decrypt(blob))
        } catch (e: GeneralSecurityException) {
            // Khóa mất (gỡ cài đặt, đổi khóa màn hình…): coi như chưa đăng nhập.
            null
        } catch (e: IllegalArgumentException) {
            null
        }
        return tokens
    }

    override suspend fun save(tokens: Tokens) {
        val blob = encrypt(Json.encodeToString(Tokens.serializer(), tokens))
        dataStore.edit { it[KEY_TOKENS] = blob }
        this.tokens = tokens
    }

    override suspend fun clear() {
        tokens = null
        dataStore.edit { it.remove(KEY_TOKENS) }
    }

    private fun encrypt(plain: String): String {
        val cipher = Cipher.getInstance(TRANSFORMATION).apply { init(Cipher.ENCRYPT_MODE, key()) }
        return Base64.getEncoder().encodeToString(cipher.iv + cipher.doFinal(plain.toByteArray()))
    }

    private fun decrypt(blob: String): String {
        val bytes = Base64.getDecoder().decode(blob)
        val cipher = Cipher.getInstance(TRANSFORMATION).apply {
            init(Cipher.DECRYPT_MODE, key(), GCMParameterSpec(TAG_BITS, bytes, 0, IV_BYTES))
        }
        return String(cipher.doFinal(bytes, IV_BYTES, bytes.size - IV_BYTES))
    }

    private fun key(): SecretKey {
        val keyStore = KeyStore.getInstance(ANDROID_KEYSTORE).apply { load(null) }
        (keyStore.getEntry(KEY_ALIAS, null) as? KeyStore.SecretKeyEntry)?.let { return it.secretKey }
        return KeyGenerator.getInstance(KeyProperties.KEY_ALGORITHM_AES, ANDROID_KEYSTORE).apply {
            init(
                KeyGenParameterSpec.Builder(KEY_ALIAS, KeyProperties.PURPOSE_ENCRYPT or KeyProperties.PURPOSE_DECRYPT)
                    .setBlockModes(KeyProperties.BLOCK_MODE_GCM)
                    .setEncryptionPaddings(KeyProperties.ENCRYPTION_PADDING_NONE)
                    .setKeySize(256)
                    .build(),
            )
        }.generateKey()
    }

    private companion object {
        const val ANDROID_KEYSTORE = "AndroidKeyStore"
        const val KEY_ALIAS = "dayhoc_tokens"
        const val TRANSFORMATION = "AES/GCM/NoPadding"
        const val IV_BYTES = 12
        const val TAG_BITS = 128
        val KEY_TOKENS = stringPreferencesKey("tokens")
    }
}
