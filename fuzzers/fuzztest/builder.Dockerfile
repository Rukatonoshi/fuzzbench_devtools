ARG parent_image
FROM $parent_image

RUN apt-get update -y && \
	apt-get install -y \
	clang \
	cmake \
	libstdc++-10-dev

RUN git clone https://github.com/google/fuzztest.git /fuzztest && \
	cd /fuzztest && \
	CC=clang CXX=clang++ cmake -DCMAKE_BUILD_TYPE=RelWithDebug -DFUZZTEST_FUZZING_MODE=on && \
	cmake --build . -j100 && \
	cp fuzztest/libfuzztest_llvm_fuzzer_wrapper.a /usr/lib/FuzzTest.a 
	#ar r FuzzTest.a *.o && \
	#cp FuzzTest.a /usr/lib
	
	
