#include <cstddef>
#include <cstdint>
#include <cstdlib>
#include <iostream>
#include <string>
#include <vector>

#include "absl/flags/declare.h"
#include "absl/flags/flag.h"
#include "absl/log/check.h"
#include "absl/random/bit_gen_ref.h"
#include "absl/random/random.h"
#include "./fuzztest/fuzztest.h"
#include "./fuzztest/fuzztest_macros.h"
#include "./fuzztest/internal/domains/arbitrary_impl.h"
#include "./fuzztest/internal/domains/container_of_impl.h"
#include "./fuzztest/internal/domains/domain_base.h"
#include "./fuzztest/internal/io.h"
#ifndef FUZZTEST_USE_CENTIPEDE
#include "./fuzztest/internal/coverage.h"
#endif

ABSL_DECLARE_FLAG(std::string, llvm_fuzzer_wrapper_dict_file);
ABSL_DECLARE_FLAG(std::string, llvm_fuzzer_wrapper_corpus_dir);

/*
ABSL_FLAG(std::string, llvm_fuzzer_wrapper_dict_file, "",
          "Path to dictionary file used by the wrapped legacy LLVMFuzzer "
          "target (https://llvm.org/docs/LibFuzzer.html#fuzz-target).");
ABSL_FLAG(std::string, llvm_fuzzer_wrapper_corpus_dir, "",
          "Path to seed corpus directory used by the wrapped legacy LLVMFuzzer "
          "target (https://llvm.org/docs/LibFuzzer.html#fuzz-target).");
*/

constexpr static size_t kByteArrayMaxLen = 4096;

extern "C" int LLVMFuzzerTestOneInput(const uint8_t* data, size_t size);

std::vector<std::vector<uint8_t>> ReadByteArraysFromDirectory() {
  const std::string flag = absl::GetFlag(FLAGS_llvm_fuzzer_wrapper_corpus_dir);
  if (flag.empty()) return {};
  std::vector<fuzztest::internal::FilePathAndData> files =
      fuzztest::internal::ReadFileOrDirectory(flag);

  std::vector<std::vector<uint8_t>> out;
  out.reserve(files.size());
  for (const fuzztest::internal::FilePathAndData& file : files) {
    out.push_back(
        {file.data.begin(),
         file.data.begin() + std::min(file.data.size(), kByteArrayMaxLen)});
  }
  return out;
}

std::vector<std::vector<uint8_t>> ReadByteArrayDictionaryFromFile() {
  const std::string flag = absl::GetFlag(FLAGS_llvm_fuzzer_wrapper_dict_file);
  if (flag.empty()) return {};
  std::vector<fuzztest::internal::FilePathAndData> files =
      fuzztest::internal::ReadFileOrDirectory(flag);

  std::vector<std::vector<uint8_t>> out;
  out.reserve(files.size());
  // Dictionary must be in the format specified at
  // https://llvm.org/docs/LibFuzzer.html#dictionaries
  for (const fuzztest::internal::FilePathAndData& file : files) {
    absl::StatusOr<std::vector<std::string>> parsed_entries =
        fuzztest::ParseDictionary(file.data);
    CHECK(parsed_entries.status().ok())
        << "Could not parse dictionary file " << file.path << ": "
        << parsed_entries.status();
    for (const std::string& parsed_entry : *parsed_entries) {
      out.emplace_back(parsed_entry.begin(), parsed_entry.end());
    }
  }
  return out;
}

class ArbitraryByteVector
    : public fuzztest::internal::SequenceContainerOfImpl<
          std::vector<uint8_t>, fuzztest::internal::ArbitraryImpl<uint8_t>> {
  using Base = typename ArbitraryByteVector::ContainerOfImplBase;

 public:
  using typename Base::corpus_type;

  ArbitraryByteVector() { WithMaxSize(kByteArrayMaxLen); }
};

void TestOneInput(const std::vector<uint8_t>& data) {
  LLVMFuzzerTestOneInput(data.data(), data.size());
}

FUZZ_TEST(LLVMFuzzer, TestOneInput)
    .WithDomains(ArbitraryByteVector()
                     .WithDictionary(ReadByteArrayDictionaryFromFile)
                     .WithSeeds(ReadByteArraysFromDirectory));
