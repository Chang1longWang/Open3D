// ----------------------------------------------------------------------------
// -                        Open3D: www.open3d.org                            -
// ----------------------------------------------------------------------------
// The MIT License (MIT)
//
// Copyright (c) 2018 www.open3d.org
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
// FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS
// IN THE SOFTWARE.
// ----------------------------------------------------------------------------

#include "open3d/core/SizeVector.h"
#include "open3d/core/kernel/CumSum.h"
#include "open3d/utility/Console.h"

namespace open3d {
namespace core {
namespace kernel {

void CumSumCPU(const Tensor& src, Tensor& dst, int64_t dim) {
    // Copy first slice of source Tensor to destination Tensor.
    dst.Slice(dim, 0, 1).CopyFrom(src.Slice(dim, 0, 1));
    int64_t num_elements = src.GetShapeRef()[dim];

    // Return if there are no elements;
    if (num_elements <= 0) {
        return;
    }

    for (int64_t i = 1; i < num_elements; i++) {
        Tensor src_slice = src.Slice(dim, i, i + 1);
        Tensor prev_slice = dst.Slice(dim, i - 1, i);
        Tensor dst_slice = dst.Slice(dim, i, i + 1);
        dst_slice.AsRvalue() = src_slice.Add(prev_slice);
    }
}

}  // namespace kernel
}  // namespace core
}  // namespace open3d