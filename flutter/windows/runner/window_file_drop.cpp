#include "window_file_drop.h"

#include <flutter/encodable_value.h>
#include <flutter/method_channel.h>
#include <flutter/standard_method_codec.h>
#include <windows.h>
#include <ole2.h>
#include <shellapi.h>

#include <map>
#include <memory>
#include <string>
#include <vector>

namespace {
using Value = flutter::EncodableValue;
using Channel = flutter::MethodChannel<Value>;

class DropTarget final : public IDropTarget {
 public:
  DropTarget(HWND window, int64_t view_id, Channel* channel)
      : window_(window), view_id_(view_id), channel_(channel) {}

  HRESULT STDMETHODCALLTYPE QueryInterface(REFIID iid, void** result) override {
    if (!result) return E_POINTER;
    *result = nullptr;
    if (iid == IID_IUnknown || iid == IID_IDropTarget) {
      *result = static_cast<IDropTarget*>(this);
      AddRef();
      return S_OK;
    }
    return E_NOINTERFACE;
  }
  ULONG STDMETHODCALLTYPE AddRef() override { return InterlockedIncrement(&refs_); }
  ULONG STDMETHODCALLTYPE Release() override {
    const ULONG refs = InterlockedDecrement(&refs_);
    if (!refs) delete this;
    return refs;
  }
  HRESULT STDMETHODCALLTYPE DragEnter(IDataObject* data, DWORD, POINTL, DWORD* effect) override {
    FORMATETC format = {CF_HDROP, nullptr, DVASPECT_CONTENT, -1, TYMED_HGLOBAL};
    accepts_ = data && data->QueryGetData(&format) == S_OK;
    if (effect) *effect = accepts_ ? (*effect & DROPEFFECT_COPY) : DROPEFFECT_NONE;
    return S_OK;
  }
  HRESULT STDMETHODCALLTYPE DragOver(DWORD, POINTL, DWORD* effect) override {
    if (effect) *effect = accepts_ ? (*effect & DROPEFFECT_COPY) : DROPEFFECT_NONE;
    return S_OK;
  }
  HRESULT STDMETHODCALLTYPE DragLeave() override { accepts_ = false; return S_OK; }
  HRESULT STDMETHODCALLTYPE Drop(IDataObject* data, DWORD, POINTL position, DWORD* effect) override {
    flutter::EncodableList paths;
    FORMATETC format = {CF_HDROP, nullptr, DVASPECT_CONTENT, -1, TYMED_HGLOBAL};
    STGMEDIUM medium = {};
    if (accepts_ && data && data->GetData(&format, &medium) == S_OK) {
      auto drop = static_cast<HDROP>(GlobalLock(medium.hGlobal));
      if (drop) {
        const UINT count = DragQueryFileW(drop, 0xFFFFFFFF, nullptr, 0);
        for (UINT i = 0; i < count; ++i) {
          const UINT length = DragQueryFileW(drop, i, nullptr, 0);
          std::vector<wchar_t> path(length + 1);
          if (!length || !DragQueryFileW(drop, i, path.data(), length + 1)) continue;
          const int bytes = WideCharToMultiByte(CP_UTF8, WC_ERR_INVALID_CHARS, path.data(),
                                                 length, nullptr, 0, nullptr, nullptr);
          if (bytes <= 0) continue;
          std::string utf8(bytes, '\0');
          WideCharToMultiByte(CP_UTF8, WC_ERR_INVALID_CHARS, path.data(), length,
                              utf8.data(), bytes, nullptr, nullptr);
          paths.emplace_back(utf8);
        }
        GlobalUnlock(medium.hGlobal);
      }
      ReleaseStgMedium(&medium);
    }
    if (!paths.empty()) {
      POINT point = {position.x, position.y};
      ScreenToClient(window_, &point);
      flutter::EncodableMap args = {
          {Value("viewId"), Value(view_id_)},
          {Value("x"), Value(static_cast<double>(point.x))},
          {Value("y"), Value(static_cast<double>(point.y))},
          {Value("paths"), Value(paths)},
      };
      channel_->InvokeMethod("drop", std::make_unique<Value>(args));
    }
    if (effect) *effect = paths.empty() ? DROPEFFECT_NONE : DROPEFFECT_COPY;
    accepts_ = false;
    return S_OK;
  }

 private:
  ~DropTarget() = default;
  HWND window_;
  int64_t view_id_;
  Channel* channel_;
  LONG refs_ = 1;
  bool accepts_ = false;
};
}  // namespace

class WindowFileDrop::Impl {
 public:
  explicit Impl(flutter::FlutterEngine* engine)
      : registrar_(engine->GetRegistrarForPlugin("WindowFileDrop")),
        channel_(engine->messenger(), "reminal/window_file_drop",
                 &flutter::StandardMethodCodec::GetInstance()),
        ole_initialized_(SUCCEEDED(OleInitialize(nullptr))) {
    channel_.SetMethodCallHandler([this](const auto& call, auto result) {
      const auto* value = call.arguments();
      int64_t id;
      if (value && std::holds_alternative<int64_t>(*value)) id = std::get<int64_t>(*value);
      else if (value && std::holds_alternative<int32_t>(*value)) id = std::get<int32_t>(*value);
      else { result->Error("invalid_view", "Expected a view ID"); return; }
      if (call.method_name() == "attach") {
        if (targets_.count(id)) { result->Success(); return; }
        auto view = FlutterDesktopPluginRegistrarGetViewById(registrar_, id);
        if (!view) { result->Error("view_not_found", "Flutter view not found"); return; }
        HWND window = FlutterDesktopViewGetHWND(view);
        auto* target = new DropTarget(window, id, &channel_);
        const HRESULT status = RegisterDragDrop(window, target);
        if (FAILED(status)) {
          target->Release();
          result->Error("registration_failed", "RegisterDragDrop failed");
          return;
        }
        targets_.emplace(id, std::make_pair(window, target));
        result->Success();
      } else if (call.method_name() == "detach") {
        Detach(id);
        result->Success();
      } else {
        result->NotImplemented();
      }
    });
  }
  ~Impl() {
    while (!targets_.empty()) Detach(targets_.begin()->first);
    channel_.SetMethodCallHandler(nullptr);
    if (ole_initialized_) OleUninitialize();
  }

 private:
  void Detach(int64_t id) {
    auto it = targets_.find(id);
    if (it == targets_.end()) return;
    RevokeDragDrop(it->second.first);
    it->second.second->Release();
    targets_.erase(it);
  }
  FlutterDesktopPluginRegistrarRef registrar_;
  Channel channel_;
  bool ole_initialized_;
  std::map<int64_t, std::pair<HWND, DropTarget*>> targets_;
};

WindowFileDrop::WindowFileDrop(flutter::FlutterEngine* engine)
    : impl_(std::make_unique<Impl>(engine)) {}
WindowFileDrop::~WindowFileDrop() = default;
