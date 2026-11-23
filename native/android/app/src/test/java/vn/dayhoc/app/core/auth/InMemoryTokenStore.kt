package vn.dayhoc.app.core.auth

/** Bản giả của [TokenStore] cho test JVM: Android Keystore không chạy ngoài thiết bị. */
class InMemoryTokenStore(initial: Tokens? = null) : TokenStore {
    @Volatile
    override var tokens: Tokens? = initial
        private set

    override suspend fun load(): Tokens? = tokens

    override suspend fun save(tokens: Tokens) {
        this.tokens = tokens
    }

    override suspend fun clear() {
        tokens = null
    }
}
