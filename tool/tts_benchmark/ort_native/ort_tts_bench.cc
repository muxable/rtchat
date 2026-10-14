// Raw ONNX Runtime benchmark for TTS acoustic models (Kitten, Kokoro, Piper).
//
// Runs the model directly with the official onnxruntime-android build, which
// (unlike the sherpa-onnx prebuilt libraries) includes the XNNPACK and NNAPI
// execution providers, so the providers can be compared on the same model.
// Token ids come from make_ids.py (character-level, no phonemizer): the audio
// is not meaningful, but the sequence lengths match real chat messages.
//
// Usage:
//   ort_tts_bench --model m.onnx --ids ids.txt [--voices voices.bin]
//                 [--provider cpu|xnnpack|nnapi] [--threads 2]
//                 [--sample-rate 24000] [--label name]
// Prints one JSON line.

#include <sys/resource.h>

#include <algorithm>
#include <chrono>
#include <cstdio>
#include <cstring>
#include <fstream>
#include <map>
#include <sstream>
#include <string>
#include <vector>

#include "onnxruntime_cxx_api.h"
#ifdef __ANDROID__
#include "nnapi_provider_factory.h"
#endif

namespace {

using Clock = std::chrono::steady_clock;

double Seconds(Clock::time_point a, Clock::time_point b) {
  return std::chrono::duration<double>(b - a).count();
}

double Quantile(std::vector<double> xs, double q) {
  std::sort(xs.begin(), xs.end());
  double pos = (xs.size() - 1) * q;
  size_t lo = static_cast<size_t>(pos);
  size_t hi = std::min(lo + 1, xs.size() - 1);
  return xs[lo] + (xs[hi] - xs[lo]) * (pos - lo);
}

double MaxRssMb() {
  rusage u{};
  getrusage(RUSAGE_SELF, &u);
  return u.ru_maxrss / 1024.0;  // ru_maxrss is in KiB on Linux/Android
}

}  // namespace

int main(int argc, char** argv) {
  std::map<std::string, std::string> a = {{"--provider", "cpu"},
                                          {"--threads", "2"},
                                          {"--sample-rate", "24000"},
                                          {"--label", ""},
                                          {"--voices", ""}};
  for (int i = 1; i + 1 < argc; i += 2) a[argv[i]] = argv[i + 1];
  if (!a.count("--model") || !a.count("--ids")) {
    std::fprintf(stderr, "usage: %s --model m.onnx --ids ids.txt ...\n",
                 argv[0]);
    return 64;
  }
  const std::string provider = a["--provider"];
  const int threads = std::stoi(a["--threads"]);
  const int sample_rate = std::stoi(a["--sample-rate"]);

  std::vector<std::vector<int64_t>> lines;
  {
    std::ifstream f(a["--ids"]);
    std::string line;
    while (std::getline(f, line)) {
      std::istringstream ss(line);
      std::vector<int64_t> ids;
      int64_t v;
      while (ss >> v) ids.push_back(v);
      if (!ids.empty()) lines.push_back(ids);
    }
  }
  std::vector<float> style(256, 0.0f);
  if (!a["--voices"].empty()) {
    std::ifstream f(a["--voices"], std::ios::binary);
    f.read(reinterpret_cast<char*>(style.data()), 256 * sizeof(float));
  }

  std::string available;
  for (auto& p : Ort::GetAvailableProviders()) available += "\"" + p + "\",";
  if (!available.empty()) available.pop_back();

  Ort::Env env(ORT_LOGGING_LEVEL_WARNING, "tts-bench");
  Ort::SessionOptions so;
  so.SetGraphOptimizationLevel(GraphOptimizationLevel::ORT_ENABLE_ALL);
  if (provider == "xnnpack") {
    // XNNPACK runs its own thread pool; ORT recommends 1 intra-op thread
    // and no spinning when it is enabled.
    so.SetIntraOpNumThreads(1);
    so.AddConfigEntry("session.intra_op.allow_spinning", "0");
    so.AppendExecutionProvider(
        "XNNPACK", {{"intra_op_num_threads", std::to_string(threads)}});
  } else {
    so.SetIntraOpNumThreads(threads);
  }
#ifdef __ANDROID__
  if (provider == "nnapi") {
    Ort::ThrowOnError(OrtSessionOptionsAppendExecutionProvider_Nnapi(so, 0));
  }
#endif

  auto t0 = Clock::now();
  Ort::Session session(env, a["--model"].c_str(), so);
  double load_s = Seconds(t0, Clock::now());

  Ort::AllocatorWithDefaultOptions alloc;
  std::vector<std::string> in_names, out_names;
  for (size_t i = 0; i < session.GetInputCount(); ++i)
    in_names.push_back(session.GetInputNameAllocated(i, alloc).get());
  for (size_t i = 0; i < session.GetOutputCount(); ++i)
    out_names.push_back(session.GetOutputNameAllocated(i, alloc).get());
  std::vector<const char*> in_c, out_c;
  for (auto& n : in_names) in_c.push_back(n.c_str());
  out_c.push_back(out_names[0].c_str());

  auto mem = Ort::MemoryInfo::CreateCpu(OrtArenaAllocator, OrtMemTypeDefault);
  auto infer = [&](std::vector<int64_t>& ids) -> std::pair<double, size_t> {
    int64_t len = static_cast<int64_t>(ids.size());
    std::vector<int64_t> lens = {len}, sid = {0};
    std::vector<float> scales = {0.667f, 1.0f, 0.8f}, speed = {1.0f};
    std::vector<int64_t> ids_shape = {1, len}, one = {1}, three = {3},
                         style_shape = {1, 256};
    std::vector<Ort::Value> inputs;
    for (auto& n : in_names) {
      if (n == "input_ids" || n == "tokens" || n == "input") {
        inputs.push_back(Ort::Value::CreateTensor<int64_t>(
            mem, ids.data(), ids.size(), ids_shape.data(), 2));
      } else if (n == "input_lengths") {
        inputs.push_back(
            Ort::Value::CreateTensor<int64_t>(mem, lens.data(), 1, one.data(), 1));
      } else if (n == "scales") {
        inputs.push_back(Ort::Value::CreateTensor<float>(mem, scales.data(), 3,
                                                         three.data(), 1));
      } else if (n == "sid") {
        inputs.push_back(
            Ort::Value::CreateTensor<int64_t>(mem, sid.data(), 1, one.data(), 1));
      } else if (n == "style") {
        inputs.push_back(Ort::Value::CreateTensor<float>(
            mem, style.data(), 256, style_shape.data(), 2));
      } else if (n == "speed") {
        inputs.push_back(
            Ort::Value::CreateTensor<float>(mem, speed.data(), 1, one.data(), 1));
      } else {
        throw std::runtime_error("unexpected input " + n);
      }
    }
    auto s = Clock::now();
    auto out = session.Run(Ort::RunOptions{nullptr}, in_c.data(), inputs.data(),
                           inputs.size(), out_c.data(), 1);
    double dt = Seconds(s, Clock::now());
    return {dt, out[0].GetTensorTypeAndShapeInfo().GetElementCount()};
  };

  infer(lines[0]);  // warm-up
  std::vector<double> times;
  double audio_s = 0, total = 0;
  for (auto& ids : lines) {
    auto [dt, n] = infer(ids);
    times.push_back(dt);
    total += dt;
    audio_s += static_cast<double>(n) / sample_rate;
  }

  std::printf(
      "{\"label\":\"%s\",\"runtime\":\"ort\",\"ort_version\":\"%s\","
      "\"available_providers\":[%s],\"provider\":\"%s\",\"threads\":%d,"
      "\"messages\":%zu,\"load_s\":%.4f,\"synth_median_s\":%.4f,"
      "\"synth_p90_s\":%.4f,\"rtf\":%.4f,\"audio_total_s\":%.2f,"
      "\"rss_max_mb\":%.1f}\n",
      a["--label"].c_str(), Ort::GetVersionString().c_str(), available.c_str(),
      provider.c_str(), threads, lines.size(), load_s, Quantile(times, 0.5),
      Quantile(times, 0.9), total / audio_s, audio_s, MaxRssMb());
  return 0;
}
