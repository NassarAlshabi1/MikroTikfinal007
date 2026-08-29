package com.mikrotik.manager

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.net.VpnService
import android.os.Build
import android.os.ParcelFileDescriptor
import android.util.Log
import java.io.FileInputStream
import java.io.FileOutputStream
import java.net.DatagramPacket
import java.net.DatagramSocket
import java.net.InetAddress
import java.net.InetSocketAddress
import java.nio.ByteBuffer
import java.util.concurrent.atomic.AtomicBoolean

/**
 * L2TP VPN Service for MikroTik Manager
 * 
 * This service establishes an L2TP VPN tunnel to the MikroTik router.
 * It uses Android's VpnService API to create a TUN interface and
 * forwards L2TP traffic through the tunnel.
 */
class L2TPVpnService : VpnService() {
    companion object {
        private const val TAG = "L2TPVpnService"
        private const val CHANNEL_ID = "mikrotik_vpn_channel"
        private const val NOTIFICATION_ID = 1001
        private const val L2TP_PORT = 1701
        private const val BUFFER_SIZE = 32767
        
        // Actions
        const val ACTION_CONNECT = "com.mikrotik.manager.CONNECT"
        const val ACTION_DISCONNECT = "com.mikrotik.manager.DISCONNECT"
        
        // Extras
        const val EXTRA_VPN_SERVER = "vpn_server"
        const val EXTRA_VPN_SECRET = "vpn_secret"
        const val EXTRA_VPN_USER = "vpn_user"
        const val EXTRA_VPN_PASSWORD = "vpn_password"
        const val EXTRA_ROUTER_IP = "router_ip"
        
        // State
        private val isConnected = AtomicBoolean(false)
        
        fun isVpnConnected(): Boolean = isConnected.get()
    }
    
    private var vpnInterface: ParcelFileDescriptor? = null
    private var l2tpSocket: DatagramSocket? = null
    private var isRunning = false
    
    override fun onCreate() {
        super.onCreate()
        createNotificationChannel()
    }
    
    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        when (intent?.action) {
            ACTION_CONNECT -> {
                val server = intent.getStringExtra(EXTRA_VPN_SERVER) ?: ""
                val secret = intent.getStringExtra(EXTRA_VPN_SECRET) ?: ""
                val user = intent.getStringExtra(EXTRA_VPN_USER) ?: ""
                val password = intent.getStringExtra(EXTRA_VPN_PASSWORD) ?: ""
                val routerIp = intent.getStringExtra(EXTRA_ROUTER_IP) ?: ""
                
                startVpn(server, secret, user, password, routerIp)
            }
            ACTION_DISCONNECT -> {
                stopVpn()
            }
        }
        return START_STICKY
    }
    
    private fun startVpn(server: String, secret: String, user: String, 
                         password: String, routerIp: String) {
        if (isRunning) return
        
        try {
            // Create VPN interface
            val builder = Builder()
            builder.setSession("MikroTik L2TP")
            builder.setMtu(1400)
            
            // Add routes - route all traffic through VPN for simplicity
            // In production, you might want to route only the router's network
            builder.addRoute("0.0.0.0", 0)
            builder.addRoute("::", 0)
            
            // Set DNS servers
            builder.addDnsServer("8.8.8.8")
            builder.addDnsServer("8.8.4.4")
            
            // Exclude the VPN server itself from the tunnel
            try {
                val serverAddr = InetAddress.getByName(server)
                val serverIp = serverAddr.hostAddress
                if (serverIp != null) {
                    builder.addRoute(serverIp, 32)
                }
            } catch (e: Exception) {
                Log.w(TAG, "Could not resolve server for exclusion: $e")
            }
            
            // Protect the socket from being routed through VPN
            vpnInterface = builder.establish()
            
            if (vpnInterface == null) {
                Log.e(TAG, "Failed to establish VPN interface")
                sendBroadcast(Intent("VPN_CONNECTION_FAILED"))
                return
            }
            
            isRunning = true
            isConnected.set(true)
            
            // Start L2TP connection in background thread
            Thread {
                try {
                    runL2tpTunnel(server, secret, user, password, routerIp)
                } catch (e: Exception) {
                    Log.e(TAG, "L2TP tunnel error: $e")
                    stopVpn()
                }
            }.start()
            
            // Start foreground notification
            startForeground(NOTIFICATION_ID, createNotification())
            
            sendBroadcast(Intent("VPN_CONNECTED"))
            Log.i(TAG, "VPN started: $server")
            
        } catch (e: Exception) {
            Log.e(TAG, "Failed to start VPN: $e")
            stopVpn()
        }
    }
    
    private fun runL2tpTunnel(server: String, secret: String, user: String,
                              password: String, routerIp: String) {
        try {
            // Resolve server address
            val serverAddr = InetAddress.getByName(server)
            
            // Create UDP socket for L2TP
            l2tpSocket = DatagramSocket()
            l2tpSocket?.soTimeout = 10000
            
            // Protect the socket from VPN routing
            if (l2tpSocket != null) {
                protect(l2tpSocket!!)
            }
            
            // L2TP control connection setup
            // Send L2TP SCCRQ (Start-Control-Connection-Request)
            val scrqPacket = buildL2TPSCCRQ(secret)
            val scrqDatagram = DatagramPacket(
                scrqPacket, scrqPacket.size, serverAddr, L2TP_PORT
            )
            l2tpSocket?.send(scrqDatagram)
            
            // Wait for SCCRP (Start-Control-Connection-Reply)
            val buffer = ByteArray(BUFFER_SIZE)
            val responsePacket = DatagramPacket(buffer, buffer.size)
            l2tpSocket?.receive(responsePacket)
            
            val sccrpData = buffer.copyOf(responsePacket.length)
            Log.d(TAG, "Received SCCRP: ${responsePacket.length} bytes")
            
            // Send SCCCN (Start-Control-Connection-Connected)
            val scccnPacket = buildL2TPSCCCN()
            val scccnDatagram = DatagramPacket(
                scccnPacket, scccnPacket.size, serverAddr, L2TP_PORT
            )
            l2tpSocket?.send(scccnDatagram)
            
            // Send ICCRQ (Incoming-Call-Request) to establish tunnel
            val iccrqPacket = buildL2TPICCRQ(user, password)
            val iccrqDatagram = DatagramPacket(
                iccrqPacket, iccrqPacket.size, serverAddr, L2TP_PORT
            )
            l2tpSocket?.send(iccrqDatagram)
            
            // Wait for ICCRP (Incoming-Call-Reply)
            val iccrpBuffer = ByteArray(BUFFER_SIZE)
            val iccrpPacket = DatagramPacket(iccrpBuffer, iccrpBuffer.size)
            l2tpSocket?.receive(iccrpPacket)
            
            Log.d(TAG, "Received ICCRP: ${iccrpPacket.length} bytes")
            
            // Send ICCCN (Incoming-Call-Connected)
            val icccnPacket = buildL2TPICCCN()
            val icccnDatagram = DatagramPacket(
                icccnPacket, icccnPacket.size, serverAddr, L2TP_PORT
            )
            l2tpSocket?.send(icccnDatagram)
            
            Log.i(TAG, "L2TP tunnel established")
            
            // Start data forwarding
            val localFd = vpnInterface?.fileDescriptor
            if (localFd != null) {
                val localIn = FileInputStream(localFd)
                val localOut = FileOutputStream(localFd)
                
                // Read from TUN and send to L2TP
                val tunReader = Thread {
                    try {
                        val packet = ByteArray(BUFFER_SIZE)
                        while (isRunning) {
                            val length = localIn.read(packet)
                            if (length > 0) {
                                val l2tpPacket = wrapInL2TP(packet, length)
                                val dataDatagram = DatagramPacket(
                                    l2tpPacket, l2tpPacket.size, serverAddr, L2TP_PORT
                                )
                                l2tpSocket?.send(dataDatagram)
                            }
                        }
                    } catch (e: Exception) {
                        if (isRunning) Log.e(TAG, "TUN reader error: $e")
                    }
                }
                tunReader.isDaemon = true
                tunReader.start()
                
                // Read from L2TP and write to TUN
                while (isRunning) {
                    try {
                        val dataBuffer = ByteArray(BUFFER_SIZE)
                        val dataPacket = DatagramPacket(dataBuffer, dataBuffer.size)
                        l2tpSocket?.receive(dataPacket)
                        
                        val payload = unwrapL2TP(dataBuffer, dataPacket.length)
                        if (payload != null && payload.isNotEmpty()) {
                            localOut.write(payload)
                            localOut.flush()
                        }
                    } catch (e: java.net.SocketTimeoutException) {
                        // Timeout is normal, continue loop
                    } catch (e: Exception) {
                        if (isRunning) Log.e(TAG, "L2TP data error: $e")
                    }
                }
            }
            
        } catch (e: Exception) {
            Log.e(TAG, "L2TP tunnel error: $e")
            throw e
        }
    }
    
    private fun buildL2TPSCCRQ(secret: String): ByteArray {
        val payload = ByteBuffer.allocate(512)
        
        // L2TP Header
        payload.putShort(0x0200) // Flags: Type=0 (control), Length=1, Tunnel ID=0
        payload.putShort(0)      // Length
        payload.putShort(0)      // Tunnel ID (0 for initial)
        payload.putShort(0)      // Session ID (0 for control)
        
        // L2TP Control Message Header
        payload.putShort(0)      // Ns (next send)
        payload.putShort(0)      // Nr (next receive)
        
        // Message Type
        payload.putShort(1)      // SCCRQ (1)
        
        // TLVs
        // Protocol Version
        payload.putShort(0x8008) // Type 2, M=0
        payload.putShort(2)      // Length
        payload.putShort(0x0001) // Version 1.0
        
        // Host Name (empty for now)
        payload.putShort(0x8007) // Type 1, M=0
        payload.putShort(0)      // Length
        
        // Tunnel Authenticate
        if (secret.isNotEmpty()) {
            val secretBytes = secret.toByteArray()
            payload.putShort(0x800B.toShort()) // Type 3, M=0
            payload.putShort(secretBytes.size) // Length
            payload.put(secretBytes)
        }
        
        // Framing Capabilities
        payload.putShort(0x8003.toShort()) // Type 3, M=0
        payload.putShort(4)
        payload.putInt(0x00000001) // Async framing
        
        // Bearer Capabilities
        payload.putShort(0x8004.toShort()) // Type 4, M=0
        payload.putShort(4)
        payload.putInt(0x00000001) // Digital
        
        payload.flip()
        val result = ByteArray(payload.remaining())
        payload.get(result)
        return result
    }
    
    private fun buildL2TPSCCCN(): ByteArray {
        val payload = ByteBuffer.allocate(256)
        
        // L2TP Header
        payload.putShort(0x0200)
        payload.putShort(4)
        payload.putShort(1) // Tunnel ID (assigned by server)
        payload.putShort(0)
        
        // Control Message Header
        payload.putShort(1) // Ns
        payload.putShort(1) // Nr
        
        // Message Type
        payload.putShort(3) // SCCCN (3)
        
        payload.flip()
        val result = ByteArray(payload.remaining())
        payload.get(result)
        return result
    }
    
    private fun buildL2TPICCRQ(user: String, password: String): ByteArray {
        val payload = ByteBuffer.allocate(512)
        
        // L2TP Header
        payload.putShort(0x0200)
        payload.putShort(4)
        payload.putShort(1) // Tunnel ID
        payload.putShort(0) // Session ID (0 for setup)
        
        // Control Message Header
        payload.putShort(2) // Ns
        payload.putShort(2) // Nr
        
        // Message Type
        payload.putShort(7) // ICCRQ (7)
        
        // Call ID
        payload.putShort(0x8009.toShort()) // Type 9, M=0
        payload.putShort(2)
        payload.putShort(1) // Call ID
        
        // User Name
        if (user.isNotEmpty()) {
            val userBytes = user.toByteArray()
            payload.putShort(0x8006.toShort()) // Type 6, M=0
            payload.putShort(userBytes.size)
            payload.put(userBytes)
        }
        
        payload.flip()
        val result = ByteArray(payload.remaining())
        payload.get(result)
        return result
    }
    
    private fun buildL2TPICCCN(): ByteArray {
        val payload = ByteBuffer.allocate(256)
        
        // L2TP Header
        payload.putShort(0x0200)
        payload.putShort(4)
        payload.putShort(1) // Tunnel ID
        payload.putShort(1) // Session ID
        
        // Control Message Header
        payload.putShort(3) // Ns
        payload.putShort(3) // Nr
        
        // Message Type
        payload.putShort(14) // ICCCN (14)
        
        payload.flip()
        val result = ByteArray(payload.remaining())
        payload.get(result)
        return result
    }
    
    private fun wrapInL2TP(data: ByteArray, length: Int): ByteArray {
        val headerSize = 12
        val result = ByteArray(headerSize + length)
        
        // L2TP Data Header
        result[0] = 0x00
        result[1] = 0x02  // Type=1 (data), Length=0
        result[2] = (headerSize + length).toByte()
        result[3] = 0x00
        result[4] = 0x00  // Tunnel ID
        result[5] = 0x01
        result[6] = 0x00  // Session ID
        result[7] = 0x01
        
        System.arraycopy(data, 0, result, headerSize, length)
        return result
    }
    
    private fun unwrapL2TP(data: ByteArray, length: Int): ByteArray? {
        if (length < 12) return null
        
        // Skip L2TP header (12 bytes for data packets)
        val payloadSize = length - 12
        if (payloadSize <= 0) return null
        
        return data.copyOfRange(12, length)
    }
    
    private fun stopVpn() {
        isRunning = false
        isConnected.set(false)
        
        try {
            l2tpSocket?.close()
            l2tpSocket = null
        } catch (e: Exception) {
            Log.w(TAG, "Error closing L2TP socket: $e")
        }
        
        try {
            vpnInterface?.close()
            vpnInterface = null
        } catch (e: Exception) {
            Log.w(TAG, "Error closing VPN interface: $e")
        }
        
        stopForeground(STOP_FOREGROUND_REMOVE)
        stopSelf()
        
        sendBroadcast(Intent("VPN_DISCONNECTED"))
        Log.i(TAG, "VPN stopped")
    }
    
    override fun onRevoke() {
        stopVpn()
        super.onRevoke()
    }
    
    override fun onDestroy() {
        stopVpn()
        super.onDestroy()
    }
    
    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "MikroTik VPN",
                NotificationManager.IMPORTANCE_LOW
            ).apply {
                description = "L2TP VPN Connection"
            }
            val manager = getSystemService(NotificationManager::class.java)
            manager.createNotificationChannel(channel)
        }
    }
    
    private fun createNotification(): Notification {
        val intent = Intent(this, MainActivity::class.java)
        val pendingIntent = PendingIntent.getActivity(
            this, 0, intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            Notification.Builder(this, CHANNEL_ID)
                .setContentTitle("MikroTik VPN")
                .setContentText("L2TP VPN Connection Active")
                .setSmallIcon(android.R.drawable.ic_lock_lock)
                .setContentIntent(pendingIntent)
                .setOngoing(true)
                .build()
        } else {
            @Suppress("DEPRECATION")
            Notification.Builder(this)
                .setContentTitle("MikroTik VPN")
                .setContentText("L2TP VPN Connection Active")
                .setSmallIcon(android.R.drawable.ic_lock_lock)
                .setContentIntent(pendingIntent)
                .setOngoing(true)
                .build()
        }
    }
}
