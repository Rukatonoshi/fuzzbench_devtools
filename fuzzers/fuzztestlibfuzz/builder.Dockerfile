ARG parent_image
FROM $parent_image

RUN apt-get update -y && \
	apt-get install -y \
	clang-12 \
    llvm-12 \
    llvm-12-dev \
    llvm-12-tools \
	cmake \
	libstdc++-10-dev
ENV PATH='/usr/lib/llvm-12/bin':$PATH
ENV ASAN_SYMBOLIZER_PATH=/usr/lib/llvm-12/bin/llvm-symbolizer
#ENV LD_LIBRARY_PATH='/usr/lib/llvm-12/lib':$LD_LIBRARY_PATH
RUN env
RUN git clone \
 	--depth 1 \
	--branch main \
	https://github.com/google/fuzztest.git /fuzztest && \
	cd /fuzztest && \
    git pull && git fetch --all --tags && \
    git log && \
	git checkout 2024-10-28

COPY llvm_fuzzer_wrapper.cc /fuzztest/fuzztest/llvm_fuzzer_wrapper.cc

RUN	cd /fuzztest && \ 
    CC=clang-12 CXX=clang++-12 cmake -DCMAKE_BUILD_TYPE=RelWithDebug -DFUZZTEST_COMPATIBILITY_MODE=libfuzzer && \
    cmake --build . -j$(nproc) && \
    echo 'create /usr/lib/libfuzztest.a' >lib_build_script.txt && \ 
    (find . -type f -name "*.a" | grep -v '_main.a$' | grep -v '_wrapper.a$' | awk '{ print "addlib " $1 }' ) >> lib_build_script.txt && \
    echo 'addlib fuzztest/libfuzztest_llvm_fuzzer_main.a' >> lib_build_script.txt && \
    echo 'addlib fuzztest/libfuzztest_compatibility_mode.a' >> lib_build_script.txt && \
    (find /usr/lib/ -type f -name "libclang_rt.fuzzer_no_main-x86_64.a" | awk '{ print "addlib " $1 }' ) >> lib_build_script.txt && \
    echo 'save\nend' >>lib_build_script.txt && cat lib_build_script.txt && ar -M < lib_build_script.txt && rm lib_build_script.txt && \
    cp fuzztest/CMakeFiles/fuzztest_llvm_fuzzer_wrapper.dir/llvm_fuzzer_wrapper.cc.o /fuzztest && \
	cp /usr/lib/llvm-12/bin/llvm-symbolizer /fuzztest
