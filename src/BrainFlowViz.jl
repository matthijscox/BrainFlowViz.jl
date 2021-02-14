module BrainFlowViz

    using BrainFlow
    using Makie, GLMakie, AbstractPlotting
    using DataStructures
    using LinearAlgebra

    undo_transpose(A::LinearAlgebra.Transpose)= transpose(A)
    undo_transpose(A) = A

    function calc_avg_band_powers(data, board_id = BrainFlow.SYNTHETIC_BOARD)
        chans = 1:size(data, 2)
        sampling_rate = BrainFlow.get_sampling_rate(board_id)
        apply_filter = true
        avg_band_power = BrainFlow.get_avg_band_powers(undo_transpose(data), chans, sampling_rate, apply_filter)
    end

    function set_dark!(ax)
        ax.backgroundcolor[] = :black
        ax.ylabelcolor[] = :white
        ax.xlabelcolor[] = :white
        ax.yticklabelcolor[] = :white
        ax.xticklabelcolor[] = :white
        ax.xtickcolor[] = :white
        ax.ytickcolor[] = :white
        ax.leftspinecolor[] = :white
        ax.rightspinecolor[] = :white
        ax.topspinecolor[] = :white
        ax.bottomspinecolor[] = :white
        ax.xgridcolor = :black
        ax.ygridcolor = :black
        #ax.titlecolor = :white # need to update Makie?
    end

    function set_dark!(axes::AbstractArray)
        for ax in axes
            set_dark!(ax)
        end
    end

    function init_scene(xs, ys;
        x_lim = (0, length(xs)),
        y_lim = (0, 1),
        theme = :light,
        color = :green,
        ncolumns = 2,
        column_gap = 0,
        layout_size = (1200, 700)
    )

        nsamples, nchannels = size(ys)
        ys_n = []
        for n = 1:nchannels
            push!(ys_n, Node(view(ys, :, n)))
        end

        outer_padding = 30

        scene, layout = layoutscene(
            outer_padding,
            resolution = layout_size,
            backgroundcolor = RGBf0(0.99, 0.99, 0.99),
        )

        layout_top = GridLayout()

        n_ax_per_column = Int(ceil(nchannels/ncolumns))

        ax = Array{LAxis, 1}(undef, nchannels)
        for n = 1:nchannels
            row_loc = mod(n-1, n_ax_per_column)+1
            col_loc = Int(ceil(n/n_ax_per_column))
            ax[n] = layout_top[row_loc, col_loc] = LAxis(scene, ylabel = "ch$n")
            lines!(ax[n], xs, ys_n[n], color = color, linewidth = 2)
            ax[n].yticklabelsvisible = false
            limits!(ax[n], x_lim[1], x_lim[2], y_lim[1], y_lim[2])
        end

        # TODO: use AbstractPlotting.Theme
        if theme == :dark
            scene.backgroundcolor[] = RGBf0(0.01, 0.01, 0.01)
            set_dark!(ax)
        end
        #linkaxes!(ax...)

        # hide the x stuff
        is_bottom_ax(n::Int) = mod(n, n_ax_per_column) == 0
        for n=1:nchannels-1
            if !is_bottom_ax(n)
                hidexdecorations!(ax[n], grid = false)
            end
        end

        colgap!(layout_top, column_gap)
        layout[1,1] = layout_top

        return scene, layout, ys_n
    end

    function init_bandpowers!(
        scene::Scene, 
        layout::GridLayout; 
        theme = :light, 
        color = :green, 
        kwargs...
    )
        
        n_bands = 5
        
        bottom_axes = []
        band_names = ["delta", "theta", "alpha", "beta", "gamma"]

        layout_bottom = GridLayout()
        for n = 1:n_bands
            push!(bottom_axes, LAxis(scene, title = band_names[n]))
            layout_bottom[1,n] = bottom_axes[n]
        end
        if theme == :dark
            set_dark!(bottom_axes)
        end
        layout[2,1] = layout_bottom
        rowsize!(layout, 2, Relative(0.3))

        bandpower_buffer_size = 100
        xs = 1:bandpower_buffer_size
        ys_n = []

        for n = 1:n_bands
            cb = CircularBuffer{Float64}(bandpower_buffer_size)
            append!(cb, rand(bandpower_buffer_size)) 
            push!(ys_n, Node(cb))
            lines!(bottom_axes[n], xs, ys_n[n], color = color, linewidth = 2)
        end

        return ys_n
    end

    # live plotting function
    function plot_data(
        data_func::Function, 
        nsamples::Int, 
        nchannels::Int; 
        delay = 0.05, 
        y_lim = :auto, 
        plot_band_powers::Bool = true, 
        board_id, 
        kwargs...
    )

        xs = collect(1:nsamples)
        #ys = zeros(nsamples, nchannels)
        ys = data_func()

        if y_lim === :auto
            y_lim = (minimum(ys), maximum(ys))
            println("ylim = $y_lim")
        end

        scene, layout, ys_n = init_scene(xs, ys; y_lim = y_lim, kwargs...)

        # add a nested grid at the bottom
        if plot_band_powers
            bands_data = init_bandpowers!(scene, layout; kwargs...)
        end

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

            if plot_band_powers
                avg_band_powers = calc_avg_band_powers(ys, board_id)[1]
                n_bands = length(bands_data)
                for n = 1:n_bands
                    cb = bands_data[n][]
                    push!(cb, avg_band_powers[n])
                    bands_data[n][] = cb
                end
            end

            # optional if you want to zoom in + update limits:
            # AbstractPlotting.update_limits!(scene)
            # AbstractPlotting.update!(scene)

            # yield() # allow another task to run, e.g. brainflow data gathering? or use yieldto()
        end
    end

end # module
