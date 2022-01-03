package com.corecoder.corecoder_develop;

import android.content.Intent;
import android.net.Uri;

import androidx.annotation.NonNull;
import androidx.core.content.FileProvider;

import java.io.File;

import io.flutter.embedding.android.FlutterActivity;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.plugin.common.MethodChannel;

public class MainActivity extends FlutterActivity {
    private static final String CHANNEL = "com.corecoder.android/launcher";

    @Override
    public void configureFlutterEngine(@NonNull FlutterEngine flutterEngine) {
        super.configureFlutterEngine(flutterEngine);
        new MethodChannel(flutterEngine.getDartExecutor().getBinaryMessenger(), CHANNEL)
                .setMethodCallHandler(
                        (call, result) -> {
                            // Note: this method is invoked on the main thread.
                            if(call.method.equals("androidOpenFileWith")){
                                String packageName = call.argument("package");
                                String filePath = call.argument("filepath");
                                assert filePath != null;
                                File file = new File(filePath);

                                // Get URI and MIME type of file
                                Uri uri = FileProvider.getUriForFile(this,  packageName + ".fileprovider", file);
                                String mime = getContentResolver().getType(uri);

                                // Open file with user selected app
                                Intent intent = new Intent();
                                intent.setAction(Intent.ACTION_VIEW);
                                intent.setDataAndType(uri, mime);
                                intent.addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION);
                                startActivity(intent);
                            }
                        }
                );
    }
}
