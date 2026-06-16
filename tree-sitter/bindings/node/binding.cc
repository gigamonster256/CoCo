#include "tree_sitter/parser.h"
#include <node.h>
#include "nan.h"

using namespace v8;

extern "C" TSLanguage * tree_sitter_coco();

namespace {

NAN_METHOD(New) {}

void Init(Local<Object> exports, Local<Object> module) {
  Local<FunctionTemplate> parser_tpl = Nan::New<FunctionTemplate>(New);
  parser_tpl->SetClassName(Nan::New("Parser").ToLocalChecked());
  parser_tpl->InstanceTemplate()->SetInternalFieldCount(1);

  Nan::Set(exports, Nan::New("Language").ToLocalChecked(),
           Nan::New<External>(tree_sitter_coco()));

  Nan::Set(module, Nan::New("exports").ToLocalChecked(), exports);
}

NODE_MODULE(tree_sitter_coco_binding, Init)

}  // namespace
