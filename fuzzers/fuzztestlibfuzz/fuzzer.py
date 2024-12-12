# Copyright 2020 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
"""Integration code for FuzzTest "libFuzzer comp mode" fuzzer."""

import os
import subprocess

# Helper library that contains important functions for building.
from fuzzers import utils


def build():
    """Build benchmark and copy fuzzer to $OUT."""
    flags = [
        # List of flags to append to CFLAGS, CXXFLAGS during
        # benchmark compilation.
        '-g',
        '-DFUZZING_BUILD_MODE_UNSAFE_FOR_PRODUCTION',
        '-UNDEBUG',
        '-fsanitize=address',
        '-fsanitize-coverage=inline-8bit-counters',
        '-fsanitize-coverage=trace-cmp',
        '-fsanitize=fuzzer-no-link'
    ]
    utils.append_flags('CFLAGS', flags)  # Adds flags to existing CFLAGS.
    utils.append_flags('CXXFLAGS', flags)  # Adds flags to existing CXXFLAGS.

    os.environ['CC'] = 'clang'  # C compiler.
    os.environ['CXX'] = 'clang++'  # C++ compiler.

    os.environ[
        'FUZZER_LIB'] = '/fuzztest/llvm_fuzzer_wrapper.cc.o /fuzztest/compatibility_mode.cc.o  /usr/lib/libfuzztest.a'  # Path to your compiled fuzzer lib.

    # Helper function that actually builds benchmarks using the environment you
    # have prepared.
    utils.build_benchmark()

    # You should copy any fuzzer binaries that you need at runtime to the
    # $OUT directory. E.g. for AFL:
    # shutil.copy('/afl/afl-fuzz', os.environ['OUT'])


def fuzz(input_corpus, output_corpus, target_binary):
    """Run fuzzer.

    Arguments:
      input_corpus: Directory containing the initial seed corpus for
                    the benchmark.
      output_corpus: Output directory to place the newly generated corpus
                     from fuzzer run.
      target_binary: Absolute path to the fuzz target binary.
    """
    # Run your fuzzer on the benchmark.
    #    subprocess.call([
    #        your_fuzzer,
    #        '<flag-for-input-corpus>',
    #        input_corpus,
    #        '<flag for-output-corpus',
    #        output_corpus,
    #        '<other command-line options>',
    #        target_binary,
    #    ])

    fuzztest_env = os.environ.copy()
    fuzztest_env["FUZZTEST_REPRODUCERS_OUT_DIR"] = output_corpus
    #    fuzztest_env["FUZZTEST_TESTSUITE_OUT_DIR"] = os.path.join(output_corpus, "testSuites")

    subprocess.call([
        target_binary,
        "--llvm_fuzzer_wrapper_corpus_dir",
        input_corpus,
        "--fuzz=LLVMFuzzer.TestOneInput",
        "--stack_limit_kb",
        "102400",
    ],
                    env=fuzztest_env)
