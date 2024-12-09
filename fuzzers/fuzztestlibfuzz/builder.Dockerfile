ARG parent_image
FROM $parent_image

RUN apt-get update -y && \
	apt-get install -y \
	clang \
	cmake \
	libstdc++-10-dev 

RUN git clone \
 	--depth 1 \
	--branch main \
	https://github.com/google/fuzztest.git /fuzztest && \
	cd /fuzztest && \
	CC=clang CXX=clang++ cmake -DCMAKE_BUILD_TYPE=RelWithDebug -DFUZZTEST_COMPATIBILITY_MODE=libfuzzer && \
	cmake --build . -j$(nproc) && \
    echo 'create /usr/lib/libfuzztest.a' >lib_build_script.txt && \ 
    (find . -type f -name "*.a" | grep -v '_main.a$' | grep -v '_wrapper.a$' | awk '{ print "addlib " $1 }' ) >> lib_build_script.txt && \
    echo 'addlib fuzztest/libfuzztest_llvm_fuzzer_main.a' >> lib_build_script.txt && \
    echo 'save\nend' >>lib_build_script.txt && cat lib_build_script.txt && ar -M < lib_build_script.txt && rm lib_build_script.txt && \
    cp fuzztest/CMakeFiles/fuzztest_llvm_fuzzer_wrapper.dir/llvm_fuzzer_wrapper.cc.o /fuzztest
	
