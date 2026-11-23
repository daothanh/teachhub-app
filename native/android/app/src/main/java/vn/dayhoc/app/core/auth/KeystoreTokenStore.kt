package vn.dayhoc.app.core.auth

import android.content.Context
import android.security.keystore.KeyGenParameterSpec
import android.security.keystore.KeyProperties
import androidx.datastore.preferences.core.edit
import androidx.datastore.preferences.core.stringPreferencesKey
import androidx.datastore.preferences.preferencesDataStore
import java.security.KeyStore
import java.util.Base64
import javax.crypto.Cipher
import javax.crypto.KeyGenerator
import javax.crypto.SecretKey
import javax.crypto.spec.GCMParameterSpec
import kotlin.coroutines.cancellation.CancellationException
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.withContext
import kotlinx.serialization.json.Json

private val Context.authDataStore by preferencesDataStore(name = "auth")

/** Token lưu trong DataStore, mã hóa AES-256-GCM bằng khóa không xuất được của Android Keystore. */
class KeystoreTokenStore(context: Context) : TokenStore {
    private val dataStore = context.applicationContext.authDataStore

    @Volatile
    override var tokens: Tokens? = null
        private set

    override suspend fun load(): Tokens? = withContext(Dispatchers.IO) {
        // Đọc đĩa lỗi (IOException, CorruptionException…): coi như chưa đăng nhập.
        val blob = orNull { dataStore.data.first()[KEY_TOKENS] } ?: return@withContext null
        val loaded = orNull { Json.decodeFromString<Tokens>(decrypt(blob)) }
        if (loaded == null) {
            // Không giải mã được (khóa Keystore bị xóa/reset, blob hỏng): bỏ blob, đăng nhập lại.
            orNull { dataStore.edit { it.remove(KEY_TOKENS) } }
        }
        tokens = loaded
        loaded
    }

    override suspend fun save(tokens: Tokens) {
        // Gán bộ nhớ trước: ghi đĩa lỗi chỉ làm mất phiên ở lần mở app sau, phiên đang chạy vẫn dùng được.
        this.tokens = tokens
        withContext(Dispatchers.IO) {
            orNull {
                val blob = encrypt(Json.encodeToString(Tokens.serializer(), tokens))
                dataStore.edit { it[KEY_TOKENS] = blob }
            }
        }
    }

    override suspend fun clear() {
        tokens = null
        withContext(Dispatchers.IO) { dataStore.edit { it.remove(KEY_TOKENS) } }
    }

    /** Chạy [block]; mọi lỗi trừ hủy coroutine thành `null`. */
    private inline fun <T> orNull(block: () -> T): T? = try {
        block()
    } catch (e: CancellationException) {
        throw e
    } catch (e: Exception) {
        null
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
