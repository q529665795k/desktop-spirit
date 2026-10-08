package com.marvis.desktop_spirit;

import android.accessibilityservice.AccessibilityService;
import android.content.SharedPreferences;
import android.graphics.Rect;
import android.util.Log;
import android.view.accessibility.AccessibilityEvent;
import android.view.accessibility.AccessibilityNodeInfo;

import org.json.JSONArray;
import org.json.JSONObject;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

/**
 * v0.8.3 桌面灵宠感知服务(无障碍)。
 *
 * 用途:当用户停留在桌面(Launcher)时,读取屏幕上应用图标的位置坐标,写入
 * SharedPreferences(key=desktop_spirit_icons, JSON 数组),供悬浮窗引擎的
 * "吃桌面图标"互动使用:宠物爬过去、做吃/扑的动作。
 *
 * 权限:本服务无法由 App 直接开启,必须用户在 系统设置 → 无障碍 → 桌面灵宠 手动打开
 * (Android 系统强制要求用户授权无障碍能力)。
 *
 * 隐私:仅自用桌宠;只读屏幕节点坐标,不读取/上传任何内容文本。
 */
public class SpiritAccessibilityService extends AccessibilityService {

    private static final String TAG = "SpiritA11y";
    private static final String PREFS = "spirit_a11y";
    private static final String KEY_ICONS = "desktop_spirit_icons";
    private static final String KEY_ON = "desktop_spirit_a11y_on";
    private static final int MAX_ICONS = 30;

    /** 判定桌面:当前窗口是主流桌面 Launcher 包名(小米/红米/原生/三方) */
    private static final String[] LAUNCHERS = {
            "com.miui.home", "com.miui.home.launcher",
            "com.android.launcher", "com.android.launcher3",
            "com.google.android.apps.nexuslauncher", "com.sec.android.app.launcher",
            "com.huawei.android.launcher", "com.oppo.launcher", "com.vivo.launcher",
            "com.coloros.launcher", "com.bbk.launcher", "com.microntek.launcher",
            "com.oneplus.launcher", "com.nova.launcher", "com.microsoft.launcher",
            "com.teslacoilsw.launcher", "com.atom.launcher", "com.smartisanos.launcher",
    };

    @Override
    public void onAccessibilityEvent(AccessibilityEvent event) {
        if (event == null) return;
        // 只在窗口切换/内容变化时抓取,避免高频回调刷屏
        final int type = event.getEventType();
        if (type != AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED
                && type != AccessibilityEvent.TYPE_WINDOW_CONTENT_CHANGED) {
            return;
        }
        // 限制频率:每 2 秒最多抓一次,防卡顿
        final long now = System.currentTimeMillis();
        if (now - mLastCapture < 2000) return;
        mLastCapture = now;

        try {
            final AccessibilityNodeInfo root = getRootInActiveWindow();
            if (root == null) return;
            final String pkg = event.getPackageName() == null ? "" : event.getPackageName().toString();
            final boolean onDesktop = isLauncher(pkg) || root.getPackageName() != null && isLauncher(root.getPackageName().toString());
            if (!onDesktop) {
                root.recycle();
                return;
            }
            final List<Map<String, Object>> icons = new ArrayList<>();
            collectIcons(root, icons, 0);
            root.recycle();

            final JSONArray arr = new JSONArray();
            for (Map<String, Object> m : icons) {
                arr.put(new JSONObject(m));
            }
            final SharedPreferences sp = getSharedPreferences(PREFS, MODE_PRIVATE);
            sp.edit().putString(KEY_ICONS, arr.toString()).apply();
            Log.d(TAG, "captured " + icons.size() + " icons");
        } catch (Exception e) {
            Log.d(TAG, "capture failed: " + e.getMessage());
        }
    }

    /** 递归收集"图标类"节点:可点击、可见、有内容描述/文本、边界在屏幕内且尺寸适中 */
    private void collectIcons(AccessibilityNodeInfo node, List<Map<String, Object>> out, int depth) {
        if (node == null || depth > 12 || out.size() >= MAX_ICONS) return;
        try {
            final Rect r = new Rect();
            node.getBoundsInScreen(r);
            final int w = r.width(), h = r.height();
            // 图标一般 30~200px;太大是卡片/窗口,太小是装饰点
            final boolean sizeOk = w >= 30 && w <= 220 && h >= 30 && h <= 220;
            final boolean visible = node.isVisibleToUser() && !r.isEmpty();
            final CharSequence desc = node.getContentDescription();
            final CharSequence txt = node.getText();
            final boolean hasLabel = (desc != null && desc.length() > 0) || (txt != null && txt.length() > 0);
            final boolean clickable = node.isClickable();
            if (sizeOk && visible && hasLabel && clickable) {
                final Map<String, Object> m = new HashMap<>();
                m.put("x", r.centerX());
                m.put("y", r.centerY());
                m.put("w", w);
                m.put("h", h);
                m.put("label", String.valueOf(desc != null ? desc : txt));
                // 简单去重:与已有图标中心距离 < 12px 则跳过
                boolean dup = false;
                for (Map<String, Object> e : out) {
                    final int dx = ((Number) e.get("x")).intValue() - r.centerX();
                    final int dy = ((Number) e.get("y")).intValue() - r.centerY();
                    if (dx * dx + dy * dy < 144) { dup = true; break; }
                }
                if (!dup) out.add(m);
            }
            if (node.getChildCount() > 0) {
                for (int i = 0; i < node.getChildCount(); i++) {
                    collectIcons(node.getChild(i), out, depth + 1);
                }
            }
        } catch (Exception ignored) {
        }
    }

    private boolean isLauncher(String pkg) {
        for (String l : LAUNCHERS) {
            if (pkg != null && pkg.equals(l)) return true;
        }
        return false;
    }

    @Override
    public void onInterrupt() {
    }

    @Override
    public void onServiceConnected() {
        super.onServiceConnected();
        mLastCapture = 0;
        getSharedPreferences(PREFS, MODE_PRIVATE)
                .edit().putBoolean(KEY_ON, true).apply();
        Log.d(TAG, "connected");
    }

    @Override
    public boolean onUnbind(android.content.Intent intent) {
        getSharedPreferences(PREFS, MODE_PRIVATE)
                .edit().putBoolean(KEY_ON, false).apply();
        return super.onUnbind(intent);
    }

    @Override
    public void onDestroy() {
        getSharedPreferences(PREFS, MODE_PRIVATE)
                .edit().putBoolean(KEY_ON, false).apply();
        super.onDestroy();
    }

    private long mLastCapture = 0;
}
