package com.raceteamiq.watch

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.tooling.preview.Devices
import androidx.compose.ui.tooling.preview.Preview
import androidx.compose.ui.unit.dp
import androidx.lifecycle.lifecycleScope
import androidx.wear.compose.material.MaterialTheme
import androidx.wear.compose.material.Scaffold
import androidx.wear.compose.material.Text
import androidx.wear.compose.material.items
import com.google.android.gms.wearable.Wearable
import kotlinx.coroutines.launch

class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContent {
            WearApp()
        }
    }

    override fun onResume() {
        super.onResume()
        lifecycleScope.launch { flushPendingSessions(this@MainActivity) }
    }
}

@Composable
fun WearApp() {
    val context = LocalContext.current
    var events by remember { mutableStateOf<List<UpcomingEvent>>(emptyList()) }

    LaunchedEffect(context) {
        Wearable.getDataClient(context).upcomingEventsFlow(context).collect {
            events = it
        }
    }

    Scaffold(modifier = Modifier.fillMaxSize()) {
        EventListScreen(events = events, onEventClick = { })
    }
}

@Composable
fun EventListScreen(events: List<UpcomingEvent>, onEventClick: (String) -> Unit) {
    if (events.isEmpty()) {
        Text(
            text = "Upcoming events\n\nOpen Race Team IQ on your phone to sync events.",
            style = MaterialTheme.typography.body1,
            textAlign = TextAlign.Center,
            modifier = Modifier
                .fillMaxSize()
                .padding(16.dp)
        )
    } else {
        androidx.wear.compose.material.ScalingLazyColumn(
            modifier = Modifier.fillMaxSize()
        ) {
            item {
                androidx.wear.compose.material.ListHeader {
                    Text("Upcoming", style = MaterialTheme.typography.title2)
                }
            }
            items(events.size) { index ->
                val event = events[index]
                Column(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(horizontal = 8.dp, vertical = 4.dp)
                ) {
                    Text(
                        text = event.name,
                        style = MaterialTheme.typography.body1
                    )
                    Text(
                        text = buildString {
                            append(event.trackName)
                            append(" · ")
                            append(event.date)
                            event.scheduledStartTime?.let { append(" · $it") }
                        },
                        style = MaterialTheme.typography.caption1
                    )
                }
            }
        }
    }
}

@Preview(device = Devices.WEAR_OS_SMALL_ROUND, showSystemUi = true)
@Composable
fun DefaultPreview() {
    WearApp()
}
