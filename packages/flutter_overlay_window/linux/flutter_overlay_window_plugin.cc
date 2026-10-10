#include "flutter_overlay_window_plugin.h"

#include <flutter_linux/flutter_linux.h>
#include <gtk/gtk.h>

struct _FlutterOverlayWindowPlugin {
  GObject parent_instance;
  FlMethodChannel* channel;
};

G_DEFINE_TYPE(FlutterOverlayWindowPlugin, flutter_overlay_window_plugin, G_TYPE_OBJECT)

static void flutter_overlay_window_plugin_handle_method_call(
    FlutterOverlayWindowPlugin* self,
    FlMethodCall* method_call) {
  g_autoptr(FlMethodResponse) response = nullptr;
  const gchar* method = fl_method_call_get_name(method_call);

  if (strcmp(method, "showOverlay") == 0) {
    // Stub implementation - on Linux we use regular window with transparency
    response = FL_METHOD_RESPONSE(fl_method_success_response_new(nullptr));
  } else if (strcmp(method, "closeOverlay") == 0) {
    response = FL_METHOD_RESPONSE(fl_method_success_response_new(nullptr));
  } else if (strcmp(method, "moveOverlay") == 0) {
    response = FL_METHOD_RESPONSE(fl_method_success_response_new(nullptr));
  } else if (strcmp(method, "resizeOverlay") == 0) {
    response = FL_METHOD_RESPONSE(fl_method_success_response_new(nullptr));
  } else if (strcmp(method, "setClickThrough") == 0) {
    response = FL_METHOD_RESPONSE(fl_method_success_response_new(nullptr));
  } else if (strcmp(method, "getScreenWidth") == 0) {
    gint width = gdk_screen_width();
    response = FL_METHOD_RESPONSE(fl_method_success_response_new(
        fl_value_new_float(static_cast<double>(width))));
  } else if (strcmp(method, "getScreenHeight") == 0) {
    gint height = gdk_screen_height();
    response = FL_METHOD_RESPONSE(fl_method_success_response_new(
        fl_value_new_float(static_cast<double>(height))));
  } else if (strcmp(method, "isOverlayActive") == 0) {
    response = FL_METHOD_RESPONSE(fl_method_success_response_new(
        fl_value_new_bool(false)));
  } else {
    response = FL_METHOD_RESPONSE(fl_method_not_implemented_response_new());
  }

  fl_method_call_respond(method_call, response, nullptr);
}

static void flutter_overlay_window_plugin_dispose(GObject* object) {
  FlutterOverlayWindowPlugin* self = FLUTTER_OVERLAY_WINDOW_PLUGIN(object);
  g_clear_object(&self->channel);
  G_OBJECT_CLASS(flutter_overlay_window_plugin_parent_class)->dispose(object);
}

static void flutter_overlay_window_plugin_class_init(
    FlutterOverlayWindowPluginClass* klass) {
  G_OBJECT_CLASS(klass)->dispose = flutter_overlay_window_plugin_dispose;
}

static void flutter_overlay_window_plugin_init(FlutterOverlayWindowPlugin* self) {}

void FlutterOverlayWindowPluginRegisterWithRegistrar(FlDesktopPluginRegistrar* registrar) {
  FlutterOverlayWindowPlugin* plugin = FLUTTER_OVERLAY_WINDOW_PLUGIN(
      g_object_new(flutter_overlay_window_plugin_get_type(), nullptr));

  g_autoptr(FlStandardMethodCodec) codec = fl_standard_method_codec_new();
  plugin->channel = fl_method_channel_new(
      fl_plugin_registrar_get_messenger(FL_PLUGIN_REGISTRAR(registrar)),
      "desktop_spirit/overlay",
      FL_METHOD_CODEC(codec));

  fl_method_channel_set_method_call_handler(plugin->channel,
      [](FlMethodChannel* channel, FlMethodCall* method_call, gpointer user_data) {
        flutter_overlay_window_plugin_handle_method_call(
            FLUTTER_OVERLAY_WINDOW_PLUGIN(user_data), method_call);
      },
      g_object_ref(plugin), g_object_unref);
}