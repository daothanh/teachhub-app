package vn.dayhoc.app.shell

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.res.stringResource
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import vn.dayhoc.app.R
import vn.dayhoc.app.core.designsystem.DhPrimaryButton
import vn.dayhoc.app.core.designsystem.TeachHubTokens.Dimens

/** Màn tạm sau đăng nhập — placeholder NA-04, thay bằng chọn vai trò (T01c) và không gian vai trò. */
@Composable
fun HomeScreen(viewModel: HomeViewModel, onLoggedOut: () -> Unit) {
    val state by viewModel.state.collectAsStateWithLifecycle()
    LaunchedEffect(state) { if (state == HomeUiState.LoggedOut) onLoggedOut() }

    val type = MaterialTheme.typography
    Scaffold { padding ->
        Column(
            modifier = Modifier.fillMaxSize().padding(padding).padding(Dimens.spacingPage),
            verticalArrangement = Arrangement.spacedBy(Dimens.spacingContent),
        ) {
            when (val s = state) {
                HomeUiState.Loading, HomeUiState.LoggedOut -> CircularProgressIndicator()
                is HomeUiState.Failure -> {
                    Text(stringResource(R.string.splash_load_failed), style = type.bodyLarge)
                    DhPrimaryButton(text = stringResource(R.string.retry), onClick = viewModel::load)
                }
                is HomeUiState.NoRole -> {
                    Text(stringResource(R.string.home_greeting, s.name), style = type.headlineMedium)
                    Text(stringResource(R.string.role_pick_placeholder), style = type.titleMedium)
                }
                is HomeUiState.HasRole -> {
                    Text(stringResource(R.string.home_greeting, s.name), style = type.headlineMedium)
                    Text(stringResource(R.string.home_role, s.roleLabel), style = type.titleMedium)
                }
            }
            if (state !is HomeUiState.Loading && state != HomeUiState.LoggedOut) {
                Text(
                    stringResource(R.string.placeholder_note),
                    style = type.bodySmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant,
                )
                DhPrimaryButton(text = stringResource(R.string.logout), onClick = viewModel::logout)
            }
        }
    }
}
