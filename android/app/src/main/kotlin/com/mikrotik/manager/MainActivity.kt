package com.mikrotik.manager

import android.app.Activity
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.net.VpnService
import android.os.Build
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.mikrotik.manager/vpn"
    private var vpnChannel: MethodChannel? = null
    private var vpnReceiver: BroadcastReceiver? = null

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        vpnChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
        vpnChannel?.setMethodCallHandler { call, result ->
            when (call.method) {
                "startVpn" -> {
                    val server = call.argument<String>("server") ?: ""
                    val secret = call.argument<String>("secret") ?: ""
                    val user = call.argument<String>("user") ?: ""
                    val password = call.argument<String>("password") ?: ""
                    val routerIp = call.argument<String>("routerIp") ?: ""

                    val intent = Intent(this, L2TPVpnService::class.java).apply {
                        action = L2TPVpnService.ACTION_CONNECT
                        putExtra(L2TPVpnService.EXTRA_VPN_SERVER, server)
                        putExtra(L2TPVpnService.EXTRA_VPN_SECRET, secret)
                        putExtra(L2TPVpnService.EXTRA_VPN_USER, user)
                        putExtra(L2TPVpnService.EXTRA_VPN_PASSWORD, password)
                        putExtra(L2TPVpnService.EXTRA_ROUTER_IP, routerIp)
                    }

                    // Check VPN permission
                    val vpnIntent = VpnService.prepare(this)
                    if (vpnIntent != null) {
                        // Need user permission - start activity for result
                        startActivityForResult(vpnIntent, VPN_REQUEST_CODE)
                        result.success(mapOf("status" to "permission_needed"))
                    } else {
                        // Permission already granted
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                            startForegroundService(intent)
                        } else {
                            startService(intent)
                        }
                        result.success(mapOf("status" to "started"))
                    }
                }
                "stopVpn" -> {
                    val intent = Intent(this, L2TPVpnService::class.java).apply {
                        action = L2TPVpnService.ACTION_DISCONNECT
                    }
                    startService(intent)
                    result.success(mapOf("status" to "stopped"))
                }
                "isVpnConnected" -> {
                    result.success(mapOf("connected" to L2TPVpnService.isVpnConnected()))
                }
                else -> {
                    result.notImplemented()
                }
            }
        }

        // Register VPN state receiver
        vpnReceiver = object : BroadcastReceiver() {
            override fun onReceive(context: Context?, intent: Intent?) {
                when (intent?.action) {
                    "VPN_CONNECTED" -> {
                        vpnChannel?.invokeMethod("onVpnStateChanged", mapOf("connected" to true))
                    }
                    "VPN_DISCONNECTED" -> {
                        vpnChannel?.invokeMethod("onVpnStateChanged", mapOf("connected" to false))
                    }
                    "VPN_CONNECTION_FAILED" -> {
                        vpnChannel?.invokeMethod("onVpnStateChanged", mapOf(
                            "connected" to false,
                            "error" to "VPN connection failed"
                        ))
                    }
                }
            }
        }

        val filter = IntentFilter().apply {
            addAction("VPN_CONNECTED")
            addAction("VPN_DISCONNECTED")
            addAction("VPN_CONNECTION_FAILED")
        }
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            registerReceiver(vpnReceiver, filter, RECEIVER_NOT_EXPORTED)
        } else {
            registerReceiver(vpnReceiver, filter)
        }
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode == VPN_REQUEST_CODE) {
            if (resultCode == Activity.RESULT_OK) {
                // User granted VPN permission - start VPN
                val intent = Intent(this, L2TPVpnService::class.java).apply {
                    action = L2TPVpnService.ACTION_CONNECT
                }
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                    startForegroundService(intent)
                } else {
                    startService(intent)
                }
                vpnChannel?.invokeMethod("onVpnPermissionGranted", null)
            } else {
                vpnChannel?.invokeMethod("onVpnPermissionDenied", null)
            }
        }
    }

    override fun onDestroy() {
        vpnReceiver?.let { unregisterReceiver(it) }
        super.onDestroy()
    }

    companion object {
        private const val VPN_REQUEST_CODE = 1001
    }
}
