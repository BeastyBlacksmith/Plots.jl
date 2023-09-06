module PlotsSeries

export Series, should_add_to_legend
using Plots: Plots, DefaultsDict

mutable struct Series
    plotattributes::DefaultsDict
end

Base.getindex(series::Series, k::Symbol) = series.plotattributes[k]
Base.setindex!(series::Series, v, k::Symbol) = (series.plotattributes[k] = v)
Base.get(series::Series, k::Symbol, v) = get(series.plotattributes, k, v)
Base.push!(series::Series, args...) = extend_series!(series, args...)
Base.append!(series::Series, args...) = extend_series!(series, args...)


# TODO: consider removing
attr(series::Series, k::Symbol) = series.plotattributes[k]
attr!(series::Series, v, k::Symbol) = (series.plotattributes[k] = v)
function attr!(series::Series; kw...)
    plotattributes = KW(kw)
    Plots.preprocess_attributes!(plotattributes)
    for (k, v) in plotattributes
        if haskey(_series_defaults, k)
            series[k] = v
        else
            @warn "unused key $k in series attr"
        end
    end
    _series_updated(series[:subplot].plt, series)
    series
end

should_add_to_legend(series::Series) =
    series.plotattributes[:primary] &&
    series.plotattributes[:label] != "" &&
    series.plotattributes[:seriestype] ∉ (
        :hexbin,
        :bins2d,
        :histogram2d,
        :hline,
        :vline,
        :contour,
        :contourf,
        :contour3d,
        :surface,
        :wireframe,
        :heatmap,
        :image,
    )

Plots.get_subplot(series::Series) = series.plotattributes[:subplot]
Plots.RecipesPipeline.is3d(series::Series) = RecipesPipeline.is3d(series.plotattributes)
Plots.ispolar(series::Series) = ispolar(series.plotattributes[:subplot])
# -------------------------------------------------------
# operate on individual series

function extend_series!(series::Series, yi)
    y = extend_series_data!(series, yi, :y)
    x = extend_to_length!(series[:x], length(y))
    expand_extrema!(series[:subplot][:xaxis], x)
    x, y
end

extend_series!(series::Series, xi, yi) =
    (extend_series_data!(series, xi, :x), extend_series_data!(series, yi, :y))

extend_series!(series::Series, xi, yi, zi) = (
    extend_series_data!(series, xi, :x),
    extend_series_data!(series, yi, :y),
    extend_series_data!(series, zi, :z),
)

function extend_series_data!(series::Series, v, letter)
    copy_series!(series, letter)
    d = extend_by_data!(series[letter], v)
    expand_extrema!(series[:subplot][get_attr_symbol(letter, :axis)], d)
    d
end

function copy_series!(series, letter)
    plt = series[:plot_object]
    for s in plt.series_list, l in (:x, :y, :z)
        if (s !== series || l !== letter) && s[l] === series[letter]
            series[letter] = copy(series[letter])
        end
    end
end

extend_to_length!(v::AbstractRange, n) = range(first(v), step = step(v), length = n)
function extend_to_length!(v::AbstractVector, n)
    vmax = isempty(v) ? 0 : ignorenan_maximum(v)
    extend_by_data!(v, vmax .+ (1:(n - length(v))))
end
extend_by_data!(v::AbstractVector, x) = isimmutable(v) ? vcat(v, x) : push!(v, x)
extend_by_data!(v::AbstractVector, x::AbstractVector) =
    isimmutable(v) ? vcat(v, x) : append!(v, x)

# -------------------------------------------------------
end # PlotsSeries
