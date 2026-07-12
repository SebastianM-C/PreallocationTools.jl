module PreallocationToolsSparseConnectivityTracerExt

using PreallocationTools: PreallocationTools, DiffCache, get_tmp
using SparseConnectivityTracer: AbstractTracer, Dual

function PreallocationTools.get_tmp(dc::DiffCache, u::T) where {
        T <:
        Union{AbstractTracer, Dual},
    }
    return get_tmp(dc, typeof(u))
end

function PreallocationTools.get_tmp(
        dc::DiffCache, u::AbstractArray{<:T}
    ) where {T <: Union{AbstractTracer, Dual}}
    return get_tmp(dc, eltype(u))
end

function PreallocationTools.get_tmp(dc::DiffCache, ::Type{T}) where {
        T <: Union{
            AbstractTracer, Dual,
        },
    }
    # Reuse the `any_du` backing store (like the generic non-dual fallback) instead
    # of allocating a fresh array per call. `get_tmp`'s contract is that repeated
    # fetches from the same `DiffCache` see the same storage: callers commonly write
    # through one fetch and read through another (e.g. the collocation loops in
    # BoundaryValueDiffEq). A fresh `similar` per call breaks that — the reads see
    # unwritten memory, which for inline-allocated tracer types crashes the sparsity
    # detection. Detection happens only once or twice, so the type-unstable
    # `Vector{Any}` storage is not a performance concern.
    if length(dc.du) > length(dc.any_du)
        resize!(dc.any_du, length(dc.du))
    end
    return PreallocationTools._restructure(dc.du, dc.any_du)
end

end
