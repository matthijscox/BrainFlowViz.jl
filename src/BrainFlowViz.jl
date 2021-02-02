module BrainFlowViz

    using BrainFlow
    using Makie, GLMakie, AbstractPlotting

    function init_scene(xs, ys;
        x_lim = (0, length(xs)),
        y_lim = (0, 1),
        theme = :light,
        color = :green,
        ncolumns = 2,
    )
        nsamples, nchannels = size(ys)
        ys_n = []
        for n = 1:nchannels
            push!(ys_n, Node(view(ys, :, n)))
        end

        outer_padding = 30

        scene, layout = layoutscene(
            outer_padding,
            resolution = (1200, 700),
            backgroundcolor = RGBf0(0.99, 0.99, 0.99),
        )

        n_ax_per_column = Int(ceil(nchannels/ncolumns))

        ax = Array{LAxis, 1}(undef, nchannels)
        for n = 1:nchannels
            row_loc = mod(n-1, n_ax_per_column)+1
            col_loc = Int(ceil(n/n_ax_per_column))
            ax[n] = layout[row_loc, col_loc] = LAxis(scene, ylabel = "ch$n")
            lines!(ax[n], xs, ys_n[n], color = color, linewidth = 2)
            ax[n].yticklabelsvisible = false
            limits!(ax[n], x_lim[1], x_lim[2], y_lim[1], y_lim[2])
        end

        # TODO: use AbstractPlotting.Theme
        if theme == :dark
            scene.backgroundcolor[] = RGBf0(0.01, 0.01, 0.01)
            for n = 1:nchannels
                ax[n].backgroundcolor[] = :black
                ax[n].ylabelcolor[] = :white
                ax[n].xlabelcolor[] = :white
                ax[n].yticklabelcolor[] = :white
                ax[n].xticklabelcolor[] = :white
                ax[n].xtickcolor[] = :white
                ax[n].ytickcolor[] = :white
                ax[n].leftspinecolor[] = :white
                ax[n].rightspinecolor[] = :white
                ax[n].topspinecolor[] = :white
                ax[n].bottomspinecolor[] = :white
                ax[n].xgridcolor = :black
                ax[n].ygridcolor = :black
            end
        end
        #linkaxes!(ax...)

        # hide the x stuff
        is_bottom_ax(n::Int) = mod(n, n_ax_per_column) == 0
        for n=1:nchannels-1
            if !is_bottom_ax(n)
                hidexdecorations!(ax[n], grid = false)
            end
        end

        return scene, ys_n
    end

    # live plotting function
    function plot_data(data_func::Function, nsamples, nchannels; delay = 0.05, y_lim = :auto, kwargs...)

        xs = collect(1:nsamples)
        #ys = zeros(nsamples, nchannels)
        ys = data_func()

        if y_lim === :auto
            y_lim = (minimum(ys), maximum(ys))
        end

        scene, ys_n = init_scene(xs, ys; y_lim = y_lim, kwargs...)

        display(scene)

        while(true)
            sleep(delay)

            # overwrite the original data
            ys = data_func()
            available_nsamples = size(ys, 1)

            # update x-axis without triggering a refresh
            empty!(xs)
            append!(xs, collect(1:available_nsamples))

            # update the scene
            # is this the most efficient? Or could we refresh 4 axes in a scene at the same time
            for n = 1:nchannels
                ys_n[n][] = view(ys, :, n)
            end

            # optional if you want to zoom in + update limits:
            # AbstractPlotting.update_limits!(scene)
            # AbstractPlotting.update!(scene)

            # yield() # allow another task to run, e.g. brainflow data gathering? or use yieldto()
        end
    end

end # module
