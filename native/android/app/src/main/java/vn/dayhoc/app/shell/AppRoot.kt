package vn.dayhoc.app.shell

import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.MaterialTheme
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.foundation.background
import androidx.lifecycle.viewmodel.compose.viewModel
import androidx.navigation.NavDestination.Companion.hasRoute
import androidx.navigation.NavHostController
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable
import androidx.navigation.compose.rememberNavController
import kotlinx.serialization.Serializable
import vn.dayhoc.app.AppContainer

@Serializable
data object SplashRoute

@Serializable
data object LoginRoute

@Serializable
data object HomeRoute

/** Điều hướng gốc: Splash → Đăng nhập | Màn tạm; hết phiên ở bất kỳ đâu → Đăng nhập. */
@Composable
fun AppRoot(container: AppContainer) {
    val nav = rememberNavController()

    val sessionExpired by container.sessionExpired.collectAsState()
    LaunchedEffect(sessionExpired) {
        if (!sessionExpired) return@LaunchedEffect
        // Đang ở Đăng nhập thì giữ nguyên, không mất email đang nhập.
        if (nav.currentDestination?.hasRoute<LoginRoute>() != true) nav.resetTo(LoginRoute)
        container.sessionExpired.value = false
    }

    NavHost(navController = nav, startDestination = SplashRoute) {
        composable<SplashRoute> {
            Box(Modifier.fillMaxSize().background(MaterialTheme.colorScheme.background), Alignment.Center) {
                CircularProgressIndicator()
            }
            LaunchedEffect(Unit) {
                // Có token thì vào màn tạm (màn này gọi /auth/me); không thì đăng nhập.
                nav.resetTo(if (container.tokenStore.load() != null) HomeRoute else LoginRoute)
            }
        }
        composable<LoginRoute> {
            val vm = viewModel { LoginViewModel(container.authRepository) }
            LoginScreen(vm, onLoggedIn = { nav.resetTo(HomeRoute) })
        }
        composable<HomeRoute> {
            val vm = viewModel { HomeViewModel(container.authRepository) }
            HomeScreen(vm, onLoggedOut = { nav.resetTo(LoginRoute) })
        }
    }
}

private fun NavHostController.resetTo(route: Any) = navigate(route) {
    popUpTo(graph.id) { inclusive = true }
}
