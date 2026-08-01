package com.example.my_wallet

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.content.Intent
import android.net.Uri
import android.content.pm.PackageManager

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.example.my_wallet/upi"
    private val UPI_PAYMENT_REQUEST_CODE = 99
    private var pendingResult: MethodChannel.Result? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "getInstalledUpiApps" -> {
                    val apps = listOf(
                        mapOf("name" to "PhonePe", "packageName" to "com.phonepe.app"),
                        mapOf("name" to "Google Pay", "packageName" to "com.google.android.apps.nbu.paisa.user"),
                        mapOf("name" to "Paytm", "packageName" to "net.one97.paytm"),
                        mapOf("name" to "BHIM", "packageName" to "in.org.npci.upiapp")
                    )
                    val installedApps = mutableListOf<Map<String, String>>()
                    val pm = packageManager
                    for (app in apps) {
                        try {
                            pm.getPackageInfo(app["packageName"]!!, PackageManager.GET_ACTIVITIES)
                            installedApps.add(app)
                        } catch (e: PackageManager.NameNotFoundException) {
                            // App not installed
                        }
                    }
                    result.success(installedApps)
                }
                "launchUpiApp" -> {
                    val uriString = call.argument<String>("uri")
                    val packageName = call.argument<String>("packageName")
                    if (uriString != null) {
                        try {
                            val intent = Intent(Intent.ACTION_VIEW)
                            intent.data = Uri.parse(uriString)
                            if (packageName != null && packageName.isNotEmpty()) {
                                intent.setPackage(packageName)
                            }
                            pendingResult = result
                            startActivityForResult(intent, UPI_PAYMENT_REQUEST_CODE)
                        } catch (e: Exception) {
                            result.error("LAUNCH_FAILED", e.message, null)
                        }
                    } else {
                        result.error("INVALID_ARGUMENT", "URI cannot be null", null)
                    }
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode == UPI_PAYMENT_REQUEST_CODE) {
            val result = pendingResult
            pendingResult = null
            if (result != null) {
                if (data != null) {
                    val response = data.getStringExtra("response")
                    if (response != null) {
                        result.success(response)
                    } else {
                        val bundle = data.extras
                        if (bundle != null) {
                            val responseData = StringBuilder()
                            for (key in bundle.keySet()) {
                                responseData.append(key).append("=").append(bundle.get(key)).append("&")
                            }
                            if (responseData.isNotEmpty()) {
                                responseData.setLength(responseData.length - 1) // strip last &
                            }
                            result.success(responseData.toString())
                        } else {
                            result.success("resultCode=$resultCode&status=unknown")
                        }
                    }
                } else {
                    if (resultCode == RESULT_OK) {
                        result.success("resultCode=RESULT_OK&status=success")
                    } else {
                        result.success("resultCode=$resultCode&status=cancelled")
                    }
                }
            }
        }
    }
}
