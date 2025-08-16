package io.kaspium.kaspiumwallet

import android.content.Intent
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.nfc.NdefMessage
import android.nfc.NdefRecord
import android.nfc.NfcAdapter
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterFragmentActivity() {
    private val CHANNEL = "io.kaspium.kaspiumwallet/links"

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        handleIntent(intent)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        handleIntent(intent)
    }

    private fun handleIntent(intent: Intent?) {
        if (intent == null) return

        var data: String? = intent.dataString

        // Handle NFC URIs delivered via ACTION_NDEF_DISCOVERED.
        if (data == null && intent.action == NfcAdapter.ACTION_NDEF_DISCOVERED) {
            val rawMsgs = intent.getParcelableArrayExtra(NfcAdapter.EXTRA_NDEF_MESSAGES)
            if (rawMsgs != null) {
                for (raw in rawMsgs) {
                    val msg = raw as? NdefMessage ?: continue
                    for (record in msg.records) {
                        try {
                            // URI Well-known type
                            if (record.tnf == NdefRecord.TNF_WELL_KNOWN &&
                                record.type.contentEquals(NdefRecord.RTD_URI)
                            ) {
                                val uri = record.toUri()
                                if (uri != null) {
                                    data = uri.toString()
                                    break
                                }
                            }
                            // text/uri-list MIME
                            if (record.tnf == NdefRecord.TNF_MIME_MEDIA &&
                                String(record.type) == "text/uri-list"
                            ) {
                                val payload = record.payload
                                val text = String(payload, Charsets.UTF_8)
                                // text/uri-list can contain multiple lines and comments ('#')
                                val candidate = text
                                    .lines()
                                    .map { it.trim() }
                                    .firstOrNull { it.isNotEmpty() && !it.startsWith("#") }
                                if (!candidate.isNullOrEmpty()) {
                                    data = candidate
                                    break
                                }
                            }
                        } catch (_: Exception) {
                        }
                    }
                    if (data != null) break
                }
            }
        }

        val link = data ?: return

        Handler(Looper.getMainLooper()).post {
            flutterEngine?.dartExecutor?.binaryMessenger?.let { messenger ->
                MethodChannel(messenger, CHANNEL).invokeMethod("link", link, null)
            }
        }
    }
}
