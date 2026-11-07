package com.videohub.pro

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp

private enum class Tab(val label: String) {
    HOME("Home"), EXPLORE("Explore"), DOWNLOADS("Downloads"), LIBRARY("Library"), SETTINGS("Settings")
}
private enum class Appearance { LIGHT, DARK }
private enum class LightStyle { CLASSIC, MINIMAL, OCEAN }

class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContent { VideoHubApp() }
    }
}

@Composable
private fun VideoHubApp() {
    var tab by remember { mutableStateOf(Tab.HOME) }
    var appearance by remember { mutableStateOf(Appearance.LIGHT) }
    var lightStyle by remember { mutableStateOf(LightStyle.CLASSIC) }
    var query by remember { mutableStateOf("") }

    val dark = appearance == Appearance.DARK
    val bg = when {
        dark -> Color(0xFF101114)
        lightStyle == LightStyle.OCEAN -> Color(0xFFEAF5FA)
        lightStyle == LightStyle.MINIMAL -> Color(0xFFF7F7F5)
        else -> Color(0xFFF5F6FA)
    }
    val surface = if (dark) Color(0xFF1B1D22) else Color.White
    val accent = when (lightStyle) {
        LightStyle.OCEAN -> Color(0xFF087E8B)
        LightStyle.MINIMAL -> Color(0xFF343A40)
        LightStyle.CLASSIC -> Color(0xFF6654D9)
    }
    MaterialTheme(
        colorScheme = if (dark) darkColorScheme(primary = Color(0xFFB8ACFF), background = bg, surface = surface)
                     else lightColorScheme(primary = accent, background = bg, surface = surface)
    ) {
        Scaffold(
            containerColor = bg,
            topBar = {
                Row(
                    Modifier.fillMaxWidth().background(surface).padding(horizontal = 18.dp, vertical = 16.dp),
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Icon(Icons.Default.PlayCircleFilled, null, tint = accent, modifier = Modifier.size(30.dp))
                    Spacer(Modifier.width(9.dp))
                    Column(Modifier.weight(1f)) {
                        Text("VideoHub Pro", fontSize = 20.sp, fontWeight = FontWeight.Bold)
                        Text("Your media space", fontSize = 11.sp, color = MaterialTheme.colorScheme.onSurfaceVariant)
                    }
                    IconButton(onClick = { tab = Tab.SETTINGS }) {
                        Icon(Icons.Default.Settings, contentDescription = "Settings")
                    }
                }
            },
            bottomBar = {
                NavigationBar(containerColor = surface) {
                    val icons = listOf(Icons.Default.Home, Icons.Default.Explore, Icons.Default.Download, Icons.Default.VideoLibrary, Icons.Default.Settings)
                    Tab.values().forEachIndexed { index, item ->
                        NavigationBarItem(
                            selected = tab == item,
                            onClick = { tab = item },
                            icon = { Icon(icons[index], contentDescription = item.label) },
                            label = { Text(item.label, fontSize = 10.sp) }
                        )
                    }
                }
            }
        ) { padding ->
            Column(Modifier.fillMaxSize().padding(padding).padding(horizontal = 16.dp)) {
                when (tab) {
                    Tab.HOME -> HomeScreen(query, { query = it }, accent, surface)
                    Tab.EXPLORE -> ExploreScreen(accent, surface)
                    Tab.DOWNLOADS -> DownloadsScreen(surface)
                    Tab.LIBRARY -> LibraryScreen(surface)
                    Tab.SETTINGS -> SettingsScreen(
                        appearance, { appearance = it }, lightStyle, { lightStyle = it }, surface
                    )
                }
            }
        }
    }
}

@Composable
private fun HomeScreen(query: String, onQuery: (String) -> Unit, accent: Color, surface: Color) {
    Spacer(Modifier.height(14.dp))
    OutlinedTextField(
        value = query, onValueChange = onQuery, modifier = Modifier.fillMaxWidth(),
        placeholder = { Text("Search your media") },
        leadingIcon = { Icon(Icons.Default.Search, null) },
        singleLine = true, shape = RoundedCornerShape(16.dp)
    )
    Spacer(Modifier.height(18.dp))
    Text("Welcome back", fontSize = 23.sp, fontWeight = FontWeight.Bold)
    Text("Find, play and organize media you are allowed to access.", color = MaterialTheme.colorScheme.onSurfaceVariant)
    Spacer(Modifier.height(18.dp))
    Row(horizontalArrangement = Arrangement.spacedBy(10.dp)) {
        listOf("Video", "Music", "Podcasts").forEach {
            AssistChip(onClick = {}, label = { Text(it) }, leadingIcon = { Icon(Icons.Default.PlayArrow, null) })
        }
    }
    Spacer(Modifier.height(20.dp))
    SectionTitle("Featured")
    FeatureCard("Your media, organized", "Add files from your device or browse supported sources.", accent, surface)
    Spacer(Modifier.height(18.dp))
    SectionTitle("Quick access")
    FeatureCard("Downloads", "Manage up to 5 queued or active tasks.", accent, surface)
    Spacer(Modifier.height(18.dp))
    Text("Only download content you own or are authorized to save. Some platforms do not permit external downloads.", fontSize = 12.sp, color = MaterialTheme.colorScheme.onSurfaceVariant)
}

@Composable
private fun ExploreScreen(accent: Color, surface: Color) {
    Spacer(Modifier.height(18.dp))
    SectionTitle("Explore")
    Text("Choose a supported source or browse media stored on your device.", color = MaterialTheme.colorScheme.onSurfaceVariant)
    Spacer(Modifier.height(14.dp))
    listOf("Device files", "Public-domain media", "Creator-provided downloads", "Help & supported sources").forEach {
        FeatureCard(it, "Open supported content using official access options.", accent, surface)
        Spacer(Modifier.height(10.dp))
    }
}

@Composable
private fun DownloadsScreen(surface: Color) {
    Spacer(Modifier.height(18.dp))
    SectionTitle("Download manager")
    Text("0 active • 0 queued • maximum 5 tasks", color = MaterialTheme.colorScheme.onSurfaceVariant)
    Spacer(Modifier.height(12.dp))
    FeatureCard("Nothing downloading", "Add an authorized direct download from a source that permits it.", MaterialTheme.colorScheme.primary, surface)
    Spacer(Modifier.height(12.dp))
    Text("Default concurrency: 2. Resume is available only when the source server supports it.", fontSize = 12.sp, color = MaterialTheme.colorScheme.onSurfaceVariant)
}

@Composable
private fun LibraryScreen(surface: Color) {
    Spacer(Modifier.height(18.dp))
    SectionTitle("My Library")
    FeatureCard("Your library is empty", "Choose files from your device to add them. Library information is designed to stay on this device.", MaterialTheme.colorScheme.primary, surface)
}

@Composable
private fun SettingsScreen(
    appearance: Appearance, setAppearance: (Appearance) -> Unit,
    style: LightStyle, setStyle: (LightStyle) -> Unit, surface: Color
) {
    Spacer(Modifier.height(18.dp))
    SectionTitle("Appearance")
    Card(colors = CardDefaults.cardColors(containerColor = surface), shape = RoundedCornerShape(18.dp)) {
        Column(Modifier.padding(16.dp)) {
            Text("Theme", fontWeight = FontWeight.SemiBold)
            Row(verticalAlignment = Alignment.CenterVertically) {
                FilterChip(appearance == Appearance.LIGHT, { setAppearance(Appearance.LIGHT) }, label = { Text("Light") })
                Spacer(Modifier.width(8.dp))
                FilterChip(appearance == Appearance.DARK, { setAppearance(Appearance.DARK) }, label = { Text("Dark") })
            }
            Spacer(Modifier.height(12.dp))
            Text("Light theme style", fontWeight = FontWeight.SemiBold)
            LightStyle.values().forEach {
                Row(Modifier.fillMaxWidth().clickable { setStyle(it) }.padding(vertical = 7.dp), verticalAlignment = Alignment.CenterVertically) {
                    RadioButton(selected = style == it, onClick = { setStyle(it) })
                    Text(when (it) {
                        LightStyle.CLASSIC -> "Classic"
                        LightStyle.MINIMAL -> "Minimal"
                        LightStyle.OCEAN -> "Ocean"
                    })
                }
            }
        }
    }
    Spacer(Modifier.height(14.dp))
    SectionTitle("Downloads")
    FeatureCard("Task limit: 5", "Default simultaneous tasks: 2 • Wi-Fi preferred", MaterialTheme.colorScheme.primary, surface)
    Spacer(Modifier.height(14.dp))
    SectionTitle("Privacy")
    Text("Your library and preferences are intended to be stored locally. This starter build does not include account sign-in or cloud sync.", fontSize = 13.sp, color = MaterialTheme.colorScheme.onSurfaceVariant)
    Spacer(Modifier.height(14.dp))
    Text("VideoHub Pro • Version 1.0.0", fontSize = 12.sp, color = MaterialTheme.colorScheme.onSurfaceVariant)
}

@Composable
private fun SectionTitle(title: String) {
    Text(title, fontSize = 18.sp, fontWeight = FontWeight.Bold)
}
@Composable
private fun FeatureCard(title: String, subtitle: String, accent: Color, surface: Color) {
    Card(
        modifier = Modifier.fillMaxWidth(),
        colors = CardDefaults.cardColors(containerColor = surface),
        shape = RoundedCornerShape(18.dp)
    ) {
        Row(Modifier.padding(16.dp), verticalAlignment = Alignment.CenterVertically) {
            Box(Modifier.size(42.dp).background(accent.copy(alpha = .12f), RoundedCornerShape(13.dp)), contentAlignment = Alignment.Center) {
                Icon(Icons.Default.PlayCircle, null, tint = accent)
            }
            Spacer(Modifier.width(13.dp))
            Column {
                Text(title, fontWeight = FontWeight.SemiBold)
                Text(subtitle, fontSize = 12.sp, color = MaterialTheme.colorScheme.onSurfaceVariant)
            }
        }
    }
}
