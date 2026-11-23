package vn.dayhoc.app.shell

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch
import vn.dayhoc.app.core.auth.AuthRepository
import vn.dayhoc.app.core.network.ApiError

sealed interface HomeUiState {
    data object Loading : HomeUiState
    data class NoRole(val name: String) : HomeUiState
    data class HasRole(val name: String, val roleLabel: String) : HomeUiState
    data class Failure(val error: ApiError) : HomeUiState
    data object LoggedOut : HomeUiState
}

/** Màn tạm sau đăng nhập (placeholder NA-04): gọi `/auth/me` rồi `/me/memberships`. */
class HomeViewModel(private val auth: AuthRepository) : ViewModel() {
    private val _state = MutableStateFlow<HomeUiState>(HomeUiState.Loading)
    val state: StateFlow<HomeUiState> = _state.asStateFlow()

    init {
        load()
    }

    fun load() {
        _state.value = HomeUiState.Loading
        viewModelScope.launch {
            _state.value = try {
                val user = auth.me()
                val name = user.displayName ?: user.email
                val first = auth.memberships().items.firstOrNull()
                if (first == null) HomeUiState.NoRole(name) else HomeUiState.HasRole(name, first.label)
            } catch (e: ApiError) {
                HomeUiState.Failure(e)
            }
        }
    }

    fun logout() {
        viewModelScope.launch {
            auth.logout()
            _state.value = HomeUiState.LoggedOut
        }
    }
}
