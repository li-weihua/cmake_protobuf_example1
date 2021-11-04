# cmake use protobuf by ExternalProject_Add

## ninja problem

When cmake uses ninja generator, **ExternalProject_Add** should add all **BUILD_BYPRODUCTS** to let ninja work!